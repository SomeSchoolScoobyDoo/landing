-- Step 9: explicit learner course enrolment.
-- Learners may self-enrol only in courses that are currently published.
-- Enrolment rows are private to their owner and cannot be edited by clients.

create table if not exists public.course_enrollments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  enrolled_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint course_enrollments_user_course_key unique (user_id, course_id)
);

create index if not exists course_enrollments_user_recent_idx
  on public.course_enrollments(user_id, enrolled_at desc);
create index if not exists course_enrollments_course_idx
  on public.course_enrollments(course_id);

drop trigger if exists course_enrollments_set_updated_at on public.course_enrollments;
create trigger course_enrollments_set_updated_at
before update on public.course_enrollments
for each row execute function public.set_updated_at();

alter table public.course_enrollments enable row level security;
revoke all on public.course_enrollments from anon, authenticated;
grant select, insert on public.course_enrollments to authenticated;
grant all on public.course_enrollments to service_role;

drop policy if exists "Learners can view their own course enrolments" on public.course_enrollments;
create policy "Learners can view their own course enrolments"
on public.course_enrollments for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Learners can enrol themselves in published courses" on public.course_enrollments;
create policy "Learners can enrol themselves in published courses"
on public.course_enrollments for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.courses c
    where c.id = course_enrollments.course_id
      and c.status = 'published'
  )
);

-- There are deliberately no client UPDATE or DELETE grants/policies.
-- Enrolment status and institutional entitlements require trusted workflows
-- when paid school/corporate learning is introduced.
