# Strategy Specification — DonVo (DVS) — Drive Range Liquidity (DRL)
## Version 1.0 | XAUUSD Session Range Sweep + Mean Reversion Strategy

---

## 1. Executive Summary

DonVo's Drive Range Liquidity (DRL) methodology is among the most systematically quantifiable strategies in this set. It identifies equal highs/lows (liquidity pools) at Asian and London session extremes, waits for New York session to sweep these levels (stop hunt), then enters a mean reversion trade back into the session range. The setup is clean, rule-based, and highly suited to automation.

---

## 2. Market Structure & Signal Generation

### 2.1 Asian Session Range Construction (00:00–06:00 UTC)
- At 06:00 UTC, lock the following levels:
  - **Asian High (AH)**: Highest high of all candles from 00:00–06:00 UTC
  - **Asian Low (AL)**: Lowest low of all candles from 00:00–06:00 UTC
  - **Asian Midpoint (AM)**: (AH + AL) / 2
- Range stored as static horizontal levels for the day

### 2.2 London Session Range Construction (07:00–10:00 UTC)
- At 10:00 UTC, lock:
  - **London High (LH)**: Highest high from 07:00–10:00 UTC
  - **London Low (LL)**: Lowest low from 07:00–10:00 UTC
- Note: London range may extend or overlap Asian range

### 2.3 Liquidity Identification
- **Buy-Side Liquidity (BSL)**: Equal highs at AH or LH (stops resting above = buy stops)
- **Sell-Side Liquidity (SSL)**: Equal lows at AL or LL (stops resting below = sell stops)
- "Equal" defined as: within 5 pips of the marked level across at least 2 candle wicks

### 2.4 Liquidity Sweep Detection (NY Session: 13:00+ UTC)
**Bearish Sweep (Short Setup)**:
1. During NY session, price pushes ABOVE AH or LH by at least 5 pips (sweep)
2. Price then returns BELOW the swept level within 3 candles (failed breakout)
3. Confirmation: 5M or 15M bearish candle closes back below swept level

**Bullish Sweep (Long Setup)**:
1. During NY session, price pushes BELOW AL or LL by at least 5 pips (sweep)
2. Price then returns ABOVE the swept level within 3 candles
3. Confirmation: 5M or 15M bullish candle closes back above swept level

### 2.5 Entry
- Market order on confirmation candle close
- Entry direction: OPPOSITE to the sweep direction (mean reversion)

### 2.6 Target
- Primary: Opposite session extreme (AL for shorts after BSL sweep, AH for longs after SSL sweep)
- Secondary: Asian Midpoint (AM) as conservative partial target (50%)

---

## 3. Execution Windows (Session Filter)

| Parameter | Value |
|-----------|-------|
| Range Build 1 | 00:00–06:00 UTC (Asian range) |
| Range Build 2 | 07:00–10:00 UTC (London range) |
| Trade Window | 13:00–18:00 UTC (New York session) |
| Day Filter | Monday–Friday |

---

## 4. Risk Parameters

| Parameter | Value |
|-----------|-------|
| Stop Loss | Above sweep wick high + 5 pip buffer (for short) / Below sweep wick low − 5 pips (for long) |
| Take Profit 1 | Asian Midpoint (AM) — 50% close |
| Take Profit 2 | Opposite session extreme |
| R:R | Minimum 1:2 (skip if target too close) |
| Risk per Trade | 1% |
| Max Sweep Tolerance | 5–25 pip sweep (reject if sweep > 30 pips — may indicate real breakout) |
| Max Daily Trades | 2 (1 long + 1 short maximum) |
| News Filter | No entry 30 min before/after Tier-1 events |

---

## 5. Input Parameter Matrix

```
// EA Inputs — DonVo DRL Strategy
input double   RiskPercent       = 1.0;
input bool     UseFixedLot       = false;
input double   FixedLot          = 0.01;
input int      AsianStartHour    = 0;      // UTC
input int      AsianEndHour      = 6;      // UTC
input int      LondonStartHour   = 7;      // UTC
input int      LondonEndHour     = 10;     // UTC
input int      NYStartHour       = 13;     // UTC
input int      NYEndHour         = 18;     // UTC
input double   SweepMinPips      = 5.0;   // Minimum pip sweep beyond level
input double   SweepMaxPips      = 30.0;  // Maximum pip sweep (above = reject)
input int      SweepConfirmBars  = 3;     // Max bars to return below level
input double   SL_BufferPips     = 5.0;   // Buffer pips beyond sweep wick
input double   TP1_Percent       = 50.0;  // % close at midpoint
input double   MinRR             = 2.0;   // Minimum required R:R
input int      MaxDailyTrades    = 2;
input bool     UseNewsFilter     = true;
input int      NewsBufferMin     = 30;
```

---

## 6. Filter Constraints

| Filter | Rule |
|--------|------|
| Spread | Max 20 points |
| Sweep Size | 5–30 pips (outside range = rejected) |
| Equal Highs/Lows | Level must have ≥ 2 wick touches within 5 pips |
| R:R | Skip if opposing session extreme < 2× SL distance away |
| News | Hard block 30 min before/after high-impact events |
| Range Width | Skip if Asian range < 15 pips (too narrow, likely holiday/low liquidity) |

---

## 7. Mathematical Edge Analysis

- **Win Rate Target**: 58–68% (liquidity sweeps are high-probability reversals in XAUUSD)
- **Average R:R**: 2.5 (AM target partial + full opposite extreme)
- **Expected Value**: EV = (0.63 × 2.5) − (0.37 × 1) = 1.575 − 0.37 = **+1.21R per trade**
- **Profit Factor Target**: 2.0–2.8

---

## 8. Automation Assessment

- **Highest automation potential** of the 10 strategies
- Session range construction: fully algorithmic
- Sweep detection: fully algorithmic
- Mean reversion target: fully algorithmic
- Only risk: "equal highs/lows" identification requires cluster detection (implemented via tolerance band)

---

*Spec Version: 1.0 | Generated: 2026-09-13*
