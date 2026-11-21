-- Step 9 follow-up: learner withdrawal and re-enrolment access-control tests.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(10);

select extensions.has_table('public','course_enrollment_events','enrolment event history table exists');
select extensions.ok((select relrowsecurity from pg_class where oid='public.course_enrollment_events'::regclass),'enrolment event history RLS enabled');
select extensions.ok(has_table_privilege('authenticated','public.course_enrollment_events','SELECT'),'learners can read their own enrolment history');
select extensions.ok(not has_table_privilege('authenticated','public.course_enrollment_events','INSERT'),'learners cannot forge enrolment history');
select extensions.ok(not has_table_privilege('authenticated','public.course_enrollment_events','UPDATE'),'learners cannot alter enrolment history');
select extensions.ok(not has_table_privilege('authenticated','public.course_enrollment_events','DELETE'),'learners cannot delete enrolment history');
select extensions.ok(exists (
  select 1 from pg_policies
  where schemaname='public' and tablename='course_enrollment_events'
    and policyname='Learners can view their own enrolment history'
    and cmd='SELECT' and 'authenticated'=any(roles)
),'enrolment history reads are owner-scoped');
select extensions.ok(has_function_privilege('authenticated','public.manage_course_enrollment(text,text)','EXECUTE'),'authenticated learners can use the controlled enrolment workflow');
select extensions.ok(not has_function_privilege('anon','public.manage_course_enrollment(text,text)','EXECUTE'),'anonymous users cannot change enrolments');
select extensions.ok(not has_table_privilege('authenticated','public.course_enrollments','UPDATE') and not has_table_privilege('authenticated','public.course_enrollments','DELETE'),'learners still cannot directly modify or delete enrolment rows');

select * from extensions.finish();
rollback;
