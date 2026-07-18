-- Live expense-split working state (preset rows + incomes).
-- Previously UserDefaults-only, so each partner saw their own local numbers.
-- Persisting here keeps both partners' calculator identical, and the existing
-- realtime subscription on households propagates edits as they happen.

alter table public.households
    add column if not exists expense_presets     jsonb             not null default '[]'::jsonb,
    add column if not exists expense_income_a    double precision  not null default 0,
    add column if not exists expense_income_b    double precision  not null default 0,
    add column if not exists expenses_updated_at timestamptz;
