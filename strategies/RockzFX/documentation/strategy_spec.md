# Strategy Specification — RockzFX (Tony Rockall) — BST Model
## Version 1.0 | XAUUSD Behavior-Structure-Trend Multi-Timeframe Framework

---

## 1. Executive Summary

RockzFX's Behavior-Structure-Trend (BST) model is a three-layer multi-timeframe confluence system. All three layers must align before a trade is taken, making it a high-precision, lower-frequency strategy. The methodology is explicitly rule-based with quantifiable conditions on each timeframe, making it well-suited for EA implementation.

---

## 2. Strategy Framework — BST Three Layers

### Layer 1: STRUCTURE (4H Timeframe — Macro Bias)

**Bullish Structure**:
- 4H chart is forming sequence: Higher Low → Higher High → Higher Low...
- Current 4H close is above the prior swing low
- Bias: LONG only

**Bearish Structure**:
- 4H chart is forming sequence: Lower High → Lower Low → Lower High...
- Current 4H close is below the prior swing high
- Bias: SHORT only

**Detection Algorithm**:
- Track last 3 swing highs and 3 swing lows using ZigZag equivalent (N-bar high/low detection)
- Bullish: SH[n] > SH[n-1] AND SL[n] > SL[n-1]
- Bearish: SH[n] < SH[n-1] AND SL[n] < SL[n-1]

### Layer 2: BEHAVIOR (1H Timeframe — Sentiment Signal)

**Bullish Behavior (Long Signal)**:
- A 1H candle forms at or near a key S/R level (previously identified swing low or round number)
- The candle has a LONG LOWER WICK: wick length ≥ 50% of total candle range (High − Low)
- Candle closes in the upper half of its range (close > midpoint of High-Low)

**Bearish Behavior (Short Signal)**:
- A 1H candle forms at or near a key S/R level (previously identified swing high or round number)
- The candle has a LONG UPPER WICK: wick length ≥ 50% of total candle range
- Candle closes in the lower half of its range (close < midpoint of High-Low)

### Layer 3: TREND ENTRY (15M/5M Timeframe — Trigger)

After Structure + Behavior both aligned:
1. On 15M chart, identify a recent minor swing high (for short) or minor swing low (for long)
2. Wait for price to **break** below that minor swing low (for short) / above minor swing high (for long)
3. Wait for price to **retest** the broken level from the new direction
4. Enter on the close of the retest candle (first pull-back to broken level)

---

## 3. Full Entry Checklist

✅ 4H Structure = Bearish (lower highs and lower lows)
✅ 1H Behavior = Bearish (upper wick candle at resistance zone, wick ≥ 50%)
✅ 15M Trend = Minor swing high broken to downside + retest confirmed
→ **SELL entry** on 15M retest candle close

✅ 4H Structure = Bullish (higher highs and higher lows)
✅ 1H Behavior = Bullish (lower wick candle at support zone, wick ≥ 50%)
✅ 15M Trend = Minor swing low broken to upside + retest confirmed
→ **BUY entry** on 15M retest candle close

---

## 4. Execution Windows (Session Filter)

| Parameter | Value |
|-----------|-------|
| Session 1 | London Open Killzone: 07:00–09:00 UTC |
| Session 2 | NY Open Killzone: 13:00–15:00 UTC |
| Day Filter | Monday–Friday |

---

## 5. Risk Parameters

| Parameter | Value |
|-----------|-------|
| Stop Loss | Beyond 1H behavior candle wick extreme + 10 pip buffer |
| Take Profit | Next 4H structural swing point (opposing swing H/L) |
| Risk per Trade | 0.5–1% |
| Breakeven | Move SL to entry when 1:1 R:R reached |
| Trailing Stop | Manual — hold for 4H target (EA: ATR trailing after 1:1) |
| Max Daily Trades | 2 |

---

## 6. Input Parameter Matrix

```
// EA Inputs — RockzFX BST Model
input double   RiskPercent         = 1.0;
input bool     UseFixedLot         = false;
input double   FixedLot            = 0.01;
input int      Structure_Lookback  = 10;    // Bars for 4H swing detection
input int      Behavior_Lookback   = 3;     // 1H bars to check for wick signal
input double   WickRatioMin        = 0.50;  // Min wick ratio for behavior signal
input int      Trend_SwingBars     = 5;     // 15M bars for minor swing detection
input double   SL_BufferPips       = 10.0;  // Buffer beyond behavior candle wick
input int      SessionStart1       = 7;     // London killzone start (UTC)
input int      SessionEnd1         = 9;     // London killzone end (UTC)
input int      SessionStart2       = 13;    // NY killzone start (UTC)
input int      SessionEnd2         = 15;    // NY killzone end (UTC)
input double   ATR_TrailMulti      = 2.0;   // ATR multiplier for trailing stop
input int      ATR_Period          = 14;
input int      MaxDailyTrades      = 2;
input double   MaxSpread           = 25;
```

---

## 7. Filter Constraints

| Filter | Rule |
|--------|------|
| All 3 Layers Required | No trade without full BST alignment |
| Spread | Max 25 points |
| 4H Structure Age | Structure signal must be confirmed within last 10 4H candles |
| 1H Behavior | Wick ratio ≥ 50%, candle close in correct half |
| News | Avoid 30 min before/after Tier-1 events |

---

## 8. Mathematical Edge Analysis

- **Win Rate Target**: 55–65% (triple confluence filter = high quality, lower frequency)
- **Average R:R**: 2.5–3.5 (structural swing targets)
- **Expected Value**: EV = (0.60 × 3.0) − (0.40 × 1) = 1.80 − 0.40 = **+1.40R per trade**
- **Profit Factor Target**: 2.0–2.5
- **Frequency**: ~3–5 trades per week (selective)

---

*Spec Version: 1.0 | Generated: 2026-09-13*
