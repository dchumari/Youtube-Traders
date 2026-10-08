# Strategy Specification — Lorenzo Corrado — LTA Concepts
## Version 1.0 | XAUUSD Volume Order Block + DXY Correlation Strategy

---

## 1. Executive Summary

Lorenzo Corrado's LTA Concepts framework blends volume-based Order Block identification with DXY (US Dollar Index) inverse correlation filtering and a daily "War Map" of macro liquidity levels. The strategy trades high-volume OB retests during the New York session where volume expansion confirms directional bias, while DXY provides fundamental context. This is a medium-frequency strategy with 2–4 trades per week.

---

## 2. Market Structure & Signal Generation

### 2.1 LTA War Map — Daily Level Construction
At daily open (00:00 UTC), mark:
- **Weekly Open (WO)**: Monday 00:00 UTC open price
- **Monthly Open (MO)**: First trading day of month 00:00 UTC open
- **Prior Day High (PDH)**: Previous day's highest high
- **Prior Day Low (PDL)**: Previous day's lowest low
- These form the macro "War Map" — key magnetic levels for price

### 2.2 High-Volume Order Block (LTA OB) Identification
- A "High-Volume OB" is a candle where:
  - Bar volume > 1.8× the 20-bar average volume (session-normalized)
  - The candle is the last strong directional candle BEFORE an impulse move
  - The impulse after the OB candle travels at least 15 pips
- **Bullish LTA OB**: High-volume BEARISH candle before a bullish impulse
- **Bearish LTA OB**: High-volume BULLISH candle before a bearish impulse

### 2.3 DXY Inverse Correlation Filter
- DXY is tracked as a separate instrument (US Dollar Index)
- **Gold Bullish condition**: DXY 4H trending downward (lower highs/lower lows) OR DXY breaking below a key support
- **Gold Bearish condition**: DXY 4H trending upward (higher highs/higher lows) OR DXY breaking above key resistance
- **Disqualifier**: If DXY and XAUUSD are moving in the SAME direction (positive correlation period) — skip ALL trades until correlation restores

### 2.4 Session Volume Expansion Filter
- NY Open must show volume on the first 15M candle > 1.5× the Asian session average
- This confirms institutional participation has begun

### 2.5 Entry Conditions
1. LTA OB identified (high-volume zone on 4H/1H)
2. Price returns to LTA OB zone during NY session
3. DXY inverse correlation confirms direction
4. NY session volume expansion confirmed
5. Entry: Limit order at OB zone midpoint or market on 5M reversal candle at OB zone

---

## 3. Execution Windows (Session Filter)

| Parameter | Value |
|-----------|-------|
| War Map Construction | Daily 00:00 UTC |
| OB Identification | 4H / 1H anytime |
| Trade Execution | NY Session: 13:00–18:00 UTC |
| Day Filter | Monday–Friday |

---

## 4. Risk Parameters

| Parameter | Value |
|-----------|-------|
| Stop Loss | Below/above full LTA OB zone |
| Take Profit 1 | Weekly Open or Monthly Open (War Map level) |
| Take Profit 2 | Prior Day High/Low (opposite extreme) |
| Risk per Trade | 1% (FundedNext-style limits) |
| Max Daily DD | 4% (funded account rule) |
| DXY Filter | Hard skip if DXY and XAUUSD positively correlated |
| Max Daily Trades | 3 |

---

## 5. Input Parameter Matrix

```
// EA Inputs — Lorenzo Corrado LTA Concepts
input double   RiskPercent         = 1.0;
input bool     UseFixedLot         = false;
input double   FixedLot            = 0.01;
input int      OB_VolMultiplier    = 18;    // Volume multiplier × 10 (1.8×)
input int      OB_AvgPeriod        = 20;   // Bars for average volume
input double   OB_MinImpulse_Pips  = 15.0; // Min impulse after OB (pips)
input int      DXY_StructureBars   = 10;   // 4H bars for DXY trend detection
input double   VolExpansionMulti   = 1.5;  // NY open volume vs Asian avg
input int      SessionStartHour    = 13;   // NY session (UTC)
input int      SessionEndHour      = 18;
input double   MaxDailyDD_Pct      = 4.0;  // Max daily drawdown %
input int      MaxDailyTrades      = 3;
input double   MaxSpread           = 25;
// Note: DXY requires USDX or DXY symbol available in MT5
// If unavailable, uses EURUSD inverse as DXY proxy (EUR 57.6% weight in DXY)
input bool     UseDXY_Filter       = true;
input string   DXY_Symbol          = "USDX"; // Change to "DXY" or "EURUSD" as proxy
```

---

## 6. Filter Constraints

| Filter | Rule |
|--------|------|
| DXY Correlation | Skip if XAUUSD + DXY both rising or both falling |
| Volume Expansion | Skip if NY first 15M volume < 1.5× Asian avg |
| OB Volume | OB candle must be ≥ 1.8× session average |
| OB Impulse | OB must be followed by 15+ pip impulse |
| Spread | Max 25 points |

---

## 7. Mathematical Edge Analysis

- **Win Rate Target**: 52–60% (volume OBs + DXY filter = selective but reliable)
- **Average R:R**: 2.5–3.0 (War Map targets are macro)
- **Expected Value**: EV = (0.56 × 2.7) − (0.44 × 1) = 1.51 − 0.44 = **+1.07R per trade**
- **Profit Factor Target**: 1.8–2.5

---

## 8. Automation Limitations

- DXY symbol availability varies by broker — EURUSD inverse used as proxy if unavailable
- Volume OB identification uses tick volume (good proxy for XAUUSD)
- War Map levels are fully algorithmic (calculated from OHLC of prior periods)

---

*Spec Version: 1.0 | Generated: 2026-09-13*
