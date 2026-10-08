# Arjo_MMT — Strategy Specification & MQL5 Logic

## 1. Strategy Overview
This Expert Advisor implements the signature trading models of **Arjo (@Arjoio - Money Making Team)**, built for high-precision institutional execution on Gold (`XAUUSD`) and Nasdaq (`NQ` / `US100`).

## 2. Integrated Strategy Models
### Model 1:  Market Maker Buy/Sell Model (MMBM / MMSM Complete Curve)
- **Entry Rules**: Defined in `Arjo_MMT_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with London Open & NY Killzones.
### Model 2:  SMT (Smart Money Technique) Correlation Divergence Trigger
- **Entry Rules**: Defined in `Arjo_MMT_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with London Open & NY Killzones.
### Model 3:  Multi-Session Breaker & Liquidity Void Run
- **Entry Rules**: Defined in `Arjo_MMT_EA.mq5` via selectable `StrategyMode`.
- **Target R:R**: 2.0R to 3.5R with optional dual partials (50% at 1:1, 50% at 1:2+).
- **Session Filter**: Aligned with London Open & NY Killzones.
