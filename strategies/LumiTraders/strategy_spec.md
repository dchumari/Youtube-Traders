# LumiTraders — Strategy Specification & MQL5 Logic

## 1. Strategy Overview
This Expert Advisor implements the signature trading models of **Dasha (@LumiTraders)**, built for high-precision institutional execution on Gold (`XAUUSD`) and Nasdaq (`NQ` / `US100`).

## 2. Integrated Strategy Models
### Model 1:  ICT 2022 Mentorship (M15 DOL -> M5/M1 MSS with Displacement -> 50% FVG Re-entry)
- **Entry Rules**: Defined in `LumiTraders_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with New York AM Session (09:15 – 11:30 AM EST).
### Model 2:  NY AM Silver Bullet Scalper (10
- **Entry Rules**: Defined in `LumiTraders_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with New York AM Session (09:15 – 11:30 AM EST).
### Model 3:  Previous Day High/Low (PDH/PDL) Purge & Revert
- **Entry Rules**: Defined in `LumiTraders_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with New York AM Session (09:15 – 11:30 AM EST).
