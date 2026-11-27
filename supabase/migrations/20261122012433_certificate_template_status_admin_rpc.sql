
begin;
create or replace function private.get_certificate_template_status()
returns table(version text, is_active boolean, signature_asset_path text)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or not private.is_academy_admin() then
    raise exception 'Academy administrator access required' using errcode = '42501';
  end if;
  return query
    select t.version, t.is_active, t.signature_asset_path
    from private.certificate_templates t
    order by t.created_at desc;
end;
$$;
revoke all on function private.get_certificate_template_status() from public, anon;
grant execute on function private.get_certificate_template_status() to authenticated;

create or replace function public.get_certificate_template_status()
returns table(version text, is_active boolean, signature_asset_path text)
language sql
stable
security invoker
set search_path = ''
as $$
  select * from private.get_certificate_template_status();
$$;
revoke all on function public.get_certificate_template_status() from public, anon;
grant execute on function public.get_certificate_template_status() to authenticated;
commit;
