# Integrations Division — Delivery Process

## Entry condition
Learner, organisation and school divisions and their individual security gates are complete.

## Sequence
1. Inventory vendors and data flows before adding SDKs or API calls.
2. Document purpose, data fields, data subjects, region, retention, subprocessors, contracts, scopes and user disclosures.
3. Prioritise integrations based on product need and operational readiness.
4. Implement one provider at a time behind server-side boundaries.
5. Add webhook signature verification, idempotency, retries and failure handling.
6. Verify data minimisation and keep secrets server-side.
7. Test provider outage, timeout, replay, revocation and deletion paths.
8. Run end-to-end acceptance checks using sandbox/test provider accounts.
9. Close with integration security/privacy gate. Do not begin release readiness until it passes.

## Mandatory provider review
For each provider record why it is needed; exact fields leaving Kaizora; affected data subjects; processing/storage locations; subprocessors; retention/deletion; model training use; user notice/consent/legal basis; API scopes; secret/webhook controls; revocation and breach response.

## Rules
- Check current provider docs and eligibility at implementation time.
- Do not infer online checkout API support from POS documentation.
- Do not store card details without separately approved compliance design.
- Verify webhook signatures and payment status server-side.
- Analytics must not become a side channel for personal data.
- Integration security is a dedicated final stage gate.
