-- Documents that a user accepted the onboarding disclaimer, with which
-- version of the text and when — a legal trail per profile.
alter table profiles
  add column if not exists disclaimer_accepted_at timestamptz,
  add column if not exists disclaimer_version text;
