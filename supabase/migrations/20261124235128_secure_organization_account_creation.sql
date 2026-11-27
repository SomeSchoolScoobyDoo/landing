-- Secure organisation-account creation and visibility for pending applicants.

create or replace function public.create_organization_account(
  p_name text,
  p_organization_type text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := (select auth.uid());
  v_organization_id uuid;
  v_role text;
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if p_name is null or char_length(btrim(p_name)) < 2 or char_length(btrim(p_name)) > 160 then
    raise exception 'Organisation name must be between 2 and 160 characters' using errcode = '22023';
  end if;

  if p_organization_type not in ('school', 'corporation') then
    raise exception 'Unsupported organisation type' using errcode = '22023';
  end if;

  v_role := case
    when p_organization_type = 'school' then 'school_admin'
    else 'corporate_admin'
  end;

  insert into public.organizations (
    name,
    organization_type,
    status,
    verification_status
  )
  values (
    btrim(p_name),
    p_organization_type,
    'pending',
    'unverified'
  )
  returning id into v_organization_id;

  insert into public.organization_memberships (
    organization_id,
    user_id,
    membership_role
  )
  values (
    v_organization_id,
    v_user_id,
    v_role
  );

  return v_organization_id;
end;
$function$;

revoke all on function public.create_organization_account(text, text) from public, anon;
grant execute on function public.create_organization_account(text, text) to authenticated;

drop policy if exists "Members can read their organizations" on public.organizations;
create policy "Users can read organisations they belong to"
  on public.organizations
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.organization_memberships as membership
      where membership.organization_id = organizations.id
        and membership.user_id = (select auth.uid())
    )
  );
