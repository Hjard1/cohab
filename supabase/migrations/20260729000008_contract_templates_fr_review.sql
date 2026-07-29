-- France review fixes (fr templates only):
--  * purpose v3: drop unverifiable "acte notarié" claim; honest acte authentique
--    / publicité foncière recommendation (opposability to tiers); updates
--    require a new signed version.
--  * assets_intro v2: "détiennent en commun" is wrong for assets recorded 100/0.
--  * dissolution v3: full improved structure -- valeur disponible definition,
--    sale/buyout triggers, creditor carve-out, (d) dette résiduelle.
--  * buyout v2: lottery -> neutral third party; interest -> taux légal (a real
--    French statutory rate set by arrêté).
--  * disposal_consent v2: cannot void bona fide third-party acquisitions --
--    state as breach between the parties.

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('purpose', 'fr', 'OBJET DE LA CONVENTION',
 'La présente convention confirme les quotes-parts de propriété que les parties ont convenues entre elles sur les actifs communs et documente les apports financiers de chacune.{{dissolution}} Elle ne crée ni ne transfère par elle-même aucun droit de propriété; pour les immeubles, les quotes-parts devraient également figurer dans l''acte authentique publié à la publicité foncière pour être opposables aux tiers. Les parties s''engagent à actualiser la convention en signant une nouvelle version en cas de changement de situation.',
 3, 'published'),
('assets_intro', 'fr', 'ACTIFS ENREGISTRÉS ET QUOTES-PARTS',
 'Les parties ont enregistré les actifs suivants dans cohab à la date de signature et confirment les quotes-parts indiquées:',
 2, 'published'),
('dissolution', 'fr', 'RÈGLEMENT ÉCONOMIQUE EN CAS DE VENTE, RACHAT OU SÉPARATION',
 'Les présentes dispositions constituent l''accord économique propre des parties sur les actifs enregistrés. Elles s''appliquent lorsque l''union prend fin, lorsqu''un actif commun est vendu et en cas de rachat de la part de l''autre partie. En cas de rachat, la valeur vénale de l''actif — déterminée selon les règles d''évaluation de la présente convention — tient lieu de prix de vente.

Par valeur disponible, on entend la valeur de vente ou de rachat de l''actif, déduction faite des prêts qui le grèvent et des frais raisonnables de vente. La présente convention n''affecte pas les droits des banques ou autres créanciers.

(a) Restitution des apports en premier. Les sommes versées par chaque partie — augmentées des intérêts courus ({{rate}} par an jusqu''à la date de versement) — sont restituées avant tout partage du solde.

(b) Insuffisance. Si la valeur disponible est inférieure au total des apports, elle est répartie proportionnellement aux versements de chaque partie.

(c) Excédent. L''éventuel solde restant après restitution des apports est réparti selon les quotes-parts convenues.

(d) Dette résiduelle. Si la valeur ne couvre même pas les prêts et les frais de vente, les parties supportent entre elles la dette restante au prorata de leurs quotes-parts.

Le présent accord n''est pas un testament et ne régit pas la succession. Si l''union prend fin par le décès d''une partie, le droit des successions s''applique — les parties sont invitées à rédiger des testaments.',
 3, 'published'),
('buyout', 'fr', 'DROIT DE PRÉEMPTION',
 'En cas de dissolution de l''union et de copropriété immobilière:

(a) Droit de préemption. La partie détenant la quote-part la plus élevée a le droit de racheter la part de l''autre. En cas d''égalité (50/50), les parties s''efforcent d''abord de parvenir à un accord écrit; à défaut dans les 30 jours, le droit de préemption est déterminé par médiation ou, si celle-ci échoue, par un tiers neutre désigné d''un commun accord par les parties.

(b) Évaluation. Le prix de rachat correspond à la moyenne de deux expertises indépendantes, une par partie.

(c) Délai. Le rachat ou la vente sur le marché libre doit être achevé dans les 6 mois suivant la notification écrite.

(d) Intérêts de retard. En cas de dépassement du délai, la partie défaillante doit des intérêts au taux légal en vigueur.',
 2, 'published'),
('disposal_consent', 'fr', 'CONSENTEMENT AUX CESSIONS',
 'Aucune partie ne peut vendre, louer, hypothéquer ou autrement disposer des actifs communs sans le consentement écrit préalable de l''autre. La disposition sans ce consentement constitue un manquement contractuel entre les parties; les droits des tiers de bonne foi ne sont pas affectés.',
 2, 'published')
on conflict (clause_key, language, version) do nothing;
