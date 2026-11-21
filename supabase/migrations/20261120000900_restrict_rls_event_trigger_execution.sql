-- Some Supabase environments install this event-trigger handler at the platform
-- level, while clean local/CI databases do not. Revoke direct API execution only
-- when the function exists; PostgreSQL's event-trigger mechanism remains intact.
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    execute 'revoke execute on function public.rls_auto_enable() from public, anon, authenticated';
  end if;
end;
$$;
