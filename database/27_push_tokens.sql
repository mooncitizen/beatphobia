-- push tokens for APNs; allow multiple devices per user
-- Run after core schema setup

begin;

-- Required for gen_random_uuid()
create extension if not exists pgcrypto with schema public;

create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios')),
  device_id text not null,
  app_version text,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique(token)
);

alter table public.push_tokens enable row level security;

-- Users can see only their tokens
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'push_tokens' and policyname = 'select_own_tokens'
  ) then
    create policy select_own_tokens on public.push_tokens
      for select using (user_id = auth.uid());
  end if;
end$$;

-- Users can insert tokens for themselves
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'push_tokens' and policyname = 'insert_own_tokens'
  ) then
    create policy insert_own_tokens on public.push_tokens
      for insert to authenticated with check (user_id = auth.uid());
  end if;
end$$;

-- Users can update their own token rows (to refresh last_seen_at/app_version/device_id)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'push_tokens' and policyname = 'update_own_tokens'
  ) then
    create policy update_own_tokens on public.push_tokens
      for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
  end if;
end$$;

-- Users can delete their own tokens (e.g., logout)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'push_tokens' and policyname = 'delete_own_tokens'
  ) then
    create policy delete_own_tokens on public.push_tokens
      for delete to authenticated using (user_id = auth.uid());
  end if;
end$$;

-- Helper function to upsert by token safely under RLS
create or replace function public.register_push_token(
  p_token text,
  p_device_id text,
  p_platform text default 'ios',
  p_app_version text default null
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  -- Require authenticated user
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Must be authenticated';
  end if;

  insert into public.push_tokens (user_id, token, platform, device_id, app_version)
  values (v_user_id, p_token, p_platform, p_device_id, p_app_version)
  on conflict (token)
  do update set
    user_id = excluded.user_id,
    platform = excluded.platform,
    device_id = excluded.device_id,
    app_version = excluded.app_version,
    last_seen_at = now();
end;
$$;

revoke all on function public.register_push_token(text, text, text, text) from public;
grant execute on function public.register_push_token(text, text, text, text) to authenticated;

commit;


