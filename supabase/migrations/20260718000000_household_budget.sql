-- Monthly budget snapshot saved from the expense-split calculator.
-- Previously local-only (SwiftData), so the "Save to overview" result was
-- only visible on the device that saved it. Persisting here lets both
-- partners see the same budget overview on the dashboard.

alter table public.households
    add column if not exists budget_income_a        double precision not null default 0,
    add column if not exists budget_income_b        double precision not null default 0,
    add column if not exists budget_total_expenses  double precision not null default 0,
    add column if not exists budget_split_a         double precision not null default 0.5,
    add column if not exists budget_pays_a          double precision not null default 0,
    add column if not exists budget_pays_b          double precision not null default 0,
    add column if not exists budget_net_transfer    double precision not null default 0,
    add column if not exists budget_saved_at        timestamptz;
