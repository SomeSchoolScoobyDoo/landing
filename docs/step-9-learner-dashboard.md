# Step 9: Learner Dashboard

## Scope
- Add private, explicit course enrolment records for self-serve learners.
- Allow authenticated learners to enrol only in currently published courses and withdraw from an enrolled course from either its detail page or learner dashboard.
- Build the learner dashboard with enrolled courses, lesson completion, overall progress, next lesson, recent activity, and assessment results.
- Add a public course preview containing course metadata and published module/lesson titles only. Public previews do not expose lesson explanations, module goals, lesson durations, videos, exercises, quizzes, or answer keys.
- Add course-page enrolment action and link learners to their dashboard after enrolment.

## Data and access boundaries
- `course_enrollments` is unique per learner and course.
- Learners can read only their own enrolments and enrolment event history.
- Anonymous visitors can call a narrow, read-only preview RPC that exposes course metadata and published module/lesson titles only; it does not grant direct anonymous access to lesson or module tables.
- Learner clients cannot directly update or delete enrolment records. A security-definer workflow validates the authenticated learner and performs enrolment, withdrawal, and re-enrolment.
- Withdrawal is a soft status change. It preserves the enrolment row, event history, lesson progress, and assessment attempts; re-enrolment reactivates the existing record.
- Active enrolment is required by RLS to read modules, lessons, lesson resources, assessments, questions, progress, and assessment attempts. Assessment submissions also verify active enrolment inside the grading RPC. Withdrawal suspends learning access without deleting progress or results.
- Lesson progress remains sourced from `lesson_progress`; assessment results remain sourced from the learner's own `assessment_attempts`.
- Dashboard queries run server-side through the authenticated Supabase client and rely on existing RLS policies.
- Institutional paid access and entitlement checks are not enabled by this milestone.

## Progress calculation
- Per-course completion = completed published lessons / published lessons in that enrolled course.
- Overall completion = completed published lessons / published lessons across all enrolled courses.
- Courses with no published lessons show zero progress and link back to course details.
- The dashboard does not invent placeholder progress or sample scores.

## Validation
Run `supabase test db` against a disposable local Supabase instance. The pgTAP suites check the enrolment table, RLS, grants, owner-scoped policies, no client update/delete access, uniqueness, timestamp trigger, event-history access, authenticated-only workflow execution, enrol/withdraw/re-enrol behaviour, and public preview filtering and output columns. Apply Step 9 migrations 004 through 008 to the development database before testing enrolment, withdrawal, re-enrolment, learner access, and the public curriculum preview. Migration 007 replaces the already-applied migration 006 preview function with the titles-only return schema. Migration 008 makes active enrolment a database-enforced requirement for learning content and assessment access. The preview RPC remains public and title-only.

## Not included
- Full-catalogue course import and production content publishing. A development-only seed for S1 and S2 is included at `supabase/seeds/step_9_s1_s2_development_seed.sql`; it must only be run against `kaizora-development` and has not been executed by this change.
- Final certificate eligibility and generation.
- Paid school/corporate entitlement management.
- Production deployment or merging stacked milestone branches.
