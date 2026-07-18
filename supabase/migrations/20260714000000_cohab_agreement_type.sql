-- ============================================================
-- Cohab — Agreement type (cohabitation vs rental) + relationship
-- type rename ("couple"/"housemates"/"business" → "partner"/"friend"/"married")
-- ============================================================

-- ── agreement_type ──────────────────────────────────────────
alter table households
  add column if not exists agreement_type text not null default 'cohabitation'
    check (agreement_type in ('cohabitation', 'rental'));

-- ── relationship_type: migrate values then swap the check constraint ──
update households set relationship_type = 'partner' where relationship_type = 'couple';
update households set relationship_type = 'friend' where relationship_type in ('housemates', 'business');

-- Drop whatever check constraint currently governs relationship_type, by
-- introspection rather than an assumed name — the original inline `check()`
-- in the CREATE TABLE gets a Postgres-assigned name that may not match the
-- conventional `<table>_<column>_check` pattern in every environment.
do $$
declare
  v_constraint_name text;
begin
  select con.conname into v_constraint_name
  from pg_constraint con
  join pg_class rel on rel.oid = con.conrelid
  join pg_attribute att on att.attrelid = rel.oid and att.attnum = any(con.conkey)
  where rel.relname = 'households'
    and con.contype = 'c'
    and att.attname = 'relationship_type';

  if v_constraint_name is not null then
    execute format('alter table households drop constraint %I', v_constraint_name);
  end if;
end $$;

alter table households
  add constraint households_relationship_type_check
    check (relationship_type in ('partner', 'friend', 'married'));
alter table households alter column relationship_type set default 'partner';

-- ── create_household RPC: add p_agreement_type ─────────────────
create or replace function create_household(
  p_partner_a_label      text,
  p_partner_b_label      text,
  p_currency             text,
  p_country              text,
  p_annual_interest_rate float,
  p_setup_mode           text,
  p_relationship_type    text,
  p_agreement_type       text,
  p_email_a              text,
  p_email_b              text
) returns uuid as $$
declare
  v_id uuid;
begin
  insert into households (
    partner_a_label, partner_b_label,
    currency, country, annual_interest_rate,
    setup_mode, relationship_type, agreement_type,
    email_a, email_b
  ) values (
    p_partner_a_label, p_partner_b_label,
    p_currency, p_country, p_annual_interest_rate,
    p_setup_mode, p_relationship_type, p_agreement_type,
    p_email_a, p_email_b
  ) returning id into v_id;

  insert into household_members (household_id, user_id, role)
  values (v_id, auth.uid(), 'a');

  return v_id;
end;
$$ language plpgsql security definer;
