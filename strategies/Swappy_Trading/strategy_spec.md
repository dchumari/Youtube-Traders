# Swappy_Trading — Strategy Specification & MQL5 Logic

## 1. Strategy Overview
This Expert Advisor implements the signature trading models of **Swappy (@SwappyTrading)**, built for high-precision institutional execution on Gold (`XAUUSD`) and Nasdaq (`NQ` / `US100`).

## 2. Integrated Strategy Models
### Model 1:  IPDA Algorithmic Dealing Ranges (50% Premium/Discount Equilibrium)
- **Entry Rules**: Defined in `Swappy_Trading_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Daily London Open & NY Market Hours.
### Model 2:  London Open Judas Swing (02
- **Entry Rules**: Defined in `Swappy_Trading_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Daily London Open & NY Market Hours.
### Model 3:  Breaker Block (BB) Structural Reversal
- **Entry Rules**: Defined in `Swappy_Trading_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with Daily London Open & NY Market Hours.
