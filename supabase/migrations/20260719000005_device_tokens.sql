-- APNs device tokens, one row per device per user. Written by the app after
-- the user grants notification permission; read by the notify-partner edge
-- function (service role) to push partner-activity notifications.
create table if not exists public.device_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  token       text not null unique,
  language    text not null default 'nb',
  platform    text not null default 'ios',
  updated_at  timestamptz not null default now()
);

alter table public.device_tokens enable row level security;

-- Users manage only their own tokens.
create policy device_tokens_owner on public.device_tokens
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
