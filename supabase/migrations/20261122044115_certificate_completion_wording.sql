begin;

-- Rename the internal policy field so the product consistently speaks about course completion.
drop function if exists public.configure_course_certificate(uuid, boolean, uuid[], boolean, boolean);
drop function if exists private.configure_course_certificate(uuid, boolean, uuid[], boolean, boolean);
alter table public.courses rename column certificate_requires_participation_review to certificate_requires_completion_review;
alter table public.course_certificates alter column certificate_title set default 'CERTIFICATE OF COMPLETION';
insert into private.certificate_templates(version, signature_asset_path, is_active)
values ('original-slide-v2', 'certificates/chisom-okafor-signature.png', false)
on conflict (version) do nothing;

create or replace function private.configure_course_certificate(
  p_course_id uuid,
  p_enabled boolean,
  p_required_assessment_ids uuid[],
  p_practical_verification_required boolean,
  p_completion_review_required boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_requested integer;
  v_valid integer;
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
  where a.course_id = p_course_id
    and a.status = 'published'
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
  update public.courses c
  set certificate_enabled = p_enabled,
      certificate_requires_practical_verification = coalesce(p_practical_verification_required, true),
      certificate_requires_completion_review = coalesce(p_completion_review_required, false),
      updated_at = now()
  where c.id = p_course_id;
end;
$function$;
revoke all on function private.configure_course_certificate(uuid, boolean, uuid[], boolean, boolean) from public, anon;
grant execute on function private.configure_course_certificate(uuid, boolean, uuid[], boolean, boolean) to authenticated;

create or replace function public.configure_course_certificate(
  p_course_id uuid,
  p_enabled boolean,
  p_required_assessment_ids uuid[],
  p_practical_verification_required boolean,
  p_completion_review_required boolean
)
returns void
language sql
security invoker
set search_path = ''
as $function$
  select private.configure_course_certificate(
    p_course_id, p_enabled, p_required_assessment_ids,
    p_practical_verification_required, p_completion_review_required
  );
$function$;
revoke all on function public.configure_course_certificate(uuid, boolean, uuid[], boolean, boolean) from public, anon;
grant execute on function public.configure_course_certificate(uuid, boolean, uuid[], boolean, boolean) to authenticated;

create or replace function private.certificate_eligibility_for_user(p_user_id uuid, p_course_id uuid)
returns table(eligible boolean, reason text, template_version text)
language plpgsql stable security definer set search_path = ''
as $function$
declare
  v_course public.courses%rowtype;
  v_name text;
  v_lesson_count integer;
  v_template text;
begin
  if p_user_id is null or p_course_id is null then
    return query select false, 'A learner and course are required'::text, null::text; return;
  end if;
  select c.* into v_course from public.courses c where c.id = p_course_id;
  if not found or v_course.status <> 'published' then
    return query select false, 'This course is not currently published'::text, null::text; return;
  end if;
  if not v_course.certificate_enabled then
    return query select false, 'This course is not configured to offer a formal certificate'::text, null::text; return;
  end if;
  if not exists (select 1 from public.course_enrollments e where e.user_id=p_user_id and e.course_id=p_course_id and e.status='active') then
    return query select false, 'An active course enrolment is required'::text, null::text; return;
  end if;
  select count(*) into v_lesson_count from public.lessons l join public.course_modules m on m.id=l.module_id
  where m.course_id=p_course_id and m.status='published' and l.status='published';
  if v_lesson_count=0 then
    return query select false, 'This course has no published lessons to complete'::text, null::text; return;
  end if;
  if exists (
    select 1 from public.lessons l join public.course_modules m on m.id=l.module_id
    where m.course_id=p_course_id and m.status='published' and l.status='published'
      and not exists (select 1 from public.lesson_progress p where p.user_id=p_user_id and p.lesson_id=l.id and p.completed_at is not null)
  ) then
    return query select false, 'Complete every published lesson before requesting a certificate'::text, null::text; return;
  end if;
  if exists (
    select 1 from public.assessments a where a.course_id=p_course_id and a.required_for_certificate
      and (a.status<>'published' or not exists (select 1 from public.assessment_attempts aa where aa.assessment_id=a.id and aa.user_id=p_user_id and aa.passed=true))
  ) then
    return query select false, 'Pass every assessment marked as required for this certificate'::text, null::text; return;
  end if;
  if v_course.certificate_requires_practical_verification and exists (
    select 1 from public.lessons l join public.course_modules m on m.id=l.module_id
    where m.course_id=p_course_id and m.status='published' and l.status='published'
      and coalesce(l.content, '{}'::jsonb) ? 'practical_exercise'
  ) then
    return query select false, 'This course includes practical exercises, but verified practical submissions are not yet supported by the LMS'::text, null::text; return;
  end if;
  if v_course.certificate_requires_completion_review then
    return query select false, 'Additional course-completion review is required, but no completion-review record exists yet'::text, null::text; return;
  end if;
  select p.full_name into v_name from public.profiles p where p.id=p_user_id;
  if v_name is null or char_length(trim(v_name))<2 then
    return query select false, 'A verified learner profile name is required'::text, null::text; return;
  end if;
  select t.version into v_template from private.certificate_templates t where t.is_active=true order by t.created_at desc limit 1;
  if v_template is null then
    return query select false, 'The approved certificate artwork and authentic signatory signature are not installed yet'::text, null::text; return;
  end if;
  return query select true, null::text, v_template;
end;
$function$;

create or replace function private.issue_course_certificate_for_user(p_user_id uuid,p_course_id uuid,p_allow_reissue boolean)
returns public.course_certificates
language plpgsql security definer set search_path = ''
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
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='28000'; end if;
  if p_allow_reissue then
    if not private.is_academy_admin() then raise exception 'Academy administrator access required' using errcode='42501'; end if;
  elsif p_user_id<>auth.uid() then
    raise exception 'You can only request your own certificate' using errcode='42501';
  end if;
  select e.id into v_enrollment from public.course_enrollments e
    where e.user_id=p_user_id and e.course_id=p_course_id and e.status='active' for update;
  if v_enrollment is null then raise exception 'An active course enrolment is required' using errcode='42501'; end if;
  select e.eligible,e.reason,e.template_version into v_eligible,v_reason,v_template
    from private.certificate_eligibility_for_user(p_user_id,p_course_id) e;
  if not coalesce(v_eligible,false) then
    raise exception '%',coalesce(v_reason,'Certificate eligibility could not be verified') using errcode='P0001';
  end if;
  select c.* into v_course from public.courses c where c.id=p_course_id;
  select p.* into v_profile from public.profiles p where p.id=p_user_id;
  select coalesce(jsonb_agg(a.id order by a.display_order),'[]'::jsonb) into v_required
    from public.assessments a where a.course_id=p_course_id and a.required_for_certificate;
  select c.* into v_existing from public.course_certificates c
    where c.user_id=p_user_id and c.course_id=p_course_id and c.status='valid' for update;
  if found and not p_allow_reissue then return v_existing; end if;
  if found and p_allow_reissue then
    update public.course_certificates set status='revoked',revoked_at=now(),revoked_by=auth.uid(),
      revocation_reason='Reissued by academy administrator' where id=v_existing.id;
    v_previous:=v_existing.id;
  else
    select c.id into v_previous from public.course_certificates c
      where c.user_id=p_user_id and c.course_id=p_course_id order by c.issued_at desc limit 1;
    if v_previous is not null and not p_allow_reissue then
      raise exception 'A previous certificate was revoked; an academy administrator must authorise reissue' using errcode='42501';
    end if;
  end if;
  insert into public.course_certificates(
    user_id,course_id,enrollment_id,learner_name_snapshot,course_title_snapshot,
    recognition_text,template_version,requirements_snapshot,reissued_from_id
  ) values (
    p_user_id,p_course_id,v_enrollment,v_profile.full_name,v_course.title,
    'in recognition of their successful completion of the '||v_course.title||
      ' course, including its required learning activities, practical tasks, and assessments.',
    v_template,
    jsonb_build_object('all_published_lessons_required',true,'required_assessment_ids',v_required,
      'practical_verification_required',v_course.certificate_requires_practical_verification,
      'completion_review_required',v_course.certificate_requires_completion_review),
    v_previous
  ) returning * into v_result;
  return v_result;
end;
$function$;
commit;
