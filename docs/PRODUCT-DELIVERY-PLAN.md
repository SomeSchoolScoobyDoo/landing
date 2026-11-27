# Kaizora Product Delivery Plan

**Status:** Working plan, grounded in repository milestone specifications and product-owner direction.  
**Last updated:** 2026-11-24

## Product intent

Kaizora AI Academy is a practical learning platform for independent learners, schools and organisations. The current repository direction is Next.js + TypeScript, Supabase for PostgreSQL, authentication and private storage, and Vercel hosting. Review service tiers and production topology before launch.

## Source-of-truth hierarchy

1. Accepted product decisions and this plan define intended behaviour.
2. Division specifications define detailed requirements and acceptance criteria.
3. Code, migrations and tests define what is actually implemented.
4. Preview observations and feedback identify gaps; they do not silently override accepted decisions.

Record proposed versus accepted decisions explicitly. A merged PR or passing build does not by itself prove the user journey is complete.

## Delivery order

Security is the final gate of each division, not one giant audit at the end.

| Order | Division | Completion gate |
|---|---|---|
| 1 | Individual learner experience | Learner journeys, content, progress, assessment, enrolment, certificates and support flows verified |
| 2 | Learner security and privacy | Learner data isolation, browser exposure, authorization, RLS, abuse, storage, logs and third-party data boundaries tested |
| 3 | Organisation experience | Organisation onboarding, workspace, staff/learner management, course assignment, reports and admin workflows verified |
| 4 | Organisation security and privacy | Tenant isolation, role escalation, invitations, exports, reporting and operator access tested |
| 5 | School experience | School setup, teacher/staff roles, classes/cohorts, rosters, assignments and reporting verified |
| 6 | School security and privacy | Student/teacher/admin separation, safeguarding, roster isolation, bulk export and retention tested |
| 7 | Integrations | Payments, email, analytics, AI services, media/content providers and institutional integrations implemented and verified |
| 8 | Integration security and privacy | Vendor due diligence, consent/notice, scopes, secrets, webhooks, retention, deletion, subprocessors and incident obligations reviewed |
| 9 | Release readiness | Regression, monitoring, backup/restore, incident response, support and production launch decision |

## Current learner-stage baseline from repository specs

The existing milestone documents record:
- Step 4: Supabase SSR authentication, signup, sign-in/out, password reset, email confirmation and server-side identity validation. Real preview/deployment environment variables and end-to-end verification remain configuration dependencies.
- Step 5: profiles, organisations, memberships and audit events with RLS, restricted client writes and server-side role checks. pgTAP tests cover identity and tenant boundaries.
- Step 6: database-backed public catalogue with published-course visibility and server-side catalogue reads. Course import and publishing workflows remain separate.
- Step 7: protected lesson delivery, progress and private resources with expiring signed URLs. Import and authoring workflows remain deferred.
- Step 8: assessment questions separated from answer keys and server-side grading. Learner-facing quiz UI and content import remain deferred.
- Step 9: private enrolment, dashboard and public title-only curriculum preview. The docs specify that active enrolment gates learning content and assessment access.

These are documented implementation claims, not a substitute for checking the current branch, migrations, deployed environment and test output. A Ronda preview currently showed the setup fallback because Supabase public environment variables were absent in that sandbox. That preview state is not successful learner-flow verification.

## Definition of done for a division

- Product requirements and primary/exception journeys are written.
- Empty, loading, error, denied, recovery and mobile states are handled.
- Acceptance criteria are tested against the actual preview.
- Authorization is enforced server-side and by database policy.
- Negative tests prove users cannot access another user's or tenant's data.
- Browser inspection confirms only the current user's authorized data is delivered.
- Logs, analytics, errors, exports, caches and source maps do not leak sensitive data.
- Third-party data flows and user-facing disclosures are documented.
- Security gate report is complete and all release-blocking findings are resolved.
- Preview feedback is triaged, resolved or explicitly deferred with rationale.

## Delegation and operating model

Use available project tools for repository inspection, implementation, preview, issue tracking and security testing. Treat any co-founder/manager identities, responsibilities and access as unverified until the connected source can be inspected. Do not invent owners or grant access based on assumptions. Notion agent-directory access is currently unavailable on this workspace plan; this does not block product planning or repository work.

## Change control

Every meaningful decision record should include date, division, status (proposed/accepted/superseded), decision, rationale, alternatives, impact, risks, owner only when confirmed, and verification evidence. Update the plan when scope or sequencing changes. Preserve previous rationale.
