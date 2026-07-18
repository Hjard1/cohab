-- ============================================================
-- Cohab — Core Schema
-- ============================================================
-- Design principles:
--   • All enum-like values stored as English text keys ("home", "a", "formal")
--     — frontend maps to display strings in the correct language
--   • Contract text is generated client-side from live data; never stored
--   • Settlement calculations are pure math; never persisted
--   • Amounts stored as float for v1 — migrate to numeric(15,2) before scale
-- ============================================================

-- ── 1. profiles ─────────────────────────────────────────────
-- One row per authenticated user. Mirrors auth.users for app queries.

create table if not exists profiles (
  user_id      uuid primary key references auth.users on delete cascade,
  display_name text not null default '',
  email        text not null default '',
  created_at   timestamptz not null default now()
);

-- Auto-populate from Google / email sign-up metadata
create or replace function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (user_id, display_name, email)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'name',
      split_part(new.email, '@', 1)
    ),
    coalesce(new.email, '')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();


-- ── 2. households ───────────────────────────────────────────
-- The shared unit. Partner A creates it; Partner B joins via invite token.
-- Names are stored on the household so they can be set before Partner B
-- has an account (onboarding captures both names up front).

create table if not exists households (
  id                   uuid primary key default gen_random_uuid(),
  partner_a_label      text not null default '',   -- display name for role "a"
  partner_b_label      text not null default '',   -- display name for role "b"
  currency             text not null default 'GBP',
  country              text not null default 'GB',
  annual_interest_rate float not null default 0.05,
  setup_mode           text not null default 'memory'
                         check (setup_mode in ('formal', 'memory')),
  relationship_type    text not null default 'couple'
                         check (relationship_type in ('couple', 'housemates', 'business')),
  agreement_status     text not null default 'none'
                         check (agreement_status in ('none', 'pending', 'signed')),
  signed_at            timestamptz,
  -- Snapshot counters — detect if data changed since last signing
  signed_asset_count   int not null default 0,
  signed_contrib_count int not null default 0,
  -- DocuSeal state
  docuseal_slug        text not null default '',
  docuseal_view_url    text not null default '',
  -- Signing emails (may differ from profile emails)
  email_a              text not null default '',
  email_b              text not null default '',
  created_at           timestamptz not null default now()
);


-- ── 3. household_members ────────────────────────────────────
-- Max 2 rows per household (role 'a' and 'b').
-- A user may belong to multiple households (edge case, not restricted).

create table if not exists household_members (
  household_id uuid not null references households on delete cascade,
  user_id      uuid not null references profiles  on delete cascade,
  role         text not null check (role in ('a', 'b')),
  joined_at    timestamptz not null default now(),
  primary key (household_id, user_id),
  -- Enforce unique role per household
  unique (household_id, role)
);

create index idx_hm_user on household_members(user_id);


-- ── 4. assets ───────────────────────────────────────────────
-- Shared property, vehicles, savings accounts, etc.
-- asset_type values: "home" | "car" | "cabin" | "investment" | "savings" | "other"

create table if not exists assets (
  id                  uuid primary key default gen_random_uuid(),
  household_id        uuid not null references households on delete cascade,
  asset_type          text not null default 'home',
  label               text not null default '',
  address             text not null default '',
  current_value       float not null default 0,
  remaining_loan      float not null default 0,
  sales_cost_fraction float not null default 0.02,
  ownership_share_a   float not null default 0.5
                        check (ownership_share_a >= 0 and ownership_share_a <= 1),
  purchase_date       date not null default current_date,
  created_at          timestamptz not null default now()
);

create index idx_assets_household on assets(household_id);


-- ── 5. contributions ────────────────────────────────────────
-- Equity contributions to a specific asset.
-- category values: "deposit" | "down_payment" | "extra_payment" |
--                  "renovation" | "maintenance" | "inheritance" | "other"
-- owner_key "a" or "b" — resolves to partner A or B of the household

create table if not exists contributions (
  id         uuid primary key default gen_random_uuid(),
  asset_id   uuid not null references assets on delete cascade,
  owner_key  text not null check (owner_key in ('a', 'b')),
  amount     float not null check (amount > 0),
  date       date not null default current_date,
  label      text not null default '',
  category   text not null default 'other',
  created_at timestamptz not null default now()
);

create index idx_contributions_asset on contributions(asset_id);


-- ── 6. shared_expenses ──────────────────────────────────────
-- Running costs both partners share (utilities, insurance, etc.).
-- split_ratio_a = fraction partner A pays (0.5 = 50/50).

create table if not exists shared_expenses (
  id            uuid primary key default gen_random_uuid(),
  household_id  uuid not null references households on delete cascade,
  label         text not null default '',
  amount        float not null check (amount > 0),
  paid_by_key   text not null check (paid_by_key in ('a', 'b')),
  split_ratio_a float not null default 0.5
                  check (split_ratio_a >= 0 and split_ratio_a <= 1),
  date          date not null default current_date,
  category      text not null default 'other',
  is_recurring  boolean not null default false,
  created_at    timestamptz not null default now()
);

