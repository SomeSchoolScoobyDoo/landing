# Step 8: Protected Assessments and Automatic Marking

## Scope
Step 8 adds lesson quizzes and course final assessments, learner-visible question/options, separately protected answer keys, attempt history, configurable passing scores, configurable retake limits, and server-side automatic grading.

## Data boundaries
- Learners can read questions and options only for published assessments in published courses and, for lesson quizzes, published lessons/modules.
- Correct option keys and explanations are stored in `assessment_answer_keys`, which has RLS enabled and no client grants or policies.
- Per-question submitted responses and correctness are stored in `assessment_attempt_answers`, which is also inaccessible to learner clients.
- Learners can read only their own aggregate attempt history.
- Learners cannot insert or update attempts or scores directly.
- The `submit_assessment` database function validates the assessment, complete answer set, question membership, option membership, and attempt limit before grading.
- The function returns only attempt ID, attempt number, aggregate percentage, and pass/fail status.

## Retakes and passing
Each assessment stores a passing score percentage and maximum attempts. Defaults are 70% and three attempts. Trusted publishing workflows may set different values within database constraints. Attempt limits are enforced atomically by the grading function's transaction.

## JSON mapping
The agreed course JSON's `lesson_quiz` and `final_assessment` structures must be validated and split during import:
- Question prompt and option key/text pairs go into `assessment_questions`.
- Correct option key and optional explanation go into `assessment_answer_keys`.
- Lesson quizzes reference a lesson. Final assessments reference a course and have no lesson ID.
- Never store correct answers in learner-readable lesson content or question options.

## Validation
Run `supabase test db` against a disposable local Supabase instance. The pgTAP suite checks schema, RLS, grants, answer-key secrecy, attempt write restrictions, function permissions, and assessment constraints.

## Not included
This step does not import course JSON, seed questions, create the assessment authoring interface, or implement the learner-facing quiz form. Those follow after the database and grading boundary are reviewed.
