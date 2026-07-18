-- Keep the same asset order for every household member and device.
alter table public.assets add column if not exists sort_order integer;

with ranked_assets as (
  select id, row_number() over (partition by household_id order by created_at, id) - 1 as position
  from public.assets
)
update public.assets
set sort_order = ranked_assets.position
from ranked_assets
where assets.id = ranked_assets.id
  and assets.sort_order is null;

create or replace function public.assign_asset_sort_order()
returns trigger
language plpgsql
as $$
begin
  if new.sort_order is null then
    select coalesce(max(sort_order) + 1, 0)
    into new.sort_order
    from public.assets
    where household_id = new.household_id;
  end if;
  return new;
end;
$$;

drop trigger if exists set_asset_sort_order on public.assets;
create trigger set_asset_sort_order
  before insert on public.assets
  for each row execute function public.assign_asset_sort_order();

alter table public.assets alter column sort_order set not null;
create index if not exists idx_assets_household_sort_order
  on public.assets(household_id, sort_order);
