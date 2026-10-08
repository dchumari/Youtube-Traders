# Strategy Specification — TradeIQ Academy
## Version 1.0 | XAUUSD AI MACD Fusion + CPR Scalping Strategy

---

## 1. Executive Summary

TradeIQ Academy operates two complementary rule-based systems on XAUUSD. System A uses an AI Adaptive Supertrend combined with Dual MACD momentum confirmation for 1M scalping during the New York session. System B uses Central Pivot Range (CPR) calculations to classify the day type (trending vs ranging) and trade pullbacks to key pivot levels. Both systems are explicitly quantitative and automation-ready.

---

## 2. System A — AI Adaptive Supertrend + Dual MACD (1M Scalping)

### 2.1 AI Adaptive Supertrend
- Standard Supertrend formula: Upper Band = (High + Low)/2 + Factor × ATR
- "AI Adaptive" = Factor automatically adjusts based on recent ATR volatility regime
- **EA Implementation**: Use dynamic factor: Factor = Base_Factor × (1 + ATR_Regime_Multiplier)
  - ATR_Regime_Multiplier = clamp((CurrentATR - AvgATR) / AvgATR, -0.3, +0.3)
- Parameters: ATR Period = 10, Base Factor = 3.0
- **Bullish Signal**: Price crosses above Supertrend line (green)
- **Bearish Signal**: Price crosses below Supertrend line (red)

### 2.2 Dual MACD Confirmation
**Fast MACD** (3, 10, 16):
- Signal: Both MACD line and Signal line positive AND histogram > 0 → Bullish momentum
- Signal: Both MACD line and Signal line negative AND histogram < 0 → Bearish momentum

**Slow MACD** (12, 26, 9):
- Signal: MACD line above Signal line AND histogram increasing → Bullish confirmation
- Signal: MACD line below Signal line AND histogram decreasing → Bearish confirmation

### 2.3 Entry Conditions (System A)
**BUY**:
- Supertrend is BULLISH (price above line)
- Fast MACD histogram > 0 AND increasing (momentum accelerating)
- Slow MACD MACD line > Signal line
- All three align → BUY on next 1M open

**SELL**:
- Supertrend is BEARISH (price below line)
- Fast MACD histogram < 0 AND decreasing
- Slow MACD MACD line < Signal line
- All three align → SELL on next 1M open

---

## 3. System B — Central Pivot Range (CPR) Day Classification

### 3.1 CPR Calculation (Daily, from Prior Day OHLC)
```
Pivot (P)  = (Prior_High + Prior_Low + Prior_Close) / 3
BC         = (Prior_High + Prior_Low) / 2
TC         = (P - BC) + P
CPR Width  = TC - BC   (in pips)
```

### 3.2 Day Type Classification
| CPR Width | Day Type | Strategy |
|-----------|----------|----------|
| < 15 pips | Narrow CPR | Strong trending day expected — trade breakout direction |
| 15–30 pips | Normal CPR | Standard session range — trade CPR level rejections |
| > 30 pips | Wide CPR | Ranging/reversal day — trade CPR extremes as S/R |

### 3.3 System B Entry Conditions
**Narrow CPR — Breakout Mode**:
- Price breaks above TC → Buy pullback to TC (bullish trend)
- Price breaks below BC → Sell rally to BC (bearish trend)

**Normal/Wide CPR — Rejection Mode**:
- Price approaches TC from above → Sell (TC acts as resistance)
- Price approaches BC from below → Buy (BC acts as support)
- Wait for 5M pin bar or engulfing at CPR level

### 3.4 System B Targets
- Narrow CPR Bullish: Prior Day High → Weekly High
- Narrow CPR Bearish: Prior Day Low → Weekly Low
- Wide CPR: Opposite CPR boundary (TC↔BC)

---

## 4. Execution Windows (Session Filter)

| Parameter | Value |
|-----------|-------|
| System A Window | NY Session: 13:00–18:00 UTC (1M scalping) |
| System B Window | From NY Open: 13:00+ UTC |
| CPR Calculation | Daily at 00:00 UTC from prior day OHLC |
| Day Filter | Monday–Friday |

---

## 5. Risk Parameters

| Parameter | Value |
|-----------|-------|
| System A SL | 5–10 pips below/above Supertrend line |
| System B SL | Below/above opposite CPR boundary |
| Take Profit | 1:2 R:R minimum |
| Risk per Trade | 0.5–1% |
| Max Trades/Session | 3 total (both systems combined) |
| Breakeven | At 1:1 R:R |

---

## 6. Input Parameter Matrix

```
// EA Inputs — TradeIQ_Academy
input double   RiskPercent         = 1.0;
input bool     UseFixedLot         = false;
input double   FixedLot            = 0.01;
// System A
input int      ST_ATR_Period       = 10;   // Supertrend ATR period
input double   ST_Base_Factor      = 3.0;  // Supertrend base factor
input double   ST_AI_MaxAdjust     = 0.30; // Max AI factor adjustment
input int      FastMACD_Fast       = 3;
input int      FastMACD_Slow       = 10;
input int      FastMACD_Signal     = 16;
input int      SlowMACD_Fast       = 12;
input int      SlowMACD_Slow       = 26;
input int      SlowMACD_Signal     = 9;
input double   SL_Pips_A          = 8.0;  // System A stop loss pips
// System B
input double   CPR_NarrowMax      = 15.0;  // Narrow CPR threshold (pips)
input double   CPR_WideMin        = 30.0;  // Wide CPR threshold (pips)
input double   SL_Pips_B          = 12.0; // System B stop loss pips
input double   MinRR              = 2.0;
// Sessions
input int      SessionStartHour   = 13;   // NY (UTC)
input int      SessionEndHour     = 18;
input int      MaxDailyTrades     = 3;
input double   MaxSpread          = 20;
input bool     UseSystemA         = true;
input bool     UseSystemB         = true;
```

---

## 7. Filter Constraints

| Filter | Rule |
|--------|------|
| System A | All 3 indicators must align (Supertrend + 2× MACD) |
| System B | CPR width determines day type before any entry |
| Spread | Max 20 points |
| News | Avoid ±15 min around Tier-1 events (scalping especially sensitive) |
| Max Trades | 3 per session combined |

---

## 8. Mathematical Edge Analysis

**System A (Scalping)**:
- Win Rate Target: 52–58% (trend-following in direction of institutional flow)
- R:R: 2.0
- EV: (0.55 × 2.0) − (0.45 × 1) = 1.10 − 0.45 = **+0.65R/trade**

**System B (CPR)**:
- Win Rate Target: 58–65% (CPR is statistically reliable mean-reversion tool)
- R:R: 2.0
- EV: (0.61 × 2.0) − (0.39 × 1) = 1.22 − 0.39 = **+0.83R/trade**

- **Combined Profit Factor Target**: 1.6–2.0

---

*Spec Version: 1.0 | Generated: 2026-09-13*
