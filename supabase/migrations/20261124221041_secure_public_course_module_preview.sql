-- Let anonymous visitors read only module metadata for published courses.
-- Lesson rows and lesson content remain inaccessible to anonymous visitors.

grant select on public.course_modules to anon;

drop policy if exists "Public can view modules in published courses" on public.course_modules;
create policy "Public can view modules in published courses"
on public.course_modules
for select
to anon
using (
  status = 'published'
  and exists (
    select 1
    from public.courses as c
    where c.id = course_modules.course_id
      and c.status = 'published'
  )
);

-- The private helper now runs as the caller so the module RLS policy applies.
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
security invoker
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
grant execute on function private.get_public_course_module_preview(text) to anon, authenticated;
