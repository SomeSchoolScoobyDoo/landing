# Release Readiness — Process

## Entry condition
Learner, organisation, school and integration divisions are complete, and every division security/privacy gate has passed.

## Sequence
1. Freeze scope and identify release commit.
2. Run automated tests, migration checks and full user-journey regression.
3. Verify production environment variables and secret access without exposing values.
4. Verify backup restore and rollback procedures.
5. Verify observability and ensure logs/analytics do not leak PII.
6. Review legal notices, vendor register and support/incident readiness.
7. Conduct accessibility, performance and cross-device checks.
8. Record go/no-go with owners and evidence.
9. Deploy only after explicit release approval.
10. Run smoke tests, monitor, and rollback if release criteria fail.

## No-go conditions
Unresolved critical/high security issue; incomplete division gate; unverified payment flow; missing required privacy disclosure; broken backup/restore; exposed secret; or inability to recover from production failure.

## Post-release
Record release version, migrations, monitoring window, incidents, user feedback and follow-up tasks.
