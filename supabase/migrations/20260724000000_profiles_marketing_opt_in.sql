-- Marketing email preference per user.
-- NULL/false = not opted in (GDPR-safe default: marketing emails require an
-- explicit opt-in). The web account page (/konto on mycohab) exposes a
-- toggle that updates this column; profiles RLS ("own profile") already
-- allows users to update their own row.
alter table public.profiles
  add column if not exists marketing_opt_in boolean not null default false;
