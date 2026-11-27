-- Organisation verification foundation.
-- This migration is intentionally additive. Application workflows and enforcement
-- must be implemented and tested before verification is enabled in production.

alter table public.organizations
  add column if not exists verification_status text not null default 'unverified',
  add column if not exists verified_at timestamptz,
  add column if not exists verification_method text;

alter table public.organizations
  drop constraint if exists organizations_verification_status_check;
alter table public.organizations
  add constraint organizations_verification_status_check
  check (verification_status in ('unverified', 'pending', 'verified', 'rejected', 'suspended'));

alter table public.organizations
  drop constraint if exists organizations_verification_method_check;
alter table public.organizations
  add constraint organizations_verification_method_check
  check (
    verification_method is null
    or verification_method in ('dns_txt', 'manual_call', 'manual_documents')
  );

create table if not exists public.organization_domains (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  domain text not null check (
    char_length(domain) between 3 and 253
    and domain = lower(btrim(domain))
    and domain !~ '[/@:[:space:]]'
  ),
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'revoked', 'failed')),
  verification_method text not null default 'dns_txt'
    check (verification_method = 'dns_txt'),
  challenge_token text not null,
  created_by uuid not null references auth.users(id) on delete restrict,
  verified_at timestamptz,
  last_checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists organization_domains_active_domain_uidx
  on public.organization_domains (lower(domain))
  where verification_status <> 'revoked';

create index if not exists organization_domains_organization_status_idx
  on public.organization_domains (organization_id, verification_status);

create table if not exists public.organization_verification_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  applicant_user_id uuid not null references auth.users(id) on delete restrict,
  method text not null check (method in ('call', 'documents')),
  status text not null default 'pending'
    check (status in ('pending', 'scheduled', 'under_review', 'needs_information', 'verified', 'rejected', 'cancelled')),
  contact_name text not null check (char_length(btrim(contact_name)) between 2 and 120),
  applicant_position text not null check (char_length(btrim(applicant_position)) between 2 and 120),
  operating_address text not null check (char_length(btrim(operating_address)) between 5 and 500),
  reason text not null check (char_length(btrim(reason)) between 10 and 2000),
  supporting_document_paths text[] not null default '{}'
    check (cardinality(supporting_document_paths) <= 10),
  requested_call_at timestamptz,
  scheduled_call_at timestamptz,
  reviewer_user_id uuid references auth.users(id) on delete set null,
  reviewer_notes text,
  decision_reason text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organization_verification_call_schedule_check
    check (method = 'call' or (requested_call_at is null and scheduled_call_at is null)),
  constraint organization_verification_reviewer_separation_check
    check (reviewer_user_id is null or reviewer_user_id <> applicant_user_id)
);

create index if not exists organization_verification_requests_org_status_idx
  on public.organization_verification_requests (organization_id, status, submitted_at desc);

create index if not exists organization_verification_requests_applicant_idx
  on public.organization_verification_requests (applicant_user_id, submitted_at desc);

create index if not exists organization_verification_requests_reviewer_idx
  on public.organization_verification_requests (reviewer_user_id, status)
  where reviewer_user_id is not null;

create table if not exists public.organization_verification_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  request_id uuid references public.organization_verification_requests(id) on delete set null,
  actor_user_id uuid references auth.users(id) on delete set null,
  event_type text not null check (char_length(event_type) between 1 and 100),
  from_status text,
  to_status text,
  details jsonb not null default '{}'::jsonb
    check (jsonb_typeof(details) = 'object'),
  created_at timestamptz not null default now()
);

create index if not exists organization_verification_events_org_created_idx
  on public.organization_verification_events (organization_id, created_at desc);

alter table public.organization_domains enable row level security;
alter table public.organization_verification_requests enable row level security;
alter table public.organization_verification_events enable row level security;

-- Verification challenges, submitted evidence, reviewer notes and event history
-- are private server-managed data. Do not expose them through the Data API.
revoke all on public.organization_domains from anon, authenticated;
revoke all on public.organization_verification_requests from anon, authenticated;
revoke all on public.organization_verification_events from anon, authenticated;

grant all on public.organization_domains to service_role;
grant all on public.organization_verification_requests to service_role;
grant all on public.organization_verification_events to service_role;
