-- Step 7 lesson delivery, progress ownership, and private resource tests.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(21);

select extensions.has_table('public','course_modules','course modules table exists');
select extensions.has_table('public','lessons','lessons table exists');
select extensions.ok(exists (select 1 from pg_constraint where conrelid='public.lessons'::regclass and conname='lessons_content_excludes_assessment_answers'),'learner-readable lesson content excludes quiz answer keys');
select extensions.has_table('public','lesson_resources','lesson resources table exists');
select extensions.has_table('public','lesson_progress','lesson progress table exists');
select extensions.ok((select relrowsecurity from pg_class where oid='public.course_modules'::regclass),'modules RLS enabled');
select extensions.ok((select relrowsecurity from pg_class where oid='public.lessons'::regclass),'lessons RLS enabled');
select extensions.ok((select relrowsecurity from pg_class where oid='public.lesson_resources'::regclass),'resources RLS enabled');
select extensions.ok((select relrowsecurity from pg_class where oid='public.lesson_progress'::regclass),'progress RLS enabled');
select extensions.ok(not has_table_privilege('anon','public.lessons','SELECT'),'anonymous visitors cannot read lesson content');
select extensions.ok(has_table_privilege('authenticated','public.lesson_progress','SELECT'),'authenticated learners can query own progress subject to RLS');
select extensions.ok(not has_table_privilege('authenticated','public.lesson_progress','DELETE'),'learners cannot delete progress records');
select extensions.ok(has_table_privilege('service_role','public.lessons','INSERT'),'trusted server workflows can create lessons');
select extensions.ok((select not public from storage.buckets where id='kaizora-learning-resources'),'learning resource bucket is private');
select extensions.ok(exists (select 1 from pg_policies where schemaname='storage' and tablename='objects' and policyname='Learners can download published lesson resources'),'storage download policy exists');

insert into public.course_categories(id,slug,name) values ('51000000-0000-4000-8000-000000000001','step7-category','Step 7 Category');
insert into public.courses(id,category_id,slug,title,status) values ('52000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000001','step7-course','Step 7 Course','published');
insert into public.course_modules(id,course_id,module_number,title,status) values ('53000000-0000-4000-8000-000000000001','52000000-0000-4000-8000-000000000001',1,'Published module','published');
insert into public.lessons(id,module_id,lesson_number,title,status) values
('54000000-0000-4000-8000-000000000001','53000000-0000-4000-8000-000000000001','1.1','Published lesson','published'),
('54000000-0000-4000-8000-000000000002','53000000-0000-4000-8000-000000000001','1.2','Draft lesson','draft'),
('54000000-0000-4000-8000-000000000003','53000000-0000-4000-8000-000000000001','1.3','Second published lesson','published');
select extensions.throws_ok(
  $pgtap$insert into public.lessons(module_id,lesson_number,title,content) values ('53000000-0000-4000-8000-000000000001','1.4','Quiz answer leakage','{"lesson_quiz": []}'::jsonb)$pgtap$,
  '23514', null, 'learner-readable lesson content rejects embedded quiz data'
);

insert into auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, confirmation_token, email_change, email_change_token_new, recovery_token)
values
('55000000-0000-4000-8000-000000000001','authenticated','authenticated','step7-a@example.test','',now(),now(),now(),'{}','{}',false,'','','',''),
('55000000-0000-4000-8000-000000000002','authenticated','authenticated','step7-b@example.test','',now(),now(),now(),'{}','{}',false,'','','','')
on conflict (id) do nothing;

-- Step 9 now requires active enrolment before learners can read or write progress.
-- Keep this Step 7 fixture enrolled so its original progress-ownership assertions
-- continue testing ownership rather than the newer enrolment gate.
insert into public.course_enrollments(user_id, course_id, status) values
('55000000-0000-4000-8000-000000000001','52000000-0000-4000-8000-000000000001','active'),
('55000000-0000-4000-8000-000000000002','52000000-0000-4000-8000-000000000001','active');

insert into public.lesson_progress(user_id,lesson_id,last_position_seconds) values
('55000000-0000-4000-8000-000000000001','54000000-0000-4000-8000-000000000001',120),
('55000000-0000-4000-8000-000000000002','54000000-0000-4000-8000-000000000001',60);

set local role authenticated;
select set_config('request.jwt.claim.sub','55000000-0000-4000-8000-000000000001',true);
select extensions.is((select count(*) from public.lesson_progress),1::bigint,'learners see only their own progress');
select extensions.is((select count(*) from public.lessons),2::bigint,'learners see published lessons only');

insert into public.lesson_progress(user_id,lesson_id,last_position_seconds)
values ('55000000-0000-4000-8000-000000000001','54000000-0000-4000-8000-000000000003',30);
select extensions.is((select count(*) from public.lesson_progress),2::bigint,'learners can create progress for themselves on a published lesson');
select extensions.throws_ok(
  $pgtap$insert into public.lesson_progress(user_id,lesson_id) values ('55000000-0000-4000-8000-000000000002','54000000-0000-4000-8000-000000000003')$pgtap$,
  '42501', null, 'learners cannot create progress for another user'
);
select extensions.throws_ok(
  $pgtap$insert into public.lesson_progress(user_id,lesson_id) values ('55000000-0000-4000-8000-000000000001','54000000-0000-4000-8000-000000000002')$pgtap$,
  '42501', null, 'learners cannot create progress for a draft lesson'
);
reset role;
select * from extensions.finish();
rollback;
