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

## Design tokens (Direction C — Warm Editorial)

```
Background:  #FAF9F6  (cream)
Text:        #211E1C  (ink)
Accent:      #148F5C  (muted green)
Card:        #FFFFFF  (white)
```
