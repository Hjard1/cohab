-- Norway purpose fix (nb template only):
--  * purpose v3: stop claiming the whole agreement "gjentar og bekrefter det
--    som allerede er tinglyst" -- the app only knows what users typed, and the
--    claim is wrong for non-registrable assets (sparing, møbler) and for assets
--    the user did NOT mark as registered. Now: shares as stated by the parties;
--    for assets the user marked as tinglyst the parties confirm grunnboken;
--    skjøte recommendation for real estate; updates require a new signed
--    version (parity with all other languages).

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('purpose', 'nb', 'AVTALENS FORMÅL',
 'Denne avtalen bekrefter den eierbrøken partene selv har opplyst i felles eiendeler og dokumenterer hva hver av dem har betalt inn.{{dissolution}} For eiendeler som er merket som tinglyst, bekrefter partene at eierbrøken er tinglyst i grunnboken. Avtalen skaper ikke i seg selv nye eiendomsrettigheter — for fast eiendom bør eierbrøken også fremgå av skjøtet for å være beskyttet overfor tredjeparter. Partene forplikter seg til å oppdatere avtalen ved å signere en ny versjon når forholdene endrer seg.',
 3, 'published')
on conflict (clause_key, language, version) do nothing;
