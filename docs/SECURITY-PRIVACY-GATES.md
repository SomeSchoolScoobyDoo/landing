# Kaizora Security, Privacy and Third-Party Gate Standard

**Status:** Required engineering standard  
**Last updated:** 2026-11-24

## Core privacy promise

No unauthorised user should be able to inspect another learner's or tenant's personal information through the DOM, browser developer tools, network responses, browser storage, URLs, logs, exports, analytics or cached responses.

Developer tools are not a security boundary. An authenticated user can inspect data delivered to their own browser. The system must ensure that the browser receives only the minimum data that the current user is authorised to see.

A privileged developer/operator with production database or infrastructure access may technically access records. Do not promise otherwise if privileged access exists. Instead enforce least privilege, named accounts, MFA, time-bounded access, audit logging, justified break-glass access and synthetic data for development.

## Mandatory controls

### Client and browser
- Never ship service-role keys, signing secrets, provider credentials or privileged tokens to client code or NEXT_PUBLIC variables.
- Return only the fields needed by the current view. Avoid over-fetching full profiles or tenant records.
- Do not treat hidden UI, client-side route guards, opaque IDs or disabled controls as authorization.
- Enforce access in server actions, route handlers, server components, RPCs and file delivery.
- Inspect DOM, source, bundles, source maps, network responses, local/session storage, cookies, caches and browser logs.
- Keep PII and secrets out of URLs, query strings, analytics, client logs, exception messages and feedback attachments.
- Use secure, HttpOnly and appropriate SameSite cookies. Do not store session tokens or sensitive records in localStorage.
- Set private/no-store cache behaviour for user-specific responses and verify CDN/cache isolation.

### Database, roles and storage
- Deny by default. Define roles and permissions explicitly.
- Use Supabase RLS and server-side authorization. Test both positive and negative cases.
- Keep service-role credentials server-only and narrowly available.
- Test horizontal IDOR, vertical privilege escalation, stale sessions, revoked membership and tenant switching.
- Keep public course metadata separate from protected lessons, assessments, submissions, certificates and learner records.
- Keep protected files in private buckets and issue short-lived signed URLs only after authorization.
- Audit sensitive administrative access and changes.

### Third-party processors
Maintain a vendor register for every provider receiving, storing, processing or accessing personal data. Capture service/purpose, data categories and fields shared, data subjects, processing region, cross-border transfers, subprocessors, retention/deletion, security controls, DPA/contract status, breach terms, OAuth/API scopes, webhook security, secret rotation, model-training use, user-facing notice/consent and disconnect paths.

Before enabling a provider, minimise data, verify terms and security posture, document the flow, make privacy disclosures accurate, and test failure/revocation paths. Do not send learner content or PII to an AI provider without a documented purpose, valid legal basis, appropriate vendor terms and clear user disclosure.

## Per-division gates

### Learner security gate
Review authentication, sessions, profiles, enrolments, progress, assessments, submissions, certificates, support access, private files, account deletion and retention. Prove learner A cannot access learner B's data.

### Organisation security gate
Review tenant isolation, organisation admin roles, staff permissions, learner lists, reports, exports, invitations, billing contacts and audit logs. Prove organisation A cannot access organisation B.

### School security gate
Review student/teacher/admin boundaries, classes, rosters, assignments, reports, safeguarding, bulk operations, retention and children's data considerations where applicable.

### Integration security gate
Review every vendor and integration: payment, email, analytics, AI, media, identity and institutional systems. Verify data minimisation, scopes, secret storage, webhook signatures, retries/idempotency, deletion, revocation, subprocessors, international transfers and incident obligations.

## Evidence required to pass

- Data-flow map and threat model for the division.
- RLS and authorization tests, including cross-user and cross-tenant negative tests.
- Dependency, secret and static-analysis scans.
- Application security testing appropriate to the changed surface.
- Manual browser/network/storage and cache inspection.
- Logging/analytics review for PII leakage.
- Vendor register and disclosure review when third parties are involved.
- Findings triaged by severity. Critical/high findings block release until fixed or explicitly accepted by the accountable product owner with a documented mitigation.
- Dated report with scan IDs, commit/branch, test commands/results, residual risks and reviewer sign-off.

An unfinished, failed or unavailable scan is not a clean result. Zero findings from an incomplete scan is not proof of safety.

## Incident readiness

Before production, define escalation, containment, breach assessment/notification, evidence preservation, data-subject requests, retention/deletion and backup expiry. Restrict production access by role and need; use synthetic or anonymised data for development and preview screenshots.

This is an engineering standard, not legal advice. Obtain a jurisdiction-specific review of applicable Nigerian data-protection requirements and any other jurisdictions relevant to learners and institutions.
