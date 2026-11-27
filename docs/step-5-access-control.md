# Step 5: Identity and Access Control

## Database foundation

The identity migration creates:

- `profiles`, linked to Supabase Auth users.
- `organizations`, with school/corporation types and pending/active/suspended/closed lifecycle states.
- `organization_memberships`, with organization-scoped roles.
- `audit_events`, with actor, organization, action, target, metadata, and timestamp fields.

RLS is enabled on all four tables. Client grants are deliberately narrow: authenticated users can read their own profile and memberships, read organizations where they are active members, and update only their own profile name. Clients cannot create or modify organizations, memberships, or audit records.

## Organization authorization

The database functions `is_organization_member(uuid)` and `has_organization_role(uuid, text[])` are SECURITY DEFINER helpers with an empty search path and restricted execute grants. They evaluate the authenticated user's membership and require the organization status to be `active`. Pending, suspended, and closed organizations do not grant tenant access.

Server-side application code should use `requireOrganizationRole` from `lib/auth/authorization.ts` before any organization-scoped privileged operation. It validates the organization ID, verifies the user with `auth.getUser()`, and asks the database helper to confirm the allowed role. Never trust a role, user ID, or organization ID supplied only by client-side state.

## Audit events

`writeAuditEvent` in `lib/audit/write-audit-event.ts` is server-only and uses the server-only `SUPABASE_SERVICE_ROLE_KEY`. The key must never use a `NEXT_PUBLIC_` prefix, be sent to the browser, or be committed to source control. The database intentionally has no client insert policy for audit events.

Configure `SUPABASE_SERVICE_ROLE_KEY` only in a trusted server environment before enabling server workflows that write audit events. Do not log passwords, tokens, session cookies, payment data, or other secrets in audit metadata.

## Automated verification

The pgTAP suite in `supabase/tests/step_5_access_control.test.sql` verifies RLS, grants, profile isolation, tenant isolation, role helper behavior, inactive-organization denial, and restricted writes. Run it with `supabase test db`.

The additive migration `20261118000200_enforce_active_organization_access.sql` is required for projects that have already applied the initial identity migration.
