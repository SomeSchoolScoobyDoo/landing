begin;

select extensions.plan(10);

select extensions.ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'course_modules'
      and policyname = 'Learners can view modules in published courses'
      and coalesce(qual, '') ilike '%course_enrollments%'
      and coalesce(qual, '') ilike '%active%'
  ),
  'module reads require an active course enrolment'
);

select extensions.ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'lessons'
      and policyname = 'Learners can view lessons in published courses'
      and coalesce(qual, '') ilike '%course_enrollments%'
      and coalesce(qual, '') ilike '%active%'
  ),
  'lesson reads require an active course enrolment'
);

select extensions.ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'lesson_resources'
      and policyname = 'Learners can view resources for published lessons'
      and coalesce(qual, '') ilike '%course_enrollments%'
      and coalesce(qual, '') ilike '%active%'
  ),
  'lesson resource reads require an active course enrolment'
);

select extensions.ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'lesson_progress'
      and policyname = 'Learners can read their own lesson progress'
      and coalesce(qual, '') ilike '%course_enrollments%'
      and coalesce(qual, '') ilike '%active%'
  ),
  'lesson progress reads require an active course enrolment'
);

select extensions.ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'lesson_progress'
      and policyname = 'Learners can create their own lesson progress'
      and coalesce(with_check, '') ilike '%course_enrollments%'
      and coalesce(with_check, '') ilike '%active%'
  ),
  'lesson progress inserts require an active course enrolment'
);

select extensions.ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'lesson_progress'
      and policyname = 'Learners can update their own lesson progress'
      and coalesce(qual, '') ilike '%course_enrollments%'
      and coalesce(with_check, '') ilike '%course_enrollments%'
  ),
  'lesson progress updates require an active course enrolment'
);

select extensions.ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'assessments'
      and policyname = 'Learners can view published course assessments'
      and coalesce(qual, '') ilike '%course_enrollments%'
      and coalesce(qual, '') ilike '%active%'
  ),
  'assessment reads require an active course enrolment'
);

select extensions.ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'assessment_questions'
      and policyname = 'Learners can view questions for published assessments'
      and coalesce(qual, '') ilike '%course_enrollments%'
      and coalesce(qual, '') ilike '%active%'
  ),
  'assessment question reads require an active course enrolment'
);

select extensions.ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'assessment_attempts'
      and policyname = 'Learners can read their own assessment attempts'
      and coalesce(qual, '') ilike '%course_enrollments%'
      and coalesce(qual, '') ilike '%active%'
  ),
  'assessment attempt reads require an active course enrolment'
);

select extensions.ok(
  position(
    'Active course enrolment required'
    in pg_get_functiondef('public.submit_assessment(uuid,jsonb)'::regprocedure)
  ) > 0,
  'assessment submissions require an active course enrolment'
);

select * from extensions.finish();
rollback;
