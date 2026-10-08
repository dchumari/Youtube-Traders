# Strategy Specification — Stock Sniper Trading (SST / Coach Ronny)
## Version 1.0 | XAUUSD Structural Price Action + Candlestick Confirmation

---

## 1. Executive Summary

Stock Sniper Trading's methodology layers macro S/R level analysis (Daily/4H) with lower-timeframe candlestick confirmation patterns (engulfing, pin bar), filtered by fundamental context (US Treasury yields, DXY direction). The strategy plays swing reversals and pullbacks at major price levels and is designed to capture 50–150 pip moves on XAUUSD. Frequency is moderate: 3–5 trades per week.

---

## 2. Market Structure & Signal Generation

### 2.1 Key Level Identification (Daily/4H)
Pre-session, mark the following levels:
- **Prior Day High (PDH)** and **Prior Day Low (PDL)**
- **Prior Week High (PWH)** and **Prior Week Low (PWL)**
- **Round Numbers**: Every $10 increment on XAUUSD (e.g., 2300, 2310, 2320...)
- **Major Swing Points**: 4H chart swing highs/lows from last 20 bars
- Levels that have been tested 3+ times are "premium" levels (highest confluence)

### 2.2 Tokyo Session Range (00:00–06:00 UTC)
- Mark Asian high and low as secondary reference levels
- If price is range-bound in Tokyo within 30 pips = expect NY directional move

### 2.3 Candlestick Confirmation Patterns (15M/1H)
At a key level, wait for ONE of the following:

**Bullish Patterns (at support/demand)**:
- **Bullish Engulfing**: Current candle body completely engulfs prior candle body (bullish), close above prior open
- **Hammer/Pin Bar**: Lower wick ≥ 2× body size, body in upper 30% of candle range, closes positive

**Bearish Patterns (at resistance/supply)**:
- **Bearish Engulfing**: Current candle body completely engulfs prior candle body (bearish), close below prior open
- **Shooting Star**: Upper wick ≥ 2× body size, body in lower 30% of candle range, closes negative

### 2.4 Entry Conditions
1. Price reaches a pre-marked key level (within 10 pip tolerance)
2. A qualifying candlestick pattern forms on 15M or 1H at that level
3. Macroeconomic context aligns:
   - Long gold: US yields falling OR DXY falling
   - Short gold: US yields rising OR DXY rising
4. Entry: Market order on confirmation candle close

---

## 3. Execution Windows (Session Filter)

| Parameter | Value |
|-----------|-------|
| Level Construction | Pre-session (before 07:00 UTC) |
| Session 1 | Tokyo range play: 00:00–06:00 UTC |
| Session 2 | New York execution: 13:00–17:00 UTC |
| Day Filter | Monday–Friday |

---

## 4. Risk Parameters

| Parameter | Value |
|-----------|-------|
| Stop Loss | 10–15 pips beyond confirmation candle wick |
| Take Profit | Next Daily/4H key level |
| R:R | Minimum 1:2 |
| Risk per Trade | 1–2% |
| Breakeven | Move SL to entry at 1:1 |
| Max Daily Trades | 3 |
| News Filter | Avoid CPI/PPI/NFP/FOMC ±30 min |

---

## 5. Input Parameter Matrix

```
// EA Inputs — Stock_Sniper_Trading SST
input double   RiskPercent        = 1.0;
input bool     UseFixedLot        = false;
input double   FixedLot           = 0.01;
input int      KeyLevel_Lookback  = 20;    // 4H bars for swing detection
input double   Level_Tolerance    = 10.0;  // Pips tolerance for level touch
input double   RoundNumber_Step   = 10.0;  // Round number step (10 = every $10 on XAUUSD)
input double   Engulf_MinRatio    = 1.0;   // Engulfing min body ratio (current/prior)
input double   PinBar_WickRatio   = 2.0;   // Wick must be 2× body for pin bar
input double   SL_PipBuffer       = 12.0;  // SL buffer beyond wick
input double   MinRR              = 2.0;
input int      SessionStart1      = 0;     // Tokyo
input int      SessionEnd1        = 6;
input int      SessionStart2      = 13;    // NY
input int      SessionEnd2        = 17;
input bool     UseNewsFilter      = true;
input int      NewsBufferMin      = 30;
input int      MaxDailyTrades     = 3;
input double   MaxSpread          = 20;
// Macro filter (simplified): uses EURUSD as DXY proxy
input bool     UseMacroFilter     = false; // Enable DXY/yield filter
input string   DXY_Proxy          = "EURUSD"; // Inverse DXY proxy
```

---

## 6. Filter Constraints

| Filter | Rule |
|--------|------|
| Key Level | Price must be within 10 pips of pre-marked level |
| Candle Pattern | Must be qualifying engulfing or pin bar |
| R:R | Skip if next level < 2× SL distance |
| Spread | Max 20 points |
| News | ±30 min blackout around Tier-1 events |

---

## 7. Mathematical Edge Analysis

- **Win Rate Target**: 55–65% (price action at well-defined levels has high hit rate)
- **Average R:R**: 2.2 (next key level often within range)
- **Expected Value**: EV = (0.60 × 2.2) − (0.40 × 1) = 1.32 − 0.40 = **+0.92R per trade**
- **Profit Factor Target**: 1.7–2.2

---

*Spec Version: 1.0 | Generated: 2026-09-13*
