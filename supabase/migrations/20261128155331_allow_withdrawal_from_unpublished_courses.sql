-- Allow learners to withdraw from courses that have since been unpublished.
-- New self-enrolments remain restricted to published, explicitly free courses.

create or replace function public.manage_course_enrollment(
  p_course_slug text,
  p_action text
)
returns void
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
  v_course_id uuid;
  v_course_access_type text;
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

  if p_action = 'enrol' then
    select c.id, c.access_type into v_course_id, v_course_access_type
    from public.courses c
    where c.slug = p_course_slug and c.status = 'published';
  else
    select c.id, c.access_type into v_course_id, v_course_access_type
    from public.courses c
    where c.slug = p_course_slug;
  end if;

  if v_course_id is null then
    raise exception 'This course is not currently available' using errcode = 'P0002';
  end if;

  if p_action = 'enrol' and coalesce(v_course_access_type, 'unconfigured') <> 'free' then
    raise exception 'Verified payment is required before enrolling in this course'
      using errcode = '42501';
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
      raise exception 'You are not actively enrolled in this course'
        using errcode = 'P0002';
    end if;

    update public.course_enrollments
    set status = 'withdrawn', withdrawn_at = now()
    where id = v_enrollment_id;

    insert into public.course_enrollment_events(enrollment_id, user_id, event_type)
    values (v_enrollment_id, v_user_id, 'withdrawn');
  end if;
end;
$function$;
