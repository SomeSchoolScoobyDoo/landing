-- Course feedback submitted by learners after completing a course.
create table if not exists public.course_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  overall_rating smallint not null check (overall_rating between 1 and 5),
  content_clarity smallint not null check (content_clarity between 1 and 5),
  learning_pace smallint not null check (learning_pace between 1 and 5),
  practical_confidence smallint not null check (practical_confidence between 1 and 5),
  most_useful text not null default '' check (char_length(most_useful) <= 2000),
  improvement_suggestion text not null default '' check (char_length(improvement_suggestion) <= 2000),
  blockers text not null default '' check (char_length(blockers) <= 2000),
  would_recommend boolean,
  submitted_at timestamptz not null default now(),
  unique (user_id, course_id)
);

create index if not exists course_feedback_course_submitted_idx
  on public.course_feedback(course_id, submitted_at desc);

alter table public.course_feedback enable row level security;
revoke all on public.course_feedback from anon, authenticated;
grant select, insert on public.course_feedback to authenticated;
grant all on public.course_feedback to service_role;

drop policy if exists "Learners can read their own course feedback" on public.course_feedback;
create policy "Learners can read their own course feedback"
on public.course_feedback for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Learners can submit feedback for active enrolments" on public.course_feedback;
create policy "Learners can submit feedback for active enrolments"
on public.course_feedback for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.course_enrollments e
    where e.user_id = (select auth.uid())
      and e.course_id = course_feedback.course_id
      and e.status = 'active'
  )
);

-- Include the complete platform journey in tester feedback.
alter table public.course_feedback
  add column if not exists platform_experience_rating smallint not null default 3
  check (platform_experience_rating between 1 and 5);
