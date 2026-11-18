# Kaizora AI Academy — Step 2 Architecture & Threat Model

**Status:** Proposed architecture for review  
**Date:** 2026-11-18  
**Repository:** `SomeSchoolScoobyDoo/landing`  
**Branch:** `kaizora-step-1-audit`  
**Scope:** Architecture design only. No application backend, database, authentication, payment integration, hosting configuration, or security control is implemented by this document.

## 1. Product requirements this architecture must satisfy

1. Individuals can discover and take standalone courses without paying for course access.
2. A learner may purchase a certificate only when the relevant course's completion and assessment rules are satisfied.
3. Schools can manage their own institution, lecturers, students, classes/cohorts, course assignments and reports.
4. Corporations can manage their own organization, employees, training assignments and reports.
5. Lecturers/instructors can manage only the classes and learning activities assigned to them.
6. Multiple-choice assessments are marked automatically by trusted server-side logic. Answer keys must never be sent to learner clients.
7. Assessment retake limits are configurable per assessment/course policy; the current planning baseline is three attempts unless the course policy explicitly defines otherwise.
8. Kaizora administrators can manage courses, users, institutional accounts and platform operations under least privilege.
9. Authorized moderators can review reports and remove prohibited uploads/content, with a complete audit trail.
10. Users and institutions can request account closure/deletion and email unsubscribe. Deletion must revoke sessions and follow a documented legal-retention policy.
11. Institutional data must be isolated by tenant at the database and backend layers, not merely hidden in the interface.

## 2. Recommended architecture

### 2.1 Architecture style

Use a **modular monolith** for the first production version, not microservices.

A modular monolith keeps identity, learning, assessments, certificates, payments, institutions, moderation and administration in one deployable application with explicit module boundaries. This reduces operational complexity and cost for a small team while preserving the option to split modules later if scale or isolation requirements justify it.

### 2.2 Proposed stack (provisional)

| Layer | Proposed choice | Reason / constraint |
|---|---|---|
| Web application | Next.js with TypeScript | One application for public pages and authenticated workflows; server-side route handlers for trusted operations |
| Database | Supabase-hosted PostgreSQL | Relational data, transactions, constraints, row-level security and managed backups |
| Identity | Supabase Auth, configured for secure server-side sessions | Avoid building password storage and token issuance from scratch |
| File storage | Private Supabase Storage buckets | Course materials, certificates and reported uploads must not be public by default |
| Hosting | A managed Node-compatible host selected after cost and security review | Do not assume Netlify; verify region, logs, headers, environment variables, backups and deployment controls |
| Payments | Provider adapter, initially evaluate Paystack for NGN and supported international payments | Confirm current fees, supported currencies, settlement, refund and webhook behaviour before committing |
| Email | Transactional email provider to be selected | Verification, recovery, invitations, receipts and notifications |
| Monitoring | Structured application logs plus provider monitoring/error reporting | No sensitive payloads or secrets in logs |

**Important:** This is a proposed baseline, not a vendor commitment. Before implementation, verify current pricing, data-processing terms, availability in Nigeria, backup/restore capability, region options, service limits and the ability to export data. Keep payment and email integrations behind provider interfaces so they can be replaced.

### 2.3 Logical system boundary

```text
Public visitors / Learners / Lecturers / School admins / Corporate admins
                              |
                         HTTPS only
                              |
                    Next.js application
          +-------------------+--------------------+
          |                   |                    |
       UI pages          Server/API layer       Webhook routes
                              |
                    Authentication check
                    Tenant + role authorization
                    Input validation
                    Business rules
                              |
              +---------------+----------------+
              |               |                |
          PostgreSQL     Private Storage    Provider adapters
          + RLS           + signed access    +-- Payments
              |                              +-- Email
        Audit events                         +-- Monitoring
              |
        Encrypted backups
```

The browser is untrusted. It may display controls and submit requests, but it is never authoritative for permissions, assessment scores, certificate eligibility, payment status or tenant identity.

