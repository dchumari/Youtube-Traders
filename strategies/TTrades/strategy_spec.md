# TTrades — Strategy Specification & MQL5 Logic

## 1. Strategy Overview
This Expert Advisor implements the signature trading models of **TTrades (@TTrades)**, built for high-precision institutional execution on Gold (`XAUUSD`) and Nasdaq (`NQ` / `US100`).

## 2. Integrated Strategy Models
### Model 1:  TTrades Fractal Model (TTFM - HTF POI -> MTF MSS -> LTF 3-Candle Fractal)
- **Entry Rules**: Defined in `TTrades_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with New York Open & Session Overlaps.
### Model 2:  Daily Bias & Draw on Liquidity (DOL) Expansion Engine
- **Entry Rules**: Defined in `TTrades_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with New York Open & Session Overlaps.
### Model 3:  Liquidity Void Filling & Mitigation
- **Entry Rules**: Defined in `TTrades_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with New York Open & Session Overlaps.
