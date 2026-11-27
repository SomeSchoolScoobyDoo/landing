# Organisation Division — Delivery Process

## Entry condition
Individual learner experience and its security/privacy gate are signed off.

## Sequence
1. Define tenant model, lifecycle, roles and permission matrix before UI implementation.
2. Document owner/admin/manager/instructor/member journeys.
3. Build onboarding, verification and invitations.
4. Build workspace, membership and settings.
5. Build course assignment, group management and reporting.
6. Build billing-contact boundaries, exports and offboarding.
7. Test with synthetic organisation A and B, multiple roles and learners.
8. Run acceptance walkthrough and resolve defects.
9. Close with organisation security/privacy gate. Do not start school work before sign-off.

## Mandatory scenarios
Owner creates organisation and invites administrator; administrator invites manager/instructor and learners within assigned permissions; manager assigns course to group; instructor sees only assigned classes/learners; learner participates; authorised admin views aggregate progress and performs approved export; member is removed and access revoked; organisation is suspended or closed and retention/offboarding policy applies.

## Rules
- Tenant ID from client input is never proof of access.
- Every server query and mutation checks membership and role.
- Aggregate reports must not leak identifiable data to unauthorised roles.
- Bulk operations are audited and bounded.
- Security gate is the final stop for this division.
