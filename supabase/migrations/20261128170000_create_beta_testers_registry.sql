create table public.beta_testers (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (char_length(btrim(full_name)) between 2 and 120),
  contact_email text,
  tester_status text not null default 'active' check (tester_status in ('active','completed','withdrawn')),
  certificate_status text not null default 'pending_launch' check (certificate_status in ('pending_launch','eligible','issued','withheld')),
  certificate_number text unique,
  certificate_issued_at timestamptz,
  notes text not null default '',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint beta_testers_email_length check (contact_email is null or char_length(contact_email) <= 254),
  constraint beta_testers_certificate_consistency check (
    (certificate_status = 'issued' and certificate_number is not null and certificate_issued_at is not null)
    or certificate_status <> 'issued'
  )
);

create unique index beta_testers_full_name_lower_uidx on public.beta_testers (lower(btrim(full_name)));

alter table public.beta_testers enable row level security;

create policy "Academy admins can view beta testers"
on public.beta_testers for select to authenticated
using (public.is_academy_admin());

create policy "Academy admins can add beta testers"
on public.beta_testers for insert to authenticated
with check (public.is_academy_admin());

create policy "Academy admins can update beta testers"
on public.beta_testers for update to authenticated
using (public.is_academy_admin())
with check (public.is_academy_admin());

grant select, insert, update on public.beta_testers to authenticated;

insert into public.beta_testers (full_name, tester_status, certificate_status, notes)
values ('Rachael Ogunowo', 'active', 'pending_launch', 'Confirmed Kaizora AI Academy tester. Issue beta tester recognition certificate after public launch.')
on conflict (lower(btrim(full_name))) do update
set tester_status = excluded.tester_status,
    certificate_status = case
      when public.beta_testers.certificate_status = 'issued' then public.beta_testers.certificate_status
      else excluded.certificate_status
    end,
    notes = excluded.notes,
    updated_at = now();
