# School Division — Delivery Process

## Entry condition
Organisation division and its security gate are complete. School workflows need their own permission model.

## Sequence
1. Confirm school use cases and institutional terminology.
2. Define school tenant, classes, cohorts, academic periods and role boundaries.
3. Implement school onboarding and staff invitations.
4. Implement class/cohort setup, roster management and teacher assignment.
5. Implement course assignment and student learning views.
6. Implement teacher progress views and school reporting.
7. Implement student lifecycle, safeguarding, retention and offboarding.
8. Test with synthetic school A/B, teachers, students and administrators.
9. Close with school security/privacy gate. Integrations begin only after sign-off.

## Mandatory scenarios
School administrator creates workspace and invites staff; teacher is assigned to a class and sees only that class; student sees own learning records and assigned class materials; teacher assigns course; student progress updates; student transfers/leaves and old access is revoked; administrator produces authorised report; school offboarding follows retention/export rules.

## Rules
- Treat student data as potentially higher risk, especially where minors may use the service.
- Do not assume guardian accounts or age ranges without confirmation.
- Avoid exposing student lists to unassigned teachers.
- Bulk roster import/export requires validation, confirmation and audit.
- Security is the final stop for the school division.
