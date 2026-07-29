-- Denmark review fixes (da templates only):
--  * dissolution v2: define "tilgængelig værdi", cover buyout/death, lender
--    carve-out, residual-debt distribution (mirrors improved en/sv).
--  * governing_law v2: proper Danish section title "LOVVALG" (v1 fell back
--    to English "GOVERNING LAW" in the app).
--  * assets_valuation v2: Swedish typo "parterna" -> "parterne".
--  * disposal_consent v2: Swedish typo "samtycke" -> "samtykke".
--  * buyout v2: lottery -> neutral third party; delay interest references
--    renteloven (a real statutory rate in Denmark, unlike the vague en text).

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('dissolution', 'da', 'FORDELING VED OPHØR',
 'Hvis samlivsforholdet ophører — herunder ved en parts død — hvis et fælles aktiv sælges, eller hvis en part overtager den andens andel, gælder følgende som parternes egen aftale om de registrerede aktiver. Ved overtagelse anvendes aktivets markedsværdi, fastsat efter aftalens vurderingsregler, i stedet for en salgspris.

Med tilgængelig værdi menes salgs- eller overtagelsesværdien fratrukket lån, der belaster aktivet, samt rimelige salgsomkostninger. Aftalen påvirker ikke pengeinstitutters eller andre kreditorers rettigheder.

(a) Indbetalinger tilbagebetales først. Hvad den enkelte part har indbetalt — med påløbne renter ({{rate}} per år indtil udbetalingsdagen) — tilbagebetales til den pågældende, inden det resterende fordeles.

(b) Underskud. Hvis den tilgængelige værdi er lavere end de samlede indbetalinger, fordeles den forholdsmæssigt efter, hvad hver part har indbetalt.

(c) Overskud. Et eventuelt restbeløb efter tilbagebetaling af indbetalinger fordeles efter parternes registrerede ejerandele.

(d) Restgæld. Hvis værdien ikke engang dækker lån og salgsomkostninger, bærer parterne restgælden internt i forhold til deres ejerandele.',
 2, 'published'),
('governing_law', 'da', 'LOVVALG',
 'Denne aftale er underlagt dansk ret. Tvister, der ikke løses i mindelighed, indbringes for de ordinære domstole.',
 2, 'published'),
('assets_valuation', 'da', null,
 'Ved uenighed om markedsværdien af et fælles aktiv er parterne enige om, at hver part indhenter én uafhængig vurdering fra en autoriseret vurderingsmand og anvender gennemsnittet af de to.',
 2, 'published'),
('disposal_consent', 'da', 'DISPOSITIONSSAMTYKKE',
 'Ingen af parterne må sælge, udleje, pantsætte eller på anden måde disponere over fælles aktiver uden den anden parts skriftlige samtykke. Transaktioner gennemført uden sådant samtykke kan gøres ugyldige af den part, der ikke har givet samtykke.',
 2, 'published'),
('buyout', 'da', 'OVERTAGELSESRET',
 'Hvis samlivsforholdet ophører, og parterne ejer en fælles bolig:

(a) Overtagelsesret. Den part med den største registrerede ejerandel har ret til at overtage den andens andel. Ved ens ejerandel (50/50) skal parterne i første omgang forsøge at nå en skriftlig aftale. Lykkes dette ikke inden 30 dage, afgøres overtagelsesretten ved mægling eller, hvis dette mislykkes, af en af parterne i fællesskab udpeget neutral tredjepart.

(b) Vurdering. Overtagelsesprisen fastsættes som gennemsnittet af to uafhængige vurderinger, én indhentet af hver part.

(c) Tidsfrist. Overtagelse eller salg på det åbne marked skal gennemføres inden 6 måneder fra skriftlig opsigelse eller den dokumenterede dato, samlivsforholdet faktisk ophørte.

(d) Morarenter. Overskrides fristen, betaler den forsinkede part morarenter i henhold til renteloven.',
 2, 'published')
on conflict (clause_key, language, version) do nothing;
