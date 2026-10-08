# Tanja_Trades — Strategy Specification & MQL5 Logic

## 1. Strategy Overview
This Expert Advisor implements the signature trading models of **Tanja (@TanjaTrades)**, built for high-precision institutional execution on Gold (`XAUUSD`) and Nasdaq (`NQ` / `US100`).

## 2. Integrated Strategy Models
### Model 1:  Pre-Market Range Judas Sweep (09
- **Entry Rules**: Defined in `Tanja_Trades_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Tuesday–Friday (09:15 AM EST – NY Morning Session).
### Model 2:  M1 Silver Bullet High-Frequency Scalper
- **Entry Rules**: Defined in `Tanja_Trades_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Tuesday–Friday (09:15 AM EST – NY Morning Session).
### Model 3:  Balanced Price Range (BPR) Center-Line Retest
- **Entry Rules**: Defined in `Tanja_Trades_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Tuesday–Friday (09:15 AM EST – NY Morning Session).
