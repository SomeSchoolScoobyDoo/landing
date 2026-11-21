-- Step 9: safe public course previews before enrolment.
-- Expose only published curriculum metadata and a short excerpt from the first
-- published lesson. Full lesson content remains behind authenticated access.

create or replace function public.get_public_course_preview(p_course_slug text)
returns table (
  course_title text,
  course_summary text,
  course_description text,
  difficulty text,
  estimated_minutes integer,
  module_number integer,
  module_title text,
  module_goal text,
  lesson_number text,
  lesson_title text,
  lesson_minutes integer,
  sample_explanation text
)
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  with first_sample as (
    select l.id
    from public.courses c
    join public.course_modules m on m.course_id = c.id and m.status = 'published'
    join public.lessons l on l.module_id = m.id and l.status = 'published'
    where c.slug = p_course_slug and c.status = 'published'
      and nullif(l.content ->> 'simple_explanation', '') is not null
    order by m.display_order, m.module_number, l.display_order, l.lesson_number
    limit 1
  )
  select
    c.title,
    c.summary,
    c.description,
    c.difficulty,
    c.estimated_minutes,
    m.module_number,
    m.title,
    m.goal,
    l.lesson_number,
    l.title,
    l.estimated_minutes,
    case
      when l.id = (select id from first_sample)
      then left(coalesce(l.content ->> 'simple_explanation', ''), 1200)
      else null
    end
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
