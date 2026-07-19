# Cohab — Developer Notes

## Figma

- **File key:** `OzXkrPcWGPfaPyjoblmhSG`
- **Page:** Motion (id: `54:3`)

| Screen | Node ID |
|---|---|
| Welcome | `2006:5298` |
| Select country | `2010:5296` |
| Add partner | `2010:5344` |
| Cohab option | `2010:5377` |
| Add asset | `2006:5316` |
| Dashboard | `2006:5355` |
| Agreement | `2010:5409` |
| Asset detail | `2006:5399` |
| Calculators | `2006:5440` |

## Project

- **Stack:** Swift 6 / SwiftUI, iOS 17+, XcodeGen (`project.yml` er kilde til sannhet)
- **Bundle ID:** `com.hjard.cohab`
- **Generate project:** `xcodegen generate`

## Architecture

- `Cohab/Models/Models.swift` — datamodeller og fargetoken (`Color.cohGreen`)
- `Cohab/Views/` — alle SwiftUI-views
- `docs/PRODUCT-SPEC.md` — produktspesifikasjon

## Signing (DocuSeal + BankID)

- **DocuSeal** (gratis, maks 10 signeringer/mnd per household): `docuseal-submit` /
  `docuseal-webhook` edge functions, sporing i `cohab_docuseal_submissions`.
  Grensen håndheves i `docuseal-submit` (429 `DOCUSEAL_MONTHLY_LIMIT`).
- **BankID via DealBuilder** (kun `DealBuilderService.supportedCountries`, p.t. NO):
  `dealbuilder-submit` / `dealbuilder-status` / `dealbuilder-webhook` edge functions,
  sporing i `cohab_dealbuilder_cases`. 1 signering inkludert per household (totalt,
  ingen måneds-reset); deretter 1 kreditt per signering (`cohab_household_credits`,
  RPC `cohab_add_bankid_credit`, consumable IAP `com.hjard.cohab.bankid_extra`, 125 NOK).
  Kredittsjekk i `dealbuilder-submit` (402 `BANKID_CREDITS_EXHAUSTED`).
- Secrets (Supabase project `yvckcujoopwqjjnoxsze`): `DEALBUILDER_API_KEY_P`,
  `DEALBUILDER_TEMPLATE_ID_P`, `DEALBUILDER_SENDER_EMAIL_P`, `DEALBUILDER_WEBHOOK_SECRET`.
  Webhook-URL i DealBuilder-dashboard:
  `https://yvckcujoopwqjjnoxsze.supabase.co/functions/v1/dealbuilder-webhook?token=<DEALBUILDER_WEBHOOK_SECRET>`

## Design tokens (Direction C — Warm Editorial)

```
Background:  #FAF9F6  (cream)
Text:        #211E1C  (ink)
Accent:      #148F5C  (muted green)
Card:        #FFFFFF  (white)
```
