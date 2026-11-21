-- Step 8 assessment security and grading tests.
begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(24);

select extensions.has_table('public','assessments','assessments table exists');
select extensions.has_table('public','assessment_questions','assessment questions table exists');
select extensions.has_table('public','assessment_answer_keys','protected answer keys table exists');
select extensions.has_table('public','assessment_attempts','assessment attempts table exists');
select extensions.has_table('public','assessment_attempt_answers','private attempt responses table exists');

select extensions.ok((select relrowsecurity from pg_class where oid='public.assessments'::regclass),'assessments RLS enabled');
select extensions.ok((select relrowsecurity from pg_class where oid='public.assessment_questions'::regclass),'questions RLS enabled');
select extensions.ok((select relrowsecurity from pg_class where oid='public.assessment_answer_keys'::regclass),'answer keys RLS enabled');
select extensions.ok((select relrowsecurity from pg_class where oid='public.assessment_attempts'::regclass),'attempts RLS enabled');
select extensions.ok((select relrowsecurity from pg_class where oid='public.assessment_attempt_answers'::regclass),'attempt responses RLS enabled');

select extensions.ok(not has_table_privilege('authenticated','public.assessment_answer_keys','SELECT'),'learners cannot read answer keys');
select extensions.ok(not has_table_privilege('authenticated','public.assessment_attempt_answers','SELECT'),'learners cannot read per-question grading records');
select extensions.ok(not has_table_privilege('authenticated','public.assessment_attempts','INSERT'),'learners cannot forge assessment attempts');
select extensions.ok(not has_table_privilege('authenticated','public.assessment_attempts','UPDATE'),'learners cannot change scores');
select extensions.ok(has_function_privilege('authenticated','public.submit_assessment(uuid,jsonb)','EXECUTE'),'authenticated learners can submit through grading RPC');
select extensions.ok(not has_function_privilege('anon','public.submit_assessment(uuid,jsonb)','EXECUTE'),'anonymous users cannot submit assessments');

select extensions.ok(exists (
  select 1 from pg_policies
  where schemaname='public' and tablename='assessment_attempts'
    and policyname='Learners can read their own assessment attempts'
),'attempt history is owner-scoped');

select extensions.ok(exists (
  select 1 from pg_indexes where schemaname='public'
    and indexname='assessments_one_lesson_quiz_idx'
),'only one lesson quiz is allowed per lesson');
select extensions.ok(exists (
  select 1 from pg_indexes where schemaname='public'
    and indexname='assessments_one_final_assessment_idx'
),'only one final assessment is allowed per course');

select extensions.ok(exists (
  select 1 from pg_constraint where conrelid='public.assessments'::regclass
    and conname='assessments_scope_check'
),'assessment type and lesson scope are constrained');
select extensions.ok(exists (
  select 1 from pg_constraint where conrelid='public.assessments'::regclass
    and conname='assessments_passing_score_percentage_check'
),'passing score is constrained to a percentage');
select extensions.ok(exists (
  select 1 from pg_constraint where conrelid='public.assessments'::regclass
    and conname='assessments_max_attempts_check'
),'retake limit is constrained');

select extensions.ok(exists (
  select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='submit_assessment'
    and p.prosecdef
),'grading function executes with controlled definer privileges');

select extensions.ok(not has_table_privilege('anon','public.assessments','SELECT'),'anonymous users cannot read assessment content');

select * from extensions.finish();
rollback;
