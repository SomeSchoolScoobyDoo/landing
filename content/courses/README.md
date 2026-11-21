# Course source content

This folder is the source-of-truth location for new Kaizora courses.

- Add one JSON file per course (for example, `intro-to-ai.json`).
- Do not add course exports, learner records, credentials, or secrets here.
- Course files are reviewed and validated before import into Supabase.
- The importer and database schema remain in the application; ordinary lesson text and assessment content belong in the database after import, not Supabase Storage.
- This folder is intentionally empty of course records. New course content will be supplied separately.

A course JSON should include stable course metadata, learning outcomes, prerequisites, modules, lessons, practical activities, assessments, answer keys, and completion criteria. The exact schema will be documented alongside the importer before the first new course is loaded.
