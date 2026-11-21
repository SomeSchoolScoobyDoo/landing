-- Step 7: lesson delivery, learner progress, and private learning resources.
-- Course content is stored as structured JSON so the agreed Claude lesson schema can
-- be mapped without flattening or inventing a competing lesson format.

create table if not exists public.course_modules (
  id uuid primary key default gen_random_uuid(),
  course_id uuid not null references public.courses(id) on delete cascade,
  module_number integer not null check (module_number > 0),
  title text not null,
  goal text not null default '',
  display_order integer not null default 0,
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (course_id, module_number),
  constraint course_modules_title_length check (char_length(trim(title)) between 2 and 180),
  constraint course_modules_goal_length check (char_length(goal) <= 2000)
);

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  module_id uuid not null references public.course_modules(id) on delete cascade,
  lesson_number text not null,
  title text not null,
  estimated_minutes integer not null default 15 check (estimated_minutes between 1 and 600),
  youtube_url text,
  content jsonb not null default '{}'::jsonb check (jsonb_typeof(content) = 'object'),
  display_order integer not null default 0,
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (module_id, lesson_number),
  constraint lessons_number_length check (char_length(lesson_number) between 1 and 20),
  constraint lessons_title_length check (char_length(trim(title)) between 2 and 180),
  constraint lessons_youtube_url_format check (
    youtube_url is null or youtube_url ~ '^https://(www\.)?(youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)'
  ),
  constraint lessons_content_excludes_assessment_answers check (not (content ? 'lesson_quiz'))
);

create table if not exists public.lesson_resources (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  title text not null,
  description text not null default '',
  storage_path text not null unique,
  mime_type text,
  file_size_bytes bigint check (file_size_bytes is null or file_size_bytes >= 0),
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  constraint lesson_resources_title_length check (char_length(trim(title)) between 1 and 180),
  constraint lesson_resources_path_length check (char_length(storage_path) between 1 and 500)
);

create table if not exists public.lesson_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  completed_at timestamptz,
  last_position_seconds integer not null default 0 check (last_position_seconds >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, lesson_id)
);

create index if not exists course_modules_course_order_idx
  on public.course_modules(course_id, display_order, module_number);
create index if not exists lessons_module_order_idx
  on public.lessons(module_id, display_order, lesson_number);
create index if not exists lesson_resources_lesson_order_idx
  on public.lesson_resources(lesson_id, display_order);
create index if not exists lesson_progress_user_updated_idx
  on public.lesson_progress(user_id, updated_at desc);
create index if not exists lesson_progress_lesson_idx
  on public.lesson_progress(lesson_id);

drop trigger if exists course_modules_set_updated_at on public.course_modules;
create trigger course_modules_set_updated_at before update on public.course_modules
for each row execute function public.set_updated_at();
drop trigger if exists lessons_set_updated_at on public.lessons;
create trigger lessons_set_updated_at before update on public.lessons
for each row execute function public.set_updated_at();
drop trigger if exists lesson_progress_set_updated_at on public.lesson_progress;
create trigger lesson_progress_set_updated_at before update on public.lesson_progress
for each row execute function public.set_updated_at();

alter table public.course_modules enable row level security;
alter table public.lessons enable row level security;
alter table public.lesson_resources enable row level security;
alter table public.lesson_progress enable row level security;

revoke all on public.course_modules, public.lessons, public.lesson_resources, public.lesson_progress from anon, authenticated;
grant select on public.course_modules, public.lessons, public.lesson_resources to authenticated;
grant select, insert, update on public.lesson_progress to authenticated;
grant all on public.course_modules, public.lessons, public.lesson_resources, public.lesson_progress to service_role;

drop policy if exists "Learners can view modules in published courses" on public.course_modules;
create policy "Learners can view modules in published courses"
on public.course_modules for select to authenticated
using (
  status = 'published' and exists (
    select 1 from public.courses c
    where c.id = course_modules.course_id and c.status = 'published'
  )
);

drop policy if exists "Learners can view lessons in published courses" on public.lessons;
create policy "Learners can view lessons in published courses"
on public.lessons for select to authenticated
using (
  status = 'published' and exists (
    select 1
    from public.course_modules m
    join public.courses c on c.id = m.course_id
    where m.id = lessons.module_id
      and m.status = 'published'
      and c.status = 'published'
  )
);

drop policy if exists "Learners can view resources for published lessons" on public.lesson_resources;
create policy "Learners can view resources for published lessons"
on public.lesson_resources for select to authenticated
using (
  exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = m.course_id
    where l.id = lesson_resources.lesson_id
      and l.status = 'published'
      and m.status = 'published'
      and c.status = 'published'
  )
);

drop policy if exists "Learners can read their own lesson progress" on public.lesson_progress;
create policy "Learners can read their own lesson progress"
on public.lesson_progress for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Learners can create their own lesson progress" on public.lesson_progress;
create policy "Learners can create their own lesson progress"
on public.lesson_progress for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = m.course_id
    where l.id = lesson_progress.lesson_id
      and l.status = 'published'
      and m.status = 'published'
      and c.status = 'published'
  )
);

drop policy if exists "Learners can update their own lesson progress" on public.lesson_progress;
create policy "Learners can update their own lesson progress"
on public.lesson_progress for update to authenticated
using ((select auth.uid()) = user_id)
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1
    from public.lessons l
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = m.course_id
    where l.id = lesson_progress.lesson_id
      and l.status = 'published'
      and m.status = 'published'
      and c.status = 'published'
  )
);

-- Private bucket. Authenticated downloads are allowed only when the object path
-- is registered to a published lesson in a published course.
insert into storage.buckets (id, name, public, file_size_limit)
values ('kaizora-learning-resources', 'kaizora-learning-resources', false, 52428800)
on conflict (id) do update set public = false, file_size_limit = 52428800;

drop policy if exists "Learners can download published lesson resources" on storage.objects;
create policy "Learners can download published lesson resources"
on storage.objects for select to authenticated
using (
  bucket_id = 'kaizora-learning-resources'
  and exists (
    select 1
    from public.lesson_resources r
    join public.lessons l on l.id = r.lesson_id
    join public.course_modules m on m.id = l.module_id
    join public.courses c on c.id = m.course_id
    where r.storage_path = storage.objects.name
      and l.status = 'published'
      and m.status = 'published'
      and c.status = 'published'
  )
);
