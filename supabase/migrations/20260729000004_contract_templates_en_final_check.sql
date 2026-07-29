-- UK final check fixes (en templates only):
--  * assets_intro v2: "jointly hold" is wrong for assets recorded 100/0 --
--    same fix as sv/da (recorded assets + confirmed shares).
--  * purpose v4: "keep records up to date" -> updates happen by signing a new
--    version (parity with sv/da after the Swedish review, point 9).

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('assets_intro', 'en', 'RECORDED ASSETS AND OWNERSHIP SHARES',
 'The parties have recorded the following assets in cohab at the time of signing and confirm the stated ownership shares:',
 2, 'published'),
('purpose', 'en', 'PURPOSE',
 'This agreement confirms the ownership shares the parties have agreed between themselves in their shared assets, and documents what each has contributed financially.{{dissolution}} This agreement does not by itself create, vary or transfer any interest in property; for shares in a home to bind third parties, they should also be recorded in a declaration of trust. The parties intend this agreement to be legally binding and agree to update it by signing a new version when circumstances change.',
 4, 'published')
on conflict (clause_key, language, version) do nothing;
