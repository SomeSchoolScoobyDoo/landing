
begin;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to anon, authenticated;

alter table public.courses
  add column if not exists certificate_enabled boolean not null default false,
  add column if not exists certificate_requires_practical_verification boolean not null default true,
  add column if not exists certificate_requires_participation_review boolean not null default false;
alter table public.assessments
  add column if not exists required_for_certificate boolean not null default false;

create table if not exists private.academy_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  granted_at timestamptz not null default now(),
  granted_by uuid references auth.users(id) on delete set null
);
alter table private.academy_admins enable row level security;
revoke all on private.academy_admins from public, anon, authenticated;

create table if not exists private.certificate_templates (
  version text primary key,
  signature_asset_path text not null,
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null
);
alter table private.certificate_templates enable row level security;
revoke all on private.certificate_templates from public, anon, authenticated;
insert into private.certificate_templates(version, signature_asset_path, is_active)
values ('original-slide-v1', 'certificates/chisom-okafor-signature.png', false)
on conflict (version) do nothing;

create table if not exists public.course_certificates (
  id uuid primary key default gen_random_uuid(),
  certificate_number text not null unique default ('KZA-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 20))),
  user_id uuid not null references auth.users(id) on delete restrict,
  course_id uuid not null references public.courses(id) on delete restrict,
  enrollment_id uuid not null references public.course_enrollments(id) on delete restrict,
  learner_name_snapshot text not null check (char_length(trim(learner_name_snapshot)) between 2 and 120),
  course_title_snapshot text not null check (char_length(trim(course_title_snapshot)) between 1 and 180),
  certificate_title text not null default 'CERTIFICATE OF PARTICIPATION',
  recognition_text text not null,
  signatory_name text not null default 'Chisom Okafor',
  signatory_title text not null default 'Founder & CEO',
  institution_name text not null default 'KAIZORA AI ACADEMY',
  template_version text not null references private.certificate_templates(version),
  requirements_snapshot jsonb not null default '{}'::jsonb,
  status text not null default 'valid' check (status in ('valid', 'revoked')),
  issued_at timestamptz not null default now(),
  revoked_at timestamptz,
  revoked_by uuid references auth.users(id) on delete set null,
  revocation_reason text check (revocation_reason is null or char_length(revocation_reason) <= 1000),
  reissued_from_id uuid references public.course_certificates(id) on delete set null,
  check ((status = 'valid' and revoked_at is null and revoked_by is null) or (status = 'revoked' and revoked_at is not null))
);
create unique index if not exists course_certificates_one_valid_per_learner_course
  on public.course_certificates(user_id, course_id) where status = 'valid';
create index if not exists course_certificates_user_issued_idx
  on public.course_certificates(user_id, issued_at desc);
comment on table public.course_certificates is 'Formal course certificates, separate from ordinary course completion badges.';

create table if not exists public.certificate_email_deliveries (
  id uuid primary key default gen_random_uuid(),
  certificate_id uuid not null references public.course_certificates(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  recipient_email text not null check (char_length(recipient_email) <= 320),
  status text not null default 'pending' check (status in ('pending', 'sent', 'failed', 'not_configured')),
  attempt_count integer not null default 0 check (attempt_count >= 0),
  last_error text check (last_error is null or char_length(last_error) <= 2000),
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (certificate_id)
);

create or replace function private.is_academy_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from private.academy_admins a where a.user_id = auth.uid());
$$;
revoke all on function private.is_academy_admin() from public, anon;
grant execute on function private.is_academy_admin() to authenticated;

create or replace function public.is_academy_admin()
returns boolean language sql stable security invoker set search_path = ''
as $$ select private.is_academy_admin(); $$;
revoke all on function public.is_academy_admin() from public, anon;
grant execute on function public.is_academy_admin() to authenticated;

create or replace function private.certificate_eligibility_for_user(p_user_id uuid, p_course_id uuid)
returns table(eligible boolean, reason text, template_version text)
language plpgsql stable security definer set search_path = ''
as $$
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
  if not exists (select 1 from public.course_enrollments e where e.user_id = p_user_id and e.course_id = p_course_id and e.status = 'active') then
    return query select false, 'An active course enrolment is required'::text, null::text; return;
  end if;
  select count(*) into v_lesson_count
  from public.lessons l join public.course_modules m on m.id = l.module_id
  where m.course_id = p_course_id and m.status = 'published' and l.status = 'published';
  if v_lesson_count = 0 then
    return query select false, 'This course has no published lessons to complete'::text, null::text; return;
  end if;
  if exists (
    select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    where m.course_id = p_course_id and m.status = 'published' and l.status = 'published'
      and not exists (select 1 from public.lesson_progress p where p.user_id = p_user_id and p.lesson_id = l.id and p.completed_at is not null)
  ) then
    return query select false, 'Complete every published lesson before requesting a certificate'::text, null::text; return;
  end if;
  if exists (
    select 1 from public.assessments a
    where a.course_id = p_course_id and a.required_for_certificate
      and (a.status <> 'published' or not exists (
        select 1 from public.assessment_attempts aa
        where aa.assessment_id = a.id and aa.user_id = p_user_id and aa.passed = true
      ))
  ) then
    return query select false, 'Pass every assessment marked as required for this certificate'::text, null::text; return;
  end if;
  if v_course.certificate_requires_practical_verification and exists (
    select 1 from public.lessons l join public.course_modules m on m.id = l.module_id
    where m.course_id = p_course_id and m.status = 'published' and l.status = 'published'
      and coalesce(l.content, '{}'::jsonb) ? 'practical_exercise'
  ) then
    return query select false, 'This course includes practical exercises, but verified practical submissions are not yet supported by the LMS'::text, null::text; return;
  end if;
  if v_course.certificate_requires_participation_review then
    return query select false, 'Additional participation review is required, but no participation review record exists yet'::text, null::text; return;
  end if;
  select p.full_name into v_name from public.profiles p where p.id = p_user_id;
  if v_name is null or char_length(trim(v_name)) < 2 then
    return query select false, 'A verified learner profile name is required'::text, null::text; return;
  end if;
  select t.version into v_template from private.certificate_templates t where t.is_active = true order by t.created_at desc limit 1;
  if v_template is null then
    return query select false, 'The approved certificate artwork and authentic signatory signature are not installed yet'::text, null::text; return;
  end if;
  return query select true, null::text, v_template;
end;
$$;
revoke all on function private.certificate_eligibility_for_user(uuid, uuid) from public, anon;
grant execute on function private.certificate_eligibility_for_user(uuid, uuid) to authenticated;

create or replace function public.get_certificate_eligibility(p_course_id uuid)
returns table(eligible boolean, reason text)
language sql stable security invoker set search_path = ''
as $$
  select e.eligible, e.reason from private.certificate_eligibility_for_user(auth.uid(), p_course_id) e;
$$;
revoke all on function public.get_certificate_eligibility(uuid) from public, anon;
grant execute on function public.get_certificate_eligibility(uuid) to authenticated;

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
  select count(distinct x) into v_requested from unnest(coalesce(p_required_assessment_ids, array[]::uuid[])) as x;
  select count(distinct a.id) into v_valid from public.assessments a
    where a.course_id = p_course_id and a.status = 'published'
      and a.id = any(coalesce(p_required_assessment_ids, array[]::uuid[]));
  if v_requested <> v_valid then
    raise exception 'One or more required assessments do not belong to this published course' using errcode = '22023';
  end if;
  if not exists (select 1 from public.courses c where c.id = p_course_id) then
    raise exception 'Course not found' using errcode = 'P0002';
  end if;
  update public.assessments a set required_for_certificate =
    (a.id = any(coalesce(p_required_assessment_ids, array[]::uuid[])))
    where a.course_id = p_course_id;
  update public.courses c set
    certificate_enabled = p_enabled,
    certificate_requires_practical_verification = coalesce(p_practical_verification_required, true),
    certificate_requires_participation_review = coalesce(p_participation_review_required, false),
    updated_at = now()
    where c.id = p_course_id;
end;
$$;
revoke all on function private.configure_course_certificate(uuid, boolean, uuid[], boolean, boolean) from public, anon;
grant execute on function private.configure_course_certificate(uuid, boolean, uuid[], boolean, boolean) to authenticated;

create or replace function public.configure_course_certificate(
  p_course_id uuid, p_enabled boolean, p_required_assessment_ids uuid[],
  p_practical_verification_required boolean, p_participation_review_required boolean
)
returns void language sql security invoker set search_path = ''
as $$
  select private.configure_course_certificate(p_course_id, p_enabled, p_required_assessment_ids,
    p_practical_verification_required, p_participation_review_required);
$$;
revoke all on function public.configure_course_certificate(uuid, boolean, uuid[], boolean, boolean) from public, anon;
grant execute on function public.configure_course_certificate(uuid, boolean, uuid[], boolean, boolean) to authenticated;

create or replace function private.issue_course_certificate_for_user(p_user_id uuid, p_course_id uuid, p_allow_reissue boolean)
returns public.course_certificates
language plpgsql security definer set search_path = ''
as $$
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
  if auth.uid() is null then raise exception 'Authentication required' using errcode = '28000'; end if;
  if p_allow_reissue then
    if not private.is_academy_admin() then raise exception 'Academy administrator access required' using errcode = '42501'; end if;
  elsif p_user_id <> auth.uid() then
    raise exception 'You can only request your own certificate' using errcode = '42501';
  end if;
  select e.id into v_enrollment from public.course_enrollments e
    where e.user_id = p_user_id and e.course_id = p_course_id and e.status = 'active' for update;
  if v_enrollment is null then raise exception 'An active course enrolment is required' using errcode = '42501'; end if;
  select e.eligible, e.reason, e.template_version into v_eligible, v_reason, v_template
    from private.certificate_eligibility_for_user(p_user_id, p_course_id) e;
  if not coalesce(v_eligible, false) then
    raise exception '%', coalesce(v_reason, 'Certificate eligibility could not be verified') using errcode = 'P0001';
  end if;
  select c.* into v_course from public.courses c where c.id = p_course_id;
  select p.* into v_profile from public.profiles p where p.id = p_user_id;
  select coalesce(jsonb_agg(a.id order by a.display_order), '[]'::jsonb) into v_required
    from public.assessments a where a.course_id = p_course_id and a.required_for_certificate;
  select c.* into v_existing from public.course_certificates c
    where c.user_id = p_user_id and c.course_id = p_course_id and c.status = 'valid' for update;
  if found and not p_allow_reissue then return v_existing; end if;
  if found and p_allow_reissue then
    update public.course_certificates set status='revoked', revoked_at=now(), revoked_by=auth.uid(),
      revocation_reason='Reissued by academy administrator' where id=v_existing.id;
    v_previous := v_existing.id;
  else
    select c.id into v_previous from public.course_certificates c
      where c.user_id=p_user_id and c.course_id=p_course_id order by c.issued_at desc limit 1;
    if v_previous is not null and not p_allow_reissue then
      raise exception 'A previous certificate was revoked; an academy administrator must authorise reissue' using errcode = '42501';
    end if;
  end if;
  insert into public.course_certificates(
    user_id, course_id, enrollment_id, learner_name_snapshot, course_title_snapshot,
    recognition_text, template_version, requirements_snapshot, reissued_from_id
  ) values (
    p_user_id, p_course_id, v_enrollment, v_profile.full_name, v_course.title,
    'in recognition of their participation in the ' || v_course.title ||
    ' programme, having completed the required learning activities, practical tasks, and participation requirements.',
    v_template,
    jsonb_build_object('all_published_lessons_required', true, 'required_assessment_ids', v_required,
      'practical_verification_required', v_course.certificate_requires_practical_verification,
      'participation_review_required', v_course.certificate_requires_participation_review),
    v_previous
  ) returning * into v_result;
  return v_result;
end;
$$;
revoke all on function private.issue_course_certificate_for_user(uuid, uuid, boolean) from public, anon;
grant execute on function private.issue_course_certificate_for_user(uuid, uuid, boolean) to authenticated;

create or replace function public.issue_course_certificate(p_course_id uuid)
returns table(id uuid, certificate_number text, issued_at timestamptz, course_title text, status text)
language sql security invoker set search_path = ''
as $$
  select c.id, c.certificate_number, c.issued_at, c.course_title_snapshot, c.status
  from private.issue_course_certificate_for_user(auth.uid(), p_course_id, false) c;
$$;
revoke all on function public.issue_course_certificate(uuid) from public, anon;
grant execute on function public.issue_course_certificate(uuid) to authenticated;

create or replace function public.reissue_course_certificate(p_user_id uuid, p_course_id uuid)
returns table(id uuid, certificate_number text, issued_at timestamptz, course_title text, status text)
language sql security invoker set search_path = ''
as $$
  select c.id, c.certificate_number, c.issued_at, c.course_title_snapshot, c.status
  from private.issue_course_certificate_for_user(p_user_id, p_course_id, true) c;
$$;
revoke all on function public.reissue_course_certificate(uuid, uuid) from public, anon;
grant execute on function public.reissue_course_certificate(uuid, uuid) to authenticated;

create or replace function private.revoke_course_certificate(p_certificate_id uuid, p_reason text)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null or not private.is_academy_admin() then
    raise exception 'Academy administrator access required' using errcode = '42501';
  end if;
  if p_certificate_id is null or p_reason is null or char_length(trim(p_reason)) < 3 or char_length(p_reason) > 1000 then
    raise exception 'A certificate and revocation reason are required' using errcode = '22023';
  end if;
  update public.course_certificates set status='revoked', revoked_at=now(), revoked_by=auth.uid(),
    revocation_reason=trim(p_reason) where id=p_certificate_id and status='valid';
  if not found then raise exception 'A valid certificate with that ID was not found' using errcode = 'P0002'; end if;
end;
$$;
revoke all on function private.revoke_course_certificate(uuid, text) from public, anon;
grant execute on function private.revoke_course_certificate(uuid, text) to authenticated;

create or replace function public.revoke_course_certificate(p_certificate_id uuid, p_reason text)
returns void language sql security invoker set search_path = ''
as $$ select private.revoke_course_certificate(p_certificate_id, p_reason); $$;
revoke all on function public.revoke_course_certificate(uuid, text) from public, anon;
grant execute on function public.revoke_course_certificate(uuid, text) to authenticated;

create or replace function private.verify_course_certificate(p_certificate_number text)
returns table(certificate_number text, learner_name text, course_title text, issued_at timestamptz,
  status text, signatory_name text, signatory_title text, institution_name text)
language sql stable security definer set search_path = ''
as $$
  select c.certificate_number, c.learner_name_snapshot, c.course_title_snapshot, c.issued_at,
    c.status, c.signatory_name, c.signatory_title, c.institution_name
  from public.course_certificates c
  where c.certificate_number = upper(trim(p_certificate_number));
$$;
revoke all on function private.verify_course_certificate(text) from public;
grant execute on function private.verify_course_certificate(text) to anon, authenticated;

create or replace function public.verify_course_certificate(p_certificate_number text)
returns table(certificate_number text, learner_name text, course_title text, issued_at timestamptz,
  status text, signatory_name text, signatory_title text, institution_name text)
language sql stable security invoker set search_path = ''
as $$ select * from private.verify_course_certificate(p_certificate_number); $$;
revoke all on function public.verify_course_certificate(text) from public;
grant execute on function public.verify_course_certificate(text) to anon, authenticated;

create or replace function private.set_certificate_template_active(p_version text, p_active boolean)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null or not private.is_academy_admin() then
    raise exception 'Academy administrator access required' using errcode = '42501';
  end if;
  if not exists (select 1 from private.certificate_templates t where t.version=p_version) then
    raise exception 'Certificate template not found' using errcode = 'P0002';
  end if;
  if p_active then update private.certificate_templates set is_active=false; end if;
  update private.certificate_templates set is_active=p_active, created_by=coalesce(created_by, auth.uid())
    where version=p_version;
end;
$$;
revoke all on function private.set_certificate_template_active(text, boolean) from public, anon;
grant execute on function private.set_certificate_template_active(text, boolean) to authenticated;

create or replace function public.set_certificate_template_active(p_version text, p_active boolean)
returns void language sql security invoker set search_path = ''
as $$ select private.set_certificate_template_active(p_version, p_active); $$;
revoke all on function public.set_certificate_template_active(text, boolean) from public, anon;
grant execute on function public.set_certificate_template_active(text, boolean) to authenticated;

alter table public.course_certificates enable row level security;
alter table public.certificate_email_deliveries enable row level security;
revoke all on public.course_certificates from anon, authenticated;
revoke all on public.certificate_email_deliveries from anon, authenticated;
grant select on public.course_certificates to authenticated;
grant select on public.certificate_email_deliveries to authenticated;
grant all on public.course_certificates to service_role;
grant all on public.certificate_email_deliveries to service_role;

drop policy if exists "Learners can view their own certificates" on public.course_certificates;
create policy "Learners can view their own certificates" on public.course_certificates
for select to authenticated using ((select auth.uid()) = user_id or public.is_academy_admin());

drop policy if exists "Learners can view their own certificate email deliveries" on public.certificate_email_deliveries;
create policy "Learners can view their own certificate email deliveries" on public.certificate_email_deliveries
for select to authenticated using ((select auth.uid()) = user_id or public.is_academy_admin());

drop policy if exists "Academy admins can view all courses" on public.courses;
create policy "Academy admins can view all courses" on public.courses
for select to authenticated using (public.is_academy_admin());

drop policy if exists "Academy admins can view all assessments" on public.assessments;
create policy "Academy admins can view all assessments" on public.assessments
for select to authenticated using (public.is_academy_admin());

commit;
