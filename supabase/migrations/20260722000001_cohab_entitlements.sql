-- Cohab entitlements: who has unlocked the "formal" agreement type.
-- One row per user. formal_unlocked is set to true by:
--   * the stripe-webhook edge function after a web purchase (source 'stripe_web'),
--   * (future) a function verifying the App Store one-time purchase
--     com.hjard.cohab.formal (source 'app_store').
-- The iOS app and the mycohab web app read the row to gate the formal flow.
--
-- RLS: users can READ only their own row. No write policies => inserts and
-- updates happen only via the service role (edge functions, which bypass RLS).
create table if not exists public.cohab_entitlements (
  user_id            uuid primary key references auth.users(id) on delete cascade,
  formal_unlocked    boolean not null default false,
  source             text,
  stripe_session_id  text unique,
  created_at         timestamptz default now(),
  updated_at         timestamptz default now()
);

alter table public.cohab_entitlements enable row level security;

create policy "users can read own entitlement"
  on public.cohab_entitlements
  for select
  using (auth.uid() = user_id);