create index idx_expenses_household on shared_expenses(household_id);


-- ── 7. invite_tokens ────────────────────────────────────────
-- Partner A generates a token; B opens the link and joins.
-- Token is single-use and expires after 7 days.

create table if not exists invite_tokens (
  token        uuid primary key default gen_random_uuid(),
  household_id uuid not null references households on delete cascade,
  role         text not null default 'b' check (role in ('a', 'b')),
  created_by   uuid not null references profiles on delete cascade,
  expires_at   timestamptz not null default now() + interval '7 days',
  used_at      timestamptz    -- null = unused
);

create index idx_invite_tokens_household on invite_tokens(household_id);


-- ── Helper functions ─────────────────────────────────────────

-- Is the current user a member of this household?
create or replace function is_household_member(p_household_id uuid)
returns boolean as $$
  select exists (
    select 1 from household_members
    where household_id = p_household_id
    and   user_id      = auth.uid()
  );
$$ language sql security definer stable;


-- Create a household and register the creator as partner A.
-- Called from the app after onboarding; returns the new household id.
create or replace function create_household(
  p_partner_a_label      text,
  p_partner_b_label      text,
  p_currency             text,
  p_country              text,
  p_annual_interest_rate float,
  p_setup_mode           text,
  p_relationship_type    text,
  p_email_a              text,
  p_email_b              text
) returns uuid as $$
declare
  v_id uuid;
begin
  insert into households (
    partner_a_label, partner_b_label,
    currency, country, annual_interest_rate,
    setup_mode, relationship_type,
    email_a, email_b
  ) values (
    p_partner_a_label, p_partner_b_label,
    p_currency, p_country, p_annual_interest_rate,
    p_setup_mode, p_relationship_type,
    p_email_a, p_email_b
  ) returning id into v_id;

  insert into household_members (household_id, user_id, role)
  values (v_id, auth.uid(), 'a');

  return v_id;
end;
$$ language plpgsql security definer;


-- Partner B joins by claiming an invite token.
-- Atomic: validates token, creates membership, marks token used.
create or replace function join_household_via_token(p_token uuid)
returns uuid as $$
declare
  v_household_id uuid;
  v_role         text;
begin
  -- Claim token atomically
  update invite_tokens
  set    used_at = now()
  where  token      = p_token
  and    used_at    is null
  and    expires_at > now()
  returning household_id, role into v_household_id, v_role;

  if v_household_id is null then
    raise exception 'invalid_token'
      using hint = 'Token is invalid, expired, or already used.';
  end if;

  -- Add membership (idempotent)
  insert into household_members (household_id, user_id, role)
  values (v_household_id, auth.uid(), v_role)
  on conflict (household_id, user_id) do nothing;

  return v_household_id;
end;
$$ language plpgsql security definer;


-- ── Row Level Security ───────────────────────────────────────

alter table profiles          enable row level security;
alter table households        enable row level security;
alter table household_members enable row level security;
alter table assets            enable row level security;
alter table contributions     enable row level security;
alter table shared_expenses   enable row level security;
alter table invite_tokens     enable row level security;

-- profiles: own row only
create policy "own profile"
  on profiles for all
  using (user_id = auth.uid());

-- households: any authenticated user may insert (via create_household function)
create policy "households: insert own"
  on households for insert
  with check (true);   -- create_household fn is security definer, so auth.uid() is valid here

create policy "households: members read"
  on households for select
  using (is_household_member(id));

create policy "households: members update"
  on households for update
  using (is_household_member(id));

-- household_members
create policy "hm: read own household"
  on household_members for select
  using (is_household_member(household_id));

create policy "hm: self insert"
  on household_members for insert
  with check (user_id = auth.uid());

-- assets
create policy "assets: household members"
  on assets for all
  using (is_household_member(household_id));

-- contributions (via asset → household)
create policy "contributions: household members"
  on contributions for all
  using (
    exists (
      select 1 from assets a
      where  a.id           = contributions.asset_id
      and    is_household_member(a.household_id)
    )
  );

-- shared_expenses
create policy "expenses: household members"
  on shared_expenses for all
  using (is_household_member(household_id));

-- invite_tokens: creator manages their own; anyone can read an unclaimed token
create policy "invites: creator read"
  on invite_tokens for select
  using (created_by = auth.uid());

create policy "invites: read valid"
  on invite_tokens for select
  using (used_at is null and expires_at > now());

create policy "invites: creator insert"
  on invite_tokens for insert
  with check (created_by = auth.uid());

create policy "invites: claim"
  on invite_tokens for update
  using  (used_at is null and expires_at > now())
  with check (used_at is not null);
