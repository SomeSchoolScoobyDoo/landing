# Integrations Division — Security and Third-Party Privacy Gate

Final stop after integrations, before release readiness.

## Scope
Payment processors, email delivery, analytics, AI providers, video/media/content services, identity providers, institutional systems, support tools, monitoring and subprocessors.

## Vendor register fields
Provider; service; purpose; data subjects; exact fields; data classification; processing/storage regions; international transfers; subprocessors; retention/deletion; backups; DPA/contract; security controls; breach terms; model training/product improvement use; OAuth/API scopes; credential owner; webhook validation; user notice/consent; disconnect path; review date.

## Threat scenarios
- Provider receives more personal data than required.
- Provider uses learner content for model training contrary to expectation/terms.
- API key or webhook secret is exposed in browser code, logs or repository.
- Forged/replayed webhook grants paid access or changes enrolment.
- Analytics leaks email, names, grades, submissions or tenant identifiers.
- Provider compromise exposes data across tenants.
- Revoked integration continues processing or retains data without basis.
- Cross-border processing or subprocessors are undisclosed.
- Provider outage creates unsafe access or data-integrity state.

## Required evidence
- [ ] Vendor register complete and current.
- [ ] Data-flow diagrams show each external transfer and purpose.
- [ ] Privacy notice accurately describes provider use and data categories.
- [ ] Consent/legal basis and transfer review recorded where required.
- [ ] DPA/contract, retention, deletion, backup and breach obligations reviewed.
- [ ] OAuth scopes/API permissions are least-privilege.
- [ ] Secrets are server-side, rotated and absent from client bundles/repository history.
- [ ] Webhook signatures, replay protections and idempotency tested.
- [ ] Payment lifecycle/reconciliation tested with sandbox transactions.
- [ ] Analytics payloads inspected for PII and sensitive learning data.
- [ ] AI training/retention settings and disclosures verified.
- [ ] Disconnect, token revocation and deletion workflows tested.
- [ ] No unresolved critical/high finding; residual risks signed and dated.

Incomplete vendor information is a blocker where it prevents a defensible privacy decision. A clean code scan does not replace vendor due diligence.
