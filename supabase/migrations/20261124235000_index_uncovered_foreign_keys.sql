-- Cover foreign-key columns identified by the Supabase performance advisor.
-- These indexes support joins and parent-row updates/deletes without changing
-- row-level security or application behavior.

create index if not exists assessment_attempt_answers_question_id_idx
  on public.assessment_attempt_answers (question_id);

create index if not exists course_badges_course_id_idx
  on public.course_badges (course_id);

create index if not exists course_enrollment_events_enrollment_id_idx
  on public.course_enrollment_events (enrollment_id);

create index if not exists courses_created_by_idx
  on public.courses (created_by);

create index if not exists courses_updated_by_idx
  on public.courses (updated_by);

create index if not exists organization_memberships_invited_by_idx
  on public.organization_memberships (invited_by);
