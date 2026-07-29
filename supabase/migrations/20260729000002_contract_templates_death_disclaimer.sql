-- Death-vs-inheritance clarification, all languages:
--  * Every template gains an explicit "this is not a will" paragraph:
--    inheritance is governed by inheritance law, parties should make wills.
--    (Agreements about inheritance distribution between non-married partners
--    are void in NO/SE/DK/FI, prohibited in FR/ES, and require notarial form
--    in DE -- the contract must not appear to cover death.)
--  * sv v2 / da v3: death removed from the list of events triggering the
--    settlement model (was an invalid arvsavtal/arvepakt-style clause).
--  * en v3: death is KEPT as a trigger (enforceable in E&W/US as a contract
--    binding the estate), with an explicit carve-out that it is not a will.

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('dissolution', 'nb', 'FORDELING VED OPPHØR',
 'Dersom samboerforholdet opphører, gjelder følgende rekkefølge:

(a) Innbetalinger tilbakebetales først. Det hver part har betalt inn — med opptjente renter ({{rate}} per år) — utbetales til vedkommende før resterende verdi fordeles.

(b) Ved underskudd. Er tilgjengelig verdi lavere enn de samlede innbetalingene, deles det som finnes forholdsmessig etter hva hver part har betalt inn.

(c) Overskudd. Eventuell restverdi etter at innbetalinger er dekket, fordeles etter registrert eierbrøk.

Denne avtalen er ikke et testament og regulerer ikke arv. Dersom samboerforholdet opphører ved dødsfall, gjelder arvelovens regler — partene oppfordres til å opprette testament.',
 2, 'published'),
('dissolution', 'sv', 'EKONOMISK REGLERING VID FÖRSÄLJNING, UTKÖP ELLER SEPARATION',
 'Bestämmelserna nedan är parternas ekonomiska överenskommelse om de registrerade tillgångarna — inte ett föravtal om bodelning enligt 10 § sambolagen. De gäller vid separation, vid försäljning av en gemensam tillgång och vid inlösen. Vid inlösen räknas tillgångens marknadsvärde enligt avtalets värderingsregler i stället för en försäljningsintäkt.

Med tillgängliga intäkter avses försäljnings- eller inlösenvärdet minus lån som belastar tillgången och kostnader för försäljningen. Bankens och andra borgenärers rättigheter påverkas inte.

(a) Återbetalning först. Varje parts inbetalningar återbetalas med upplupen ränta ({{rate}} per år fram till utbetalningsdagen) innan resten fördelas.

(b) Underskott. Räcker inte intäkterna till alla inbetalningar fördelas de proportionellt efter vad var och en betalat in.

(c) Överskott. Det som återstår fördelas enligt ägarandelarna.

(d) Restskuld. Om intäkterna inte ens täcker lån och kostnader bär parterna restskulden internt efter ägarandel.

Detta avtal är inte ett testamente och reglerar inte arv. Om samboförhållandet upphör genom en parts död gäller landets arvsregler — parterna uppmanas att upprätta testamente.',
 2, 'published'),
('dissolution', 'da', 'FORDELING VED OPHØR',
 'Hvis samlivsforholdet ophører, hvis et fælles aktiv sælges, eller hvis en part overtager den andens andel, gælder følgende som parternes egen aftale om de registrerede aktiver. Ved overtagelse anvendes aktivets markedsværdi, fastsat efter aftalens vurderingsregler, i stedet for en salgspris.

Med tilgængelig værdi menes salgs- eller overtagelsesværdien fratrukket lån, der belaster aktivet, samt rimelige salgsomkostninger. Aftalen påvirker ikke pengeinstitutters eller andre kreditorers rettigheder.

(a) Indbetalinger tilbagebetales først. Hvad den enkelte part har indbetalt — med påløbne renter ({{rate}} per år indtil udbetalingsdagen) — tilbagebetales til den pågældende, inden det resterende fordeles.

(b) Underskud. Hvis den tilgængelige værdi er lavere end de samlede indbetalinger, fordeles den forholdsmæssigt efter, hvad hver part har indbetalt.

(c) Overskud. Et eventuelt restbeløb efter tilbagebetaling af indbetalinger fordeles efter parternes registrerede ejerandele.

(d) Restgæld. Hvis værdien ikke engang dækker lån og salgsomkostninger, bærer parterne restgælden internt i forhold til deres ejerandele.

Denne aftale er ikke et testamente og regulerer ikke arv. Hvis samlivsforholdet ophører ved en parts død, gælder arvelovens regler — parterne opfordres til at oprette testamente.',
 3, 'published'),