## 3. Application modules and trust boundaries

| Module | Responsibilities | Must not trust |
|---|---|---|
| Identity | Sign-up, sign-in, verification, recovery, sessions, suspension and deletion | Client-supplied user IDs, roles or email-verification claims |
| Authorization | Role checks, membership checks, tenant scoping and policy evaluation | Frontend route visibility |
| Course catalogue | Standalone courses, categories, publishing and course content | Client-supplied publication state |
| Learning | Enrolment/entitlements, lessons, progress and course completion | Client-supplied progress or completion |
| Assessments | Attempts, question delivery, scoring and retake policy | Client-submitted answer keys or scores |
| Certificates | Eligibility, issuance, unique verification identifier and revocation | Client-supplied completion/payment status |
| Payments | Checkout initiation, provider callback verification, refunds and reconciliation | Browser redirect success or client payment claims |
| Institutions | Schools, corporations, memberships, classes and assignments | Client-supplied tenant IDs without membership validation |
| Reporting | Authorized progress and aggregate reports | Unscoped queries or unrestricted exports |
| Moderation | Reports, evidence review, takedown and appeals if provided | Untrusted file metadata or public file URLs |
| Administration | Platform configuration and privileged operations | Ordinary user sessions or unlogged admin actions |

## 4. Identity, roles and permissions

### 4.1 Identity model

A person has one platform identity and may have memberships in multiple organizations. Do not create a separate login identity for every school or corporation.

Recommended core records:

- `users`: internal user identity/profile reference; authentication credentials remain with the identity provider.
- `organizations`: institution or corporation record, with a type such as `school` or `corporate`.
- `organization_memberships`: user, organization, membership status and organization-scoped role.
- `platform_roles`: privileged Kaizora-wide role assignments, separate from organization membership.
- `invitations`: organization-scoped invitation, expiry, intended email and acceptance state.
- `sessions`: managed by the identity provider; application session revocation state may be recorded where required.

A role is not a user-editable profile field. Users cannot grant themselves roles, promote themselves, change their organization membership, or create platform administrators.

### 4.2 Proposed roles

| Role | Scope | Typical permissions |
|---|---|---|
| Individual learner | Own account | Browse/enrol, learn, take assessments, view own progress and certificates |
| School owner/admin | One school tenant | Manage school profile, staff, student membership, classes, course assignments and permitted reports |
| Lecturer/instructor | Assigned school/classes | Manage assigned learning activities and view only assigned learners' relevant progress |
| School student | One or more school contexts | Access assigned courses and own learning records |
| Corporate owner/admin | One corporate tenant | Manage employees, assignments and permitted training reports |
| Corporate learner/employee | Own account within tenant | Access assigned courses and own progress |
| Kaizora course administrator | Platform scope | Create, edit, publish and archive courses |
| Kaizora support operator | Restricted platform scope | Handle defined support tasks without unrestricted access to learner content |
| Content moderator | Moderation scope | Review reports, restrict/remove content and record moderation decisions |
| Platform security administrator | Platform scope | Manage high-risk settings and privileged access; MFA mandatory |

Use permissions rather than scattered role-name conditionals. Example permission identifiers:

- `course.read_published`, `course.manage`, `course.publish`
- `learner.read_self`, `learner.read_assigned`
- `organization.manage_members`, `organization.manage_classes`
- `report.read_organization`, `report.export_organization`
- `moderation.review`, `moderation.remove_content`
- `platform.manage_users`, `platform.manage_security`

Platform roles and organization roles must remain distinct. A school administrator is not a Kaizora administrator.

### 4.3 Authorization enforcement

Every protected server operation must:
1. Validate the authenticated session.
2. Load the user's active role/membership from trusted storage.
3. Check the requested permission.
4. Resolve the target resource's tenant from the database.
5. Confirm the user is authorized for that exact tenant and resource.
6. Validate the operation's business rules.
7. Write an audit event for sensitive actions.

