# DodgysDD — Strategy Specification & MQL5 Logic

## 1. Strategy Overview
This Expert Advisor implements the signature trading models of **Dodgy (@DodgysDD)**, built for high-precision institutional execution on Gold (`XAUUSD`) and Nasdaq (`NQ` / `US100`).

## 2. Integrated Strategy Models
### Model 1:  Signature Inversion FVG (iFVG) Engine
- **Entry Rules**: Defined in `DodgysDD_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with NY Open & High-Impact Macro Releases (CPI, NFP, FOMC).
### Model 2:  High-Impact Macro News Manipulation Model (Judas Wick -> Displacement)
- **Entry Rules**: Defined in `DodgysDD_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with NY Open & High-Impact Macro Releases (CPI, NFP, FOMC).
### Model 3:  Internal-to-External Range Liquidity (IRL -> ERL) Run
- **Entry Rules**: Defined in `DodgysDD_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with NY Open & High-Impact Macro Releases (CPI, NFP, FOMC).
