-- Public course details may expose curriculum titles and structure,
-- but never lesson bodies, answer keys, or assessment content.

create or replace function private.get_public_course_lesson_title_preview(p_course_slug text)
returns table (
  course_title text,
  course_summary text,
  course_description text,
  difficulty text,
  estimated_minutes integer,
  access_type text,
  module_number integer,
  module_title text,
  module_goal text,
  lesson_number text,
  lesson_title text
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
    m.goal,
    l.lesson_number,
    l.title
  from public.courses as c
  join public.course_modules as m
    on m.course_id = c.id
   and m.status = 'published'
  join public.lessons as l
    on l.module_id = m.id
   and l.status = 'published'
  where c.slug = p_course_slug
    and c.status = 'published'
  order by m.display_order, m.module_number, l.display_order, l.lesson_number;
$function$;

revoke all on function private.get_public_course_lesson_title_preview(text) from public, anon, authenticated;
grant execute on function private.get_public_course_lesson_title_preview(text) to anon, authenticated;

create or replace function public.get_public_course_lesson_title_preview(p_course_slug text)
returns table (
  course_title text,
  course_summary text,
  course_description text,
  difficulty text,
  estimated_minutes integer,
  access_type text,
  module_number integer,
  module_title text,
  module_goal text,
  lesson_number text,
  lesson_title text
)
language sql
stable
security invoker
set search_path = ''
as $function$
  select * from private.get_public_course_lesson_title_preview(p_course_slug);
$function$;

revoke all on function public.get_public_course_lesson_title_preview(text) from public, anon, authenticated;
grant execute on function public.get_public_course_lesson_title_preview(text) to anon, authenticated;
