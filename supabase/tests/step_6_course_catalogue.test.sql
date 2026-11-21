-- Step 6 public catalogue visibility and write-boundary tests.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(12);

select extensions.has_table('public', 'course_categories', 'course categories table exists');
select extensions.has_table('public', 'courses', 'courses table exists');
select extensions.ok(
  (select relrowsecurity from pg_class where oid = 'public.course_categories'::regclass),
  'course categories has RLS enabled'
);
select extensions.ok(
  (select relrowsecurity from pg_class where oid = 'public.courses'::regclass),
  'courses has RLS enabled'
);
select extensions.ok(
  has_table_privilege('anon', 'public.courses', 'SELECT'),
  'anonymous visitors can query the catalogue subject to RLS'
);
select extensions.ok(
  has_table_privilege('anon', 'public.course_categories', 'SELECT'),
  'anonymous visitors can query visible categories subject to RLS'
);
select extensions.ok(
  not has_table_privilege('anon', 'public.courses', 'INSERT'),
  'anonymous visitors cannot insert courses'
);
select extensions.ok(
  not has_table_privilege('authenticated', 'public.courses', 'UPDATE'),
  'authenticated users cannot update course records'
);
select extensions.ok(
  has_table_privilege('service_role', 'public.courses', 'INSERT'),
  'trusted server workflows can insert courses'
);
select extensions.ok(
  has_table_privilege('service_role', 'public.courses', 'UPDATE'),
  'trusted server workflows can update and publish courses'
);

insert into public.course_categories (id, slug, name, description) values
('41000000-0000-4000-8000-000000000001', 'published-category', 'Published Category', 'Visible category'),
('41000000-0000-4000-8000-000000000002', 'draft-only-category', 'Draft Only Category', 'Not visible yet');

insert into public.courses (id, category_id, slug, title, status) values
('42000000-0000-4000-8000-000000000001', '41000000-0000-4000-8000-000000000001', 'visible-course', 'Visible Course', 'published'),
('42000000-0000-4000-8000-000000000002', '41000000-0000-4000-8000-000000000002', 'hidden-draft-course', 'Hidden Draft Course', 'draft');

set local role anon;
select extensions.is(
  (select count(*) from public.courses),
  1::bigint,
  'public visitors see published courses only'
);
select extensions.is(
  (select count(*) from public.course_categories),
  1::bigint,
  'public visitors see only categories containing published courses'
);
reset role;
select * from extensions.finish();
rollback;
