-- Denmark full review fixes (da templates only):
--  * purpose v3: stop claiming assets are "tinglyste"/registered via Tinglysning
--    (only true for fast ejendom, and the app cannot verify it) -- mirrors the
--    Lantmäteriet/HMLR fixes in sv/en. Also: updates require a NEW signed
--    agreement (Swedish review point 9), not just "keep the data updated".
--  * assets_intro v2: "ejer i fællesskab" is wrong for assets owned 100/0 --
--    same fix as the Swedish review (registered assets + confirmed shares).
--  * purpose_dissolution v2: grammar -- "Det fastslår" -> "Den fastslår"
--    (aftale is common gender).
--  * buyout v3: "Ved ens ejerandel" -> "Ved lige ejerandele"; "skriftlig
--    opsigelse" (employment/tenancy term) -> "skriftlig meddelelse om ophør".

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('purpose', 'da', 'AFTALENS FORMÅL',
 'Denne aftale bekræfter de ejerandele i fælles aktiver, som parterne har oplyst, og dokumenterer, hvad den enkelte har indbetalt.{{dissolution}} Aftalen skaber ikke i sig selv nye ejendomsrettigheder; for fast ejendom bør ejerandelen også fremgå af skødet for at være sikret over for tredjeparter. Parterne forpligter sig til ved behov at opdatere oplysningerne gennem en ny eller ændret aftale, som underskrives af begge.',
 3, 'published'),
('assets_intro', 'da', 'REGISTREREDE AKTIVER OG EJERANDELE',
 'Parterne har registreret følgende aktiver i cohab på tidspunktet for underskrivelsen og bekræfter de angivne ejerandele:',
 2, 'published'),
('purpose_dissolution', 'da', null,
 ' Den fastslår også, hvordan aktiver fordeles, hvis samlivsforholdet ophører.',
 2, 'published'),
('buyout', 'da', 'OVERTAGELSESRET',
 'Hvis samlivsforholdet ophører, og parterne ejer en fælles bolig:

(a) Overtagelsesret. Den part med den største registrerede ejerandel har ret til at overtage den andens andel. Ved lige ejerandele (50/50) skal parterne i første omgang forsøge at nå en skriftlig aftale. Lykkes dette ikke inden 30 dage, afgøres overtagelsesretten ved mægling eller, hvis dette mislykkes, af en af parterne i fællesskab udpeget neutral tredjepart.

(b) Vurdering. Overtagelsesprisen fastsættes som gennemsnittet af to uafhængige vurderinger, én indhentet af hver part.

(c) Tidsfrist. Overtagelse eller salg på det åbne marked skal gennemføres inden 6 måneder fra skriftlig meddelelse om ophør eller den dokumenterede dato, samlivsforholdet faktisk ophørte.

(d) Morarenter. Overskrides fristen, betaler den forsinkede part morarenter i henhold til renteloven.',
 3, 'published')
on conflict (clause_key, language, version) do nothing;
