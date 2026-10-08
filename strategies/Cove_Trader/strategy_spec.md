# Cove_Trader — Strategy Specification & MQL5 Logic

## 1. Strategy Overview
This Expert Advisor implements the signature trading models of **Cove (@covetrader)**, built for high-precision institutional execution on Gold (`XAUUSD`) and Nasdaq (`NQ` / `US100`).

## 2. Integrated Strategy Models
### Model 1:  Inversion Fair Value Gap (iFVG) Momentum Breakout
- **Entry Rules**: Defined in `Cove_Trader_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Twice Daily: NY AM (09:30 AM – 12:00 PM EST) & NY PM (01:30 – 04:00 PM EST).
### Model 2:  Opening Range (9
- **Entry Rules**: Defined in `Cove_Trader_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Twice Daily: NY AM (09:30 AM – 12:00 PM EST) & NY PM (01:30 – 04:00 PM EST).
### Model 3:  NY PM Session Equilibrium Model
- **Entry Rules**: Defined in `Cove_Trader_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Twice Daily: NY AM (09:30 AM – 12:00 PM EST) & NY PM (01:30 – 04:00 PM EST).
