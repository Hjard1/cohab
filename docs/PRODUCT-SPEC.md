# Produkt- og posisjoneringsspec — Internasjonal par-økonomi-app

Status: utkast v1 · Eier: Fredrik (Hjard AS) · Avledet av Samboappen-verktøylaget

> Denne appen er **verktøylaget** fra Samboappen (eiendeler/bidrag, oppgjørsmotor,
> kalkulatorer) løsrevet fra det juridisk låste kontrakt-/signeringslaget, bygget
> som en frittstående internasjonal app fra bunnen. Den norske Samboappen lever
> videre uendret som kombinert kontrakt + verktøy i sitt hjemmemarked.

---

## 1. Én setning

Den økonomiske infrastrukturen for par som eier ting sammen uten å være gift —
hold styr på hvem som eier hva, hvem som har bidratt med hva, og hva som er
rettferdig hvis dere skiller lag eller vil endre eierbrøk.

## 2. Hva appen ER og IKKE er

**ER:** et langsiktig egenkapital- og eierskaps-regnskap for par. Hjertet er
oppgjørsmotoren: «hvis vi selger / går fra hverandre i dag, hvem får hva — med
renter på bidrag og riktig eierbrøk».

**ER IKKE:** en utgiftsdeler. Splitwise og 20 andre eier middagsregningen. Det er
et mettet commodity-marked. Vi rører det kun som støttefunksjon.

> Posisjoneringslinje: **«Splitwise sporer hva dere brukte. [App] sporer hva dere eier.»**

## 3. Målbruker og øyeblikket

**Primær:** ugifte par som co-eier (eller skal til å co-eie) betydelige eiendeler
— først og fremst bolig — i land der samboere mangler automatisk juridisk/økonomisk
vern. Spesielt par med ulik inntekt eller ulike innskudd, som vil ha et rettferdig
system uten å føle at de «mistenker» hverandre.

**Adopsjonsøyeblikket (wedgen):** flytte sammen / kjøpe bolig sammen / én legger
mer penger i en felles eiendel. Den akutte smerten: «vi er ikke 50/50 på dette —
hvordan holder vi det rettferdig, og hva skjer hvis vi går fra hverandre?»

**Sekundær TAM (ikke led med den, men den finnes):** venner/søsken som kjøper bolig
sammen. Co-eierskap er bredere enn romantikk — en naturlig utvidelse senere.

## 4. Posisjonering og kategori

- **Kategori vi prøver å eie:** «couple equity» / delt eierskap — ikke «budget»
  eller «expense split».
- **Differensiering:** egenkapital og oppgjør *over tid*. Ingen andre lar deg føre
  bidrag med renteberegning over år og regne ut et rettferdig oppgjør/rebalansering.
- **Mot hvem:** Splitwise/budsjettapper (feil kategori — vi er over dem, ikke ved
  siden av), regneark (det folk gjør i dag — feilbarlig og ikke delt), advokat
  (dyrt, engangs, ingen løpende oppfølging).
- **Tone:** ikke selg på «når dere slår opp» (deprimerende). Selg på rettferdighet,
  trygghet og åpenhet — «vit at det er rettferdig, så slipper dere å krangle om det».

## 5. MVP-scope (v1)

**Med i v1:**
- Onboarding: opprett felles «husholdning», inviter partner
- Eiendels- og bidragsregister: bolig + eierbrøk, egenkapitalbidrag (innskudd,
  ekstra nedbetalinger, oppussing, arv osv.) med datoer
- Renteberegning på bidrag: **generisk, brukervalgt rente** med fornuftig default
  (IKKE Norges Bank styringsrente)
- Utgiftsavstemming: hvem-betalte-hva på felles kostnader (støtte, ikke overskrift)
- **Oppgjørsmotor (hero-funksjonen):** «hvis vi selger/går fra hverandre i dag —
  hvem får hva», med bidrag tilbakebetalt med rente før resten fordeles på eierbrøk
- Kalkulatorer (gratis, ugated — acquisition): eierandelskalkulator,
  inntektsbasert utgiftsdeling (netto-inntekt som input), rebalanseringskalkulator
- Flervaluta
- Engelsk som base-locale

**Eksplisitt UTE av v1:**
- Den juridiske kontrakten / all dokumentgenerering (det låste laget — blir i NO-appen)
- BankID / e-signering / personnummer/ID
- Skattemotor brutto→netto (bruk netto-inntekt som input internasjonalt)
- Testament, fremtidsfullmakt
- Landsspesifikt juridisk innhold

