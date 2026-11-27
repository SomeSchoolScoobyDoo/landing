# Step 4: Authentication and account security

## Implemented in this application milestone
- Supabase SSR browser/server clients and session-refresh middleware.
- Individual learner sign-up with name metadata and email-confirmation redirect.
- Password sign-in and sign-out.
- Password-reset email flow and authenticated password update.
- Server-side dashboard session validation using auth.getUser().
- Generic sign-in and reset messages to reduce account enumeration.
- Server-side validation and a 12-character minimum password policy in the app.
- Supabase URL and publishable/anon key placeholders only; no service-role key.

## Required Supabase dashboard configuration before live testing
1. Authentication > URL Configuration: set Site URL to the deployed preview URL (or localhost for local development).
2. Add allowed Redirect URLs for the exact preview URL and http://localhost:3000/auth/callback during local testing.
3. Authentication > Providers > Email: keep the email provider enabled and require email confirmation.
4. Configure a production SMTP provider before public launch; default email sending is for testing and is rate-limited.
5. Set the Supabase password policy consistently with the app and review abuse/rate limits.

## Not yet complete
- Real environment variables are not configured in Vercel or local .env.local.
- The owner must add the public project URL and publishable/anon key through secure deployment settings, never in chat or Git.
- Account deletion requires an agreed retention policy and a server-only admin operation; it is not implemented in this milestone.
- MFA for privileged roles, session revocation controls, abuse rate limits beyond Supabase defaults, role assignment and RLS policies require later schema/authorization work.
- Automated integration and end-to-end tests are pending.

## Security notes
- The app uses auth.getUser() for server-side identity validation, not getSession() as an authorization decision.
- Authorization must be enforced by database RLS and server-side checks in later milestones; hiding UI is not access control.
- Never place a service-role key in NEXT_PUBLIC_*, browser code, Git, or client-side environment variables.
