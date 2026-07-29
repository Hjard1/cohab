-- England & Wales review fixes (en templates only):
--  * purpose v3: stop claiming shares are "registered title at HM Land Registry"
--    (HMLR never records beneficial shares), add declaration-of-trust pointer
--    and an explicit intention to be legally binding.
--  * dissolution v2: define "available proceeds", cover buyout/death, lender
--    carve-out, and residual-debt distribution (mirrors the improved sv text).
--  * buyout v2: "licensed appraiser" -> professional valuation, coin toss ->
--    neutral third party, vague delay interest -> the agreement's {{rate}}.
--  * assets_valuation v2: "licensed appraisal" -> professional valuation.
--  * separate_property v2: "registered in cohab" -> "recorded in cohab"
--    (the app is not a registry).

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
        when 'buyout'                        then array['rate']
        else array[]::text[]
    end;
$$;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('purpose', 'en', 'PURPOSE',
 'This agreement confirms the ownership shares the parties have agreed between themselves in their shared assets, and documents what each has contributed financially.{{dissolution}} This agreement does not by itself create, vary or transfer any interest in property; for shares in a home to bind third parties, they should also be recorded in a declaration of trust. The parties intend this agreement to be legally binding. Both parties agree to keep records up to date.',
 3, 'published'),
('dissolution', 'en', 'SETTLEMENT ON SEPARATION',
 'The following provisions are the parties'' own contractual arrangement for the recorded assets. They apply if the arrangement ends (including on the death of either party), if a shared asset is sold, and on a buyout. On a buyout, the asset''s market value — determined under this agreement''s valuation rules — is used in place of sale proceeds.

Available proceeds means the sale or buyout value of an asset, less any loan secured on the asset and the reasonable costs of sale. This agreement does not affect the rights of any lender or other creditor.

(a) Contributions returned first. What each party has paid in — with accrued interest at {{rate}} per annum until the payout date — is returned to that party before any remaining value is divided.

(b) Shortfall. If the available proceeds are less than the total contributions, the available amount is shared in proportion to what each party has paid in.

(c) Surplus. Any remaining value after contributions have been repaid is divided according to each party''s recorded ownership share.

(d) Residual debt. If the proceeds do not even cover the loan and the costs of sale, the parties bear the remaining debt between themselves in proportion to their ownership shares.',
 2, 'published'),
('buyout', 'en', 'BUYOUT RIGHTS AND TAKEOVER',
 'If this arrangement ends and the parties hold a jointly owned property:

(a) Right of first refusal: The party with the greater recorded ownership share has the right to buy out the other. Where ownership is equal (50/50), the parties shall first attempt written agreement; if no agreement is reached within 30 days, the right is determined by mediation or, failing that, by a mutually agreed neutral third party.

(b) Valuation: The buyout price shall be the average of two independent professional valuations, one obtained by each party.

(c) Timeline: Buyout or open-market sale shall be completed within 6 months of written notice of termination, or the documented date the arrangement ended.

(d) Interest on delay: If the deadline is missed, the delaying party shall pay interest at {{rate}} per annum on the outstanding amount.',
 2, 'published'),
('assets_valuation', 'en', null,
 'In the event of a dispute on the market value of a shared asset, the parties agree to each obtain one independent professional valuation and use the average of the two.',
 2, 'published'),
('separate_property', 'en', 'SEPARATE PROPERTY',
 'Assets that each party brought into this arrangement, and any assets received as a gift or inheritance during the arrangement, remain the sole property of the party who brought or received them.

Assets acquired jointly during the arrangement are held in the proportions recorded in cohab. Both parties are encouraged to keep records up to date; the most recently signed version of this agreement takes precedence in the event of any discrepancy.',
 2, 'published')
on conflict (clause_key, language, version) do nothing;
