-- Step 5 access-control regression tests.
-- Run with: supabase test db
begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(29);

-- Schema and RLS are present on every protected table.
select extensions.has_table('public', 'profiles', 'profiles table exists');
select extensions.has_table('public', 'organizations', 'organizations table exists');
select extensions.has_table('public', 'organization_memberships', 'organization_memberships table exists');
select extensions.has_table('public', 'audit_events', 'audit_events table exists');

select extensions.ok(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  'profiles has row-level security enabled'
);
select extensions.ok(
  (select relrowsecurity from pg_class where oid = 'public.organizations'::regclass),
  'organizations has row-level security enabled'
);
select extensions.ok(
  (select relrowsecurity from pg_class where oid = 'public.organization_memberships'::regclass),
  'organization_memberships has row-level security enabled'
);
select extensions.ok(
  (select relrowsecurity from pg_class where oid = 'public.audit_events'::regclass),
  'audit_events has row-level security enabled'
);

-- Grants are deliberately narrower than table ownership.
select extensions.ok(has_table_privilege('authenticated', 'public.profiles', 'SELECT'),
  'authenticated users can select profiles subject to RLS');
select extensions.ok(has_column_privilege('authenticated', 'public.profiles', 'full_name', 'UPDATE'),
  'authenticated users can update the full_name column');
select extensions.ok(not has_column_privilege('authenticated', 'public.profiles', 'id', 'UPDATE'),
  'authenticated users cannot update profile identity');
select extensions.ok(not has_table_privilege('authenticated', 'public.organizations', 'INSERT'),
  'authenticated users cannot create organizations directly');
select extensions.ok(not has_table_privilege('authenticated', 'public.organization_memberships', 'INSERT'),
  'authenticated users cannot create memberships directly');
select extensions.ok(not has_table_privilege('authenticated', 'public.audit_events', 'INSERT'),
  'authenticated users cannot write audit events directly');
select extensions.ok(has_function_privilege('authenticated', 'public.is_organization_member(uuid)', 'EXECUTE'),
  'authenticated users can execute the membership-check helper');
select extensions.ok(not has_function_privilege('anon', 'public.is_organization_member(uuid)', 'EXECUTE'),
  'anonymous users cannot execute the membership-check helper');

-- Create two independent users and tenants. The transaction is rolled back below.
insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
(
  '10000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated',
  'rls-alice@example.test', '', now(), '{"provider":"email","providers":["email"]}',
  '{"full_name":"RLS Alice"}', now(), now()
),
(
  '10000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated',
  'rls-bob@example.test', '', now(), '{"provider":"email","providers":["email"]}',
  '{"full_name":"RLS Bob"}', now(), now()
)
on conflict (id) do nothing;

insert into public.organizations (id, name, organization_type, status) values
('20000000-0000-4000-8000-000000000001', 'Alice School', 'school', 'active'),
('20000000-0000-4000-8000-000000000002', 'Bob Corporation', 'corporation', 'active'),
('20000000-0000-4000-8000-000000000003', 'Alice Suspended School', 'school', 'suspended')
on conflict (id) do nothing;

insert into public.organization_memberships (id, organization_id, user_id, membership_role) values
(
  '30000000-0000-4000-8000-000000000001',
  '20000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000001',
  'school_admin'
),
(
  '30000000-0000-4000-8000-000000000002',
  '20000000-0000-4000-8000-000000000002',
  '10000000-0000-4000-8000-000000000002',
  'employee'
),
(
  '30000000-0000-4000-8000-000000000003',
  '20000000-0000-4000-8000-000000000003',
  '10000000-0000-4000-8000-000000000001',
  'school_admin'
)
on conflict (organization_id, user_id) do nothing;

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-4000-8000-000000000001', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);

select extensions.is(
  (select count(*) from public.profiles),
  1::bigint,
  'Alice can see only her own profile'
);
select extensions.is(
  (select count(*) from public.profiles where id = '10000000-0000-4000-8000-000000000002'),
  0::bigint,
  'Alice cannot read Bob profile'
);
select extensions.is(
  (select count(*) from public.organization_memberships),
  2::bigint,
  'Alice can see only her own memberships'
);
select extensions.is(
  (select count(*) from public.organizations),
  1::bigint,
  'Alice can see only the organization she belongs to'
);

select extensions.ok(
  public.is_organization_member('20000000-0000-4000-8000-000000000001'),
  'membership in an active organization grants tenant access'
);
select extensions.ok(
  public.has_organization_role(
    '20000000-0000-4000-8000-000000000001',
    array['school_admin']::text[]
  ),
  'the assigned school_admin role is recognised for an active organization'
);
select extensions.ok(
  not public.is_organization_member('20000000-0000-4000-8000-000000000003'),
  'membership in a suspended organization does not grant tenant access'
);
select extensions.ok(
  not public.has_organization_role(
    '20000000-0000-4000-8000-000000000003',
    array['school_admin']::text[]
  ),
  'privileged role in a suspended organization is not effective'
);

update public.profiles
set full_name = 'Alice Updated'
where id = '10000000-0000-4000-8000-000000000001';
select extensions.is(
  (select full_name from public.profiles where id = '10000000-0000-4000-8000-000000000001'),
  'Alice Updated',
  'Alice can update her own profile name'
);

-- RLS silently filters an UPDATE targeting another user's row.
-- Verify the stored value as the database owner after the authenticated update.
update public.profiles
set full_name = 'Unauthorized Change'
where id = '10000000-0000-4000-8000-000000000002';

reset role;
select extensions.is(
  (select full_name from public.profiles where id = '10000000-0000-4000-8000-000000000002'),
  'RLS Bob',
  'Alice cannot change Bob profile because RLS filters the target row'
);
set local role authenticated;

select extensions.throws_ok(
  $$insert into public.organizations (name, organization_type) values ('Unauthorized Org', 'school')$$,
  '42501',
  null,
  'Alice cannot insert an organization through the client role'
);
select extensions.throws_ok(
  $$insert into public.organization_memberships (organization_id, user_id, membership_role)
    values ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001', 'school_admin')$$,
  '42501',
  null,
  'Alice cannot grant herself an organization membership'
);
select extensions.throws_ok(
  $$insert into public.audit_events (actor_user_id, action)
    values ('10000000-0000-4000-8000-000000000001', 'forged.event')$$,
  '42501',
  null,
  'Alice cannot forge audit events'
);

reset role;
select * from extensions.finish();
rollback;
