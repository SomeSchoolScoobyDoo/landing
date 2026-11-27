# Step 6: Course Catalogue and Publishing Foundation

## Scope

This step replaces the assumption that the old static course snapshot is the source of truth with a database-backed catalogue. It establishes category and course records, public read access to published courses, a server-side read layer, a catalogue page, and course detail pages.

The catalogue supports independently published courses. There is no required course sequence or prerequisite ordering.

## Database

Migration: `supabase/migrations/20261119000100_course_catalogue.sql`

- `course_categories` stores stable category slugs, names, descriptions and display order.
- `courses` stores stable slugs, title, summary, description, category, difficulty, estimated duration, draft/published/archived status, display order, content version, and source metadata.
- Public and authenticated clients can read only published courses.
- A category is visible only when it contains at least one published course.
- Public clients have no insert, update or delete privileges. Trusted server workflows use the service role for imports, edits, archiving and publication.
- RLS is enabled on both tables.

No course rows are seeded here. The earlier static 21-course list is not treated as the final catalogue. The current target is 29 independently importable courses, with course content supplied separately.

## Application

- `lib/courses/catalogue.ts` contains server-only published catalogue queries.
- `/courses` lists published courses grouped by category and has a safe empty/unconfigured state.
- `/courses/[slug]` displays a published course overview. It does not deliver lessons or assessments; those belong to later steps.
- Courses are not automatically published when created. Import and publication will be separate trusted workflows.

## Import approach

Courses can be imported one at a time. The database has stable slugs, a content version and source metadata so a later importer can validate and upsert a single course without replacing unrelated courses. The exact Claude JSON adapter will be written after the first real output is available; this avoids guessing its schema.

## Verification

Run `supabase test db` to execute the Step 5 and Step 6 pgTAP suites against a disposable local Supabase database. These tests do not connect to the hosted development project.

## Deliberate exclusions

Lesson delivery, video playback, lesson progress, downloadable resources, MCQ assessment tables and grading, learner dashboards, payments, certificates and institutional management are not part of Step 6.
