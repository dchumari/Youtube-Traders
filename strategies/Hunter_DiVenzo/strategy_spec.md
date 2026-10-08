# Hunter_DiVenzo — Strategy Specification & MQL5 Logic

## 1. Strategy Overview
This Expert Advisor implements the signature trading models of **Hunter DiVenzo (@hunterdivenzo / Wayond Live)**, built for high-precision institutional execution on Gold (`XAUUSD`) and Nasdaq (`NQ` / `US100`).

## 2. Integrated Strategy Models
### Model 1:  NY Open 30-Minute Volatility Sweep (09
- **Entry Rules**: Defined in `Hunter_DiVenzo_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Daily New York Morning Session (08:30 – 11:30 AM EST).
### Model 2:  Volume-Confirmed Order Block Retest (>1.25x Volume MA)
- **Entry Rules**: Defined in `Hunter_DiVenzo_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Daily New York Morning Session (08:30 – 11:30 AM EST).
### Model 3:  Trend Continuation FVG Ladder
- **Entry Rules**: Defined in `Hunter_DiVenzo_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Daily New York Morning Session (08:30 – 11:30 AM EST).
