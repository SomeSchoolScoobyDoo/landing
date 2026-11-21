-- Step 9 learner enrolment access-control tests.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(13);

select extensions.has_table('public','course_enrollments','course enrolments table exists');
select extensions.ok((select relrowsecurity from pg_class where oid='public.course_enrollments'::regclass),'course enrolments RLS enabled');
select extensions.ok(has_table_privilege('authenticated','public.course_enrollments','SELECT'),'authenticated learners can read enrolments');
select extensions.ok(not has_table_privilege('authenticated','public.course_enrollments','INSERT'),'learners must use the controlled enrolment workflow');
select extensions.ok(not has_table_privilege('authenticated','public.course_enrollments','UPDATE'),'learners cannot modify enrolment records');
select extensions.ok(not has_table_privilege('authenticated','public.course_enrollments','DELETE'),'learners cannot delete enrolment records');
select extensions.ok(not has_table_privilege('anon','public.course_enrollments','SELECT'),'anonymous users cannot read enrolments');
select extensions.ok(exists (
  select 1 from pg_policies
  where schemaname='public' and tablename='course_enrollments'
    and policyname='Learners can view their own course enrolments'
    and cmd='SELECT' and 'authenticated'=any(roles)
),'learner enrolment reads are owner-scoped');
select extensions.ok(not exists (
  select 1 from pg_policies
  where schemaname='public' and tablename='course_enrollments'
    and cmd='INSERT'
),'direct enrolment inserts are disabled in favour of the validated workflow');
select extensions.ok(not exists (
  select 1 from pg_policies
  where schemaname='public' and tablename='course_enrollments'
    and cmd in ('UPDATE','DELETE','ALL')
),'no client update or delete policy exists');
select extensions.ok(exists (
  select 1 from pg_indexes
  where schemaname='public' and indexname='course_enrollments_user_course_key'
),'duplicate enrolments are prevented');
select extensions.ok(exists (
  select 1 from pg_trigger
  where tgrelid='public.course_enrollments'::regclass
    and tgname='course_enrollments_set_updated_at'
    and not tgisinternal
),'updated_at trigger is installed');
select extensions.ok(has_table_privilege('service_role','public.course_enrollments','DELETE'),'trusted service role retains enrolment management access');

select * from extensions.finish();
rollback;
