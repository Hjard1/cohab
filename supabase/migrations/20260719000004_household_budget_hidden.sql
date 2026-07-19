-- Allow a household to hide the monthly budget card from the dashboard
-- without deleting the budget data itself.
alter table public.households
  add column if not exists budget_hidden boolean not null default false;
