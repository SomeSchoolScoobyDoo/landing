-- Step 9 enrol, withdraw, and re-enrol workflow behaviour tests.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(9);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '90000000-0000-4000-8000-000000000009',
  'authenticated', 'authenticated', 'step9-workflow-test@example.invalid', '',
  now(), '{}'::jsonb, '{}'::jsonb, now(), now()
);

insert into public.course_categories (slug, name)
values ('step9-workflow-test-category', 'Step 9 Workflow Test');

insert into public.courses (category_id, slug, title, status)
select id, 'step9-workflow-test-course', 'Step 9 Workflow Test Course', 'published'
from public.course_categories
where slug = 'step9-workflow-test-category';

select set_config('request.jwt.claim.sub', '90000000-0000-4000-8000-000000000009', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

set local role authenticated;
select public.manage_course_enrollment('step9-workflow-test-course', 'enrol');
reset role;

select extensions.ok((
  select e.status = 'active'
  from public.course_enrollments e
  join public.courses c on c.id = e.course_id
  where c.slug = 'step9-workflow-test-course'
    and e.user_id = '90000000-0000-4000-8000-000000000009'
),'first enrolment creates one active enrolment');

select extensions.ok((
  select count(*) = 1
  from public.course_enrollment_events ev
  join public.course_enrollments e on e.id = ev.enrollment_id
  join public.courses c on c.id = e.course_id
  where c.slug = 'step9-workflow-test-course' and ev.event_type = 'enrolled'
),'first enrolment records an enrolled event');

set local role authenticated;
select public.manage_course_enrollment('step9-workflow-test-course', 'enrol');
reset role;

select extensions.ok((
  select count(*) = 1
  from public.course_enrollments e
  join public.courses c on c.id = e.course_id
  where c.slug = 'step9-workflow-test-course'
    and e.user_id = '90000000-0000-4000-8000-000000000009'
),'repeated enrolment does not create a duplicate row');

select extensions.ok((
  select count(*) = 1
  from public.course_enrollment_events ev
  join public.course_enrollments e on e.id = ev.enrollment_id
  join public.courses c on c.id = e.course_id
  where c.slug = 'step9-workflow-test-course' and ev.event_type = 'enrolled'
),'repeated enrolment does not duplicate the enrolled event');

set local role authenticated;
select public.manage_course_enrollment('step9-workflow-test-course', 'withdraw');
reset role;

select extensions.ok((
  select e.status = 'withdrawn' and e.withdrawn_at is not null
  from public.course_enrollments e
  join public.courses c on c.id = e.course_id
  where c.slug = 'step9-workflow-test-course'
    and e.user_id = '90000000-0000-4000-8000-000000000009'
),'withdrawal marks the existing enrolment as withdrawn');

select extensions.ok((
  select count(*) = 1
  from public.course_enrollment_events ev
  join public.course_enrollments e on e.id = ev.enrollment_id
  join public.courses c on c.id = e.course_id
  where c.slug = 'step9-workflow-test-course' and ev.event_type = 'withdrawn'
),'withdrawal records an audit event');

set local role authenticated;
select public.manage_course_enrollment('step9-workflow-test-course', 'enrol');
reset role;

select extensions.ok((
  select e.status = 'active' and e.withdrawn_at is null
  from public.course_enrollments e
  join public.courses c on c.id = e.course_id
  where c.slug = 'step9-workflow-test-course'
    and e.user_id = '90000000-0000-4000-8000-000000000009'
),'re-enrolment reactivates the same enrolment');

select extensions.ok((
  select count(*) = 1
  from public.course_enrollment_events ev
  join public.course_enrollments e on e.id = ev.enrollment_id
  join public.courses c on c.id = e.course_id
  where c.slug = 'step9-workflow-test-course' and ev.event_type = 're_enrolled'
),'re-enrolment records a re_enrolled event');

select extensions.ok((
  select count(*) = 3
  from public.course_enrollment_events ev
  join public.course_enrollments e on e.id = ev.enrollment_id
  join public.courses c on c.id = e.course_id
  where c.slug = 'step9-workflow-test-course'
),'event history preserves enrol, withdrawal, and re-enrolment');

select * from extensions.finish();
rollback;
