# cohab

> Working name. Couple equity tracker — **track who owns what, who contributed
> what, and what's fair if you split or rebalance ownership.**
>
> _Splitwise tracks what you spent. cohab tracks what you own._

This is the **tool layer** of [Samboappen](https://github.com/Hjard1/samboappen)
— the asset/contribution ledger, settlement engine, and fairness calculators —
rebuilt as a standalone, international app, decoupled from the jurisdiction-locked
contract & signing layer. The Norwegian Samboappen continues unchanged as the
combined contract + tool product in its home market.

Full product direction: [`docs/PRODUCT-SPEC.md`](docs/PRODUCT-SPEC.md).

## What it is (and isn't)

- **Is:** a long-horizon equity & ownership ledger for couples — contributions
  with interest over time, and a settlement engine ("if we sell / split today,
  who gets what").
- **Is not:** an expense splitter. That market is commoditized; expense tracking
  is a supporting feature here, never the headline.

## Stack

- Vite + React 19 + TypeScript
- Tailwind CSS v4
- (Planned) Supabase backend, Capacitor for iOS/Android — mirroring Samboappen
  so engine logic can be copied over.

## Getting started

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # type-check + production build
```

## Decoupling from Samboappen — the three Norway anchors to replace

When porting engine logic from Samboappen, swap out these hardcoded Norwegian
assumptions:

1. **Interest rate** — Norges Bank key rate + 1% → user-chosen rate with a neutral
   default (keep annual capitalization as the method).
2. **Currency** — hardcoded `kr` → multi-currency per household.
3. **Tax** — drop the Norwegian gross→net tax engine; take net income as input.

Personal ID / BankID / e-signing are **not** needed here — they belonged to the
contract layer and are intentionally left out.

## MVP scope (v1)

In: household + partner invite · asset/contribution ledger · generic interest
accrual · settlement engine (hero) · the three calculators (free, ungated) ·
expense reconciliation (support) · multi-currency · English base locale.

Out: legal contract / document generation · BankID/e-signing/ID · tax engine ·
will / power of attorney · country-specific legal content.

## First target market

UK (England & Wales) beachhead — no "common law marriage", rising cohabitation,
strong property culture, single language & legal frame. Then IE → AU/NZ → CA/US.
