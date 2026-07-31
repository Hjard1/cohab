-- Household-shared entitlement: if one partner in a household has paid
-- (formal_unlocked), the other partner must never hit the paywall.
--
-- Approach: a security definer helper checks whether two users share a
-- household, and a new SELECT policy on cohab_entitlements lets a household
-- member read their partner's row. The iOS app (PurchaseManager
-- .refreshServerEntitlement) reads all rows visible under RLS and grants
-- access when any of them is unlocked.
--
-- No write policy is added: inserts/updates still happen only via the
-- service role (edge functions).

create or replace function public.shares_household_with(p_user_id uuid)
returns boolean as $$
  select exists (
    select 1
    from household_members mine
    join household_members theirs
      on theirs.household_id = mine.household_id
    where mine.user_id   = auth.uid()
      and theirs.user_id = p_user_id
  );
$$ language sql security definer stable;

-- Existing policy "users can read own entitlement" already covers the own
-- row; policies are OR-ed, so this adds partner visibility within a shared
-- household.
create policy "entitlements: household partner read"
  on public.cohab_entitlements
  for select
  using (public.shares_household_with(user_id));
