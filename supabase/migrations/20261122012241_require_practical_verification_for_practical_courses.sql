
begin;
create or replace function private.configure_course_certificate(
  p_course_id uuid, p_enabled boolean, p_required_assessment_ids uuid[],
  p_practical_verification_required boolean, p_participation_review_required boolean
)
returns void language plpgsql security definer set search_path = ''
as $$
declare v_requested integer; v_valid integer;
begin
  if auth.uid() is null or not private.is_academy_admin() then
    raise exception 'Academy administrator access required' using errcode = '42501';
  end if;
  if p_course_id is null or p_enabled is null then
    raise exception 'A valid course and certificate setting are required' using errcode = '22023';
  end if;
  select count(distinct x) into v_requested
    from unnest(coalesce(p_required_assessment_ids, array[]::uuid[])) as x;
  select count(distinct a.id) into v_valid
    from public.assessments a
    where a.course_id = p_course_id and a.status = 'published'
      and a.id = any(coalesce(p_required_assessment_ids, array[]::uuid[]));
  if v_requested <> v_valid then
    raise exception 'One or more required assessments do not belong to this published course' using errcode = '22023';
  end if;
  if not exists (select 1 from public.courses c where c.id = p_course_id) then
    raise exception 'Course not found' using errcode = 'P0002';
  end if;
  if not coalesce(p_practical_verification_required, true) and exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    where m.course_id = p_course_id
      and m.status = 'published'
      and l.status = 'published'
      and coalesce(l.content, '{}'::jsonb) ? 'practical_exercise'
  ) then
    raise exception 'Practical verification cannot be disabled while this course contains practical exercises without verified submission records' using errcode = '22023';
  end if;

  update public.assessments a
  set required_for_certificate = (a.id = any(coalesce(p_required_assessment_ids, array[]::uuid[])))
  where a.course_id = p_course_id;

  update public.courses c set
    certificate_enabled = p_enabled,
    certificate_requires_practical_verification = coalesce(p_practical_verification_required, true),
    certificate_requires_participation_review = coalesce(p_participation_review_required, false),
    updated_at = now()
  where c.id = p_course_id;
end;
$$;
commit;
