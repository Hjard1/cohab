-- Extra BankID signing credits per household.
-- Included: 1 BankID signing per household, ever (tracked via
-- cohab_dealbuilder_cases). Every further signing consumes one credit.
-- Credits are purchased as a consumable in-app purchase (125 NOK) and
-- added via the cohab_add_bankid_credit RPC.
create table if not exists cohab_household_credits (
  household_id          text primary key,
  bankid_extra_credits  int  not null default 0,
  updated_at            timestamptz default now()
);

-- Atomic increment, called from the app after a verified StoreKit purchase.
create or replace function cohab_add_bankid_credit(p_household_id text)
returns void
language sql
as $$
  insert into cohab_household_credits (household_id, bankid_extra_credits)
  values (p_household_id, 1)
  on conflict (household_id)
  do update set bankid_extra_credits = cohab_household_credits.bankid_extra_credits + 1,
                updated_at = now();
$$;
