-- Subscription support for cohab_entitlements.
-- The table originally tracked the one-time "formal" unlock. With the move
-- to a yearly subscription (App Store product com.hjard.cohab.premium.yearly
-- and a recurring Stripe price on web) rows need a validity window.
--
--   * product_id             — what granted access (app store id, 'stripe_yearly', ...)
--   * expires_at             — end of the current paid period. NULL = never
--                              expires, which covers all existing one-time
--                              buyers (grandfathered lifetime access).
--   * status                 — 'active' / 'canceled' / 'expired' (informational;
--                              access checks rely on formal_unlocked + expires_at).
--   * stripe_subscription_id — lets subscription lifecycle webhooks find the row.
--
-- Access rule used by the app and web: formal_unlocked = true AND
-- (expires_at IS NULL OR expires_at > now()).

alter table public.cohab_entitlements
  add column if not exists product_id text,
  add column if not exists expires_at timestamptz,
  add column if not exists status text default 'active',
  add column if not exists stripe_subscription_id text unique;

-- Existing rows are one-time buyers: status stays 'active', expires_at stays
-- null (lifetime). Nothing to backfill.
