# Strategy Specification — A.C.T. Forex Academy
## Version 1.0 | XAUUSD Analyse-Confirm-Trade (A.C.T.) System

---

## 1. Executive Summary

The A.C.T. system is a rigidly structured three-step trading methodology: Analyse the macro trend corridor on 4H, Confirm a breakout/retest on 15M, and Trade with precise execution on 5M using predefined position management (50% close at TP1, 50% runner to TP2). At 0.5–1% risk per trade with strict entry conditions, this is among the most conservative and rule-compliant strategies in the dataset.

---

## 2. Market Structure & Signal Generation

### Step 1: ANALYSE (4H Timeframe — Trend Corridor)

**Trend Corridor Construction**:
- Draw two parallel trendlines on 4H:
  - Upper boundary: connecting last 2–3 significant swing highs
  - Lower boundary: connecting last 2–3 significant swing lows
- The corridor represents the dominant trend channel

**Bias Determination**:
- Ascending channel (upper + lower boundaries both angled up) → BULLISH bias → BUY setups only
- Descending channel (both boundaries angled down) → BEARISH bias → SELL setups only
- Horizontal channel (ranging) → Both directions valid near boundaries

**EA Approximation**:
- Linear regression channel on 4H (LRC) used to approximate manual trendlines
- Period: 20 4H bars
- Upper band = LRC + 1.5 × StdDev; Lower band = LRC − 1.5 × StdDev
- Bullish bias if slope of LRC > 0; Bearish if slope < 0

### Step 2: CONFIRM (15M Timeframe — Breakout + Retest)

For LONG entry (price at lower corridor boundary):
1. A 15M candle **breaks out** ABOVE a recent minor consolidation resistance
2. Breakout candle body must be > 60% of the candle's H-L range (strong displacement)
3. Price **retests** the broken level (first pullback, must not close below origin)
4. Retest candle shows decreased volume / smaller body (absorption)

For SHORT entry (price at upper corridor boundary):
1. A 15M candle **breaks out** BELOW a recent minor consolidation support
2. Breakout candle body > 60% of H-L range
3. Price retests broken level from below
4. Retest candle shows decreased momentum

### Step 3: TRADE (5M Execution)

- Entry: Market order or limit at retest zone (5M confirmation candle close)
- Stop Loss: Beyond the breakout origin point + spread buffer
- TP1: 1:1 R:R (50% position close) — MagicKeys equivalent in EA: partial close
- TP2: 1:2 R:R or opposite corridor boundary (50% runner)
- Breakeven: Auto-trigger after TP1 hit

---

## 3. Execution Windows (Session Filter)

| Parameter | Value |
|-----------|-------|
| Pre-Session Analysis | 06:00–06:45 UTC (corridor mapping) |
| London Open Window | 07:00–10:00 UTC |
| New York Overlap | 13:00–16:00 UTC |
| Day Filter | Monday–Friday |

---

## 4. Risk Parameters

| Parameter | Value |
|-----------|-------|
| Risk per Trade | 0.5–1% (default 1%) |
| Stop Loss | Beyond breakout origin + 5 pip buffer |
| TP1 | 1:1 R:R (50% close) |
| TP2 | 1:2 R:R or corridor opposite boundary |
| Breakeven | Triggered at TP1 hit |
| Max Spread | 15 points (0.15 USD — strict) |
| News Filter | 30 min before/after high-impact events |
| Max Daily Trades | 2 |

---

## 5. Input Parameter Matrix

```
// EA Inputs — ACT_Forex_Academy
input double   RiskPercent         = 1.0;
input bool     UseFixedLot         = false;
input double   FixedLot            = 0.01;
input int      LRC_Period          = 20;   // Linear regression channel period (4H bars)
input double   LRC_StdDev_Multi    = 1.5;  // StdDev multiplier for corridor
input int      Breakout_Lookback   = 10;   // 15M bars to find minor consolidation
input double   Breakout_MinStrength = 0.60; // Min body ratio for breakout candle
input double   SL_BufferPips       = 5.0;  // Buffer beyond breakout origin
input double   TP1_RR              = 1.0;  // TP1 at 1:1 R:R
input double   TP1_ClosePercent    = 50.0; // % to close at TP1
input double   TP2_RR              = 2.0;  // TP2 at 1:2 R:R
input int      SessionStart1       = 7;    // London (UTC)
input int      SessionEnd1         = 10;
input int      SessionStart2       = 13;   // NY (UTC)
input int      SessionEnd2         = 16;
input double   MaxSpread           = 15;   // STRICT: 15 points max
input bool     UseNewsFilter       = true;
input int      NewsBufferMin       = 30;
input int      MaxDailyTrades      = 2;
```

---

## 6. Filter Constraints

| Filter | Rule |
|--------|------|
| Spread | STRICT max 15 points (0.15 USD) |
| Breakout Strength | Body ≥ 60% of candle H-L |
| Corridor Alignment | Bias direction must match corridor slope |
| Retest Valid | Retest must not close beyond breakout origin |
| News | ±30 min hard block |

---

## 7. Mathematical Edge Analysis

- **Win Rate Target**: 55–65% (tight entry conditions = high selectivity)
- **Average R:R**: 1.8 (average of TP1=1.0 and TP2=2.0 across position halves)
- **Expected Value**: EV = (0.60 × 1.8) − (0.40 × 1) = 1.08 − 0.40 = **+0.68R per trade**
- **Profit Factor Target**: 1.6–2.2
- **Note**: Conservative risk profile; recommended for funded account contexts

---

*Spec Version: 1.0 | Generated: 2026-09-13*
