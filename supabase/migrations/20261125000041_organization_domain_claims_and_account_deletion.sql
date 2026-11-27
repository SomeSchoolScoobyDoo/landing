-- Allow legitimate shared domains across separate organisation records,
-- while preventing duplicate active claims within the same organisation.
drop index if exists public.organization_domains_active_domain_uidx;
create unique index if not exists organization_domains_org_domain_active_uidx
  on public.organization_domains (organization_id, lower(domain))
  where verification_status <> 'revoked';

-- Verification records must not block a user's account deletion.
alter table public.organization_domains
  alter column created_by drop not null;
alter table public.organization_domains
  drop constraint if exists organization_domains_created_by_fkey;
alter table public.organization_domains
  add constraint organization_domains_created_by_fkey
  foreign key (created_by) references auth.users(id) on delete set null;

alter table public.organization_verification_requests
  alter column applicant_user_id drop not null;
alter table public.organization_verification_requests
  drop constraint if exists organization_verification_requests_applicant_user_id_fkey;
alter table public.organization_verification_requests
  add constraint organization_verification_requests_applicant_user_id_fkey
  foreign key (applicant_user_id) references auth.users(id) on delete set null;
