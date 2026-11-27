## Summary
<!-- What changed and why? -->

## Verification
- [ ] Relevant tests pass
- [ ] Lint and type checks pass
- [ ] Build passes
- [ ] Authorization and tenant isolation considered
- [ ] No secrets or real personal data added

## Security review
- [ ] Server-side validation and authorization are enforced
- [ ] Uploads, if any, are restricted and validated server-side
- [ ] Database changes preserve tenant isolation and least privilege
- [ ] Logs do not contain passwords, tokens, payment details, or unnecessary personal data
- [ ] Any new dependency is necessary and reviewed

## Data and migration impact
<!-- Describe schema/data changes, migration and rollback plan. -->

## Deployment impact
- [ ] Preview environment checked
- [ ] Production impact understood
- [ ] Rollback path documented