('dissolution', 'en', 'SETTLEMENT ON SEPARATION',
 'The following provisions are the parties'' own contractual arrangement for the recorded assets. They apply if the arrangement ends (including on the death of either party), if a shared asset is sold, and on a buyout. On a buyout, the asset''s market value — determined under this agreement''s valuation rules — is used in place of sale proceeds.

Available proceeds means the sale or buyout value of an asset, less any loan secured on the asset and the reasonable costs of sale. This agreement does not affect the rights of any lender or other creditor.

(a) Contributions returned first. What each party has paid in — with accrued interest at {{rate}} per annum until the payout date — is returned to that party before any remaining value is divided.

(b) Shortfall. If the available proceeds are less than the total contributions, the available amount is shared in proportion to what each party has paid in.

(c) Surplus. Any remaining value after contributions have been repaid is divided according to each party''s recorded ownership share.

(d) Residual debt. If the proceeds do not even cover the loan and the costs of sale, the parties bear the remaining debt between themselves in proportion to their ownership shares.

This agreement is not a will and does not govern inheritance. On the death of a party it binds that party''s estate as a contract to the extent permitted by applicable law; inheritance law otherwise applies, and the parties are encouraged to make wills.',
 3, 'published'),
('dissolution', 'de', 'VERMÖGENSAUFTEILUNG BEI TRENNUNG',
 'Im Fall der Auflösung der Partnerschaft gilt folgende Reihenfolge:

(a) Einzahlungen werden zuerst zurückerstattet. Die geleisteten Einzahlungen jeder Partei — zuzüglich aufgelaufener Zinsen ({{rate}} p.a.) — werden zurückerstattet, bevor der verbleibende Wert aufgeteilt wird.

(b) Unterdeckung. Reichen die verfügbaren Erlöse zur vollständigen Rückerstattung nicht aus, werden die verfügbaren Mittel anteilig verteilt.

(c) Überschuss. Verbleibt nach der Rückerstattung der Einzahlungen ein Restwert, wird dieser gemäß den eingetragenen Eigentumsanteilen aufgeteilt.

Dieser Vertrag ist kein Testament und regelt nicht die Erbfolge. Endet die Partnerschaft durch den Tod einer Partei, gilt das gesetzliche Erbrecht — den Parteien wird empfohlen, Testamente zu errichten.',
 2, 'published'),
('dissolution', 'es', 'DISTRIBUCIÓN AL SEPARARSE',
 'Si la convivencia termina, se aplicará el siguiente orden:

(a) Las aportaciones se devuelven primero. Lo que cada parte ha aportado — con los intereses acumulados ({{rate}} anual) — se devuelve antes de distribuir el valor restante.

(b) Déficit. Si los fondos disponibles son inferiores a las aportaciones totales, se distribuyen proporcionalmente a lo aportado por cada parte.

(c) Excedente. El saldo eventual tras la devolución de aportaciones se distribuye conforme a las cuotas de propiedad registradas.

Este acuerdo no es un testamento y no regula la herencia. Si la convivencia termina por el fallecimiento de una parte, se aplica la legislación sucesoria — se recomienda a las partes otorgar testamento.',
 2, 'published'),
('dissolution', 'fi', 'OMAISUUDEN JAKO EROTESSA',
 'Jos avoliitto päättyy, noudatetaan seuraavaa järjestystä:

(a) Panokset palautetaan ensin. Kunkin osapuolen maksamat summat — kertyneineen korkoineen ({{rate}} vuodessa) — palautetaan hänelle ennen jäljelle jäävän omaisuuden jakamista.

(b) Alijäämä. Jos käytettävissä olevat varat ovat pienempiä kuin panokset yhteensä, jaetaan ne suhteessa kunkin suorittamiin maksuihin.

(c) Ylijäämä. Mahdollinen jäljelle jäävä arvo jaetaan osapuolten rekisteröityjen omistusosuuksien mukaisesti.

Tämä sopimus ei ole testamentti eikä sääntele perintöä. Jos avoliitto päättyy osapuolen kuolemaan, sovelletaan perintölainsäädäntöä — osapuolia kehotetaan tekemään testamentit.',
 2, 'published'),
('dissolution', 'fr', 'RÉPARTITION EN CAS DE SÉPARATION',
 'En cas de dissolution de l''union, l''ordre suivant s''applique:

(a) Restitution des apports en premier. Les sommes versées par chaque partie — augmentées des intérêts courus ({{rate}} par an) — sont restituées avant tout partage du solde.

(b) Insuffisance. Si les fonds disponibles sont inférieurs aux apports totaux, ils sont répartis proportionnellement aux versements de chaque partie.

(c) Excédent. L''éventuel solde restant après restitution des apports est réparti selon les quotes-parts enregistrées.

Le présent accord n''est pas un testament et ne régit pas la succession. Si l''union prend fin par le décès d''une partie, le droit des successions s''applique — les parties sont invitées à rédiger des testaments.',
 2, 'published')
on conflict (clause_key, language, version) do nothing;
