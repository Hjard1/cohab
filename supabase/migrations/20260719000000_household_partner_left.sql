-- Marks a household whose other partner deleted their account.
-- The remaining partner keeps read access ("you can still see assets")
-- while the app blocks every "add new" path when this is set.
alter table households
  add column if not exists partner_left_at timestamptz;
