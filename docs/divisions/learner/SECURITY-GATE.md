# Individual Learner Division — Security and Privacy Gate

Final stop after learner functionality is complete.

## Data in scope
Account identity, email, profile, enrolment, progress, lesson activity, assessment attempts, submissions, grades, certificates, support requests and private resources.

## Threat scenarios
- Learner A substitutes Learner B's profile, enrolment, lesson, attempt, submission or certificate ID.
- Anonymous user requests protected lessons or assessment content.
- Learner accesses another learner's signed file URL or cached response.
- Client tampers with progress, completion, grade, price or enrolment status.
- Revoked user continues using stale session or previously issued access link.
- User enumerates learner IDs through search, autocomplete, dashboard counts, exports or API errors.
- Admin/support role accesses records beyond assigned need.
- PII leaks into URLs, analytics, client logs, errors or preview screenshots.

## Required checks
- [ ] Map learner data flows and classify personal/sensitive data.
- [ ] Review Supabase RLS for every learner-owned table and storage bucket.
- [ ] Run positive and negative tests using at least two synthetic learners.
- [ ] Test IDOR and role escalation across learner resources.
- [ ] Inspect DOM, bundles, source maps, network payloads, cookies and browser storage.
- [ ] Confirm service-role key and provider secrets never enter browser bundle.
- [ ] Verify user-specific responses are not shared through CDN/server cache.
- [ ] Verify logs, analytics and error reporting minimise/redact PII.
- [ ] Verify account deletion/export/retention and backup implications.
- [ ] Run dependency, secret, static-analysis and application security scans.
- [ ] Review support/operator access and audit logging.
- [ ] Record third-party services used in learner journeys and data sent to each.

## Pass conditions
No unresolved critical/high issue; all cross-learner denial tests pass; browser receives only authorised learner data; sensitive operations are audited; vendor data flows and notices are documented. Incomplete scans are not passes.

## Evidence
Record branch/commit, test commands, scan run IDs, findings/severity, synthetic-data screenshots, residual risks, reviewer and date. Block organisation-stage work until this gate passes or a formal exception is recorded.
