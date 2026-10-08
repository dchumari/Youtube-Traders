# Strategy Specification — WicksDontLie (Raja Banks)
## Version 1.0 | XAUUSD Price Action / Clean Range Strategy

---

## 1. Executive Summary

WicksDontLie employs a pure price action methodology centered on identifying "clean ranges" on higher timeframes (1H/4H) and entering on wick rejections at range boundaries on 5M/15M. The strategy is highly discretionary in range identification but rule-based in entry/exit execution. Partial profit taking (75–80% at 10–15 pips) is a core capital preservation mechanic.

---

## 2. Market Structure & Signal Generation

### 2.1 Clean Range Identification (1H/4H)
- A "clean range" is defined as a consolidation zone with:
  - Clear upper boundary (resistance) — minimum 2 touches
  - Clear lower boundary (support) — minimum 2 touches
  - Range width: 30–150 pips on XAUUSD
  - No major wicks piercing through the zone boundaries
- Ranges are marked on 4H first, refined on 1H

### 2.2 Entry Signal — Wick Rejection (15M/5M)
**Bullish Setup (Long)**:
1. Price approaches the lower boundary of the clean range
2. A 15M or 5M candle forms a long lower wick (wick ≥ 60% of candle total range)
3. Candle body closes back above the range low boundary
4. Entry: Market buy on close of rejection candle or next open

**Bearish Setup (Short)**:
1. Price approaches the upper boundary of the clean range
2. A 15M or 5M candle forms a long upper wick (wick ≥ 60% of candle total range)
3. Candle body closes back below the range high boundary
4. Entry: Market sell on close of rejection candle or next open

### 2.3 EA Approximation
Since "clean ranges" require visual identification, the EA uses:
- **Donchian Channel** (Period=20 on 1H) to approximate range boundaries
- A range is "clean" if the highest high and lowest low of the last N bars form a stable band (ATR < threshold)
- Wick ratio filter: Candle wick ≥ 60% of total H-L range, body in opposite direction

---

## 3. Execution Windows (Session Filter)

| Parameter | Value |
|-----------|-------|
| Session | New York |
| Start Time (UTC) | 11:30 |
| End Time (UTC) | 17:00 |
| Day Filter | Monday–Friday |
| Holiday Filter | US Federal Holidays excluded |

---

## 4. Risk Parameters

| Parameter | Value |
|-----------|-------|
| Stop Loss Type | Fixed pips below/above wick extreme |
| Stop Loss Distance | 8–15 pips (default: 12 pips on XAUUSD) |
| TP1 (Partial) | 10–15 pips (default: 12 pips) |
| TP1 Close % | 75% of position |
| TP2 (Runner) | Opposite range boundary (structural) |
| Risk per Trade | 1% of account |
| Breakeven | Move SL to entry after TP1 hit |
| Max Daily Trades | 3 |

---

## 5. Input Parameter Matrix

```
// EA Inputs — WicksDontLie
input double   RiskPercent       = 1.0;     // Risk per trade (%)
input bool     UseFixedLot       = false;   // Use fixed lot instead of risk %
input double   FixedLot          = 0.01;    // Fixed lot size
input int      RangePeriod       = 20;      // Donchian channel lookback (1H bars)
input double   ATR_RangeFilter   = 15.0;   // Max ATR (points) for "clean range" condition
input double   WickRatioMin      = 0.60;   // Minimum wick-to-total-range ratio
input double   SL_Pips           = 12.0;   // Stop loss in pips
input double   TP1_Pips          = 12.0;   // Take profit 1 in pips
input double   TP1_ClosePercent  = 75.0;   // % of position to close at TP1
input int      SessionStartHour  = 11;     // Session start (UTC)
input int      SessionEndHour    = 17;     // Session end (UTC)
input int      MaxDailyTrades    = 3;      // Max trades per day
input int      ATR_Period        = 14;     // ATR period for volatility
```

---

## 6. Filter Constraints

| Filter | Rule |
|--------|------|
| Spread | Max 20 points (0.20 USD on XAUUSD) |
| News | No new trades 30 min before/after high-impact events |
| ATR Volatility | Reject if ATR(14) > 40 pips (avoid extreme volatility) |
| Daily Loss Limit | Stop trading if daily loss > 2% |

---

## 7. Mathematical Edge Analysis

- **Expected Winning Setup**: Wick rejection at validated range with 75% partial close
- **Win Rate Target**: 55–65% (pure price action with session filter)
- **Expected Value per Trade**: (+12 × 0.75 × P) + (Range_width × 0.25 × P) − (12 × (1-P))
  - At P=0.60: EV ≈ +7.2 pips per trade (gross, pre-spread)
- **Profit Factor Target**: 1.5–2.0

---

## 8. Automation Limitations

- Range identification is partially discretionary → Donchian approximation introduces noise
- Partial close mechanic fully automatable in MQL5 via position modification
- "Clean range" purity cannot be perfectly replicated algorithmically; expect lower win rate vs discretionary

---

*Spec Version: 1.0 | Generated: 2026-09-13*
