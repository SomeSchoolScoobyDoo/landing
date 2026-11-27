begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(5);

insert into public.course_categories (slug, name)
values ('step12-public-preview-category', 'Step 12 Public Preview');

insert into public.courses (category_id, slug, title, summary, description, status, access_type)
select id, 'step12-public-preview-course', 'Public Preview Course', 'Public summary', 'Public description', 'published', 'free'
from public.course_categories where slug = 'step12-public-preview-category';

insert into public.courses (category_id, slug, title, summary, description, status, access_type)
select id, 'step12-unpublished-course', 'Unpublished Course', 'Hidden summary', 'Hidden description', 'draft', 'free'
from public.course_categories where slug = 'step12-public-preview-category';

insert into public.course_modules (course_id, module_number, title, goal, display_order, status)
select id, 1, 'Published Module', 'Public module goal', 1, 'published'
from public.courses where slug = 'step12-public-preview-course';

insert into public.course_modules (course_id, module_number, title, goal, display_order, status)
select id, 2, 'Draft Module', 'Private module goal', 2, 'draft'
from public.courses where slug = 'step12-public-preview-course';

insert into public.lessons (module_id, lesson_number, title, content, display_order, status)
select id, '1.1', 'Published Lesson Title', '{"secret_body":"must never be returned publicly"}'::jsonb, 1, 'published'
from public.course_modules where title = 'Published Module';

insert into public.lessons (module_id, lesson_number, title, content, display_order, status)
select id, '2.1', 'Draft Lesson Title', '{"secret_body":"must never be returned publicly"}'::jsonb, 1, 'draft'
from public.course_modules where title = 'Draft Module';

select extensions.ok(
  position('content' in pg_get_function_result('public.get_public_course_lesson_title_preview(text)'::regprocedure)) = 0,
  'the public preview result schema never includes lesson content'
);

select extensions.ok(
  has_function_privilege('anon', 'public.get_public_course_lesson_title_preview(text)', 'EXECUTE'),
  'anonymous visitors can execute the public lesson-title preview'
);

create temporary table anon_preview_results (
  course_slug text,
  lesson_count integer,
  lesson_title text
);
grant insert on anon_preview_results to anon;

set local role anon;
insert into anon_preview_results
select 'published', count(*)::integer, min(lesson_title)
from public.get_public_course_lesson_title_preview('step12-public-preview-course');
insert into anon_preview_results
select 'unpublished', count(*)::integer, min(lesson_title)
from public.get_public_course_lesson_title_preview('step12-unpublished-course');
reset role;

select extensions.is(
  (select lesson_count from anon_preview_results where course_slug = 'published'),
  1,
  'anonymous visitors receive only published lesson titles'
);

select extensions.is(
  (select lesson_title from anon_preview_results where course_slug = 'published'),
  'Published Lesson Title',
  'anonymous visitors can see the published lesson title'
);

select extensions.is(
  (select lesson_count from anon_preview_results where course_slug = 'unpublished'),
  0,
  'unpublished courses are excluded from public curriculum previews'
);

select * from extensions.finish();
rollback;
