# Kaizora AI Academy

Kaizora is a learning and institutional training platform. This repository contains the Next.js application, course content, Supabase migrations and tests, and project documentation.

## Current platform snapshot

The current learner platform includes:

- Account registration, login, password recovery, and authenticated learner navigation.
- A public catalogue containing 36 planned courses, grouped by learning area.
- Public course previews that expose course information and module/lesson titles without exposing protected lesson content.
- Learner course enrolment, lesson delivery, progress tracking, and assessments.
- Learner dashboard, course feedback, badges, and certificate workflows.
- Supporting organisation and administrative workflows.

The application is still under active development. A feature being present in the repository does not by itself mean it has passed production QA or is deployed.

## Course catalogue and publishing

The catalogue currently contains 36 entries:

- **4 available setup courses:** S1 Computer and Internet Readiness, S2 AI Toolkit Setup, S3 Developer Environment Setup, and S4 Automation Lab Setup.
- **32 coming-soon courses:** these remain visible in the catalogue but are not offered as available courses until matching course records have been imported, reviewed, and published in Supabase.

Course JSON files under `content/courses/` are source content. Committing a JSON file does not automatically publish a course in the database.

## Technology

- Next.js and TypeScript
- Supabase for PostgreSQL, authentication, row-level security, and private data
- Vercel for application hosting

## Repository structure

- `app/` - application routes and learner experiences.
- `components/` - shared UI components.
- `content/courses/` - structured course source files.
- `docs/` - product, division, security, and release documentation.
- `lib/` - server-side application logic and integrations.
- `scripts/` - course-content and certificate validation utilities.
- `supabase/migrations/` - database schema and policy changes.
- `supabase/tests/` - database access-control and workflow tests.
- `.github/workflows/` - CI and secret-scanning workflows.

## Local development

1. Install the dependencies with `npm ci`.
2. Copy `.env.example` to `.env.local`.
3. Set the required Supabase project URL and publishable/anonymous key for the intended development environment.
4. Run `npm run dev`.

Never put service-role keys or other privileged credentials in browser-exposed `NEXT_PUBLIC_` variables.

## Database and security

Apply migrations to the intended Supabase environment in order. Review the corresponding SQL tests and row-level security policies before changing access behaviour. Keep learner records, assessment answers, certificate data, and organisation data protected by server-side authorization and database policies.

## Deployment and production safety

The LMS is developed separately from the existing public Kaizora website. Keep the existing `landing` website and its production deployment intact while the LMS is being tested. Do not connect the LMS to the production domain or replace the public site until the learner and administrative workflows have passed the agreed release checks.

## Project status

This repository is the consolidated working source for the Kaizora platform. Continue tracking implementation, QA, security findings, and release readiness in the documentation and GitHub workflows. Do not describe the platform as production-ready until the required checks have actually passed.
