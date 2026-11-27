-- Support module-level quizzes and enforce the course's assessment sequence.

alter table public.assessments
  add column if not exists module_id uuid;

alter table public.assessments
  drop constraint if exists assessments_module_id_fkey;

alter table public.assessments
  add constraint assessments_module_id_fkey
  foreign key (module_id) references public.course_modules(id) on delete cascade;

alter table public.assessments
  drop constraint if exists assessments_assessment_type_check;

alter table public.assessments
  add constraint assessments_assessment_type_check
  check (assessment_type = any (array['lesson_quiz'::text, 'module_quiz'::text, 'final_assessment'::text]));

alter table public.assessments
  drop constraint if exists assessments_scope_check;

alter table public.assessments
  add constraint assessments_scope_check
  check (
    (assessment_type = 'lesson_quiz' and lesson_id is not null and module_id is null)
    or (assessment_type = 'module_quiz' and lesson_id is null and module_id is not null)
    or (assessment_type = 'final_assessment' and lesson_id is null and module_id is null)
  );

create unique index if not exists assessments_one_module_quiz_per_module
  on public.assessments(module_id)
  where assessment_type = 'module_quiz';

create index if not exists assessments_module_id_idx
  on public.assessments(module_id)
  where module_id is not null;

create or replace function public.submit_assessment(p_assessment_id uuid, p_answers jsonb)
returns table(attempt_id uuid, attempt_number integer, score_percentage numeric, passed boolean)
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
  v_assessment public.assessments%rowtype;
  v_question_count integer;
  v_answer_count integer;
  v_attempt_number integer;
  v_attempt_id uuid;
  v_correct_count integer := 0;
  v_question record;
  v_selected_key text;
  v_is_correct boolean;
  v_score numeric(5,2);
  v_passed boolean;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;
  if p_answers is null or jsonb_typeof(p_answers) <> 'array' then
    raise exception 'Answers must be a JSON array' using errcode = '22023';
  end if;

  select a.* into v_assessment
  from public.assessments a
  join public.courses c on c.id = a.course_id and c.status = 'published'
  where a.id = p_assessment_id
    and a.status = 'published'
    and (
      (
        a.assessment_type = 'lesson_quiz'
        and a.lesson_id is not null
        and a.module_id is null
        and exists (
          select 1 from public.lessons l
          join public.course_modules m on m.id = l.module_id
          where l.id = a.lesson_id
            and l.status = 'published'
            and m.status = 'published'
            and m.course_id = a.course_id
        )
      )
      or (
        a.assessment_type = 'module_quiz'
        and a.lesson_id is null
        and a.module_id is not null
        and exists (
          select 1 from public.course_modules m
          where m.id = a.module_id
            and m.status = 'published'
            and m.course_id = a.course_id
        )
      )
      or (
        a.assessment_type = 'final_assessment'
        and a.lesson_id is null
        and a.module_id is null
      )
    );
  if not found then
    raise exception 'Assessment is unavailable' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from public.course_enrollments e
    where e.user_id = v_user_id
      and e.course_id = v_assessment.course_id
      and e.status = 'active'
  ) then
    raise exception 'Active course enrolment required' using errcode = '42501';
  end if;

  if v_assessment.assessment_type = 'module_quiz' and exists (
    select 1
    from public.lessons l
    where l.module_id = v_assessment.module_id
      and l.status = 'published'
      and not exists (
        select 1 from public.lesson_progress lp
        where lp.lesson_id = l.id
          and lp.user_id = v_user_id
          and lp.completed_at is not null
      )
  ) then
    raise exception 'Complete all lessons in this module before taking the module quiz'
      using errcode = '42501';
  end if;

  if v_assessment.assessment_type = 'final_assessment' and exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    where m.course_id = v_assessment.course_id
      and m.status = 'published'
      and l.status = 'published'
      and not exists (
        select 1 from public.lesson_progress lp
        where lp.lesson_id = l.id
          and lp.user_id = v_user_id
          and lp.completed_at is not null
      )
  ) then
    raise exception 'Complete all published lessons before taking the final assessment'
      using errcode = '42501';
  end if;

  if v_assessment.assessment_type = 'final_assessment' and exists (
    select 1
    from public.assessments ma
    where ma.course_id = v_assessment.course_id
      and ma.assessment_type = 'module_quiz'
      and ma.status = 'published'
      and ma.required_for_certificate
      and not exists (
        select 1 from public.assessment_attempts aa
        where aa.assessment_id = ma.id
          and aa.user_id = v_user_id
          and aa.passed = true
      )
  ) then
    raise exception 'Pass every required module quiz before taking the final assessment'
      using errcode = '42501';
  end if;

  select count(*) into v_question_count
  from public.assessment_questions q where q.assessment_id = p_assessment_id;
  v_answer_count := jsonb_array_length(p_answers);
  if v_question_count = 0 or v_answer_count <> v_question_count then
    raise exception 'Submit one answer for every question' using errcode = '22023';
  end if;

  if (select count(*) from public.assessment_questions q
      join public.assessment_answer_keys k on k.question_id = q.id
      where q.assessment_id = p_assessment_id) <> v_question_count then
    raise exception 'Assessment answer keys are incomplete' using errcode = '22023';
  end if;

  if exists (
    select 1 from jsonb_array_elements(p_answers) as x(value)
    group by x.value->>'question_id' having count(*) > 1
  ) then
    raise exception 'Duplicate question answers are not allowed' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_answers) as x(value)
    left join public.assessment_questions q
      on q.id = (x.value->>'question_id')::uuid and q.assessment_id = p_assessment_id
    where q.id is null
  ) then
    raise exception 'Answer contains an unknown question' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_answers) as x(value)
    join public.assessment_questions q
      on q.id = (x.value->>'question_id')::uuid and q.assessment_id = p_assessment_id
    where not exists (
      select 1 from jsonb_array_elements(q.options) opt
      where opt->>'key' = x.value->>'selected_option_key'
    )
  ) then
    raise exception 'Answer contains an invalid option' using errcode = '22023';
  end if;

  select coalesce(max(t.attempt_number), 0) + 1 into v_attempt_number
  from public.assessment_attempts t
  where t.assessment_id = p_assessment_id and t.user_id = v_user_id;

  if v_attempt_number > v_assessment.max_attempts then
    raise exception 'Maximum assessment attempts reached' using errcode = 'P0001';
  end if;

  insert into public.assessment_attempts(assessment_id, user_id, attempt_number)
  values (p_assessment_id, v_user_id, v_attempt_number)
  returning id into v_attempt_id;

  for v_question in
    select q.id, k.correct_option_key, x.value->>'selected_option_key' as selected_key
    from public.assessment_questions q
    join public.assessment_answer_keys k on k.question_id = q.id
    join jsonb_array_elements(p_answers) as x(value) on (x.value->>'question_id')::uuid = q.id
    where q.assessment_id = p_assessment_id
    order by q.question_number
  loop
    v_selected_key := v_question.selected_key;
    v_is_correct := v_selected_key = v_question.correct_option_key;
    if v_is_correct then
      v_correct_count := v_correct_count + 1;
    end if;
    insert into public.assessment_attempt_answers(attempt_id, question_id, selected_option_key, is_correct)
    values (v_attempt_id, v_question.id, v_selected_key, v_is_correct);
  end loop;

  v_score := round((v_correct_count::numeric / v_question_count::numeric) * 100, 2);
  v_passed := v_score >= v_assessment.passing_score_percentage;

  update public.assessment_attempts t
  set score_percentage = v_score, passed = v_passed
  where t.id = v_attempt_id;

  return query select v_attempt_id, v_attempt_number, v_score, v_passed;
end;
$function$;
