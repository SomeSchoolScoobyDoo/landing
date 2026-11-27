-- Badge of Completion is a separate recognition from formal course certificates.
create table if not exists public.course_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade,
  course_title text not null,
  badge_title text not null,
  badge_description text not null default 'Awarded for completing all published lessons in this course.',
  issued_at timestamptz not null default now(),
  unique (user_id, course_id)
);

create index if not exists course_badges_user_issued_idx
  on public.course_badges(user_id, issued_at desc);

alter table public.course_badges enable row level security;
revoke all on public.course_badges from anon, authenticated;
grant select on public.course_badges to authenticated;
grant all on public.course_badges to service_role;

drop policy if exists "Learners can view their own course badges" on public.course_badges;
create policy "Learners can view their own course badges"
on public.course_badges for select to authenticated
using ((select auth.uid()) = user_id);

create or replace function public.award_course_badge_on_completion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_course_id uuid;
  v_course_title text;
begin
  if new.completed_at is null then
    return new;
  end if;

  select m.course_id, c.title
    into v_course_id, v_course_title
  from public.lessons l
  join public.course_modules m on m.id = l.module_id
  join public.courses c on c.id = m.course_id
  where l.id = new.lesson_id
    and l.status = 'published'
    and m.status = 'published'
    and c.status = 'published';

  if v_course_id is null then
    return new;
  end if;

  if exists (
    select 1 from public.course_enrollments e
    where e.user_id = new.user_id
      and e.course_id = v_course_id
      and e.status = 'active'
  ) and not exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    where m.course_id = v_course_id
      and m.status = 'published'
      and l.status = 'published'
      and not exists (
        select 1 from public.lesson_progress p
        where p.user_id = new.user_id
          and p.lesson_id = l.id
          and p.completed_at is not null
      )
  ) then
    insert into public.course_badges(user_id, course_id, course_title, badge_title)
    values (new.user_id, v_course_id, v_course_title, v_course_title || ' Completion Badge')
    on conflict (user_id, course_id) do nothing;
  end if;

  return new;
end;
$$;

revoke all on function public.award_course_badge_on_completion() from public, anon, authenticated;

drop trigger if exists award_course_badge_after_lesson_completion on public.lesson_progress;
create trigger award_course_badge_after_lesson_completion
after insert or update of completed_at on public.lesson_progress
for each row execute function public.award_course_badge_on_completion();
