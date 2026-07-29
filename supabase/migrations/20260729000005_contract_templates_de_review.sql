-- Germany review fixes (de templates only, also used for AT):
--  * purpose v3: drop unverifiable "im Grundbuch eingetragen" claim (mirrors
--    Lantmäteriet/HMLR/Tinglysning fixes); updates require a new signed version.
--  * assets_intro v2: "besitzen gemeinsam" is wrong for assets recorded 100/0.
--  * dissolution v3: full improved structure -- available-proceeds definition,
--    sale/buyout triggers, creditor carve-out, (d) residual debt. Death stays
--    OUT of the triggers (Erbvertrag requires notarial form, § 2276 BGB).
--  * buyout v2: lottery -> neutral third party; delay interest -> § 288 BGB.
--  * disposal_consent v2: "angefochten" misuses the technical term; state it
--    as a breach between the parties, bona fide third parties unaffected.

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('purpose', 'de', 'VERTRAGSZWECK',
 'Dieser Vertrag bestätigt die von den Parteien angegebenen Eigentumsanteile am gemeinsamen Vermögen und dokumentiert die jeweiligen Einzahlungen.{{dissolution}} Er begründet für sich keine neuen Eigentumsrechte; bei Immobilien sollten die Anteile zur Sicherung gegenüber Dritten auch im Grundbuch eingetragen werden. Die Parteien verpflichten sich, Änderungen durch einen neuen, von beiden unterzeichneten Vertrag zu dokumentieren.',
 3, 'published'),
('assets_intro', 'de', 'ERFASSTE VERMÖGENSWERTE UND EIGENTUMSANTEILE',
 'Die Parteien haben folgende Vermögenswerte in cohab zum Zeitpunkt der Unterzeichnung erfasst und bestätigen die angegebenen Eigentumsanteile:',
 2, 'published'),
('dissolution', 'de', 'WIRTSCHAFTLICHE ABWICKLUNG BEI VERKAUF, ÜBERNAHME ODER TRENNUNG',
 'Die folgenden Bestimmungen sind die eigene vertragliche Regelung der Parteien über die erfassten Vermögenswerte. Sie gelten bei Beendigung der Partnerschaft, beim Verkauf eines gemeinsamen Vermögenswerts und bei der Übernahme eines Anteils. Bei einer Übernahme tritt der nach den Bewertungsregeln dieses Vertrags ermittelte Marktwert an die Stelle eines Verkaufserlöses.

Verfügbarer Erlös ist der Verkaufs- oder Übernahmewert eines Vermögenswerts abzüglich darauf lastender Darlehen und angemessener Verkaufskosten. Die Rechte von Kreditinstituten und anderen Gläubigern bleiben unberührt.

(a) Einzahlungen werden zuerst zurückerstattet. Die geleisteten Einzahlungen jeder Partei — zuzüglich aufgelaufener Zinsen ({{rate}} p.a. bis zum Auszahlungstag) — werden zurückerstattet, bevor der verbleibende Wert aufgeteilt wird.

(b) Unterdeckung. Reicht der verfügbare Erlös nicht zur vollständigen Rückerstattung aus, wird er anteilig nach den geleisteten Einzahlungen verteilt.

(c) Überschuss. Verbleibt nach der Rückerstattung ein Restwert, wird dieser gemäß den vereinbarten Eigentumsanteilen aufgeteilt.

(d) Restschuld. Reicht der Erlös nicht einmal zur Deckung von Darlehen und Verkaufskosten aus, tragen die Parteien die verbleibende Schuld intern entsprechend ihren Eigentumsanteilen.

Dieser Vertrag ist kein Testament und regelt nicht die Erbfolge. Endet die Partnerschaft durch den Tod einer Partei, gilt das gesetzliche Erbrecht — den Parteien wird empfohlen, Testamente zu errichten.',
 3, 'published'),
('buyout', 'de', 'VORKAUFSRECHT',
 'Bei Auflösung der Partnerschaft und gemeinsamem Immobilieneigentum gilt:

(a) Vorkaufsrecht. Die Partei mit dem größeren eingetragenen Eigentumsanteil hat das Recht, den Anteil der anderen Partei zu übernehmen. Bei gleichen Anteilen (50/50) bemühen sich die Parteien zunächst um eine schriftliche Einigung. Scheitert dies binnen 30 Tagen, wird das Vorkaufsrecht durch Mediation oder, falls diese scheitert, von einer von den Parteien gemeinsam bestellten neutralen dritten Person entschieden.

(b) Bewertung. Der Übernahmepreis entspricht dem Durchschnitt zweier unabhängiger Gutachten, je eines pro Partei.

(c) Frist. Die Übernahme oder der Verkauf am freien Markt muss innerhalb von 6 Monaten nach schriftlicher Kündigung abgeschlossen sein.

(d) Verzugszinsen. Bei Fristüberschreitung schuldet die säumige Partei Verzugszinsen gemäß § 288 BGB.',
 2, 'published'),
('disposal_consent', 'de', 'VERFÜGUNGSZUSTIMMUNG',
 'Keine Partei darf gemeinsame Vermögenswerte ohne schriftliche Zustimmung der anderen verkaufen, vermieten, verpfänden oder anderweitig veräußern. Verfügungen ohne Zustimmung gelten zwischen den Parteien als Vertragsverletzung; die Rechte gutgläubiger Dritter bleiben unberührt.',
 2, 'published')
on conflict (clause_key, language, version) do nothing;
