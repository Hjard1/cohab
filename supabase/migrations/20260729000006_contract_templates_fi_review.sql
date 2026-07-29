-- Finland review fixes (fi templates only):
--  * purpose v3: drop unverifiable Maanmittauslaitos claim (also grammatically
--    wrong inflection); honest lainhuuto pointer for real estate; updates
--    require a new signed version.
--  * assets_intro v2: "omistavat yhdessä" is wrong for assets recorded 100/0.
--  * dissolution v3: full improved structure -- available-value definition,
--    sale/buyout triggers, creditor carve-out, (d) residual debt.
--  * buyout v2: lottery -> neutral third party; interest -> korkolaki.
--  * disposal_consent v2: cannot void bona fide third-party acquisitions --
--    state as breach between the parties.

insert into public.contract_templates (clause_key, language, title, body, version, status) values
('purpose', 'fi', 'SOPIMUKSEN TARKOITUS',
 'Tämä sopimus vahvistaa osapuolten ilmoittamat omistusosuudet yhteisiin varoihin ja dokumentoi kummankin maksamat panokset.{{dissolution}} Sopimus ei itsessään luo uusia omistusoikeuksia; kiinteistöjen osalta omistus on syytä hakea merkittäväksi lainhuuto- ja kirjaamisrekisteriin, jotta se sitoo myös kolmansia osapuolia. Osapuolet sitoutuvat päivittämään sopimuksen tarvittaessa uudella, molempien allekirjoittamalla versiolla.',
 3, 'published'),
('assets_intro', 'fi', 'REKISTERÖIDYT VARAT JA OMISTUSOSUUDET',
 'Osapuolet ovat rekisteröineet seuraavat varat cohab-sovellukseen allekirjoitushetkellä ja vahvistavat ilmoitetut omistusosuudet:',
 2, 'published'),
('dissolution', 'fi', 'TALOUDELLINEN JÄRJESTELY MYYNNISSÄ, LUNASTUKSESSA TAI EROSSA',
 'Seuraavat määräykset ovat osapuolten oma sopimus rekisteröidyistä varoista. Niitä sovelletaan, kun avoliitto päättyy, kun yhteinen omaisuus myydään tai kun osapuoli lunastaa toisen osuuden. Lunastuksessa käytetään myyntihinnan sijaan omaisuuden tämän sopimuksen arvostussääntöjen mukaisesti määritettyä markkina-arvoa.

Käytettävissä olevalla arvolla tarkoitetaan omaisuuden myynti- tai lunastusarvoa, josta vähennetään omaisuutta kuormittavat lainat ja kohtuulliset myyntikulut. Sopimus ei vaikuta pankkien tai muiden velkojien oikeuksiin.

(a) Panokset palautetaan ensin. Kunkin osapuolen maksamat summat — kertyneineen korkoineen ({{rate}} vuodessa maksupäivään asti) — palautetaan hänelle ennen jäljelle jäävän arvon jakamista.

(b) Alijäämä. Jos käytettävissä oleva arvo on pienempi kuin panokset yhteensä, se jaetaan suhteessa kunkin suorittamiin maksuihin.

(c) Ylijäämä. Mahdollinen panosten palautuksen jälkeen jäävä arvo jaetaan osapuolten rekisteröityjen omistusosuuksien mukaisesti.

(d) Jäännösvelka. Jos arvo ei kata edes lainoja ja myyntikuluja, osapuolet kantavat jäljelle jäävän velan keskenään omistusosuuksiensa suhteessa.

Tämä sopimus ei ole testamentti eikä sääntele perintöä. Jos avoliitto päättyy osapuolen kuolemaan, sovelletaan perintölainsäädäntöä — osapuolia kehotetaan tekemään testamentit.',
 3, 'published'),
('buyout', 'fi', 'LUNASTUSOIKEUS',
 'Jos avoliitto päättyy ja osapuolet omistavat yhteisen asunnon:

(a) Lunastusoikeus. Suurimman omistusosuuden omaavalla osapuolella on oikeus lunastaa toisen osuus. Jos omistusosuudet ovat yhtä suuret (50/50), osapuolet pyrkivät ensin kirjalliseen sopimukseen. Ellei sopimukseen päästä 30 päivässä, lunastusoikeus ratkaistaan sovittelulla tai, jos se ei johda tulokseen, osapuolten yhdessä nimittämän puolueettoman kolmannen osapuolen päätöksellä.

(b) Arvostus. Lunastushinta on kahden riippumattoman arvion keskiarvo, yksi kummankin hankkimana.

(c) Määräaika. Lunastus tai myynti vapailla markkinoilla on saatettava päätökseen 6 kuukauden kuluessa kirjallisesta irtisanomisesta tai dokumentoidusta päivämäärästä, jolloin avoliitto tosiasiallisesti päättyi.

(d) Viivästyskorko. Määräajan ylittyessä viivästyvä osapuoli maksaa viivästyskorkoa korkolain mukaisesti.',
 2, 'published'),
('disposal_consent', 'fi', 'LUOVUTUSSUOSTUMUS',
 'Kumpikaan osapuoli ei saa myydä, vuokrata, pantata tai muutoin luovuttaa yhteistä omaisuutta ilman toisen kirjallista suostumusta. Ilman suostumusta tehty luovutus on osapuolten välillä sopimusrikkomus; hyvässä uskossa olevan kolmannen osapuolen oikeudet säilyvät.',
 2, 'published')
on conflict (clause_key, language, version) do nothing;
