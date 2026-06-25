-- Tracks DocuSeal submissions created by cohab.
-- Used by the webhook to verify ownership and ignore Samboappen events.
create table if not exists cohab_docuseal_submissions (
  id             uuid primary key default gen_random_uuid(),
  household_id   text not null,
  submission_id  text not null,
  slug           text unique not null,
  status         text not null default 'pending',  -- pending | completed | declined
  email_a        text not null,
  email_b        text not null,
  created_at     timestamptz default now(),
  completed_at   timestamptz
);

create index if not exists cohab_ds_slug    on cohab_docuseal_submissions(slug);
create index if not exists cohab_ds_hhid    on cohab_docuseal_submissions(household_id);
create index if not exists cohab_ds_status  on cohab_docuseal_submissions(status);
