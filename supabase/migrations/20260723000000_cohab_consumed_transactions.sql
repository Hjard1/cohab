-- Consumed App Store transactions for consumable in-app purchases.
-- The add-bankid-credit edge function inserts the StoreKit transactionId here
-- BEFORE granting a credit: the primary key makes the operation idempotent,
-- so a retried/replayed purchase of the same transaction can never yield two
-- credits.
--
-- RLS: enabled, no policies => no direct client access at all. Only the
-- service role (edge functions, which bypass RLS) reads and writes this table.
create table if not exists public.cohab_consumed_transactions (
  transaction_id  text primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  product_id      text not null,
  created_at      timestamptz default now()
);

alter table public.cohab_consumed_transactions enable row level security;
