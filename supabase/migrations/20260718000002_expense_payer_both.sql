-- Allow 'both' as a payer on shared expenses.
-- The app's expense sheet lets partners mark an expense as paid by both
-- (each covers their own share directly), but the CHECK constraint only
-- allowed 'a' and 'b', so those inserts were rejected silently.

alter table public.shared_expenses
    drop constraint if exists shared_expenses_paid_by_key_check,
    add constraint shared_expenses_paid_by_key_check
        check (paid_by_key in ('a', 'b', 'both'));
