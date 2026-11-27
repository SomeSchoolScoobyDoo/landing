# School Division — Security and Privacy Gate

Final stop after school functionality, before integrations.

## Threat scenarios
- Teacher accesses unassigned class or another school's roster.
- Student changes identifier to view another student's grades, submissions or profile.
- School admin accesses another school.
- Roster import maps records to wrong tenant or overwrites existing students.
- Bulk exports expose more fields than role permits.
- Former student/staff retains access after transfer, withdrawal or termination.
- Support, analytics or vendors expose student personal information.
- Sensitive safeguarding notes are visible to ordinary teaching roles.

## Required evidence
- [ ] School data-flow map and threat model.
- [ ] RLS and server-side authorization reviewed for school, class, roster and learner records.
- [ ] Cross-school, cross-class and cross-student negative tests pass.
- [ ] Teacher/student/admin vertical permission tests pass.
- [ ] Roster import/export and transfer lifecycle tests pass.
- [ ] Safeguarding and sensitive support records are separately protected.
- [ ] Browser/network/cache/log/analytics inspection shows minimum authorised data only.
- [ ] Retention, deletion, backup and offboarding controls tested.
- [ ] Third-party data processors and disclosures reviewed.
- [ ] Dependency, secret, static and application security scans complete.
- [ ] Applicable child-data and jurisdictional privacy review recorded.
- [ ] No unresolved critical/high finding; residual risks signed and dated.

Incomplete scans are not a pass. Integrations wait until sign-off.
