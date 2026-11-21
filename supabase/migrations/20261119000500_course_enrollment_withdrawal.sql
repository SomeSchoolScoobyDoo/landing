-- Step 9 follow-up: learner withdrawal and re-enrolment.
-- Keep enrolment rows and learning progress. Learners never receive direct UPDATE/DELETE rights.

alter table public.course_enrollments
  add column if not exists status text not null default 'active'
    check (status in ('active', 'withdrawn')),
  add column if not exists withdrawn_at timestamptz;

create index if not exists course_enrollments_active_user_idx
  on public.course_enrollments(user_id, enrolled_at desc)
  where status = 'active';

create table if not exists public.course_enrollment_events (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references public.course_enrollments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null check (event_type in ('enrolled', 'withdrawn', 're_enrolled')),
  occurred_at timestamptz not null default now()
);

create index if not exists course_enrollment_events_owner_recent_idx
  on public.course_enrollment_events(user_id, occurred_at desc);

-- Preserve a starting point for learners who were already enrolled before this
-- migration introduced the event-history table.
insert into public.course_enrollment_events(enrollment_id, user_id, event_type, occurred_at)
select e.id, e.user_id, 'enrolled', e.enrolled_at
from public.course_enrollments e
where e.status = 'active'
  and not exists (
    select 1 from public.course_enrollment_events ev
    where ev.enrollment_id = e.id
  );

-- All enrolment writes must pass through the validated security-definer workflow
-- so event history cannot be bypassed by direct client inserts.
revoke insert on public.course_enrollments from authenticated;
drop policy if exists "Learners can enrol themselves in published courses" on public.course_enrollments;

alter table public.course_enrollment_events enable row level security;
revoke all on public.course_enrollment_events from anon, authenticated;
grant select on public.course_enrollment_events to authenticated;
grant all on public.course_enrollment_events to service_role;

drop policy if exists "Learners can view their own enrolment history" on public.course_enrollment_events;
create policy "Learners can view their own enrolment history"
on public.course_enrollment_events for select to authenticated
using ((select auth.uid()) = user_id);

create or replace function public.manage_course_enrollment(
  p_course_slug text,
  p_action text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_course_id uuid;
  v_enrollment_id uuid;
  v_status text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if p_course_slug is null
     or p_course_slug !~ '^[a-z0-9-]{1,120}$'
     or p_action is null
     or p_action not in ('enrol', 'withdraw') then
    raise exception 'Invalid course enrolment request' using errcode = '22023';
  end if;

  select c.id into v_course_id
  from public.courses c
  where c.slug = p_course_slug and c.status = 'published';

  if v_course_id is null then
    raise exception 'This course is not currently available' using errcode = 'P0002';
  end if;

  select e.id, e.status into v_enrollment_id, v_status
  from public.course_enrollments e
  where e.user_id = v_user_id and e.course_id = v_course_id
  for update;

  if p_action = 'enrol' then
    if v_enrollment_id is null then
      insert into public.course_enrollments(user_id, course_id, status)
      values (v_user_id, v_course_id, 'active')
      on conflict (user_id, course_id) do nothing
      returning id into v_enrollment_id;

      -- A concurrent enrolment may have won the unique-key race.
      if v_enrollment_id is null then
        select e.id, e.status into v_enrollment_id, v_status
        from public.course_enrollments e
        where e.user_id = v_user_id and e.course_id = v_course_id
        for update;
      else
        insert into public.course_enrollment_events(enrollment_id, user_id, event_type)
        values (v_enrollment_id, v_user_id, 'enrolled');
      end if;
    end if;

    if v_status = 'withdrawn' then
      update public.course_enrollments
      set status = 'active', enrolled_at = now(), withdrawn_at = null
      where id = v_enrollment_id;
      insert into public.course_enrollment_events(enrollment_id, user_id, event_type)
      values (v_enrollment_id, v_user_id, 're_enrolled');
    end if;
  else
    if v_enrollment_id is null or v_status <> 'active' then
      raise exception 'You are not actively enrolled in this course' using errcode = 'P0002';
    end if;

    update public.course_enrollments
    set status = 'withdrawn', withdrawn_at = now()
    where id = v_enrollment_id;

    insert into public.course_enrollment_events(enrollment_id, user_id, event_type)
    values (v_enrollment_id, v_user_id, 'withdrawn');
  end if;
end;
$$;

revoke all on function public.manage_course_enrollment(text, text) from public, anon;
grant execute on function public.manage_course_enrollment(text, text) to authenticated;
