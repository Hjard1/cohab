-- Agreement configuration that affects the generated contract text.
-- Previously local-only (SwiftData), so the two partners could generate
-- different contracts. Persisting here keeps both devices in sync.

alter table public.households
    add column if not exists rent_amount                      double precision not null default 0,
    add column if not exists rent_payer_key                   text             not null default '',
    add column if not exists rent_payment_day                 integer          not null default 1,
    add column if not exists include_dissolution_clause       boolean          not null default true,
    add column if not exists include_separate_property_clause boolean          not null default false,
    add column if not exists include_buyout_rights_clause      boolean          not null default false,
    add column if not exists include_disposal_consent_clause   boolean          not null default false,
    add column if not exists include_dispute_resolution_clause boolean          not null default false,
    add column if not exists include_debt_clause               boolean          not null default false;
