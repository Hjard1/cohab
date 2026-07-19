-- Tracks DealBuilder (BankID) signing cases created by cohab.
-- The webhook only acts on document IDs present in this table,
-- which also isolates us from Samboappen cases on the shared DealBuilder org.
create table if not exists cohab_dealbuilder_cases (
  id             uuid primary key default gen_random_uuid(),
  household_id   text not null,
  document_id    text unique not null,
  status         text not null default 'sent',  -- sent | completed | revoked
  app_url        text not null default '',
  preview_url    text not null default '',
  email_a        text not null,
  email_b        text not null,
  is_current     boolean not null default true,
  created_at     timestamptz default now(),
  completed_at   timestamptz
);

create index if not exists cohab_db_doc    on cohab_dealbuilder_cases(document_id);
create index if not exists cohab_db_hhid   on cohab_dealbuilder_cases(household_id);
create index if not exists cohab_db_status on cohab_dealbuilder_cases(status);
