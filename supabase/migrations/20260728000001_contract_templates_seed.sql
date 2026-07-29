-- Seed public.contract_templates with the contract clause texts currently
-- hardcoded in Cohab/Core/ContractGenerator.swift (buildSections), verbatim,
-- for all 8 document languages (nb, sv, da, fi, de, fr, es, en).
-- All rows: version 1, status 'published'.
-- Swift interpolations are replaced by {{token}} placeholders per the
-- token allowlist in 20260728000000_contract_templates.sql.
-- Not seeded (stay in code): the US-specific purpose and governing_law
-- variants, generated asset/contribution list blocks, party/signature/header
-- chrome, and AppStrings-sourced strings.

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('purpose','nb','AVTALENS FORMÅL','Denne avtalen bekrefter partenes registrerte eierbrøk i felles eiendeler og dokumenterer hva hver av dem har betalt inn. Avtalen oppretter ingen nye eiendomsrettigheter — den gjentar og bekrefter det som allerede er tinglyst. Partene forplikter seg til å holde oversikten oppdatert.',1,'published'),
('purpose','sv','AVTALETS ÄNDAMÅL','Detta avtal bekräftar parternas registrerade ägarandel i gemensamma tillgångar och dokumenterar vad var och en har betalat in. Avtalet skapar inga nya äganderätter — det återger och bekräftar de ägarandelar parterna har uppgett. Parterna förbinder sig att vid behov uppdatera uppgifterna genom ett nytt eller ändrat avtal som undertecknas av båda.',1,'published'),
('purpose','da','AFTALENS FORMÅL','Denne aftale bekræfter parternes tinglyste ejerandel i fælles aktiver og dokumenterer, hvad den enkelte har indbetalt. Aftalen skaber ingen nye ejendomsrettigheder — den gentager og bekræfter det, der allerede er registreret via {{registry}}. Parterne forpligter sig til at holde oplysningerne opdaterede.',1,'published'),
('purpose','fi','SOPIMUKSEN TARKOITUS','Tämä sopimus vahvistaa osapuolten rekisteröidyn omistusosuuden yhteisiin varoihin ja dokumentoi kummankin maksamat panokset. Sopimus ei luo uusia omistusoikeuksia — se toistaa ja vahvistaa {{registry}}:ssa rekisteröidyn omistuksen. Osapuolet sitoutuvat pitämään tiedot ajan tasalla.',1,'published'),
('purpose','de','VERTRAGSZWECK','Dieser Vertrag bestätigt die im {{registry}} eingetragenen Eigentumsanteile der Parteien am gemeinsamen Vermögen und dokumentiert die jeweiligen Einzahlungen. Er begründet keine neuen Eigentumsrechte — er gibt die bestehende Eintragung wieder. Die Parteien verpflichten sich, die Angaben stets aktuell zu halten.',1,'published'),
('purpose','fr','OBJET DE LA CONVENTION','La présente convention confirme les quotes-parts de propriété existantes des parties dans les actifs communs, telles qu''établies par {{registry}}, et documente les apports financiers de chacune. Elle ne crée ni ne transfère aucun droit de propriété — elle en atteste l''existence. Les parties s''engagent à tenir les informations à jour.',1,'published'),
('purpose','es','OBJETO DEL CONTRATO','Este contrato confirma las cuotas de propiedad registradas de las partes en los activos compartidos, según constan en el {{registry}}, y documenta las aportaciones económicas de cada una. No crea ni transfiere ningún derecho de propiedad — se limita a confirmar el registro existente. Las partes se comprometen a mantener la información actualizada.',1,'published'),
('purpose','en','PURPOSE','This agreement confirms each party''s registered ownership of shared assets and documents what each has contributed financially. The ownership percentages stated herein reflect the parties'' existing registered title at {{registry}} and are for record-keeping purposes. This agreement does not create, vary, or transfer any interest in property. Both parties agree to keep records up to date.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('purpose_dissolution','nb',null,' Den fastsetter også hvordan verdier fordeles dersom samlivet opphører.',1,'published'),
('purpose_dissolution','sv',null,' Det fastställer också hur tillgångar fördelas om samboförhållandet upphör.',1,'published'),
('purpose_dissolution','da',null,' Det fastslår også, hvordan aktiver fordeles, hvis samlivsforholdet ophører.',1,'published'),
('purpose_dissolution','fi',null,' Se määrittelee myös, miten varat jaetaan, jos avoliitto päättyy.',1,'published'),
('purpose_dissolution','de',null,' Er legt außerdem fest, wie das Vermögen bei Auflösung der Partnerschaft aufgeteilt wird.',1,'published'),
('purpose_dissolution','fr',null,' Elle définit également la répartition des actifs en cas de dissolution de l''union.',1,'published'),
('purpose_dissolution','es',null,' También establece cómo se dividen los activos si la relación termina.',1,'published'),
('purpose_dissolution','en',null,' It also sets out how assets are divided if the arrangement ends.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('sambolagen','sv','SAMBOLAGEN (2003:376)','Parterna är överens om att bodelning enligt sambolagen (2003:376) inte ska ske. För de tillgångar som anges i detta avtal gäller dessutom den ekonomiska fördelningsmodell som parterna har kommit överens om nedan.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('separate_property','nb','SÆREIE OG ENEEIE','Det hver av oss tok med inn i samboerforholdet, er den enkeltes eneeie. Midler eller gjenstander hver av oss mottar som gave eller arv, er også den enkeltes eneeie.

Eiendeler anskaffet underveis i samlivet tilhører den part som anskaffet dem. Partene oppfordres til å registrere eiendeler i cohab — både personlig eneeie og felles eie. Den sist signerte versjonen av denne avtalen har forrang ved eventuell uenighet.',1,'published'),
('separate_property','sv','ENSKILD EGENDOM','Det var och en av oss hade med oss in i samboförhållandet är den enskildes egendom. Tillgångar som mottagits som gåva eller arv under samboförhållandet är också den enskildes egendom.

Tillgångar som förvärvats gemensamt ägs i de andelar som registrerats i cohab. Parterna uppmanas att hålla uppgifterna uppdaterade. Den senast undertecknade versionen av detta avtal har företräde vid eventuell oenighet.',1,'published'),
('separate_property','da','SÆREJE','Hvad vi hver især bragte med ind i samlivsforholdet, er den enkeltes ejendom. Aktiver modtaget som gave eller arv under samlivsforholdet er ligeledes den enkeltes ejendom.

Aktiver erhvervet i fællesskab ejes i de andele, der er registreret i cohab. Parterne opfordres til at holde oplysningerne opdaterede. Den sidst underskrevne version af denne aftale har forrang ved eventuell uenighed.',1,'published'),
('separate_property','fi','OMA OMAISUUS','Kumpikin osapuoli omistaa yksin sen omaisuuden, jonka hän toi avoliittoon, sekä lahjaksi tai perinnöksi saamansa omaisuuden.

Yhdessä hankittu omaisuus kuuluu osapuolille cohab-sovellukseen rekisteröityjen omistusosuuksien mukaisesti. Osapuolia kannustetaan pitämään tiedot ajan tasalla. Viimeksi allekirjoitettu versio tästä sopimuksesta on ensisijainen ristiriitatilanteessa.',1,'published'),
('separate_property','de','EIGENES VERMÖGEN','Jeder Vertragspartner behält das Alleineigentum an dem Vermögen, das er in die Partnerschaft eingebracht hat, sowie an Vermögen, das er als Geschenk oder Erbschaft erhalten hat.

Gemeinsam erworbenes Vermögen wird in den in cohab eingetragenen Anteilen gehalten. Die Parteien sind angehalten, die Angaben aktuell zu halten. Die zuletzt unterzeichnete Version dieses Vertrags hat bei Unstimmigkeiten Vorrang.',1,'published'),
('separate_property','fr','PROPRIÉTÉ PERSONNELLE','Chaque partie conserve la propriété exclusive des biens qu''elle a apportés à l''union libre, ainsi que des biens reçus en donation ou par succession.

Les biens acquis en commun sont détenus selon les quotes-parts enregistrées dans cohab. Les parties sont encouragées à maintenir les informations à jour. La version du présent accord signée en dernier lieu prévaut en cas de divergence.',1,'published'),
('separate_property','es','PROPIEDAD INDIVIDUAL','Cada parte conserva la propiedad exclusiva de los bienes que aportó a la convivencia, así como de los bienes recibidos como donación o herencia.

Los bienes adquiridos conjuntamente se poseen en las proporciones registradas en cohab. Las partes se comprometen a mantener los datos actualizados. La versión firmada más recientemente prevalece en caso de discrepancia.',1,'published'),
('separate_property','en','SEPARATE PROPERTY','Assets that each party brought into this arrangement, and any assets received as a gift or inheritance during the arrangement, remain the sole property of the party who brought or received them.

Assets acquired jointly during the arrangement are held in the proportions registered in cohab. Both parties are encouraged to keep records up to date; the most recently signed version of this agreement takes precedence in the event of any discrepancy.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('assets_intro','nb','FELLES EIENDELER OG EIERSKAP','Partene eier i fellesskap følgende eiendeler registrert i cohab ved signeringstidspunktet:',1,'published'),
('assets_intro','sv','REGISTRERADE TILLGÅNGAR OCH ÄGARANDELAR','Parterna har registrerat följande tillgångar och bekräftar de angivna ägarandelarna:',1,'published'),
('assets_intro','da','FÆLLES AKTIVER OG EJERSKAB','Parterne ejer i fællesskab følgende aktiver registreret i cohab på tidspunktet for underskrivelsen:',1,'published'),
('assets_intro','fi','YHTEISET VARAT JA OMISTUS','Osapuolet omistavat yhdessä seuraavat cohab-sovellukseen allekirjoitushetkellä rekisteröidyt varat:',1,'published'),
('assets_intro','de','GEMEINSAMES VERMÖGEN UND EIGENTUMSANTEILE','Die Parteien besitzen gemeinsam folgende in cohab zum Zeitpunkt der Unterzeichnung eingetragene Vermögenswerte:',1,'published'),
('assets_intro','fr','ACTIFS COMMUNS ET PROPRIÉTÉ','Les parties détiennent en commun les actifs suivants enregistrés dans cohab à la date de signature:',1,'published'),
('assets_intro','es','ACTIVOS COMPARTIDOS Y PROPIEDAD','Las partes poseen conjuntamente los siguientes activos registrados en cohab en la fecha de firma:',1,'published'),
('assets_intro','en','SHARED ASSETS AND OWNERSHIP','The parties jointly hold the following assets as registered in cohab at the time of signing:',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('assets_empty','nb',null,'Ingen eiendeler er registrert ved signering. Eiendeler vil legges til etter felles avtale.',1,'published'),
('assets_empty','sv',null,'Inga tillgångar är registrerade vid undertecknandet. Tillgångar läggs till efter ömsesidig överenskommelse.',1,'published'),
('assets_empty','da',null,'Ingen aktiver er registreret ved underskrivelsen. Aktiver tilføjes efter fælles aftale.',1,'published'),
('assets_empty','fi',null,'Varoja ei ole rekisteröity allekirjoitushetkellä. Varat lisätään yhteisellä sopimuksella.',1,'published'),
('assets_empty','de',null,'Zum Zeitpunkt der Unterzeichnung sind keine Vermögenswerte eingetragen. Vermögenswerte werden einvernehmlich ergänzt.',1,'published'),
('assets_empty','fr',null,'Aucun actif n''est enregistré à la date de signature. Les actifs seront ajoutés d''un commun accord.',1,'published'),
('assets_empty','es',null,'No hay activos registrados en la fecha de firma. Los activos se añadirán de mutuo acuerdo.',1,'published'),
('assets_empty','en',null,'No assets registered at signing. Assets will be added by mutual agreement.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('assets_valuation','nb',null,'Ved uenighet om markedsverdien av en felles eiendel er partene enige om å innhente én uavhengig takst fra godkjent takstmann hver, og bruke gjennomsnittet av de to.',1,'published'),
('assets_valuation','sv',null,'Vid oenighet om marknadsvärdet på en gemensam tillgång är parterna överens om att var och en inhämtar ett oberoende värderingsintyg från en auktoriserad värderingsman och att använda genomsnittet av de två.',1,'published'),
('assets_valuation','da',null,'Ved uenighed om markedsværdien af et fælles aktiv er parterna enige om, at hver part indhenter én uafhængig vurdering fra en autoriseret vurderingsmand og anvender gennemsnittet af de to.',1,'published'),
('assets_valuation','fi',null,'Mikäli yhteisen omaisuuden markkina-arvosta syntyy erimielisyys, osapuolet hankkivat kukin yhden riippumattoman arvion valtuutetulta arvioijalta ja käyttävät arvojen keskiarvoa.',1,'published'),
('assets_valuation','de',null,'Bei Uneinigkeit über den Marktwert eines gemeinsamen Vermögenswerts holt jede Partei ein unabhängiges Gutachten eines zugelassenen Sachverständigen ein; der Durchschnitt beider Gutachten ist maßgeblich.',1,'published'),
('assets_valuation','fr',null,'En cas de désaccord sur la valeur marchande d''un actif commun, chaque partie mandate un expert indépendant agréé; la moyenne des deux estimations s''applique.',1,'published'),
('assets_valuation','es',null,'En caso de desacuerdo sobre el valor de mercado de un activo, cada parte obtendrá una tasación independiente de un tasador homologado; se aplicará la media de ambas.',1,'published'),
('assets_valuation','en',null,'In the event of a dispute on the market value of a shared asset, the parties agree to each obtain one independent licensed appraisal and use the average of the two.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('rental','nb','LEIEAVTALE OG HUSLEIE','Partene bor sammen i en bolig de leier, eller hvor én av partene leier ut til den andre. {{rent_sentence}} Dersom bofellesskapet opphører, faller den enkeltes betalingsplikt automatisk bort fra opphørsdatoen.',1,'published'),
('rental','sv','HYRESAVTAL','Parterna bor tillsammans i en bostad de hyr, eller där en av parterna hyr ut till den andra. {{rent_sentence}} Om samboförhållandet upphör upphör betalningsskyldigheten automatiskt från och med upphörandedatumet.',1,'published'),
('rental','da','LEJEAFTALE','Parterne bor sammen i en bolig, de lejer, eller hvor en af parterne udlejer til den anden. {{rent_sentence}} Hvis bofællesskabet ophører, bortfalder betalingsforpligtelsen automatisk fra ophørsdatoen.',1,'published'),
('rental','fi','VUOKRASOPIMUS','Osapuolet asuvat yhdessä vuokra-asunnossa, tai toinen osapuoli vuokraa asunnon toiselle. {{rent_sentence}} Jos asuminen yhdessä päättyy, maksuvelvollisuus lakkaa automaattisesti päättymispäivästä.',1,'published'),
('rental','de','MIETVEREINBARUNG','Die Parteien leben gemeinsam in einer gemieteten Wohnung, oder eine Partei vermietet an die andere. {{rent_sentence}} Endet die gemeinsame Haushaltsführung, entfällt die Zahlungspflicht automatisch ab dem Beendigungsdatum.',1,'published'),
('rental','fr','ACCORD DE LOCATION','Les parties partagent un logement qu''elles louent, ou l''une loue à l''autre. {{rent_sentence}} Si la cohabitation prend fin, l''obligation de paiement cesse automatiquement à la date de fin.',1,'published'),
('rental','es','ACUERDO DE ALQUILER','Las partes conviven en una vivienda que alquilan, o una de ellas alquila a la otra. {{rent_sentence}} Si la convivencia termina, la obligación de pago cesa automáticamente desde la fecha de finalización.',1,'published'),
('rental','en','RENTAL ARRANGEMENT','The parties share a home that they rent, or one party rents to the other. {{rent_sentence}} If the arrangement ends, the obligation to pay rent ends automatically from the date the arrangement ends.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('rental_sentence_full','nb',null,'{{payer}}, {{amount}} per måned, forfaller den {{day}}. i hver måned. Øvrige boutgifter (blant annet strøm, internett og felles husholdningsutgifter) fordeles som avtalt mellom partene og dokumenteres i cohab.',1,'published'),
('rental_sentence_full','sv',null,'{{payer}}, {{amount}} per månad, förfaller den {{day}}:e varje månad. Övriga boendekostnader (t.ex. el, internet och gemensamma hushållsutgifter) fördelas som avtalats mellan parterna och dokumenteras i cohab.',1,'published'),
('rental_sentence_full','da',null,'{{payer}}, {{amount}} om måneden, forfalder den {{day}}. i hver måned. Øvrige boligudgifter (f.eks. el, internet og fælles husholdningsudgifter) fordeles som aftalt mellem parterne og dokumenteres i cohab.',1,'published'),
('rental_sentence_full','fi',null,'{{payer}}, {{amount}} kuukaudessa, eräpäivä kunkin kuukauden {{day}}. päivä. Muut asumiskustannukset (esim. sähkö, internet ja yhteiset kotitalousmenot) jaetaan osapuolten sopimuksen mukaisesti ja kirjataan cohab-sovellukseen.',1,'published'),
('rental_sentence_full','de',null,'{{payer}}, {{amount}} pro Monat, fällig am {{day}}. jeden Monats. Weitere Wohnkosten (z. B. Strom, Internet und gemeinsame Haushaltsausgaben) werden nach Vereinbarung der Parteien aufgeteilt und in cohab dokumentiert.',1,'published'),
('rental_sentence_full','fr',null,'{{payer}}, {{amount}} par mois, exigible le {{day}} de chaque mois. Les autres frais de logement (électricité, internet, dépenses courantes du foyer, etc.) sont répartis tels que convenus entre les parties et documentés dans cohab.',1,'published'),
('rental_sentence_full','es',null,'{{payer}}, {{amount}} al mes, con vencimiento el día {{day}} de cada mes. Los demás gastos de la vivienda (electricidad, internet, gastos domésticos comunes, etc.) se reparten según lo acordado entre las partes y se documentan en cohab.',1,'published'),
('rental_sentence_full','en',null,'{{payer}}, {{amount}} per month, due on the {{day}} of each month. Other household costs (e.g. utilities, internet, and shared household expenses) are split as agreed between the parties and documented in cohab.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('rental_sentence_generic','nb',null,'Husleie og fordeling av øvrige boutgifter (blant annet strøm, internett og felles husholdningsutgifter) er som avtalt mellom partene og dokumenteres i cohab.',1,'published'),
('rental_sentence_generic','sv',null,'Hyra och fördelning av övriga boendekostnader (t.ex. el, internet och gemensamma hushållsutgifter) är som avtalats mellan parterna och dokumenteras i cohab.',1,'published'),
('rental_sentence_generic','da',null,'Husleje og fordeling af øvrige boligudgifter (f.eks. el, internet og fælles husholdningsudgifter) er som aftalt mellem parterne og dokumenteres i cohab.',1,'published'),
('rental_sentence_generic','fi',null,'Vuokra ja muiden asumiskustannusten (esim. sähkö, internet ja yhteiset kotitalousmenot) jakautuminen on osapuolten sopimuksen mukainen ja kirjataan cohab-sovellukseen.',1,'published'),
('rental_sentence_generic','de',null,'Miete und die Aufteilung weiterer Wohnkosten (z. B. Strom, Internet und gemeinsame Haushaltsausgaben) richten sich nach der Vereinbarung der Parteien und werden in cohab dokumentiert.',1,'published'),
('rental_sentence_generic','fr',null,'Le loyer et la répartition des autres frais de logement (électricité, internet, dépenses courantes du foyer, etc.) sont tels que convenus entre les parties et documentés dans cohab.',1,'published'),
('rental_sentence_generic','es',null,'El alquiler y el reparto de otros gastos de la vivienda (electricidad, internet, gastos domésticos comunes, etc.) son los acordados entre las partes y se documentan en cohab.',1,'published'),
('rental_sentence_generic','en',null,'Rent and the split of other household costs (e.g. utilities, internet, and shared household expenses) are as agreed between the parties and documented in cohab.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('rental_payer_a','nb',null,'{{name_a}} betaler husleie til {{name_b}}',1,'published'),
('rental_payer_a','sv',null,'{{name_a}} betalar hyra till {{name_b}}',1,'published'),
('rental_payer_a','da',null,'{{name_a}} betaler husleje til {{name_b}}',1,'published'),
('rental_payer_a','fi',null,'{{name_a}} maksaa vuokraa {{name_b}}lle',1,'published'),
('rental_payer_a','de',null,'{{name_a}} zahlt Miete an {{name_b}}',1,'published'),
('rental_payer_a','fr',null,'{{name_a}} verse le loyer à {{name_b}}',1,'published'),
('rental_payer_a','es',null,'{{name_a}} paga el alquiler a {{name_b}}',1,'published'),
('rental_payer_a','en',null,'{{name_a}} pays rent to {{name_b}}',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('rental_payer_b','nb',null,'{{name_b}} betaler husleie til {{name_a}}',1,'published'),
('rental_payer_b','sv',null,'{{name_b}} betalar hyra till {{name_a}}',1,'published'),
('rental_payer_b','da',null,'{{name_b}} betaler husleje til {{name_a}}',1,'published'),
('rental_payer_b','fi',null,'{{name_b}} maksaa vuokraa {{name_a}}lle',1,'published'),
('rental_payer_b','de',null,'{{name_b}} zahlt Miete an {{name_a}}',1,'published'),
('rental_payer_b','fr',null,'{{name_b}} verse le loyer à {{name_a}}',1,'published'),
('rental_payer_b','es',null,'{{name_b}} paga el alquiler a {{name_a}}',1,'published'),
('rental_payer_b','en',null,'{{name_b}} pays rent to {{name_a}}',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('rental_payer_landlord','nb',null,'Partene betaler husleie til utleier',1,'published'),
('rental_payer_landlord','sv',null,'Parterna betalar hyra till hyresvärden',1,'published'),
('rental_payer_landlord','da',null,'Parterne betaler husleje til udlejeren',1,'published'),
('rental_payer_landlord','fi',null,'Osapuolet maksavat vuokraa vuokranantajalle',1,'published'),
('rental_payer_landlord','de',null,'Die Parteien zahlen Miete an den Vermieter',1,'published'),
('rental_payer_landlord','fr',null,'Les parties versent le loyer au propriétaire',1,'published'),
('rental_payer_landlord','es',null,'Las partes pagan el alquiler al arrendador',1,'published'),
('rental_payer_landlord','en',null,'The parties pay rent to their landlord',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('contributions_empty','nb','REGISTRERTE BIDRAG','Ingen innbetalinger er registrert ved signering. Innskudd, ekstra nedbetalinger og oppussing kan registreres når som helst og forrentes med {{rate}} per år. Registrerte bidrag endrer ikke eierbrøken.',1,'published'),
('contributions_empty','sv','REGISTRERADE BIDRAG','Inga ekonomiska bidrag har registrerats vid undertecknandet. Insättningar, extra amorteringar och renoveringar kan registreras när som helst och räknas upp med {{rate}} per år. Registrerade bidrag ändrar inte parternas ägarandelar.',1,'published'),
('contributions_empty','da','REGISTREREDE BIDRAG','Ingen finansielle bidrag er registreret ved underskrivelsen. Indskud, ekstra afdrag og renoveringer kan registreres til enhver tid og forrentes med {{rate}} per år. Registrerede bidrag ændrer ikke ejerandelen.',1,'published'),
('contributions_empty','fi','REKISTERÖIDYT PANOKSET','Taloudellisia panoksia ei ole rekisteröity allekirjoitushetkellä. Talletukset, ylimääräiset lyhennykset ja remontit voidaan rekisteröidä milloin tahansa ja niille lasketaan korkoa {{rate}} vuodessa. Rekisteröidyt panokset eivät muuta omistusosuuksia.',1,'published'),
('contributions_empty','de','ERFASSTE EINZAHLUNGEN','Zum Zeitpunkt der Unterzeichnung sind keine Einzahlungen erfasst. Einlagen, zusätzliche Tilgungen und Renovierungen können jederzeit ergänzt werden und werden mit {{rate}} p.a. verzinst. Erfasste Einzahlungen ändern nicht die Eigentumsanteile.',1,'published'),
('contributions_empty','fr','APPORTS ENREGISTRÉS','Aucun apport financier n''est enregistré à la date de signature. Les dépôts, remboursements supplémentaires et travaux peuvent être ajoutés à tout moment et sont rémunérés à {{rate}} par an. Les apports enregistrés ne modifient pas les quotes-parts.',1,'published'),
('contributions_empty','es','APORTACIONES REGISTRADAS','No se han registrado aportaciones en la fecha de firma. Los depósitos, amortizaciones extraordinarias y reformas pueden registrarse en cualquier momento y generan intereses al {{rate}} anual. Las aportaciones registradas no modifican las cuotas de propiedad.',1,'published'),
('contributions_empty','en','RECORDED CONTRIBUTIONS','No contributions recorded at signing. Deposits, extra mortgage payments, and renovations may be added at any time and will accrue interest at {{rate}} per annum. Recorded contributions do not change the ownership shares.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('contributions_interest_note','nb','REGISTRERTE BIDRAG','Alle beløp forrentes med {{rate}} per år fra innbetalingsdato, kapitalisert årlig. For deler av et år beregnes renten proporsjonalt per dag, og den løper frem til utbetalingsdagen. Registrerte bidrag endrer ikke eierbrøken.
Med bidrag menes engangsinnbetalinger registrert i cohab (f.eks. innskudd, ekstra nedbetaling eller oppussing) — løpende boutgifter omfattes ikke.
',1,'published'),
('contributions_interest_note','sv','REGISTRERADE BIDRAG','Samtliga belopp räknas upp med {{rate}} per år från inbetalningsdatumet, sammansatt årligen. För del av år beräknas räntan proportionerligt per dag. Räntan löper fram till utbetalningsdagen. Registrerade bidrag ändrar inte parternas ägarandelar.
Med bidrag avses engångsinbetalningar som registrerats i cohab (till exempel kontantinsats, extra amortering eller renovering). Löpande boendekostnader som mat, el och hyra omfattas inte.
',1,'published'),
('contributions_interest_note','da','REGISTREREDE BIDRAG','Alle beløb forrentes med {{rate}} per år fra indbetalingsdatoen, kapitaliseret årligt. For dele af et år beregnes renten forholdsmæssigt pr. dag, og den løber indtil udbetalingsdatoen. Registrerede bidrag ændrer ikke ejerandelen.
Med bidrag menes engangsindbetalinger registreret i cohab (f.eks. indskud, ekstra afdrag eller renovering) — løbende boligudgifter omfattes ikke.
',1,'published'),
('contributions_interest_note','fi','REKISTERÖIDYT PANOKSET','Kaikille summille lasketaan korkoa {{rate}} vuodessa maksupäivästä lähtien, vuotuisella koronkorolla. Osittaiselta vuodelta korko lasketaan suhteellisesti päivittäin, ja sitä kertyy maksupäivään asti. Rekisteröidyt panokset eivät muuta omistusosuuksia.
Panoksella tarkoitetaan cohab-sovellukseen rekisteröityjä kertamaksuja (esim. käsiraha, ylimääräinen lyhennys tai remontti) — juoksevat asumiskulut eivät kuulu mukaan.
',1,'published'),
('contributions_interest_note','de','ERFASSTE EINZAHLUNGEN','Alle Beträge werden ab dem Einzahlungsdatum mit {{rate}} p.a. verzinst, jährlich kapitalisiert. Für Teile eines Jahres werden die Zinsen anteilig pro Tag berechnet und laufen bis zum Auszahlungstag. Erfasste Einzahlungen ändern nicht die Eigentumsanteile.
Als Einzahlungen gelten einmalige, in cohab erfasste Zahlungen (z. B. Anzahlung, zusätzliche Tilgung oder Renovierung) — laufende Wohnkosten sind ausgeschlossen.
',1,'published'),
('contributions_interest_note','fr','APPORTS ENREGISTRÉS','Tous les montants sont rémunérés à {{rate}} par an à compter de la date de versement, avec capitalisation annuelle. Pour une fraction d''année, les intérêts sont calculés au prorata par jour et courent jusqu''à la date de versement final. Les apports enregistrés ne modifient pas les quotes-parts.
Par apports, on entend les versements ponctuels enregistrés dans cohab (ex. apport initial, remboursement supplémentaire ou travaux) — les dépenses courantes du logement sont exclues.
',1,'published'),
('contributions_interest_note','es','APORTACIONES REGISTRADAS','Todos los importes generan intereses al {{rate}} anual desde la fecha de pago, con capitalización anual. Para fracciones de año, el interés se calcula proporcionalmente por día y devenga hasta la fecha de pago. Las aportaciones registradas no modifican las cuotas de propiedad.
Por aportaciones se entienden pagos únicos registrados en cohab (p. ej. entrada, amortización extraordinaria o reformas) — los gastos corrientes de la vivienda quedan excluidos.
',1,'published'),
('contributions_interest_note','en','RECORDED CONTRIBUTIONS','All amounts accrue interest at {{rate}} per annum from the date of payment, compounded annually. For part of a year, interest accrues proportionally per day and runs until the payout date. Recorded contributions do not change the ownership shares.
Contributions mean one-off payments recorded in cohab (e.g. deposit, extra mortgage payment or renovation) — ongoing household costs are not included.
',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('contributions_combined_heading','nb',null,'Samlet for alle eiendeler per {{date}}',1,'published'),
('contributions_combined_heading','sv',null,'Totalt för alla tillgångar per {{date}}',1,'published'),
('contributions_combined_heading','da',null,'Samlet for alle aktiver pr. {{date}}',1,'published'),
('contributions_combined_heading','fi',null,'Yhteensä kaikista varoista {{date}}',1,'published'),
('contributions_combined_heading','de',null,'Gesamt über alle Vermögenswerte zum {{date}}',1,'published'),
('contributions_combined_heading','fr',null,'Total pour tous les actifs au {{date}}',1,'published'),
('contributions_combined_heading','es',null,'Total de todos los activos al {{date}}',1,'published'),
('contributions_combined_heading','en',null,'Combined totals across all assets as of {{date}}',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('contributions_note','nb',null,'Endelig utbetaling avhenger av tilgjengelig verdi ved oppgjør (se fordelingsrekkefølgen).',1,'published'),
('contributions_note','sv',null,'Slutlig utbetalning beror på tillgängligt värde vid uppgörelsen (se fördelningsordningen).',1,'published'),
('contributions_note','da',null,'Den endelige udbetaling afhænger af den tilgængelige værdi ved opgørelsen (se fordelingsrækkefølgen).',1,'published'),
('contributions_note','fi',null,'Lopullinen maksu riippuu selvityshetkellä käytettävissä olevasta arvosta (ks. jakojärjestys).',1,'published'),
('contributions_note','de',null,'Die endgültige Auszahlung hängt vom bei der Abwicklung verfügbaren Wert ab (siehe Verteilungsreihenfolge).',1,'published'),
('contributions_note','fr',null,'Le versement final dépend de la valeur disponible lors du règlement (voir l''ordre de répartition).',1,'published'),
('contributions_note','es',null,'El pago final depende del valor disponible en la liquidación (véase el orden de reparto).',1,'published'),
('contributions_note','en',null,'Final payout depends on the value available at settlement (see the distribution order).',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('dissolution','nb','FORDELING VED OPPHØR','Dersom samboerforholdet opphører, gjelder følgende rekkefølge:

(a) Innbetalinger tilbakebetales først. Det hver part har betalt inn — med opptjente renter ({{rate}} per år) — utbetales til vedkommende før resterende verdi fordeles.

(b) Ved underskudd. Er tilgjengelig verdi lavere enn de samlede innbetalingene, deles det som finnes forholdsmessig etter hva hver part har betalt inn.

(c) Overskudd. Eventuell restverdi etter at innbetalinger er dekket, fordeles etter registrert eierbrøk.',1,'published'),
('dissolution','sv','EKONOMISK REGLERING VID FÖRSÄLJNING, UTKÖP ELLER SEPARATION','Bestämmelserna nedan är parternas ekonomiska överenskommelse om de registrerade tillgångarna — inte ett föravtal om bodelning enligt 10 § sambolagen. De gäller vid separation (även genom en parts död), vid försäljning av en gemensam tillgång och vid inlösen. Vid inlösen räknas tillgångens marknadsvärde enligt avtalets värderingsregler i stället för en försäljningsintäkt.

Med tillgängliga intäkter avses försäljnings- eller inlösenvärdet minus lån som belastar tillgången och kostnader för försäljningen. Bankens och andra borgenärers rättigheter påverkas inte.

(a) Återbetalning först. Varje parts inbetalningar återbetalas med upplupen ränta ({{rate}} per år fram till utbetalningsdagen) innan resten fördelas.

(b) Underskott. Räcker inte intäkterna till alla inbetalningar fördelas de proportionellt efter vad var och en betalat in.

(c) Överskott. Det som återstår fördelas enligt ägarandelarna.

(d) Restskuld. Om intäkterna inte ens täcker lån och kostnader bär parterna restskulden internt efter ägarandel.',1,'published'),
('dissolution','da','FORDELING VED OPHØR','Hvis samlivsforholdet ophører, gælder følgende rækkefølge:

(a) Indbetalinger tilbagebetales først. Hvad den enkelte part har indbetalt — med påløbne renter ({{rate}} per år) — tilbagebetales til den pågældende, inden det resterende fordeles.

(b) Underskud. Hvis de tilgængelige midler er lavere end de samlede indbetalinger, fordeles det tilgængelige beløb forholdsmæssigt i forhold til, hvad hver part har indbetalt.

(c) Overskud. Et eventuelt restbeløb efter tilbagebetaling af indbetalinger fordeles efter parternes registrerede ejerandele.',1,'published'),
('dissolution','fi','OMAISUUDEN JAKO EROTESSA','Jos avoliitto päättyy, noudatetaan seuraavaa järjestystä:

(a) Panokset palautetaan ensin. Kunkin osapuolen maksamat summat — kertyneineen korkoineen ({{rate}} vuodessa) — palautetaan hänelle ennen jäljelle jäävän omaisuuden jakamista.

(b) Alijäämä. Jos käytettävissä olevat varat ovat pienempiä kuin panokset yhteensä, jaetaan ne suhteessa kunkin suorittamiin maksuihin.

(c) Ylijäämä. Mahdollinen jäljelle jäävä arvo jaetaan osapuolten rekisteröityjen omistusosuuksien mukaisesti.',1,'published'),
('dissolution','de','VERMÖGENSAUFTEILUNG BEI TRENNUNG','Im Fall der Auflösung der Partnerschaft gilt folgende Reihenfolge:

(a) Einzahlungen werden zuerst zurückerstattet. Die geleisteten Einzahlungen jeder Partei — zuzüglich aufgelaufener Zinsen ({{rate}} p.a.) — werden zurückerstattet, bevor der verbleibende Wert aufgeteilt wird.

(b) Unterdeckung. Reichen die verfügbaren Erlöse zur vollständigen Rückerstattung nicht aus, werden die verfügbaren Mittel anteilig verteilt.

(c) Überschuss. Verbleibt nach der Rückerstattung der Einzahlungen ein Restwert, wird dieser gemäß den eingetragenen Eigentumsanteilen aufgeteilt.',1,'published'),
('dissolution','fr','RÉPARTITION EN CAS DE SÉPARATION','En cas de dissolution de l''union, l''ordre suivant s''applique:

(a) Restitution des apports en premier. Les sommes versées par chaque partie — augmentées des intérêts courus ({{rate}} par an) — sont restituées avant tout partage du solde.

(b) Insuffisance. Si les fonds disponibles sont inférieurs aux apports totaux, ils sont répartis proportionnellement aux versements de chaque partie.

(c) Excédent. L''éventuel solde restant après restitution des apports est réparti selon les quotes-parts enregistrées.',1,'published'),
('dissolution','es','DISTRIBUCIÓN AL SEPARARSE','Si la convivencia termina, se aplicará el siguiente orden:

(a) Las aportaciones se devuelven primero. Lo que cada parte ha aportado — con los intereses acumulados ({{rate}} anual) — se devuelve antes de distribuir el valor restante.

(b) Déficit. Si los fondos disponibles son inferiores a las aportaciones totales, se distribuyen proporcionalmente a lo aportado por cada parte.

(c) Excedente. El saldo eventual tras la devolución de aportaciones se distribuye conforme a las cuotas de propiedad registradas.',1,'published'),
('dissolution','en','SETTLEMENT ON SEPARATION','If this arrangement ends, the following order applies:

(a) Contributions returned first. What each party has paid in — with accrued interest at {{rate}} per annum — is returned to that party before any remaining value is divided.

(b) Shortfall. If available proceeds are less than total contributions, the available amount is shared proportionally to what each party has paid in.

(c) Surplus. Any remaining value after contributions are repaid is divided according to each party''s recorded ownership percentage.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('buyout','nb','OVERTAKELSE VED OPPHØR','Dersom samboerforholdet opphører:

(a) Fortrinnsrett: Den parten med størst tinglyst eierandel har fortrinnsrett til å overta boligen. Ved lik eierandel (50/50) skal partene forsøke å bli enige skriftlig; dersom dette ikke lykkes innen 30 dager, avgjøres fortrinnsretten ved mekling eller, dersom mekling ikke fører frem, ved loddtrekning.

(b) Verdifastsettelse: Overtakelsessummen fastsettes som gjennomsnittet av to uavhengige takster — én innhentet av hver part fra godkjent takstmann.

(c) Frist: Overtakelse eller åpent salg skal gjennomføres innen 6 måneder fra den dato en av partene skriftlig varsler om opphør, eller fra den dato samlivet faktisk opphørte dersom dette kan dokumenteres.

(d) Forsinkelsesrente: Ved oversittelse av fristen beregnes forsinkelsesrente i henhold til forsinkelsesrenteloven.',1,'published'),
('buyout','sv','INLÖSENRÄTT','Om samboförhållandet upphör och parterna äger en gemensam bostad:

(a) Inlösenrätt. Den part med störst registrerad ägarandel har rätt att lösa in den andras andel. Vid lika ägarandel (50/50) ska parterna i första hand nå skriftlig överenskommelse. Lyckas detta inte inom 30 dagar avgörs inlösenrätten genom medling eller, om det misslyckas, lottdragning.

(b) Värdering. Inlösenpriset fastställs som genomsnittet av två oberoende värderingsintyg, ett inhämtat av varje part.

(c) Tidsfrist. Inlösen eller försäljning på öppna marknaden ska slutföras inom 6 månader från skriftlig uppsägning eller den dokumenterade dag samboförhållandet faktiskt upphörde.

(d) Dröjsmålsränta. Överskrids fristen ska den dröjande parten betala ränta enligt tillämplig lag.',1,'published'),
('buyout','da','OVERTAGELSESRET','Hvis samlivsforholdet ophører, og parterne ejer en fælles bolig:

(a) Overtagelsesret. Den part med den største registrerede ejerandel har ret til at overtage den andens andel. Ved ens ejerandel (50/50) skal parterne i første omgang forsøge at nå til skriftlig aftale. Lykkes dette ikke inden 30 dage, afgøres overtagelsesretten ved mægling eller, hvis dette mislykkes, lodtrækning.

(b) Vurdering. Overtagelsesprisen fastsættes som gennemsnittet af to uafhængige vurderinger, én indhentet af hver part.

(c) Tidsfrist. Overtagelse eller salg på det åbne marked skal gennemføres inden 6 måneder fra skriftlig opsigelse eller den dokumenterede dato, samlivsforholdet faktisk ophørte.

(d) Morarenter. Overskrides fristen, skal den forsinkede part betale renter i henhold til gældende lovgivning.',1,'published'),
('buyout','fi','LUNASTUSOIKEUS','Jos avoliitto päättyy ja osapuolet omistavat yhteisen asunnon:

(a) Lunastusoikeus. Suurimman omistusosuuden omaavalla osapuolella on oikeus lunastaa toisen osuus. Tasan (50/50) jaetun omistuksen tapauksessa pyritään ensin kirjalliseen sopimukseen. Ellei sopimukseen päästä 30 päivässä, lunastusoikeus ratkaistaan sovittelulla tai arvonnalla.

(b) Arvostus. Lunastushinta on kahden riippumattoman arvion keskiarvo, yksi kummankin hankkimana.

(c) Määräaika. Lunastus tai myynti on saatettava päätökseen 6 kuukauden kuluessa kirjallisesta irtisanomisesta tai dokumentoidusta päivämäärästä, jolloin avoliitto tosiasiallisesti päättyi.

(d) Viivästyskorko. Määräajan ylittyessä viivästyvä osapuoli maksaa korkoa sovellettavan lain mukaisesti.',1,'published'),
('buyout','de','VORKAUFSRECHT','Bei Auflösung der Partnerschaft und gemeinsamem Immobilieneigentum gilt:

(a) Vorkaufsrecht. Die Partei mit dem größeren eingetragenen Eigentumsanteil hat das Recht, den Anteil der anderen Partei zu übernehmen. Bei gleichen Anteilen (50/50) bemühen sich die Parteien zunächst um eine schriftliche Einigung. Scheitert dies binnen 30 Tagen, wird das Vorkaufsrecht durch Mediation oder, falls diese scheitert, durch Los entschieden.

(b) Bewertung. Der Übernahmepreis entspricht dem Durchschnitt zweier unabhängiger Gutachten, je eines pro Partei.

(c) Frist. Die Übernahme oder der Verkauf am freien Markt muss innerhalb von 6 Monaten nach schriftlicher Kündigung abgeschlossen sein.

(d) Verzugszinsen. Bei Fristüberschreitung schuldet die säumige Partei Zinsen gemäß geltendem Recht.',1,'published'),
('buyout','fr','DROIT DE PRÉEMPTION','En cas de dissolution de l''union et de copropriété immobilière:

(a) Droit de préemption. La partie détenant la quote-part la plus élevée a le droit de racheter la part de l''autre. En cas d''égalité (50/50), les parties s''efforcent d''abord de parvenir à un accord écrit; à défaut dans les 30 jours, le droit de préemption est déterminé par médiation ou, si celle-ci échoue, par tirage au sort.

(b) Évaluation. Le prix de rachat correspond à la moyenne de deux expertises indépendantes, une par partie.

(c) Délai. Le rachat ou la vente sur le marché libre doit être achevé dans les 6 mois suivant la notification écrite.

(d) Intérêts de retard. En cas de dépassement du délai, la partie défaillante doit des intérêts conformément à la loi applicable.',1,'published'),
('buyout','es','DERECHO DE ADQUISICIÓN PREFERENTE','Si la convivencia termina y las partes son copropietarias de un inmueble:

(a) Derecho preferente. La parte con mayor cuota registrada tiene derecho a adquirir la parte de la otra. En caso de igualdad (50/50), se intentará primero un acuerdo escrito; si no se alcanza en 30 días, el derecho se determina por mediación o, si fracasa, por sorteo.

(b) Valoración. El precio de adquisición es la media de dos tasaciones independientes, una por parte.

(c) Plazo. La adquisición o venta en mercado abierto debe completarse en 6 meses desde la notificación escrita.

(d) Intereses de demora. Si se supera el plazo, la parte incumplidora pagará intereses conforme a la ley aplicable.',1,'published'),
('buyout','en','BUYOUT RIGHTS AND TAKEOVER','If this arrangement ends and the parties hold a jointly owned property:

(a) Right of first refusal: The party with the greater recorded ownership share has the right to buy out the other. Where ownership is equal (50/50), the parties shall first attempt written agreement; if no agreement is reached within 30 days, the right is determined by mediation or, failing that, by coin toss or selection by a mutually agreed neutral third party.

(b) Valuation: The buyout price shall be the average of two independent licensed appraisals, one obtained by each party from a licensed appraiser.

(c) Timeline: Buyout or open-market sale shall be completed within 6 months of written notice of termination, or the documented date the arrangement ended.

(d) Interest on delay: If the deadline is missed, the delaying party shall pay interest at the maximum rate permitted by applicable law.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('disposal_consent','nb','SAMTYKKE VED SALG OG UTLEIE','Skriftlig samtykke fra begge parter kreves ved salg, utleie, pantsettelse eller annen disposisjon av felles eiendeler. Disposisjoner foretatt uten slikt samtykke kan kreves omgjort av den parten som ikke har gitt samtykke.',1,'published'),
('disposal_consent','sv','SAMTYCKESKRAV','Ingen av parterna får sälja, hyra ut, pantsätta eller på annat sätt disponera gemensamma tillgångar utan den andra partens skriftliga samtycke. Transaktioner genomförda utan sådant samtycke kan ogiltigförklaras av den part som inte lämnat samtycke.',1,'published'),
('disposal_consent','da','DISPOSITIONSSAMTYKKE','Ingen af parterne må sælge, udleje, pantsætte eller på anden måde disponere over fælles aktiver uden den anden parts skriftlige samtykke. Transaktioner gennemført uden sådant samtycke kan gøres ugyldige af den part, der ikke har givet samtykke.',1,'published'),
('disposal_consent','fi','LUOVUTUSSUOSTUMUS','Kumpikaan osapuoli ei saa myydä, vuokrata, pantata tai muutoin luovuttaa yhteistä omaisuutta ilman toisen kirjallista suostumusta. Ilman suostumusta tehdyt luovutukset voidaan julistaa pätemättömiksi.',1,'published'),
('disposal_consent','de','VERFÜGUNGSZUSTIMMUNG','Keine Partei darf gemeinsame Vermögenswerte ohne schriftliche Zustimmung der anderen verkaufen, vermieten, verpfänden oder anderweitig veräußern. Ohne Zustimmung vorgenommene Verfügungen können von der nicht zustimmenden Partei angefochten werden.',1,'published'),
('disposal_consent','fr','CONSENTEMENT AUX CESSIONS','Aucune partie ne peut vendre, louer, hypothéquer ou autrement disposer des actifs communs sans le consentement écrit préalable de l''autre. Toute opération effectuée sans ce consentement peut être annulée à la demande de la partie lésée.',1,'published'),
('disposal_consent','es','CONSENTIMIENTO PARA DISPOSICIÓN','Ninguna parte podrá vender, arrendar, hipotecar o disponer de los activos compartidos sin el consentimiento escrito previo de la otra. Las operaciones realizadas sin dicho consentimiento podrán ser impugnadas por la parte que no lo haya otorgado.',1,'published'),
('disposal_consent','en','JOINT DISPOSAL CONSENT','Neither party may sell, lease, mortgage, pledge, or otherwise dispose of any jointly held asset without the prior written consent of both parties. Any transaction entered into without such consent shall be voidable at the non-consenting party''s election.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('dispute','nb','TVISTELØSNING','Eventuelle tvister skal først søkes løst gjennom mekling. Dersom mekling ikke fører frem innen 60 dager fra første meklingsmøte, kan saken bringes inn for ordinære domstoler i den jurisdiksjonen der den primære felles eiendelen befinner seg.',1,'published'),
('dispute','sv','TVISTELÖSNING','Tvister som uppstår till följd av detta avtal ska i första hand lösas genom medling. Om medlingen inte löser tvisten inom 60 dagar kan endera parten väcka talan vid allmän domstol.',1,'published'),
('dispute','da','TVISTLØSNING','Tvister vedrørende denne aftale skal i første omgang søges løst ved mægling. Fører mæglingen ikke til en løsning inden 60 dage, kan enhver af parterne indbringe sagen for de ordinære domstole.',1,'published'),
('dispute','fi','RIIDANRATKAISU','Sopimuksesta johtuvat riidat pyritään ensisijaisesti ratkaisemaan sovittelulla. Jos sovittelu ei tuota ratkaisua 60 päivässä, kumpi tahansa osapuoli voi saattaa asian toimivaltaisen käräjäoikeuden käsiteltäväksi.',1,'published'),
('dispute','de','STREITBEILEGUNG','Streitigkeiten aus oder im Zusammenhang mit diesem Vertrag werden zunächst durch Mediation beigelegt. Führt die Mediation binnen 60 Tagen zu keiner Lösung, können die Parteien die zuständigen ordentlichen Gerichte anrufen.',1,'published'),
('dispute','fr','RÉSOLUTION DES DIFFÉRENDS','Tout différend découlant de la présente convention sera d''abord soumis à médiation. Si aucune solution n''est trouvée dans les 60 jours, l''une ou l''autre partie peut saisir les juridictions judiciaires compétentes.',1,'published'),
('dispute','es','RESOLUCIÓN DE DISPUTAS','Cualquier disputa derivada de este contrato se someterá primero a mediación. Si no se resuelve en 60 días, cualquiera de las partes podrá acudir a los tribunales competentes.',1,'published'),
('dispute','en','DISPUTE RESOLUTION','Any dispute arising from or relating to this agreement shall first be referred to mediation. If mediation does not resolve the dispute within 60 days, either party may bring proceedings before the courts of the jurisdiction in which the primary shared asset is located.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('debt','nb','PERSONLIG GJELDSANSVAR','Gjeld og andre finansielle forpliktelser som en part har pådratt seg — enten før eller under samboerforholdet — er utelukkende den partens eget ansvar. Den andre parten er ikke ansvarlig for slik gjeld overfor kreditorer eller tredjeparter, med mindre begge parter uttrykkelig har avtalt delt ansvar skriftlig.',1,'published'),
('debt','sv','PERSONLIGT SKULDANSVAR','Skulder och andra finansiella förpliktelser som en part ådragit sig — oavsett om det skedde före eller under samboförhållandet — är uteslutande den partens eget ansvar. Den andra parten är inte ansvarig för sådana skulder gentemot fordringsägare eller tredje parter, såvida inte båda parter uttryckligen har avtalat om delat ansvar skriftligen.',1,'published'),
('debt','da','PERSONLIGT GÆLDSANSVAR','Gæld og andre finansielle forpligtelser, som en part har pådraget sig — hvad enten det er sket før eller under samlivsforholdet — er udelukkende den pågældendes eget ansvar. Den anden part er ikke ansvarlig for sådan gæld over for kreditorer eller tredjeparter, medmindre begge parter udtrykkeligt har aftalt delt ansvar skriftligt.',1,'published'),
('debt','fi','HENKILÖKOHTAINEN VELKAVASTUU','Velat ja muut taloudelliset velvoitteet, jotka osapuoli on ottanut — ennen avoliittoa tai sen aikana — ovat yksinomaan kyseisen osapuolen omaa vastuuta. Toinen osapuoli ei ole vastuussa tällaisista veloista velkojille tai kolmansille osapuolille, ellei molemmat osapuolet ole nimenomaisesti sopineet yhteisvastuusta kirjallisesti.',1,'published'),
('debt','de','PERSÖNLICHE SCHULDENHAFTUNG','Schulden und andere finanzielle Verpflichtungen, die eine Partei eingegangen ist — ob vor oder während dieser Partnerschaft — liegen ausschließlich in der Verantwortung dieser Partei. Die andere Partei haftet nicht für solche Schulden gegenüber Gläubigern oder Dritten, es sei denn, beide Parteien haben ausdrücklich eine gemeinsame Haftung schriftlich vereinbart.',1,'published'),
('debt','fr','RESPONSABILITÉ PERSONNELLE DES DETTES','Les dettes et autres obligations financières contractées par une partie — avant ou pendant cette union — relèvent exclusivement de la responsabilité de cette partie. L''autre partie n''est pas responsable de ces dettes envers les créanciers ou les tiers, sauf si les deux parties ont expressément convenu d''une responsabilité partagée par écrit.',1,'published'),
('debt','es','RESPONSABILIDAD PERSONAL POR DEUDAS','Las deudas y otras obligaciones financieras contraídas por una parte — antes o durante esta convivencia — son responsabilidad exclusiva de dicha parte. La otra parte no es responsable de dichas deudas ante acreedores o terceros, salvo que ambas partes hayan acordado expresamente una responsabilidad compartida por escrito.',1,'published'),
('debt','en','PERSONAL DEBT RESPONSIBILITY','Debts and other financial obligations incurred by a party — whether before or during this arrangement — are solely that party''s responsibility. The other party is not liable for such debts to creditors or third parties, unless both parties have expressly agreed to shared liability in writing.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('amendments','nb','ENDRINGER AV AVTALEN','Denne avtalen kan ved enighet endres. Alle endringer må dokumenteres og signeres av begge parter for å være gyldige.

Denne avtalen gjelder så lenge partene er samboere. Den opphører automatisk dersom partene inngår ekteskap eller samboerforholdet opphører. Alle forpliktelser eller krav som har oppstått før opphør, skal fortsatt gjøres opp i henhold til avtalen.',1,'published'),
('amendments','sv','ÄNDRINGAR','Detta avtal kan ändras när som helst med båda parters skriftliga samtycke. Alla ändringar ska dokumenteras och undertecknas av båda parter för att vara giltiga.

Detta avtal gäller så länge parterna gemensamt innehar de registrerade tillgångarna. Alla skyldigheter eller anspråk som uppkommit före avtalets upphörande ska regleras i enlighet med avtalet.',1,'published'),
('amendments','da','ÆNDRINGER','Denne aftale kan ændres til enhver tid med begge parters skriftlige samtykke. Alle ændringer skal dokumenteres og underskrives af begge parter for at være gyldige.

Denne aftale gælder, så længe parterne i fællesskab ejer de registrerede aktiver. Alle forpligtelser eller krav opstået inden aftalens ophør reguleres i overensstemmelse med aftalen.',1,'published'),
('amendments','fi','MUUTOKSET','Tätä sopimusta voidaan muuttaa milloin tahansa molempien osapuolten kirjallisella suostumuksella. Kaikki muutokset on dokumentoitava ja molempien allekirjoitettava.

Sopimus on voimassa niin kauan kuin osapuolet omistavat yhdessä rekisteröidyt varat. Kaikki ennen sopimuksen päättymistä syntyneet velvoitteet ratkaistaan sopimuksen mukaisesti.',1,'published'),
('amendments','de','ÄNDERUNGEN','Dieser Vertrag kann jederzeit mit schriftlicher Zustimmung beider Parteien geändert werden. Alle Änderungen sind zu dokumentieren und von beiden zu unterzeichnen.

Der Vertrag gilt, solange die Parteien gemeinsam die eingetragenen Vermögenswerte halten. Alle vor Vertragsende entstandenen Verpflichtungen werden vertragsgemäß abgewickelt.',1,'published'),
('amendments','fr','MODIFICATIONS','La présente convention peut être modifiée à tout moment avec le consentement écrit des deux parties. Toute modification doit être documentée et signée par les deux parties.

La convention reste en vigueur tant que les parties détiennent en commun les actifs enregistrés. Toutes les obligations nées avant son terme sont réglées conformément à ses stipulations.',1,'published'),
('amendments','es','MODIFICACIONES','Este contrato puede modificarse en cualquier momento con el consentimiento escrito de ambas partes. Toda modificación debe documentarse y firmarse.

El contrato estará vigente mientras las partes posean conjuntamente los activos registrados. Todas las obligaciones surgidas antes de su terminación se regularán conforme a él.',1,'published'),
('amendments','en','AMENDMENTS','This agreement may be amended at any time by the written consent of both parties. All amendments must be documented and signed by both parties to be valid.

This agreement remains in force for as long as the parties jointly hold the assets recorded herein. All obligations or claims arising before termination shall continue to be settled in accordance with this agreement.',1,'published')
on conflict (clause_key, language, version) do nothing;

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('governing_law','nb','LOVVALG','Denne avtalen reguleres av norsk lov. Tvister som ikke løses mellom partene, bringes inn for de ordinære domstoler.',1,'published'),
('governing_law','sv','TILLÄMPLIG LAG','Detta avtal regleras av svensk rätt. Tvister som inte kan lösas mellan parterna hänskjuts till allmän domstol.',1,'published'),
('governing_law','da','GOVERNING LAW','Denne aftale er underlagt dansk ret. Tvister, der ikke løses i mindelighed, indbringes for de ordinære domstole.',1,'published'),
('governing_law','fi','SOVELLETTAVA LAKI','Tähän sopimukseen sovelletaan Suomen lakia. Osapuolten väliset riidat, joita ei voida ratkaista sovinnollisesti, saatetaan toimivaltaisen käräjäoikeuden käsiteltäväksi.',1,'published'),
('governing_law','de','ANWENDBARES RECHT','Dieser Vertrag unterliegt deutschem Recht. Streitigkeiten, die nicht gütlich beigelegt werden können, werden vor den zuständigen ordentlichen Gerichten ausgetragen.',1,'published'),
('governing_law','fr','LOI APPLICABLE','La présente convention est régie par le droit français. Tout différend qui ne peut être résolu à l''amiable est soumis aux juridictions judiciaires compétentes.',1,'published'),
('governing_law','es','LEY APLICABLE','Este contrato se rige por la legislación española. Las disputas que no puedan resolverse amistosamente se someterán a los tribunales competentes de la jurisdicción donde se encuentre el activo principal compartido.',1,'published'),
('governing_law','en','GOVERNING LAW','This agreement is governed by the law of England and Wales. Any disputes that cannot be resolved between the parties shall be referred to the courts of England and Wales.',1,'published')
on conflict (clause_key, language, version) do nothing;
