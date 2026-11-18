# Kaizora AI Academy — Step 1 Repository Audit

**Audit date:** 2026-11-18  
**Repository:** `SomeSchoolScoobyDoo/landing`  
**Branch audited:** `main`  
**Scope:** Existing public marketing website and the files reviewed through the connected GitHub repository.

## 1. Executive summary

The repository currently contains a static, single-page marketing website for the former Cohort 2, eight-week AI bootcamp. It is not the learning platform described in the Kaizora platform development plan.

The existing website can be retained as the marketing site and incrementally repositioned. The learning platform should be built as a separate application with its own backend, database, authentication, authorization, storage, payment integrations and operational controls.

No production files were changed as part of this audit.

## 2. Repository and file inventory

| File / asset | Purpose | Decision |
|---|---|---|
| `index.html` | Single-page marketing content, metadata, structured data and external links | Reuse and update |
| `styles.css` | Responsive layout, typography, colours and visual components | Reuse brand tokens and selected components |
| `script.js` | Mobile navigation and progressive-enhancement animations | Reuse only where appropriate |
| `assets/kaizora-logo.svg` | Main Kaizora logo | Reuse |
| `assets/kaizora-logo.png` | PNG logo asset | Reuse where suitable |
| `robots.txt` | Search-engine crawling rules | Review during launch |
| `sitemap.xml` | Current homepage sitemap | Update when public pages change |
| `README.md` | Website notes and deployment reminders | Expand with platform/website boundary |

A root `package.json` and `.github/workflows/deploy.yml` were not found at the paths checked. This does not prove that no other workflow or hosting configuration exists; the complete repository tree and hosting-provider settings still need verification.

## 3. Existing website behaviour

- The page is a static HTML document with a separate stylesheet and JavaScript file.
- The page contains sections for the old Cohort 2 bootcamp, its curriculum, tools, outcomes, application call-to-action and FAQs.
- The application CTA points to an external Google Form.
- Social links point to Kaizora Instagram, LinkedIn and Facebook pages; email uses a mailto link.
- External links opened in a new tab include `rel="noopener noreferrer"`.
- The JavaScript controls the mobile navigation and optional scroll animations.
- No native HTML form, student login, account creation, API integration, course player or database interaction was found in the reviewed page.
- The HTML includes canonical and social metadata, Course and Organization structured data, and a Google site-verification value.

## 4. Security review

### Checks performed on reviewed files

| Check | Observation | Result |
|---|---|---|
| Obvious hard-coded credentials | No obvious API keys, passwords or private credentials identified in reviewed files | Initial pass; not an exhaustive secret scan |
| DOM injection patterns | No `innerHTML` use found in the reviewed JavaScript | No issue observed |
| External scripts | No third-party JavaScript library is loaded by the reviewed page | Reduced third-party script exposure |
| External new-tab links | Reviewed links use `noopener noreferrer` | Good practice observed |
| User input handling | No native form or user-input processing found in the reviewed page | Not applicable to current static page |
| Authentication and authorization | No authentication or protected application routes exist | Not implemented |
| Upload handling | No upload feature exists | Not implemented |
| Payment processing | No payment integration exists | Not implemented |
| Security headers / CSP | Hosting response headers and host-level configuration were not available in the reviewed files | Not verified |
| Dependency scanning | No root package manifest was found at the checked path | Automated dependency audit not yet established |
| Automated tests | No test runner was identified in the reviewed repository files | Not established |

The Google site-verification value in the HTML is intended to be public and is not equivalent to a private API credential.

### Items requiring follow-up

1. Review the Google Form's collected fields, access settings, retention and privacy notice.
2. Confirm the production hosting provider and inspect its deployed response headers.
3. Configure an appropriate Content Security Policy and other security headers at the hosting layer, after testing compatibility.
4. Inspect the complete repository tree and all deployment configuration before declaring the repository free of secrets.
5. Run an exhaustive secret scan and dependency/security scan in the chosen CI environment.
6. Confirm the canonical domain and social profile destinations before production changes.

## 5. Reuse versus rebuild

### Reuse

- Kaizora SVG and PNG logo assets.
- Existing navy/orange brand palette and visual identity.
- Marketing website as a separate public-facing site.
- Existing SEO metadata as a starting point, after updating descriptions and structured data.
- Responsive layout patterns and accessible navigation patterns where they remain suitable.

### Rebuild or create separately

- Application frontend and authenticated user experience.
- Backend API and business logic.
- Database schema and migrations.
- Identity, registration, login, recovery and role management.
- Individual learner dashboard and learning progress.
- Course catalogue, lesson delivery and assessment engine.
- Certificate eligibility, generation and verification.
- Payment integration and reconciliation.
- School and corporate tenant management.
- Institutional reporting.
- Admin dashboard, moderation and complaint workflows.
- Account deletion, data export and email preferences.
- Logging, monitoring, backups and incident response.

The static marketing website must not be treated as a secure application backend.

## 6. Architecture boundary

Recommended separation:

- **Marketing website:** Public course information, institutional programme information, contact/enquiry routes and SEO.
- **Learning application:** Authenticated learner, school, corporate, instructor, moderator and administrator workflows.
- **Backend and database:** Authoritative permissions, records, assessment scoring, payment verification, certificates and audit events.
- **External providers:** Payment, email and other integrations, each accessed through server-side credentials and verified callbacks where applicable.

The exact technology stack is deliberately not selected in this audit. That decision belongs to Step 2, after requirements, cost, hosting constraints and the threat model are reviewed.

## 7. Step 1 completion status

- [x] Confirm repository identity, visibility, default branch and connected account permissions.
- [x] Review README, HTML, CSS, JavaScript, robots.txt and sitemap.xml.
- [x] Inspect supplied SVG and PNG logo assets.
- [x] Identify the existing public-page structure and external links.
- [x] Perform an initial security review of the inspected files.
- [x] Document reusable assets and components.
- [x] Document application features that must be built separately.
- [ ] Inspect the complete repository tree and all hosting-provider settings.
- [ ] Run exhaustive secret scanning and automated security tooling.
- [ ] Verify deployed headers, TLS and production configuration.

**Status: Initial repository audit documented.** The audit is not a penetration test, exhaustive secret scan or production-hosting security verification. Those checks remain outstanding and must not be reported as passed.

**Next step:** Step 2 — design the platform architecture, database, role/permission model and threat model before selecting and implementing the application stack.