Use PostgreSQL row-level security (RLS) as defence in depth. Server-side authorization is still required. Do not rely on RLS alone if a privileged database key bypasses RLS.

For tenant-owned records, use `organization_id` on every applicable row and composite foreign keys/constraints where useful to prevent a record in one tenant from referencing another tenant's resource. Avoid queries that accept an arbitrary tenant ID and return data without checking membership.

**Service-role database credentials must never be shipped to the browser.** Any server-side privileged client must be isolated, narrowly used and protected by explicit authorization checks.

## 5. Proposed database domains

This is a domain-level map, not final SQL migrations.

| Domain | Main records |
|---|---|
| Identity | users/profiles, platform roles, organization memberships, invitations |
| Organizations | organizations, organization settings, classes/cohorts, class memberships |
| Courses | courses, categories, modules, lessons, lesson assets, publication versions |
| Enrolment | individual enrolments, organization course assignments, access entitlements |
| Learning | lesson progress, completion records |
| Assessments | assessments, questions, options, attempts, submitted answers, scoring results |
| Certificates | certificate policies, issued certificates, verification identifiers, revocation records |
| Payments | payment orders, provider transactions, webhook events, refunds, reconciliation records |
| Moderation | content reports, report evidence references, moderation actions, appeals if implemented |
| Administration | audit events, support cases, security events, notification preferences |
| Privacy | deletion requests, export requests, consent/notice versions, retention holds |

### Data invariants

- Store assessment answer keys only in server-protected records. The learner API returns question text and permitted options, never correct-answer flags or scoring keys.
- A score is calculated server-side from a submitted attempt and the stored answer key.
- Attempt counts are incremented transactionally. Concurrent requests must not bypass the attempt limit.
- A certificate is issued only after the server verifies completion, passing score, any required payment and the active certificate policy.
- Certificate verification IDs must be random, unique and non-sequential. Public verification reveals only the minimum required certificate details.
- Payment state is derived from verified provider events and reconciliation, never from a browser redirect.
- Every organization-owned record is scoped to an organization and checked against active membership and permission.
- Do not duplicate sensitive personal data into reports when an aggregate or pseudonymous identifier is sufficient.

## 6. Session, authentication and account controls

- Use the identity provider's supported secure session flow with HttpOnly, Secure and appropriate SameSite cookies in production.
- Do not store long-lived authentication tokens in browser localStorage.
- Rotate/refresh sessions safely; revoke sessions after password reset, account suspension, deletion and relevant security events.
- Rate-limit sign-in, registration, verification resend, password recovery, invitation acceptance and sensitive actions.
- Use generic password-recovery responses to reduce account enumeration.
- Require email verification before sensitive account activity.
- Require MFA for all platform administrators and security-sensitive privileged roles; prefer phishing-resistant MFA where supported.
- Require recent re-authentication for high-impact actions such as changing payment settings, promoting administrators, exporting sensitive data or deleting an organization.
- Record failed login patterns and suspicious session changes without logging passwords, tokens or full secrets.
- Define account suspension, recovery and deletion workflows before launch.

## 7. Data protection and secrets

### Data classification

| Class | Examples | Handling |
|---|---|---|
| Public | Published course descriptions, public certificate verification result | May be public after review |
| Internal | Draft lessons, internal operational notes | Authenticated and permission-scoped |
| Personal | Names, email, learning progress, organization membership | Least-privilege access, minimized collection, retention limits |
| Sensitive operational | Payment references, moderation evidence, security logs | Restricted access, encryption, audit trail |
| Secrets | API keys, database credentials, signing keys, webhook secrets | Secret manager/environment injection only; never commit or log |

### Required controls

- TLS for all application and provider communication.
- Encryption at rest for managed database, object storage and backups; verify the provider's actual guarantees.
- Field-level encryption only where the threat model requires it, with managed key rotation and a documented recovery process.
- Secrets stored in the hosting provider's secret manager or equivalent; separate development, staging and production credentials.
- No secrets in Git, client bundles, screenshots, logs, issue comments or sample environment files.
- Rotate credentials after suspected exposure and remove old credentials after successful rotation.
- Keep production data out of local development and test environments; use synthetic test data.
- Avoid collecting date of birth, government ID or other high-risk data unless a documented requirement exists.

