-- Let learners choose a certificate display name without changing their account name.
alter table public.profiles
  add column if not exists certificate_display_name text;

alter table public.profiles
  drop constraint if exists profiles_certificate_display_name_length_check;

alter table public.profiles
  add constraint profiles_certificate_display_name_length_check
  check (
    certificate_display_name is null
    or char_length(btrim(certificate_display_name)) between 2 and 120
  );

create or replace function private.issue_course_certificate_for_user(
  p_user_id uuid,
  p_course_id uuid,
  p_allow_reissue boolean
)
returns public.course_certificates
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_enrollment uuid;
  v_eligible boolean;
  v_reason text;
  v_template text;
  v_course public.courses%rowtype;
  v_profile public.profiles%rowtype;
  v_existing public.course_certificates%rowtype;
  v_previous uuid;
  v_result public.course_certificates%rowtype;
  v_required jsonb;
  v_learner_name text;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if p_allow_reissue then
    if not private.is_academy_admin() then
      raise exception 'Academy administrator access required' using errcode = '42501';
    end if;
  elsif p_user_id <> auth.uid() then
    raise exception 'You can only request your own certificate' using errcode = '42501';
  end if;

  select e.id into v_enrollment
  from public.course_enrollments e
  where e.user_id = p_user_id
    and e.course_id = p_course_id
    and e.status = 'active'
  for update;

  if v_enrollment is null then
    raise exception 'An active course enrolment is required' using errcode = '42501';
  end if;

  select e.eligible, e.reason, e.template_version
    into v_eligible, v_reason, v_template
  from private.certificate_eligibility_for_user(p_user_id, p_course_id) e;

  if not coalesce(v_eligible, false) then
    raise exception '%', coalesce(v_reason, 'Certificate eligibility could not be verified')
      using errcode = 'P0001';
  end if;

  select c.* into v_course
  from public.courses c
  where c.id = p_course_id;

  select p.* into v_profile
  from public.profiles p
  where p.id = p_user_id;

  v_learner_name := coalesce(
    nullif(btrim(v_profile.certificate_display_name), ''),
    v_profile.full_name
  );

  if v_learner_name is null or char_length(btrim(v_learner_name)) < 2 then
    raise exception 'Set a valid certificate display name in account settings before issuing a certificate'
      using errcode = '22023';
  end if;

  select coalesce(jsonb_agg(a.id order by a.display_order), '[]'::jsonb)
    into v_required
  from public.assessments a
  where a.course_id = p_course_id
    and a.required_for_certificate;

  select c.* into v_existing
  from public.course_certificates c
  where c.user_id = p_user_id
    and c.course_id = p_course_id
    and c.status = 'valid'
  for update;

  if found and not p_allow_reissue then
    return v_existing;
  end if;

  if found and p_allow_reissue then
    update public.course_certificates
    set status = 'revoked',
        revoked_at = now(),
        revoked_by = auth.uid(),
        revocation_reason = 'Reissued by academy administrator'
    where id = v_existing.id;
    v_previous := v_existing.id;
  else
    select c.id into v_previous
    from public.course_certificates c
    where c.user_id = p_user_id
      and c.course_id = p_course_id
    order by c.issued_at desc
    limit 1;

    if v_previous is not null and not p_allow_reissue then
      raise exception 'A previous certificate was revoked; an academy administrator must authorise reissue'
        using errcode = '42501';
    end if;
  end if;

  insert into public.course_certificates (
    user_id,
    course_id,
    enrollment_id,
    learner_name_snapshot,
    course_title_snapshot,
    recognition_text,
    template_version,
    requirements_snapshot,
    reissued_from_id
  ) values (
    p_user_id,
    p_course_id,
    v_enrollment,
    v_learner_name,
    v_course.title,
    'in recognition of their successful completion of the ' || v_course.title ||
      ' course, including its required learning activities, practical tasks, and assessments.',
    v_template,
    jsonb_build_object(
      'all_published_lessons_required', true,
      'required_assessment_ids', v_required,
      'practical_verification_required', v_course.certificate_requires_practical_verification,
      'completion_review_required', v_course.certificate_requires_completion_review
    ),
    v_previous
  )
  returning * into v_result;

  return v_result;
end;
$function$;
