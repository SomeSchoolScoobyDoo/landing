begin;
create extension if not exists pgtap with schema extensions;
select extensions.plan(4);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
(
  '90000000-0000-4000-8000-000000000028',
  'authenticated', 'authenticated', 'step11-learner@example.invalid', '',
  now(), '{}'::jsonb, '{"full_name":"Learner Profile Name"}'::jsonb, now(), now()
),
(
  '90000000-0000-4000-8000-000000000029',
  'authenticated', 'authenticated', 'step11-other@example.invalid', '',
  now(), '{}'::jsonb, '{"full_name":"Other Learner"}'::jsonb, now(), now()
);

select extensions.ok(
  exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles'
      and column_name = 'certificate_display_name'
  ),
  'profiles has a separate certificate display name field'
);

select extensions.ok(
  position('certificate_display_name' in pg_get_functiondef('private.issue_course_certificate_for_user(uuid,uuid,boolean)'::regprocedure)) > 0,
  'certificate issuance reads the learner-selected certificate display name'
);

select set_config('request.jwt.claim.sub', '90000000-0000-4000-8000-000000000028', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

update public.profiles
set certificate_display_name = 'Certificate Name'
where id = '90000000-0000-4000-8000-000000000028';

update public.profiles
set certificate_display_name = 'Attempted Other Name'
where id = '90000000-0000-4000-8000-000000000029';

reset role;

select extensions.ok(
  exists (
    select 1 from public.profiles
    where id = '90000000-0000-4000-8000-000000000028'
      and certificate_display_name = 'Certificate Name'
  ),
  'learners can update their own certificate display name'
);

select extensions.ok(
  exists (
    select 1 from public.profiles
    where id = '90000000-0000-4000-8000-000000000029'
      and certificate_display_name is null
  ),
  'learners cannot change another learner certificate display name'
);

select * from extensions.finish();
rollback;
