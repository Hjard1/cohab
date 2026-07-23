-- Secure cohab_household_credits.
-- Previously: no RLS, and cohab_add_bankid_credit was executable by anyone
-- with the anon key — i.e. anyone could grant themselves free BankID credits.
--
-- After this migration:
--   * RLS is enabled; household members can READ their own credits (the app
--     reads the table directly, this keeps working for signed-in users).
--   * No write policies => inserts/updates only via the service role
--     (edge functions such as dealbuilder-submit, which bypasses RLS).
--   * cohab_add_bankid_credit is revoked from anon/authenticated and granted
--     to service_role only.
--
-- NOTE: the iOS app currently calls cohab_add_bankid_credit directly with
-- the user JWT after a StoreKit purchase (DealBuilderService.addExtraCredit).
-- That call will fail once this is applied — the app must be updated to call
-- a secured edge function that verifies the purchase before adding credits.

alter table public.cohab_household_credits enable row level security;

create policy "household members can read own credits"
  on public.cohab_household_credits
  for select
  using (public.is_household_member(household_id::uuid));

revoke execute on function public.cohab_add_bankid_credit(text) from public, anon, authenticated;
grant execute on function public.cohab_add_bankid_credit(text) to service_role;
