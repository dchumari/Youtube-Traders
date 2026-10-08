# Ali_Khan_ICT — Strategy Specification & MQL5 Logic

## 1. Strategy Overview
This Expert Advisor implements the signature trading models of **Ali Khan (@alikhansmc)**, built for high-precision institutional execution on Gold (`XAUUSD`) and Nasdaq (`NQ` / `US100`).

## 2. Integrated Strategy Models
### Model 1:  Dealing Range Equilibrium & 62%-79% OTE Matrix
- **Entry Rules**: Defined in `Ali_Khan_ICT_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with New York Morning Session.
### Model 2:  Candle Body Displacement Verification (Wicks Sweep, Bodies Displace)
- **Entry Rules**: Defined in `Ali_Khan_ICT_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with New York Morning Session.
### Model 3:  Low Resistance Liquidity Run (LRLR)
- **Entry Rules**: Defined in `Ali_Khan_ICT_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with New York Morning Session.