## 6. De tre Norge-ankrene — håndtering på produktnivå

1. **Renteformel:** fra «Norges Bank styringsrente + 1 %, kapitalisert 31.12» →
   brukervalgt årlig rente med en nøytral default. Behold årlig kapitalisering som
   metode (den er ikke jurisdiksjonsbundet, bare rentekilden er det).
2. **Valuta:** fjern hardkodet «kr» → flervaluta per husholdning.
3. **Skatt:** dropp den norske 2024-skattemotoren internasjonalt; inntektskalkulator
   tar netto-inntekt direkte. (Skattemotoren kan bli en NO-only bekvemmelighet senere.)

Personnummer/BankID/signering trengs ikke — de hørte til kontraktlaget og er allerede
utelatt. Det fjerner den tyngste jurisdiksjonsbyrden gratis.

## 7. Monetisering

- **Gratis (acquisition/SEO):** alle kalkulatorer, ugated. Evt. én eiendel / read-only ledger.
- **Betalt (abonnement):** live fler-eiendels-ledger, renteberegning over tid,
  oppgjørsrapporter, partner-samarbeid, eksport.
- **Hvorfor abonnement, ikke engangspris:** ledgerens verdi er longitudinell — den
  vokser over år. Engangspris passer kontrakten (NO), abonnement passer verktøyet,
  og det gir den løpende inntekten engangsmodellen mangler.
- **Prisretning (verifiseres):** ~£4–7/mnd eller ~£39–49/år per husholdning.

## 8. Navn

«Samboappen» oversettes ikke. Kriterier for ny merkevare:
- fungerer på engelsk, .com-domene tilgjengelig, varemerke-sjekkes
- antyder delt eierskap / rettferdighet / sammen — IKKE «cohabitation contract»
- kort, uttalbart i flere språk

Retning (ikke endelig — domene/varemerke må sjekkes): Evenly, Fairshare, Sharebase,
Coown, Equita, Halvsies. Naming er en egen øvelse; ikke blokker spec på den.

## 9. Målmarked-sekvensering

Led med engelskspråklige, svakt-samboervern, høy-samboerandel, høy-boligverdi-markeder:

1. **UK (England & Wales) — beachhead.** «Common law marriage» er en myte, samboerskap
   øker raskt, sterk boligkultur, ett språk, én juridisk ramme, stort marked.
2. **Irland** — likt UK.
3. **Australia / New Zealand** — høy samboerandel, boligfokus. (NB: AU har «de facto
   relationship»-lov som gir noe vern — mykere gap, men rettferdighetsverdien holder.)
4. **Canada / USA** — store, men fragmenterte (provins/delstat). Senere.

Engelsk blir base-locale uansett, så UK-først koster ingen ekstra lokalisering.

## 10. Moat og risiko

**Moat:** oppgjørs-/egenkapitalmotoren + datalåsing (år med bidragshistorikk →
byttekostnaden vokser over tid).

**Risiko:**
1. Posisjonerings-bleed inn i utgiftsdeling → commodity-død. (Disiplin på messaging.)
2. Lav frekvens utenom kjøp-bolig-øyeblikket → acquisition-timing-problem.
3. Gapet varierer per land (AU de facto-lov mykner det). Valider per marked.
4. Tillit — sensitiv økonomi- + relasjonsdata.
5. «Hva hvis vi slår opp» er nedslående å markedsføre → ram inn som rettferdighet/trygghet.

## 11. Hva v1 MÅ bevise

Kjernehypotesen som er utestet: **at folk adopterer verktøyet UTEN kontrakten som wedge.**
I Norge dro kontrakten trafikken. Internasjonalt må kjøp-bolig-øyeblikket + kalkulatorene
gjøre den jobben.

Metrikker:
- **Activation:** opprett husholdning + registrer første eiendel
- **Retention:** kommer tilbake etter 30/90 dager
- **Willingness to pay:** konverterer til abonnement på ledger/oppgjør

## 12. Utsatte beslutninger

- Endelig navn/domene/varemerke
- Eksakt første marked (UK er anbefaling)
- Default rentemodell (flat default vs brukervalgt vs sentralbank-feed per land)
- Eksakt prispunkt
- Støtte ikke-romantiske co-eiere i v1 (anbefaling: nei, men design så det ikke utelukkes)
