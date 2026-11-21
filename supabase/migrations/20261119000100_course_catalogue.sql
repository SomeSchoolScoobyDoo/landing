-- Step 6: published course catalogue foundation.
-- Course content (lessons, videos, assessments and learner progress) is added in later steps.
-- Course records are provisioned by trusted server-side workflows, never by public clients.

create table if not exists public.course_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text not null default '',
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint course_categories_slug_format check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  constraint course_categories_name_length check (char_length(trim(name)) between 2 and 100),
  constraint course_categories_description_length check (char_length(description) <= 500)
);

create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.course_categories(id) on delete restrict,
  slug text not null unique,
  title text not null,
  summary text not null default '',
  description text not null default '',
  difficulty text not null default 'all_levels'
    check (difficulty in ('beginner', 'intermediate', 'advanced', 'all_levels')),
  estimated_minutes integer not null default 0 check (estimated_minutes >= 0),
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  display_order integer not null default 0,
  content_version integer not null default 1 check (content_version > 0),
  source_reference text,
  source_metadata jsonb not null default '{}'::jsonb
    check (jsonb_typeof(source_metadata) = 'object'),
  created_by uuid references auth.users(id) on delete set null,
  updated_by uuid references auth.users(id) on delete set null,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint courses_slug_format check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  constraint courses_title_length check (char_length(trim(title)) between 2 and 180),
  constraint courses_summary_length check (char_length(summary) <= 500),
  constraint courses_description_length check (char_length(description) <= 12000),
  constraint courses_source_reference_length check (source_reference is null or char_length(source_reference) <= 500)
);

create index if not exists courses_published_catalogue_idx
  on public.courses (category_id, display_order, title)
  where status = 'published';
create index if not exists courses_status_updated_idx
  on public.courses (status, updated_at desc);
create index if not exists course_categories_display_order_idx
  on public.course_categories (display_order, name);

drop trigger if exists course_categories_set_updated_at on public.course_categories;
create trigger course_categories_set_updated_at
before update on public.course_categories
for each row execute function public.set_updated_at();

drop trigger if exists courses_set_updated_at on public.courses;
create trigger courses_set_updated_at
before update on public.courses
for each row execute function public.set_updated_at();

alter table public.course_categories enable row level security;
alter table public.courses enable row level security;

revoke all on public.course_categories from anon, authenticated;
revoke all on public.courses from anon, authenticated;
grant select on public.course_categories to anon, authenticated;
grant select on public.courses to anon, authenticated;
grant all on public.course_categories to service_role;
grant all on public.courses to service_role;

drop policy if exists "Public can view categories with published courses" on public.course_categories;
create policy "Public can view categories with published courses"
on public.course_categories
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.courses
    where courses.category_id = course_categories.id
      and courses.status = 'published'
  )
);

drop policy if exists "Public can view published courses" on public.courses;
create policy "Public can view published courses"
on public.courses
for select
to anon, authenticated
using (status = 'published');

-- There are intentionally no client write policies. Draft creation, updates,
-- archiving and publication happen through trusted server-side workflows.
