-- The self-update RLS policy existed, but authenticated learners lacked
-- the underlying UPDATE privilege. Grant only the profile fields the UI edits.
grant update (full_name, certificate_display_name, updated_at)
on public.profiles to authenticated;