## 8. File storage and content moderation

- Private buckets by default. Public access only for explicitly approved public assets.
- Validate file type using content inspection, not filename or browser MIME claims alone.
- Enforce file size limits and allowlists; generate server-side object names.
- Store uploads in a quarantine/review state before publication where user-generated uploads are permitted.
- Scan uploads for malware where a suitable scanning service is available; do not imply a scan occurred if it did not.
- Serve private assets through short-lived, scoped signed URLs after authorization.
- Prevent path traversal, object overwrite, cross-tenant access and direct bucket enumeration.
- Restrict moderation evidence to authorized moderators; log every view, removal and restoration.
- Define appeal/review and retention rules for reports before launching user-generated uploads.

## 9. Payment and certificate trust boundary

- Browser creates a checkout request; server calculates the expected amount, currency, user, certificate and order reference.
- Server creates the provider checkout session using a secret key.
- Provider webhook signature is verified against the raw request body using the provider's documented method.
- Verify order reference, amount, currency, provider account and final transaction state.
- Make webhook processing idempotent using a unique provider event/transaction identifier and database transaction.
- Never store raw card numbers or CVV. Let the payment provider handle card data.
- Treat redirects as user experience only; confirm payment using verified webhook and/or server-to-server provider verification.
- Record refunds, disputes and reconciliation outcomes.
- Certificate issuance is a separate transaction after the server checks the authoritative eligibility rules.
- Do not let an administrator silently edit payment status; adjustments require reason, permission and audit event.

## 10. Logging, monitoring and audit

Keep security logs separate from ordinary application diagnostics where practical.

Log:
- Authentication success/failure and account recovery events.
- Role and membership changes.
- Privileged admin actions and configuration changes.
- Access-denied events and repeated cross-tenant access attempts.
- Assessment policy changes and certificate issuance/revocation.
- Payment webhook verification, duplicate events, refunds and reconciliation exceptions.
- Moderation reports, evidence access and content actions.
- Data export, deletion requests and session revocation.

Never log passwords, raw access tokens, secret keys, full payment credentials, full private file contents or unnecessary sensitive personal data.

Each audit event should include timestamp, actor, action, target record, organization scope where applicable, outcome, request/correlation ID and a minimal reason/context. Protect audit records from ordinary user modification and restrict who can read them.

Define alert thresholds for repeated authentication failures, privilege escalation attempts, cross-tenant denials, webhook failures, unusual exports, storage abuse and backup failures.

## 11. Backups, recovery and availability

- Enable managed database backups and point-in-time recovery where available.
- Back up uploaded files and critical configuration separately from the database.
- Encrypt backups and restrict restore permissions.
- Define recovery point objective (RPO) and recovery time objective (RTO) based on the business impact and provider cost before production.
- Test restoration into an isolated environment before launch and on a recurring schedule.
- Document who can initiate a restore, how credentials are rotated after an incident and how data consistency is checked.
- Keep a recovery copy independent of the primary failure domain where cost and provider capabilities allow.
- A backup that has never been restored is an untested hope, not a recovery plan.

## 12. Threat model (STRIDE-style)

