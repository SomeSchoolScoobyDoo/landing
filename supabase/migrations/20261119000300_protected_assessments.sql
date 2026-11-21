-- Step 8: protected assessments, attempts, and server-side MCQ grading.
-- Learner-readable question content is separated from answer keys. Grading runs
-- in a SECURITY DEFINER RPC and returns only the aggregate result.

create table if not exists public.assessments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete cascade,
  assessment_type text not null check (assessment_type in ('lesson_quiz', 'final_assessment')),
  title text not null,
  instructions text not null default '',
  passing_score_percentage integer not null default 70 check (passing_score_percentage between 1 and 100),
  max_attempts integer not null default 3 check (max_attempts between 1 and 20),
  status text not null default 'draft' check (status in ('draft', 'published', 'archived')),
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint assessments_title_length check (char_length(trim(title)) between 2 and 180),
  constraint assessments_instructions_length check (char_length(instructions) <= 4000),
  constraint assessments_scope_check check (
    (assessment_type = 'lesson_quiz' and lesson_id is not null)
    or (assessment_type = 'final_assessment' and lesson_id is null)
  )
);

create unique index if not exists assessments_one_lesson_quiz_idx
  on public.assessments(lesson_id) where assessment_type = 'lesson_quiz';
create unique index if not exists assessments_one_final_assessment_idx
  on public.assessments(course_id) where assessment_type = 'final_assessment';
create index if not exists assessments_course_status_idx
  on public.assessments(course_id, status, display_order);

create table if not exists public.assessment_questions (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  question_number integer not null check (question_number > 0),
  prompt text not null,
  options jsonb not null,
  created_at timestamptz not null default now(),
  unique (assessment_id, question_number),
  constraint assessment_questions_prompt_length check (char_length(trim(prompt)) between 2 and 3000),
  constraint assessment_questions_options_array check (
    jsonb_typeof(options) = 'array'
    and jsonb_array_length(options) between 2 and 6
  )
);

-- Answer keys are never granted to anon/authenticated roles.
create table if not exists public.assessment_answer_keys (
  question_id uuid primary key references public.assessment_questions(id) on delete cascade,
  correct_option_key text not null check (char_length(correct_option_key) between 1 and 20),
  explanation text not null default '',
  created_at timestamptz not null default now(),
  constraint assessment_answer_explanation_length check (char_length(explanation) <= 2000)
);

create table if not exists public.assessment_attempts (
  id uuid primary key default gen_random_uuid(),
  assessment_id uuid not null references public.assessments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  attempt_number integer not null check (attempt_number > 0),
  score_percentage numeric(5,2) not null default 0 check (score_percentage between 0 and 100),
  passed boolean not null default false,
  submitted_at timestamptz not null default now(),
  unique (assessment_id, user_id, attempt_number)
);

-- Individual responses remain private. Learners receive only the aggregate
-- result from submit_assessment, not per-question correctness or answer keys.
create table if not exists public.assessment_attempt_answers (
  attempt_id uuid not null references public.assessment_attempts(id) on delete cascade,
  question_id uuid not null references public.assessment_questions(id) on delete cascade,
  selected_option_key text not null,
  is_correct boolean not null,
  primary key (attempt_id, question_id)
);

create index if not exists assessment_attempts_user_idx
  on public.assessment_attempts(user_id, assessment_id, submitted_at desc);

alter table public.assessments enable row level security;
alter table public.assessment_questions enable row level security;
alter table public.assessment_answer_keys enable row level security;
alter table public.assessment_attempts enable row level security;
alter table public.assessment_attempt_answers enable row level security;

revoke all on public.assessments, public.assessment_questions,
  public.assessment_answer_keys, public.assessment_attempts,
  public.assessment_attempt_answers from anon, authenticated;

grant select on public.assessments, public.assessment_questions to authenticated;
grant select on public.assessment_attempts to authenticated;
grant all on public.assessments, public.assessment_questions,
  public.assessment_answer_keys, public.assessment_attempts,
  public.assessment_attempt_answers to service_role;

drop policy if exists "Learners can view published course assessments" on public.assessments;
create policy "Learners can view published course assessments"
on public.assessments for select to authenticated
using (
  status = 'published'
  and exists (
    select 1 from public.courses c
    where c.id = assessments.course_id and c.status = 'published'
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
    select 1 from public.assessments a
    where a.id = assessment_questions.assessment_id
      and a.status = 'published'
      and exists (select 1 from public.courses c where c.id = a.course_id and c.status = 'published')
      and (
        a.lesson_id is null
        or exists (
          select 1 from public.lessons l
          join public.course_modules m on m.id = l.module_id
          where l.id = a.lesson_id and l.status = 'published'
            and m.status = 'published' and m.course_id = a.course_id
        )
      )
  )
);

drop policy if exists "Learners can read their own assessment attempts" on public.assessment_attempts;
create policy "Learners can read their own assessment attempts"
on public.assessment_attempts for select to authenticated
using ((select auth.uid()) = user_id);

-- No client policies or grants exist for answer keys or individual responses.

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
