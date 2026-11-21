# Kaizora AI Academy

Unified Next.js application for the public Kaizora website and the Kaizora learning platform.

## Public pages
- `/` — Homepage
- `/about` — About Kaizora
- `/courses` — Published course catalogue
- `/learners` — Learner information
- `/institutes` — Institute information
- `/organisations` — Organisation information

## Learning platform
- `/dashboard` — Authenticated learner dashboard
- `/learn/[courseSlug]/[lessonNumber]` — Lesson delivery
- `/preview/student`, `/preview/institute`, `/preview/organisation` — Read-only design previews

The public pages render independently of Supabase. A database or LMS outage must not prevent visitors from accessing the homepage or public information pages.

## Course content
New source course JSON files belong in `content/courses/`. This folder intentionally contains no legacy course records. See its README for the import workflow. Keep the course schema, validation and importer; do not put ordinary lesson content in Supabase Storage.

## Development
1. Copy `.env.example` to `.env.local`.
2. Set the Supabase URL and publishable/anon key in the local environment.
3. Install dependencies with `npm install`.
4. Run `npm run dev`.
5. Run `npm run build` before deployment.

Never commit real credentials or a service-role key. Apply Supabase migrations deliberately; do not replay them blindly against production.
