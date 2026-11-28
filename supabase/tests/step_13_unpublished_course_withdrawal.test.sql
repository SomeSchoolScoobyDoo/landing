-- Withdrawal remains available after a course is unpublished.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(3);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '90000000-0000-4000-8000-000000000031',
  'authenticated', 'authenticated', 'draft-course-withdrawal@example.invalid', '',
  now(), '{}'::jsonb, '{}'::jsonb, now(), now()
);

insert into public.course_categories (slug, name)
values ('draft-withdrawal-test-category', 'Draft Withdrawal Test');

insert into public.courses (category_id, slug, title, status, access_type)
select id, 'draft-withdrawal-test-course', 'Draft Withdrawal Test Course', 'draft', 'free'
from public.course_categories
where slug = 'draft-withdrawal-test-category';

insert into public.course_enrollments (user_id, course_id, status)
select '90000000-0000-4000-8000-000000000031', id, 'active'
from public.courses
where slug = 'draft-withdrawal-test-course';

select set_config('request.jwt.claim.sub', '90000000-0000-4000-8000-000000000031', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

set local role authenticated;
select public.manage_course_enrollment('draft-withdrawal-test-course', 'withdraw');

select extensions.throws_ok(
  $$select public.manage_course_enrollment('draft-withdrawal-test-course', 'enrol')$$,
  'P0002',
  'This course is not currently available',
  'draft courses remain unavailable for new enrolments'
);
reset role;

select extensions.ok(
  exists (
    select 1 from public.course_enrollments e
    join public.courses c on c.id = e.course_id
    where e.user_id = '90000000-0000-4000-8000-000000000031'
      and c.slug = 'draft-withdrawal-test-course'
      and e.status = 'withdrawn'
      and e.withdrawn_at is not null
  ),
  'learners can withdraw from an existing enrolment after course unpublishing'
);

select extensions.ok(
  exists (
    select 1 from public.course_enrollment_events ev
    join public.course_enrollments e on e.id = ev.enrollment_id
    join public.courses c on c.id = e.course_id
    where e.user_id = '90000000-0000-4000-8000-000000000031'
      and c.slug = 'draft-withdrawal-test-course'
      and ev.event_type = 'withdrawn'
  ),
  'withdrawal is recorded in the enrolment event history'
);

select * from extensions.finish();
rollback;
