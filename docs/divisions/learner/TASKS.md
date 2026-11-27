# Individual Learner Division — Task Register

Status: Active. A task is complete only after implementation and verification in the running preview.

## L0 — Baseline
- [ ] Confirm current branch, commits, migrations, tests and implementation for existing steps 4–9.
- [ ] Inventory required environment variables without exposing values.
- [ ] Configure preview Supabase URL and anon key through Ronda's secure environment UI.
- [ ] Confirm preview connects to Supabase without production secrets.
- [ ] Seed synthetic learner, course and enrolment records.

## L1 — Public discovery
- [ ] Verify public homepage and course catalogue without authentication.
- [ ] Show published course titles, short descriptions, objectives, module/lesson titles, structure and price.
- [ ] Mark paid courses visibly locked while keeping course details and pricing public.
- [ ] Ensure unpublished courses and teaching materials are not publicly retrievable.
- [ ] Verify loading, empty, error and not-found states.
- [ ] Verify responsive catalogue and course detail pages.

## L2 — Accounts
- [ ] Verify signup, email confirmation, login, logout and password reset.
- [ ] Verify callback, expired and invalid token handling.
- [ ] Verify session refresh and protected route behaviour.
- [ ] Verify profile fields and validation.
- [ ] Verify Resend SMTP sender and templates end-to-end.
- [ ] Ensure credentials and tokens are not exposed in browser storage or logs.

## L3 — Enrolment and access
- [ ] Define enrolment states and server-side transition rules.
- [ ] Verify free-course enrolment and paid-course locked state.
- [ ] Never trust browser state or screenshots as payment evidence.
- [ ] Verify only active enrolments access lessons and assessments.
- [ ] Verify cancelled, expired, refunded and revoked enrolments lose access.
- [ ] Add clear denied-access and recovery states.

## L4 — Learning
- [ ] Verify learner dashboard and enrolled-course summaries.
- [ ] Verify lesson navigation, content and protected resources.
- [ ] Verify durable, idempotent progress updates tied to the authenticated learner.
- [ ] Verify lesson completion and course progress calculations.
- [ ] Verify assessment attempts, server-side grading, feedback and retry rules.
- [ ] Verify course completion and certificate eligibility.
- [ ] Verify badge/certificate learner name, course title and issue date.
- [ ] Verify download/share without exposing another learner's information.

## L5 — Learner operations
- [ ] Verify account settings and profile update.
- [ ] Define account deletion, data export and retention.
- [ ] Provide support/contact and accessible recovery paths.
- [ ] Verify notifications trigger only from valid server-side events.

## Exit
- [ ] Learner acceptance criteria pass.
- [ ] Learner security/privacy gate passes.
- [ ] Preview walkthrough and evidence recorded.
- [ ] Known gaps and deferrals documented.
