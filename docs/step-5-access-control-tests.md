# Step 5: Automated Access-Control Tests

The regression suite lives in `supabase/tests/step_5_access_control.test.sql` and uses pgTAP against a disposable local Supabase database. The additive migration `20261118000200_enforce_active_organization_access.sql` ensures pending, suspended, and closed organizations do not grant tenant access, even when membership rows remain.

## Run locally

Requirements: Docker and the Supabase CLI.

```bash
supabase start -x studio,imgproxy,edge-runtime,logflare,vector
supabase test db
```

The test runner applies repository migrations to its local database before running the test file. It does not connect to or modify the hosted `kaizora-development` project.

## Coverage

The suite checks:

- All four identity/access-control tables exist and have RLS enabled.
- Authenticated grants are limited to the intended profile and read operations.
- Profile identity fields cannot be changed by a normal authenticated user.
- Anonymous users cannot execute the membership helper.
- A user can read only their own profile and memberships.
- A user can read only active organizations for which they have a membership.
- Memberships and privileged roles in pending, suspended, or closed organizations do not grant tenant access.
- A user can update their own profile name but cannot update another user's profile.
- Client-role inserts into organizations, memberships, and audit events are rejected.

The GitHub Actions workflow `.github/workflows/access-control-tests.yml` runs this suite when relevant Supabase files change. A passing test suite is a regression guard, not a substitute for a full authorization review or production security assessment.
