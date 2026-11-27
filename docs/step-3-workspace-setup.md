# Step 3: Development Workspace Setup

## Repository
- Repository: `SomeSchoolScoobyDoo/kaizora-platform`
- Visibility: private
- Owner: Kaizora GitHub organisation
- Default branch: `main`
- Application code is kept separate from the existing public marketing repository `SomeSchoolScoobyDoo/landing`.

## Confirmed decisions
- Hosting target: Vercel.
- Domain registrar: WhoGoHost.
- Database/auth/storage direction: Supabase, initially using the free tier. Reassess limits, pricing, region, backups and data-processing terms before real users or sensitive production data.
- Institutional onboarding: individuals self-register; schools and corporations contact Kaizora and onboard learners/employees by invitation.
- Upload access: uploads are limited to organisations that have paid for the relevant service. Enforce this on the server, not only in the interface.
- Payments: deferred. Paystack is not configured; business eligibility and requirements must be resolved first.
- Product branding: Kaizora identity only. Do not add ChatGPT branding.

## Branching and change control
- Keep `main` as the protected production-bound branch.
- Use short-lived feature branches and pull requests.
- Do not deploy unreviewed changes to production.
- Branch protection status is not independently verified. Do not assume force-push protection or deletion protection is active.
- Do not commit credentials, access tokens, private keys, service-role keys, or production data.

## Environments
Create separate development, preview/staging, and production environments.
- Development: synthetic data only.
- Preview/staging: isolated Supabase project and test accounts; never reuse production secrets.
- Production: separate Supabase project, restricted credentials, backups and monitoring.
- Store Vercel and provider credentials in their respective encrypted environment-variable/secret settings. Never place secrets in source files or GitHub Actions YAML.
- Keep Supabase service-role credentials server-side only.

## Automated repository safeguards
- Dependabot configuration tracks npm and GitHub Actions dependencies weekly. npm updates become useful once a package manifest is added.
- Gitleaks secret scanning runs in GitHub Actions on pull requests to `main`, pushes to `main` and setup/feature branches, manual runs, and a weekly schedule. It scans the checked-out repository and Git history; a finding fails the job.
- The Gitleaks workflow on `setup/step-3-workspace` completed successfully on 2026-11-18 (run 44302193856). The subsequent pull-request-triggered Gitleaks run also completed successfully (run 44302203308).
- `.gitignore` excludes local environment files, keys, dependencies, build output and Vercel local configuration. `.env.example` contains placeholders only.
- GitHub Advanced Security Secret Scanning and Push Protection are not available/enabled in this repository. Gitleaks is the alternative repository-level check; it does not block a developer's push before it reaches GitHub.
- GitHub Dependency Review is not supported for this repository because the required GitHub Advanced Security/dependency-graph entitlement is unavailable. Its workflow was removed rather than leaving a permanently failing check.
- Add application lint, type-check, unit, integration, and build checks when the application scaffold and package lockfile are introduced.
- Configure required status checks after those application CI checks exist.

## Not yet configured
- Vercel project linkage and Preview/Production environment variables.
- Supabase projects, database migrations, Auth and Storage policies.
- GitHub branch protection/rulesets and required status checks.
- Supabase project created by the owner as `kaizora-development`; project credentials have not been added to the repository or application.
- Next.js/TypeScript application scaffold and responsive course-catalogue landing page are implemented on `feat/app-foundation`.
- Application CI for install, lint, type-check and production build passed on the initial scaffold PR. Gitleaks secret scan also passed.
- Dependency lockfile and automated unit/integration tests are still pending.
- Database schema, Supabase Auth/Storage policies and Vercel project linkage are still pending.
- Email provider and payment provider.
- Production deployment and custom-domain configuration.

## Safety rule
No real learner, school, corporate, payment, identity, or sensitive data should be placed in this repository or used in development. Do not treat this setup document as evidence that infrastructure has been deployed or tested.

## Verification and access limitations (2026-11-18)
- The private repository is accessible to the connected GitHub integration with push/admin permissions.
- The setup branch and the documentation/configuration files were read back successfully from GitHub.
- The Gitleaks scan on the setup branch passed, including the full-history scan. The pull-request-triggered Gitleaks check also passed.
- GitHub branch-protection read returned HTTP 403 (resource not accessible by the integration). Therefore branch protection status cannot be confirmed or changed through this connection.
- GitHub repository rulesets endpoint returned HTTP 403 stating that an upgrade to GitHub Pro or making the repository public is required. Do not make this private learning platform public just to obtain rulesets. Check the organisation's GitHub plan and available private-repository protection options before relying on branch protection.
- GitHub Advanced Security Secret Scanning, Push Protection, and Dependency Review are not available/enabled for this repository. Gitleaks is configured as the alternative secret scanner.
- No Vercel account/project management connection is available in this workflow. Vercel project linkage, environment variables and deployment protection cannot be configured or verified here.
- No application source or package manifest exists yet. Application lint/type-check/test/build jobs cannot be meaningfully configured until the framework scaffold and package lockfile exist.

## Manual settings that remain
1. Check repository/organisation plan eligibility for branch protection on a private repository. If available, protect `main`, require pull requests, and block force pushes/deletion. Add required status checks after CI exists.
2. In Vercel, create/link a project for this repository only when ready. Configure separate Preview and Production environments. Do not add real secrets until the matching Supabase projects exist. Never expose Supabase service-role keys as `NEXT_PUBLIC_*`.
3. Add unit/integration tests, generate and commit the dependency lockfile, then configure the available CI checks as required before merging.