| Threat | Example against Kaizora | Primary mitigations | Required verification |
|---|---|---|---|
| Spoofing | Attacker takes over a lecturer or admin account | Verified identity, MFA for privileged roles, rate limits, secure recovery, session revocation | Recovery abuse tests, MFA enforcement tests |
| Tampering | Learner changes score, completion or payment status in browser | Server-authoritative state, database constraints, signed/verified webhooks, audit events | Modify requests and replay events in tests |
| Repudiation | Admin denies deleting a student's content or changing a role | Append-only/restricted audit trail with actor and target | Verify every sensitive action produces an audit record |
| Information disclosure | School A reads School B's student records or answer keys leak | Tenant-scoped authorization, RLS, private storage, server-only answer keys | Cross-tenant API and database tests; inspect network responses |
| Denial of service | Automated sign-in, upload or assessment-attempt abuse | Rate limits, request/file size limits, quotas, monitoring and provider protections | Load/abuse tests within safe staging limits |
| Elevation of privilege | Student edits role or becomes school/platform admin | Server-controlled role grants, least privilege, MFA, explicit admin workflows | Attempt self-promotion and unauthorized role changes |

### Additional application-specific threats

- IDOR/BOLA: changing a lesson, report, certificate or file ID to access another user's or tenant's resource.
- Assessment leakage: answer keys, scoring rules or future questions exposed in client payloads.
- Retake race conditions: parallel requests exceed the attempt cap.
- Payment replay: duplicate or forged webhooks issue repeated entitlements/certificates.
- Malicious uploads: disguised scripts, oversized files, malware or abusive imagery.
- Unsafe exports: school/corporate admins export data outside their scope.
- Account lifecycle abuse: deleted/suspended users retain sessions or access through stale memberships.
- Moderator abuse: privileged staff access or remove content without a justified, traceable action.
- Email abuse: invitation/recovery endpoints used for spam or account enumeration.

## 13. Minimum security acceptance gates before implementation is considered production-ready

- No client-controlled role, tenant, payment, completion, score or certificate status is trusted.
- Every protected endpoint has an authorization test, including negative tests.
- Cross-tenant reads and writes fail at both application and database policy layers.
- Answer keys do not appear in browser responses, source maps or client bundles.
- Payment webhooks are authenticated, idempotent and amount/currency checked.
- Session revocation works after recovery, suspension and deletion.
- Private uploads cannot be fetched without authorization.
- Admin MFA and least-privilege access are enforced.
- Audit events cover privileged operations and are not editable by ordinary users.
- Secret and dependency scans run in CI; critical/high findings block release until resolved or formally risk-accepted.
- Backup restoration is tested and documented.
- Staging abuse/security tests pass before production deployment.

## 14. Decisions still open before Step 3

These are not safe to silently assume:

1. Confirm the application domain/subdomain and whether the marketing site remains separate.
2. Confirm Supabase as the preferred database/auth/storage provider after checking current pricing, region and terms.
3. Confirm the managed application host and deployment region.
4. Confirm payment provider, supported currencies and certificate pricing model.
5. Confirm transactional email provider.
6. Confirm whether students self-register, are invited by schools, or both.
7. Confirm whether user-generated uploads are required at launch or whether reports initially concern course comments/attachments only.
8. Set data-retention rules, privacy notice, RPO/RTO and support access policy.
9. Confirm whether a separate repository will be created for the learning application. Recommended: yes. Keep this existing repository as the marketing site and keep the platform code, secrets, CI and deployment isolated.

## 15. Step 2 status

- [x] Documented modular-monolith architecture proposal.
- [x] Defined trust boundaries and module responsibilities.
- [x] Proposed identity, platform-role and organization-membership model.
- [x] Mapped core database domains and critical invariants.
- [x] Documented session, secret, data-protection and storage requirements.
- [x] Documented payment/certificate trust boundaries.
- [x] Documented logging, monitoring and backup requirements.
- [x] Created STRIDE-style threat model and application-specific threats.
- [x] Defined minimum security acceptance gates.
- [ ] Confirm vendor, hosting, payment, email and retention decisions.
- [ ] Review and approve architecture before implementation.

**Status: Architecture and threat-model proposal documented. Step 2 is not approved/final until the open decisions are confirmed. No application infrastructure or security controls have been deployed.**

**Next step:** Step 3 — create isolated development, staging and production environments, repository/branch strategy, CI, automated tests, secret handling and dependency/security scanning. Do not begin production feature implementation before the Step 2 decisions and Step 3 controls are in place.
