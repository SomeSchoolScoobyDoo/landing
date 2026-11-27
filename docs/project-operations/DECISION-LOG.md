# Kaizora Decision Log

Newest entries first. Proposals are not decisions until the product owner accepts them.

## 2026-11-24 — Sequential divisions with a security gate after each
- Status: Accepted by product owner.
- Sequence: Individual learner → learner security/privacy gate → organisation → organisation security/privacy gate → school → school security/privacy gate → integrations → integration security/third-party privacy gate → release readiness.
- Rule: Security is the final stop within each division. A division gate blocks entry to the next division.
- Rationale: Security review must be grounded in the completed feature set and data flows of that division.

## 2026-11-24 — Browser data minimisation
- Status: Accepted requirement.
- Decision: A user's browser must not receive another user's personal information unless the current authenticated and authorised user is entitled to see it. Hiding data in the UI is not protection if it was already sent in HTML, JSON, scripts, network responses or caches.
- Qualification: Privileged production operators may technically access data. Reduce this through least privilege, audited access, synthetic development data and operational controls rather than claiming developer-side access is impossible.

## 2026-11-24 — Third-party privacy belongs in security
- Status: Accepted requirement.
- Decision: Vendor data use, subprocessors, processing regions, retention/deletion, AI training use, disclosures, consent/legal basis, breach terms and disconnect/revocation are part of integration security.
- Rule: A clean code scan does not replace vendor due diligence.

## 2026-11-24 — Preview feedback workflow
- Status: Accepted direction; implementation pending.
- Decision: Provide a small feedback/suggestion entry point on preview pages and a general suggestion route. Attach preview context automatically. Persist reports privately on the server; restrict security/privacy reports to authorised reviewers.
- Rule: Do not display a success state until persistence is confirmed.

## 2026-11-24 — Preserve production landing
- Status: Accepted.
- Decision: Keep existing landing production deployment untouched during LMS development. Use isolated previews and integrate only after testing and explicit approval.
