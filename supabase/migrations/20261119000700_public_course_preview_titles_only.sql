-- Step 9 follow-up: restrict anonymous course previews to course metadata
-- and published module/lesson titles only.
-- Migration 006 has already been applied in development, so replace its RPC
-- in a new migration rather than rewriting applied migration history.

drop function if exists public.get_public_course_preview(text);

create function public.get_public_course_preview(p_course_slug text)
returns table (
  course_title text,
  course_summary text,
  course_description text,
  difficulty text,
  estimated_minutes integer,
  module_number integer,
  module_title text,
  lesson_number text,
  lesson_title text
)
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select
    c.title,
    c.summary,
    c.description,
    c.difficulty,
    c.estimated_minutes,
    m.module_number,
    m.title,
    l.lesson_number,
    l.title
  from public.courses c
  join public.course_modules m
    on m.course_id = c.id and m.status = 'published'
  left join public.lessons l
    on l.module_id = m.id and l.status = 'published'
  where c.slug = p_course_slug
    and c.status = 'published'
  order by m.display_order, m.module_number,
           l.display_order nulls last, l.lesson_number nulls last;
$$;

revoke all on function public.get_public_course_preview(text) from public, anon;
grant execute on function public.get_public_course_preview(text) to anon, authenticated;
