-- purpose v2: the dissolution suffix is conditional (only when the household
-- enabled the dissolution clause), so it must be a placeholder, not baked in.
-- v1 seeded the purpose bodies with the suffix position collapsed — contracts
-- with the dissolution clause enabled would silently lose the sentence when
-- rendered from templates.

create or replace function public.contract_templates_allowed_tokens(p_clause_key text)
returns text[]
language sql
immutable
as $$
    select case p_clause_key
        when 'purpose'                       then array['registry', 'dissolution']
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

insert into public.contract_templates (clause_key, language, title, body, version, status)
select 'purpose', language, title,
    case language
        when 'nb' then 'Denne avtalen bekrefter partenes registrerte eierbrøk i felles eiendeler og dokumenterer hva hver av dem har betalt inn.{{dissolution}} Avtalen oppretter ingen nye eiendomsrettigheter — den gjentar og bekrefter det som allerede er tinglyst. Partene forplikter seg til å holde oversikten oppdatert.'
        when 'sv' then 'Detta avtal bekräftar parternas registrerade ägarandel i gemensamma tillgångar och dokumenterar vad var och en har betalat in.{{dissolution}} Avtalet skapar inga nya äganderätter — det återger och bekräftar de ägarandelar parterna har uppgett. Parterna förbinder sig att vid behov uppdatera uppgifterna genom ett nytt eller ändrat avtal som undertecknas av båda.'
        when 'da' then 'Denne aftale bekræfter parternes tinglyste ejerandel i fælles aktiver og dokumenterer, hvad den enkelte har indbetalt.{{dissolution}} Aftalen skaber ingen nye ejendomsrettigheder — den gentager og bekræfter det, der allerede er registreret via {{registry}}. Parterne forpligter sig til at holde oplysningerne opdaterede.'
        when 'fi' then 'Tämä sopimus vahvistaa osapuolten rekisteröidyn omistusosuuden yhteisiin varoihin ja dokumentoi kummankin maksamat panokset.{{dissolution}} Sopimus ei luo uusia omistusoikeuksia — se toistaa ja vahvistaa {{registry}}:ssa rekisteröidyn omistuksen. Osapuolet sitoutuvat pitämään tiedot ajan tasalla.'
        when 'de' then 'Dieser Vertrag bestätigt die im {{registry}} eingetragenen Eigentumsanteile der Parteien am gemeinsamen Vermögen und dokumentiert die jeweiligen Einzahlungen.{{dissolution}} Er begründet keine neuen Eigentumsrechte — er gibt die bestehende Eintragung wieder. Die Parteien verpflichten sich, die Angaben stets aktuell zu halten.'
        when 'fr' then 'La présente convention confirme les quotes-parts de propriété existantes des parties dans les actifs communs, telles qu''établies par {{registry}}, et documente les apports financiers de chacune.{{dissolution}} Elle ne crée ni ne transfère aucun droit de propriété — elle en atteste l''existence. Les parties s''engagent à tenir les informations à jour.'
        when 'es' then 'Este contrato confirma las cuotas de propiedad registradas de las partes en los activos compartidos, según constan en el {{registry}}, y documenta las aportaciones económicas de cada una.{{dissolution}} No crea ni transfiere ningún derecho de propiedad — se limita a confirmar el registro existente. Las partes se comprometen a mantener la información actualizada.'
        else 'This agreement confirms each party''s registered ownership of shared assets and documents what each has contributed financially.{{dissolution}} The ownership percentages stated herein reflect the parties'' existing registered title at {{registry}} and are for record-keeping purposes. This agreement does not create, vary, or transfer any interest in property. Both parties agree to keep records up to date.'
    end,
    2, 'published'
from public.contract_templates
where clause_key = 'purpose' and version = 1
on conflict (clause_key, language, version) do nothing;
