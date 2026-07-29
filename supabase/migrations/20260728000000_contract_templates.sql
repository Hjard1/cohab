-- Contract clause templates stored in DB so contract text can be updated
-- without an app release. The app keeps the same strings bundled as an
-- offline fallback; DB rows override them when reachable.
--
-- Model:
--   * One row per (clause_key, language, version).
--   * status 'draft' -> editable; 'published' -> immutable (change = new version).
--   * Published rows are readable by the app (anon + authenticated).
--   * Writes are only possible via service role / direct DB access.
--   * Bodies may contain {{token}} placeholders; a trigger validates them
--     against a per-clause allowlist so a bad edit fails at write time.

create table if not exists public.contract_templates (
    id          uuid primary key default gen_random_uuid(),
    clause_key  text not null,
    language    text not null,
    title       text,
    body        text not null,
    version     int  not null default 1,
    status      text not null default 'draft' check (status in ('draft', 'published')),
    updated_at  timestamptz not null default now(),
    unique (clause_key, language, version)
);

create index if not exists contract_templates_lookup
    on public.contract_templates (language, status, clause_key, version desc);

alter table public.contract_templates enable row level security;

-- Templates contain no user data; published rows are world-readable so the
-- app can fetch them with the anon key even before/without a session.
drop policy if exists "read published contract templates" on public.contract_templates;
create policy "read published contract templates"
    on public.contract_templates for select
    to anon, authenticated
    using (status = 'published');

-- Immutability: published rows can neither be updated nor deleted.
-- draft -> published is allowed (OLD.status = 'draft').
create or replace function public.contract_templates_immutable()
returns trigger
language plpgsql
as $$
begin
    if OLD.status = 'published' then
        raise exception 'contract_templates: published rows are immutable — insert a new version instead';
    end if;
    if TG_OP = 'DELETE' then
        return OLD;
    end if;
    NEW.updated_at := now();
    return NEW;
end;
$$;

drop trigger if exists contract_templates_immutable on public.contract_templates;
create trigger contract_templates_immutable
    before update or delete on public.contract_templates
    for each row execute function public.contract_templates_immutable();

-- Token allowlist per clause_key. Anything not listed here is code-composed
-- and must not contain placeholders.
create or replace function public.contract_templates_allowed_tokens(p_clause_key text)
returns text[]
language sql
immutable
as $$
    select case p_clause_key
        when 'purpose'                       then array['registry']
        when 'rental'                        then array['rent_sentence']
        when 'rental_sentence_full'          then array['payer', 'amount', 'day']
        when 'rental_payer_a'                then array['name_a', 'name_b']
        when 'rental_payer_b'                then array['name_a', 'name_b']
        when 'rental_payer_landlord'         then array['name_a', 'name_b']
        when 'contributions_empty'           then array['rate']
        when 'contributions_interest_note'   then array['rate']
        when 'contributions_combined_heading' then array['date']
        when 'contributions_note'            then array['rate']
        when 'dissolution'                   then array['rate']
        else array[]::text[]
    end;
$$;

create or replace function public.contract_templates_validate_tokens()
returns trigger
language plpgsql
as $$
declare
    tok     text;
    allowed text[] := public.contract_templates_allowed_tokens(NEW.clause_key);
begin
    for tok in
        select m[1] from regexp_matches(NEW.body, '\{\{([a-z_]+)\}\}', 'g') as m
    loop
        if not (tok = any(allowed)) then
            raise exception 'contract_templates: token {{%}} is not allowed for clause_key "%"',
                tok, NEW.clause_key;
        end if;
    end loop;
    -- Titles never carry tokens.
    if NEW.title is not null and NEW.title ~ '\{\{[a-z_]+\}\}' then
        raise exception 'contract_templates: title must not contain tokens (clause_key "%")', NEW.clause_key;
    end if;
    return NEW;
end;
$$;

drop trigger if exists contract_templates_validate_tokens on public.contract_templates;
create trigger contract_templates_validate_tokens
    before insert or update on public.contract_templates
    for each row execute function public.contract_templates_validate_tokens();

-- Audit: which template versions produced a given signed document.
alter table public.cohab_docuseal_submissions
    add column if not exists template_versions jsonb;
alter table public.cohab_dealbuilder_cases
    add column if not exists template_versions jsonb;
