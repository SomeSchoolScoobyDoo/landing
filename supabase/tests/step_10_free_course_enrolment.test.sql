begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(4);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '90000000-0000-4000-8000-000000000027',
  'authenticated', 'authenticated', 'step10-free-enrolment@example.invalid', '',
  now(), '{}'::jsonb, '{}'::jsonb, now(), now()
);

insert into public.course_categories (slug, name)
values ('step10-enrolment-access-category', 'Step 10 Enrolment Access');

insert into public.courses (category_id, slug, title, status, access_type)
select id, 'step10-free-course', 'Step 10 Free Course', 'published', 'free'
from public.course_categories
where slug = 'step10-enrolment-access-category';

insert into public.courses (category_id, slug, title, status, access_type)
select id, 'step10-paid-course', 'Step 10 Paid Course', 'published', 'paid'
from public.course_categories
where slug = 'step10-enrolment-access-category';

insert into public.courses (category_id, slug, title, status, access_type)
select id, 'step10-unconfigured-course', 'Step 10 Unconfigured Course', 'published', 'unconfigured'
from public.course_categories
where slug = 'step10-enrolment-access-category';

insert into public.course_enrollments (user_id, course_id, status)
select '90000000-0000-4000-8000-000000000027', id, 'active'
from public.courses where slug = 'step10-paid-course';

select set_config('request.jwt.claim.sub', '90000000-0000-4000-8000-000000000027', true);
select set_config('request.jwt.claim.role', 'authenticated', true);

set local role authenticated;
select public.manage_course_enrollment('step10-free-course', 'enrol');
reset role;

select extensions.ok(
  exists (
    select 1
    from public.course_enrollments e
    join public.courses c on c.id = e.course_id
    where e.user_id = '90000000-0000-4000-8000-000000000027'
      and c.slug = 'step10-free-course'
      and e.status = 'active'
  ),
  'authenticated learners can self-enrol in explicitly free courses'
);

set local role authenticated;
select extensions.throws_ok(
  $$select public.manage_course_enrollment('step10-paid-course', 'enrol')$$,
  '42501',
  'Verified payment is required before enrolling in this course',
  'paid courses reject direct self-enrolment'
);
select extensions.throws_ok(
  $select public.manage_course_enrollment('step10-unconfigured-course', 'enrol')$,
  '42501',
  'Verified payment is required before enrolling in this course',
  'unconfigured courses reject direct self-enrolment'
);
select public.manage_course_enrollment('step10-paid-course', 'withdraw');
reset role;

select extensions.ok(
  exists (
    select 1 from public.course_enrollments e
    join public.courses c on c.id = e.course_id
    where e.user_id = '90000000-0000-4000-8000-000000000027'
      and c.slug = 'step10-paid-course'
      and e.status = 'withdrawn'
      and e.withdrawn_at is not null
  ),
  'learners can still withdraw from an existing paid-course enrolment'
);

select * from extensions.finish();
rollback;
