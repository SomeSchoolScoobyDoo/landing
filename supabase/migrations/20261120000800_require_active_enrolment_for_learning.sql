-- Step 9 follow-up: require an active enrolment to access learning content.
-- Public course previews remain available through the SECURITY DEFINER preview RPC.
-- Withdrawal hides learning content until the learner enrols again; progress and
-- assessment history remain stored and become available again after re-enrolment.

begin;

drop policy if exists "Learners can view modules in published courses" on public.course_modules;
create policy "Learners can view modules in published courses"
on public.course_modules for select to authenticated
using (
  status = 'published'
  and exists (
    select 1
    from public.courses c
    join public.course_enrollments e on e.course_id = c.id
    where c.id = course_modules.course_id
      and c.status = 'published'
      and e.user_id = (select auth.uid())
      and e.status = 'active'
  )
);

drop policy if exists "Learners can view lessons in published courses" on public.lessons;
create policy "Learners can view lessons in published courses"
on public.lessons for select to authenticated
using (
  status = 'published'
  and exists (
    select 1
    from public.course_modules m
    join public.courses c on c.id = m.course_id
    join public.course_enrollments e on e.course_id = c.id
    where m.id = lessons.module_id
      and m.status = 'published'
      and c.status = 'published'
      and e.user_id = (select auth.uid())
      and e.status = 'active'
  )
);

drop policy if exists "Learners can view resources for published lessons" on public.lesson_resources;
create policy "Learners can view resources for published lessons"
on public.lesson_resources for select to authenticated
using (
  exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = m.course_id
    join public.course_enrollments e on e.course_id = c.id
    where l.id = lesson_resources.lesson_id
      and l.status = 'published'
      and m.status = 'published'
      and c.status = 'published'
      and e.user_id = (select auth.uid())
      and e.status = 'active'
  )
);

drop policy if exists "Learners can read their own lesson progress" on public.lesson_progress;
create policy "Learners can read their own lesson progress"
on public.lesson_progress for select to authenticated
using (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.course_enrollments e on e.course_id = m.course_id
    where l.id = lesson_progress.lesson_id
      and e.user_id = (select auth.uid())
      and e.status = 'active'
  )
);

drop policy if exists "Learners can create their own lesson progress" on public.lesson_progress;
create policy "Learners can create their own lesson progress"
on public.lesson_progress for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = m.course_id
    join public.course_enrollments e on e.course_id = c.id
    where l.id = lesson_progress.lesson_id
      and l.status = 'published'
      and m.status = 'published'
      and c.status = 'published'
      and e.user_id = (select auth.uid())
      and e.status = 'active'
  )
);

drop policy if exists "Learners can update their own lesson progress" on public.lesson_progress;
create policy "Learners can update their own lesson progress"
on public.lesson_progress for update to authenticated
using (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.course_enrollments e on e.course_id = m.course_id
    where l.id = lesson_progress.lesson_id
      and e.user_id = (select auth.uid())
      and e.status = 'active'
  )
)
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = m.course_id
    join public.course_enrollments e on e.course_id = c.id
    where l.id = lesson_progress.lesson_id
      and l.status = 'published'
      and m.status = 'published'
      and c.status = 'published'
      and e.user_id = (select auth.uid())
      and e.status = 'active'
  )
);

drop policy if exists "Learners can view published course assessments" on public.assessments;
create policy "Learners can view published course assessments"
on public.assessments for select to authenticated
using (
  status = 'published'
  and exists (
    select 1
    from public.courses c
    join public.course_enrollments e on e.course_id = c.id
    where c.id = assessments.course_id
      and c.status = 'published'
      and e.user_id = (select auth.uid())
      and e.status = 'active'
  )
  and (
    lesson_id is null
    or exists (
      select 1
      from public.lessons l
      join public.course_modules m on m.id = l.module_id
      where l.id = assessments.lesson_id
        and l.status = 'published'
        and m.status = 'published'
        and m.course_id = assessments.course_id
    )
  )
);

drop policy if exists "Learners can view questions for published assessments" on public.assessment_questions;
create policy "Learners can view questions for published assessments"
on public.assessment_questions for select to authenticated
using (
  exists (
    select 1
    from public.assessments a
    join public.course_enrollments e on e.course_id = a.course_id
    where a.id = assessment_questions.assessment_id
      and a.status = 'published'
      and e.user_id = (select auth.uid())
      and e.status = 'active'
      and exists (
        select 1 from public.courses c
        where c.id = a.course_id and c.status = 'published'
      )
      and (
        a.lesson_id is null
        or exists (
          select 1
          from public.lessons l
          join public.course_modules m on m.id = l.module_id
          where l.id = a.lesson_id
            and l.status = 'published'
            and m.status = 'published'
            and m.course_id = a.course_id
        )
      )
  )
);

drop policy if exists "Learners can read their own assessment attempts" on public.assessment_attempts;
create policy "Learners can read their own assessment attempts"
on public.assessment_attempts for select to authenticated
using (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.assessments a
    join public.course_enrollments e on e.course_id = a.course_id
    where a.id = assessment_attempts.assessment_id
      and e.user_id = (select auth.uid())
      and e.status = 'active'
  )
);

create or replace function public.submit_assessment(
  p_assessment_id uuid,
  p_answers jsonb
)
returns table (
  attempt_id uuid,
  attempt_number integer,
  score_percentage numeric,
  passed boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
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
  where a.id = p_assessment_id and a.status = 'published'
    and (
      a.lesson_id is null
      or exists (
        select 1 from public.lessons l
        join public.course_modules m on m.id = l.module_id
        where l.id = a.lesson_id and l.status = 'published'
          and m.status = 'published' and m.course_id = a.course_id
      )
    );
  if not found then
    raise exception 'Assessment is unavailable' using errcode = 'P0002';
  end if;

  if not exists (
    select 1
    from public.course_enrollments e
    where e.user_id = v_user_id
      and e.course_id = v_assessment.course_id
      and e.status = 'active'
  ) then
    raise exception 'Active course enrolment required' using errcode = '42501';
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
$$;

revoke all on function public.submit_assessment(uuid, jsonb) from public, anon;
grant execute on function public.submit_assessment(uuid, jsonb) to authenticated;

commit;
