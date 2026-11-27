
begin;
create or replace function private.mark_lesson_complete(p_lesson_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_completed_at timestamptz;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if not exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = m.course_id
    join public.course_enrollments e on e.course_id = c.id
    where l.id = p_lesson_id
      and l.status = 'published'
      and m.status = 'published'
      and c.status = 'published'
      and e.user_id = v_user_id
      and e.status = 'active'
  ) then
    raise exception 'An active enrolment and published lesson are required' using errcode = '42501';
  end if;

  insert into public.lesson_progress(user_id, lesson_id, completed_at)
  values (v_user_id, p_lesson_id, now())
  on conflict (user_id, lesson_id) do update
    set completed_at = coalesce(public.lesson_progress.completed_at, excluded.completed_at),
        updated_at = now()
  returning completed_at into v_completed_at;

  return v_completed_at;
end;
$$;
revoke all on function private.mark_lesson_complete(uuid) from public, anon;
grant execute on function private.mark_lesson_complete(uuid) to authenticated;

create or replace function public.mark_lesson_complete(p_lesson_id uuid)
returns timestamptz
language sql
security invoker
set search_path = ''
as $$
  select private.mark_lesson_complete(p_lesson_id);
$$;
revoke all on function public.mark_lesson_complete(uuid) from public, anon;
grant execute on function public.mark_lesson_complete(uuid) to authenticated;

drop policy if exists "Learners can create their own lesson progress" on public.lesson_progress;
drop policy if exists "Learners can update their own lesson progress" on public.lesson_progress;
revoke insert, update, delete on public.lesson_progress from authenticated;
grant select on public.lesson_progress to authenticated;
grant all on public.lesson_progress to service_role;
commit;
