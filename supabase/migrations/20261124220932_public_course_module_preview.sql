-- Public course previews expose module-level outcomes, not lesson topics.
-- Pricing remains unconfigured until an owner assigns each course as free or paid.

alter table public.courses
  add column if not exists access_type text not null default 'unconfigured'
  check (access_type in ('free', 'paid', 'unconfigured'));

create or replace function private.get_public_course_module_preview(p_course_slug text)
returns table (
  course_title text,
  course_summary text,
  course_description text,
  difficulty text,
  estimated_minutes integer,
  access_type text,
  module_number integer,
  module_title text,
  module_goal text
)
language sql
stable
security definer
set search_path = ''
as $function$
  select
    c.title,
    c.summary,
    c.description,
    c.difficulty,
    c.estimated_minutes,
    c.access_type,
    m.module_number,
    m.title,
    m.goal
  from public.courses as c
  join public.course_modules as m
    on m.course_id = c.id
   and m.status = 'published'
  where c.slug = p_course_slug
    and c.status = 'published'
  order by m.display_order, m.module_number;
$function$;

revoke all on function private.get_public_course_module_preview(text) from public, anon, authenticated;
grant usage on schema private to anon, authenticated;
grant execute on function private.get_public_course_module_preview(text) to anon, authenticated;

create or replace function public.get_public_course_module_preview(p_course_slug text)
returns table (
  course_title text,
  course_summary text,
  course_description text,
  difficulty text,
  estimated_minutes integer,
  access_type text,
  module_number integer,
  module_title text,
  module_goal text
)
language sql
stable
security invoker
set search_path = ''
as $function$
  select * from private.get_public_course_module_preview(p_course_slug);
$function$;

revoke all on function public.get_public_course_module_preview(text) from public, anon, authenticated;
grant execute on function public.get_public_course_module_preview(text) to anon, authenticated;

-- The previous RPC returned every published lesson title. Remove public access
-- so lesson-level structure stays inside the authenticated learner experience.
revoke all on function public.get_public_course_preview(text) from public, anon, authenticated;
