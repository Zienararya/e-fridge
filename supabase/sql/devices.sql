-- Devices table to store push tokens per user
create table if not exists public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android','ios','web')),
  created_at timestamptz not null default now()
);

alter table public.devices enable row level security;

-- Policies: user manages own devices
create policy if not exists "insert own device" on public.devices
for insert with check (auth.uid() = user_id or user_id is null);

create policy if not exists "select own device" on public.devices
for select using (auth.uid() = user_id or user_id is null);

create policy if not exists "delete own device" on public.devices
for delete using (auth.uid() = user_id or user_id is null);
