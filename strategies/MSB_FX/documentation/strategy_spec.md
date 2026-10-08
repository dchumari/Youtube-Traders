# Strategy Specification — MSB FX (Sharjeel Bilal) — Gold-X Fusion
## Version 1.0 | XAUUSD SMC + Smart Money Concepts Strategy

---

## 1. Executive Summary

MSB FX's "Gold-X Fusion" strategy combines Smart Money Concepts (BOS/CHoCH structural analysis) with precise entry via Order Blocks (OB) and Fair Value Gaps (FVG). The strategy demands minimum 1:3 R:R and uses a multi-timeframe waterfall confirmation (4H → 1H → 15M → 5M → 1M). News avoidance is mandatory. This is one of the most systematically documented and quantifiable strategies in the set.

---

## 2. Market Structure & Signal Generation

### 2.1 Structural Analysis (4H/1H Timeframes)

**Break of Structure (BOS)**:
- Bullish BOS: Current 4H swing high exceeds prior 4H swing high (bullish continuation)
- Bearish BOS: Current 4H swing low breaks below prior 4H swing low (bearish continuation)
- BOS confirms trend continuation

**Change of Character (CHoCH)**:
- Bullish CHoCH: After bearish structure, a swing HIGH breaks above the last swing high (reversal signal)
- Bearish CHoCH: After bullish structure, a swing LOW breaks below the last swing low (reversal signal)
- CHoCH signals potential trend reversal — highest probability setups

### 2.2 Order Block Identification (1H)
- **Bullish OB**: The last bearish candle (red) immediately before a strong bullish impulse that broke structure
  - OB zone = Open to Close of that bearish candle
- **Bearish OB**: The last bullish candle (green) immediately before a strong bearish impulse that broke structure
  - OB zone = Open to Close of that bullish candle
- **Unmitigated**: OB is valid only if price has NOT returned to it yet
- **Invalidated**: If price closes through the full OB zone body

### 2.3 Fair Value Gap (FVG) Identification (15M/5M)
- FVG = 3-candle sequence where candle 1's wick and candle 3's wick do NOT overlap
- **Bullish FVG**: Low of candle 3 > High of candle 1 (gap above = bullish imbalance)
- **Bearish FVG**: High of candle 3 < Low of candle 1 (gap below = bearish imbalance)
- Price tends to return to FVG to "fill" the imbalance

### 2.4 Entry Module 2 — Precision Entry (1M/5M)
After 4H BOS/CHoCH + 1H OB located + price returning to OB:
1. Drop to 5M or 1M
2. Wait for a **displacement candle** (strong momentum candle closing away from OB with body > 60% of H-L)
3. Mark the **5M FVG** created by the displacement sequence
4. Enter at 50% of the displacement FVG (limit order) or on retest candle close
5. Stop below the full OB zone (with buffer)

---

## 3. Execution Windows (Session Filter)

| Parameter | Value |
|-----------|-------|
| Session 1 | London Open: 07:00–10:00 UTC |
| Session 2 | New York Open: 13:00–16:00 UTC |
| Day Filter | Monday–Friday |
| Avoid | Asian Session (low volume, OBs less reliable) |

---

## 4. Risk Parameters

| Parameter | Value |
|-----------|-------|
| Minimum R:R | 1:3 (hard rule — skip trade if target not reachable) |
| Stop Loss | Below/above full OB zone + 5 pip buffer |
| Take Profit | Next structural liquidity pool (equal highs/lows, 4H swing) |
| Risk per Trade | 1% of account |
| Breakeven | Move SL to entry when 1:1 is reached |
| Max Trades/Day | 2 (quality over quantity) |
| News Filter | MANDATORY — no trades ±30 min around CPI/NFP/FOMC |

---

## 5. Input Parameter Matrix

```
// EA Inputs — MSB_FX Gold-X Fusion
input double   RiskPercent       = 1.0;     // Risk per trade (%)
input bool     UseFixedLot       = false;
input double   FixedLot          = 0.01;
input int      StructureLookback = 20;      // Bars to detect swing high/low
input int      OB_Lookback       = 5;       // Max candles back to find OB
input double   OB_Buffer_Pips    = 5.0;     // Buffer beyond OB for SL
input double   FVG_EntryLevel    = 0.5;     // FVG entry at 50% (0.5) by default
input double   MinRR             = 3.0;     // Minimum R:R (skip trade if below)
input int      SessionStart1     = 7;       // London session start (UTC)
input int      SessionEnd1       = 10;      // London session end (UTC)
input int      SessionStart2     = 13;      // NY session start (UTC)
input int      SessionEnd2       = 16;      // NY session end (UTC)
input bool     UseNewsFilter     = true;    // Enable news blackout
input string   NewsHours         = "8:30,13:30,14:00,18:00"; // UTC news times
input int      NewsBufferMin     = 30;      // Minutes before/after news to avoid
input int      MaxDailyTrades    = 2;
```

---

## 6. Filter Constraints

| Filter | Rule |
|--------|------|
| Spread | Max 25 points (XAUUSD) |
| R:R Check | Skip if distance to liquidity target < 3× SL distance |
| News | Hard block ±30 min around Tier-1 events |
| OB Age | Skip OB older than 20 1H candles (likely mitigated by market) |
| CHoCH Priority | CHoCH entries > BOS continuation (higher probability) |

---

## 7. Mathematical Edge Analysis

- **Win Rate Target**: 50–60% (SMC setups have high precision but require patience)
- **Average R:R**: 3.2 (minimum 3.0 enforced)
- **Expected Value**: EV = (0.55 × 3.2) − (0.45 × 1) = 1.76 − 0.45 = **+1.31R per trade**
- **Profit Factor Target**: 2.0–3.0

---

## 8. Automation Limitations

- OB identification requires detecting "last candle before impulse" — algorithmically complex
- FVG detection is fully algorithmic (3-candle gap check)
- CHoCH vs BOS classification requires swing high/low tracking (implemented via ZigZag logic)
- Liquidity target identification (equal highs/lows) approximated via recent N-bar range extremes

---

*Spec Version: 1.0 | Generated: 2026-09-13*
