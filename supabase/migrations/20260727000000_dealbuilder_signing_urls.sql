-- Personal, login-free signing links per signatory (DealBuilder parties[].signingUrl).
-- The app's "open signing link" button and any share flow must use these,
-- NOT app_url (which is the DealBuilder admin view and requires login).
alter table cohab_dealbuilder_cases
  add column if not exists signing_url_a text,
  add column if not exists signing_url_b text;

-- Backfill the case created before this column existed
-- (links fetched from the DealBuilder API 2026-07-27).
update cohab_dealbuilder_cases
set signing_url_a = 'https://app.dealbuilder.io/pd/sign?key=49441ae1-6a36-4ebc-a898-fb79b9572673&signatoryKey=c0eb9223-8810-4b19-b5fd-7709eafe80b9',
    signing_url_b = 'https://app.dealbuilder.io/pd/sign?key=49441ae1-6a36-4ebc-a898-fb79b9572673&signatoryKey=df5f5af2-9321-41be-98d2-dd7cb2c7cfb4'
where document_id = '8c7c413b-0ae8-43cf-9005-c4146b68c293';
