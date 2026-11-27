# Integrations Division — Task Register

Status: Planned. Start only after school security gate passes.

## I1 — Inventory and priority
- [ ] Create vendor register and data-flow map.
- [ ] Confirm business need and minimum data for each provider.
- [ ] Prioritise payments, transactional email, analytics, AI, media/content and institutional integrations.
- [ ] Confirm API/product tier, costs, regions and operational constraints.
- [ ] Define fallback and provider outage behaviour.

## I2 — Payments
- [ ] Compare checkout providers and confirm account/API eligibility.
- [ ] Document payment states, unique references, idempotency and reconciliation.
- [ ] Implement server-side initiation and verification.
- [ ] Verify signed webhooks and replay handling.
- [ ] Handle pending, success, failure, expiry, refund, chargeback and duplicate events.
- [ ] Never unlock a paid course from screenshot or client-submitted success.
- [ ] Minimise payment data stored by Kaizora.

## I3 — Email and notifications
- [ ] Verify Resend SMTP and sender domain end-to-end.
- [ ] Define transactional templates and event triggers.
- [ ] Protect recipient lists and prevent cross-tenant delivery.
- [ ] Implement retry, bounce and suppression handling.
- [ ] Keep marketing consent separate from transactional messages.

## I4 — Analytics and AI
- [ ] Define event taxonomy and prohibited personal fields.
- [ ] Review analytics payloads and consent requirements.
- [ ] Define AI use cases, input minimisation and output handling.
- [ ] Confirm retention, training use and deletion terms.
- [ ] Do not send learner submissions or PII without approved purpose and disclosure.

## I5 — Operations
- [ ] Store credentials server-side and document rotation.
- [ ] Implement rate limits, retries, idempotency and timeouts.
- [ ] Add monitoring and provider health handling.
- [ ] Provide disconnect/revocation and deletion workflows.
- [ ] Document vendor change and incident process.

## Exit
- [ ] Integration acceptance criteria pass.
- [ ] Integration security/privacy gate passes before release readiness.
