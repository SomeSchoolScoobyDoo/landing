-- Step 9 public course preview RPC access-control and output tests.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(11);

select extensions.ok(to_regprocedure('public.get_public_course_preview(text)') is not null,'public course preview function exists');
select extensions.ok((
  select prosecdef from pg_proc
  where oid='public.get_public_course_preview(text)'::regprocedure
),'course preview runs with controlled definer privileges');
select extensions.ok((
  select provolatile = 's' from pg_proc
  where oid='public.get_public_course_preview(text)'::regprocedure
),'course preview is a stable read-only function');
select extensions.ok(has_function_privilege('anon','public.get_public_course_preview(text)','EXECUTE'),'anonymous visitors can read the safe course preview');
select extensions.ok(has_function_privilege('authenticated','public.get_public_course_preview(text)','EXECUTE'),'signed-in learners can read the course preview');

insert into public.course_categories (slug, name)
values ('step9-preview-test-category', 'Step 9 Preview Test');

insert into public.courses (category_id, slug, title, status)
select id, 'step9-preview-test-course', 'Step 9 Preview Test Course', 'published'
from public.course_categories
where slug = 'step9-preview-test-category';

insert into public.courses (category_id, slug, title, status)
select id, 'step9-preview-draft-course', 'Step 9 Draft Preview Course', 'draft'
from public.course_categories
where slug = 'step9-preview-test-category';

insert into public.course_modules (course_id, module_number, title, goal, status)
select id, 1, 'Published Module', 'Published module goal', 'published'
from public.courses where slug = 'step9-preview-test-course';

insert into public.course_modules (course_id, module_number, title, goal, status)
select id, 2, 'Draft Module', 'Hidden module goal', 'draft'
from public.courses where slug = 'step9-preview-test-course';

insert into public.lessons (module_id, lesson_number, title, estimated_minutes, content, status, display_order)
select id, '0', 'Intro Without Sample Text', 5,
  '{}'::jsonb, 'published', 0
from public.course_modules
where title = 'Published Module';

insert into public.lessons (module_id, lesson_number, title, estimated_minutes, content, status)
select id, '1', 'First Published Lesson', 10,
  jsonb_build_object('simple_explanation', repeat('A', 1300)), 'published'
from public.course_modules
where title = 'Published Module';

insert into public.lessons (module_id, lesson_number, title, estimated_minutes, content, status)
select id, '2', 'Second Published Lesson', 12,
  jsonb_build_object('simple_explanation', 'Second lesson text'), 'published'
from public.course_modules
where title = 'Published Module';

insert into public.lessons (module_id, lesson_number, title, estimated_minutes, content, status)
select id, '3', 'Draft Lesson', 12,
  jsonb_build_object('simple_explanation', 'Hidden draft text'), 'draft'
from public.course_modules
where title = 'Published Module';

insert into public.lessons (module_id, lesson_number, title, estimated_minutes, content, status)
select id, '1', 'Lesson In Draft Module', 12,
  jsonb_build_object('simple_explanation', 'Hidden module lesson'), 'published'
from public.course_modules
where title = 'Draft Module';

select extensions.ok((
  select count(*) = 3
    and array_agg(lesson_title order by lesson_number) = array[
      'Intro Without Sample Text',
      'First Published Lesson',
      'Second Published Lesson'
    ]::text[]
  from public.get_public_course_preview('step9-preview-test-course')
),'preview returns the published lesson topic titles in order');

select extensions.ok(not (
  select proargnames @> array['sample_explanation']::text[]
  from pg_proc
  where oid = 'public.get_public_course_preview(text)'::regprocedure
),'public preview does not expose lesson explanations');

select extensions.ok(not (
  select proargnames @> array['module_goal']::text[]
  from pg_proc
  where oid = 'public.get_public_course_preview(text)'::regprocedure
),'public preview does not expose module goals');

select extensions.ok(not (
  select proargnames @> array['lesson_minutes']::text[]
  from pg_proc
  where oid = 'public.get_public_course_preview(text)'::regprocedure
),'public preview does not expose lesson durations');

select extensions.ok(
  (select count(*) = 0 from public.get_public_course_preview('step9-preview-draft-course'))
  and
  (select count(*) = 0 from public.get_public_course_preview('not-a-real-course')),
  'draft and unknown courses return no public preview'
);

select extensions.ok(
  not has_table_privilege('anon','public.course_modules','SELECT')
  and not has_table_privilege('anon','public.lessons','SELECT'),
  'anonymous visitors cannot directly read lesson or module tables'
);

select * from extensions.finish();
rollback;
