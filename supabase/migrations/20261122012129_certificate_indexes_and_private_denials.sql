
begin;
create index if not exists academy_admins_granted_by_idx on private.academy_admins(granted_by);
create index if not exists certificate_templates_created_by_idx on private.certificate_templates(created_by);
create index if not exists certificate_email_deliveries_user_idx on public.certificate_email_deliveries(user_id);
create index if not exists course_certificates_course_idx on public.course_certificates(course_id);
create index if not exists course_certificates_enrollment_idx on public.course_certificates(enrollment_id);
create index if not exists course_certificates_reissued_from_idx on public.course_certificates(reissued_from_id);
create index if not exists course_certificates_revoked_by_idx on public.course_certificates(revoked_by);
create index if not exists course_certificates_template_version_idx on public.course_certificates(template_version);

drop policy if exists "Deny direct access to academy admin assignments" on private.academy_admins;
create policy "Deny direct access to academy admin assignments"
on private.academy_admins for all to anon, authenticated
using (false) with check (false);

drop policy if exists "Deny direct access to certificate templates" on private.certificate_templates;
create policy "Deny direct access to certificate templates"
on private.certificate_templates for all to anon, authenticated
using (false) with check (false);
commit;
