# Organisation Division — Security and Privacy Gate

Final stop after organisation functionality, before school division.

## Threat scenarios
- Organisation A reads/modifies Organisation B by changing tenant IDs.
- Manager/instructor escalates to owner/admin.
- Invitation token is reused, transferred or accepted into wrong tenant.
- Exports, reports, dashboard totals or search leak another tenant's records.
- Removed member retains access through stale session, cache or signed URL.
- Billing/support roles gain unnecessary learning-record access.
- Bulk actions are abused to enumerate or exfiltrate records.

## Required evidence
- [ ] Tenant data-flow map and threat model.
- [ ] RLS and server-side role checks reviewed for all tenant tables.
- [ ] Cross-tenant negative tests for reads, writes, exports, search and storage.
- [ ] Vertical privilege-escalation tests for every role.
- [ ] Invitation lifecycle and revocation tests.
- [ ] Cache, report, aggregate and export isolation tests.
- [ ] Browser/network inspection confirms no unrelated tenant data is sent.
- [ ] Audit logs cover role, invitation, export, billing and membership changes.
- [ ] Production/operator access and break-glass controls reviewed.
- [ ] Dependency, secret, static and application security scans complete.
- [ ] Vendors receiving organisation/learner data are documented.
- [ ] No unresolved critical/high finding; residual risks signed and dated.

A failed or incomplete scan is not a pass. Do not begin school division until sign-off.
