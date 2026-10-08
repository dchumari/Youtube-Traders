# Channel Metadata — TradeIQ Academy

## Channel Info
- **Channel Name**: TradeIQ Academy
- **Platform**: TradingView / Multi-Broker
- **Source**: Gemini Shared Analysis + YouTube public content

## Strategy Classification
- **Type**: AI MACD Fusion + Central Pivot Range (CPR) Scalping — Quant/Rule-Based
- **Instrument Focus**: XAUUSD (primary), forex majors
- **Primary Timeframes**: 1H (CPR and trend context), 5M/1M (entry signals)

## Session Profile
- **Primary Session**: New York Session
- **Trade Window**: 13:00–18:00 UTC
- **CPR Calc**: Calculated from prior day H/L/Close at daily open

## Key Concepts — TradeIQ Dual System

### System A: AI Adaptive Supertrend + Dual MACD (1M Scalping)
1. **AI Adaptive Supertrend** — Dynamic ATR-based trailing trend indicator that adjusts factor automatically based on volatility regime
2. **MACD Signal 1 (Fast)** — 3/10/16 settings for short-term momentum
3. **MACD Signal 2 (Slow)** — 12/26/9 settings for medium-term momentum confirmation
4. **Entry Signal**: Both MACDs histograms positive AND supertrend is bullish (price above supertrend line) → BUY; reverse for SELL
5. **Momentum Thrust**: MACD must show diverging histograms (accelerating, not decelerating) at entry

### System B: Central Pivot Range (CPR) Pullback Trading
1. **CPR Calculation**:
   - Pivot (P) = (H + L + C) / 3
   - Top Central Pivot (TC) = (Pivot - BC) + Pivot
   - Bottom Central Pivot (BC) = (H + L) / 2
2. **Narrow CPR** (< 15 pips spread) = trending day expected
3. **Wide CPR** (> 30 pips spread) = ranging/reversal day expected
4. **Trade**: On narrow CPR day, buy pullbacks to TC from above; sell rallies to BC from below
5. **Target**: Prior day high or low

## Risk Parameters Observed
- **Stop Loss System A**: 5–10 pips below/above supertrend line on 1M
- **Stop Loss System B**: Below CPR opposite boundary
- **Take Profit**: 1:2 R:R minimum
- **Risk per Trade**: 0.5–1%
- **Max Trades**: 3 per session

## Scraping Notes
- YouTube Channel: TradeIQ Academy
- CPR calculation methodology well-documented on channel
- Quant-forward approach; most rules are explicit and measurable
