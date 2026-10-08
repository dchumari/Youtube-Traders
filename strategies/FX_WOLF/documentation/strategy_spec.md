# Strategy Specification — FX WOLF — Order Flow & Volume Profile
## Version 1.0 | XAUUSD Volume Profile + Cumulative Delta Strategy

---

## 1. Executive Summary

FX WOLF's strategy applies institutional order flow principles: Volume Profile (POC, HVN, LVN mapping) combined with Cumulative Delta Volume (CDV) divergence as a momentum/reversal signal. The proprietary "Ghost Wolf" / "Wolf Radar" tools are approximated using standard MT5 volume analysis and ATR-based dynamic levels. The strategy exploits the difference between price action and actual volume commitment.

---

## 2. Market Structure & Signal Generation

### 2.1 Volume Profile Construction (Session-Based)
- Volume Profile computed over the current session (Asian or NY)
- **POC (Point of Control)**: Price level with highest traded volume in session
- **HVN (High-Volume Node)**: Any level with volume > 1.5× session average volume
- **LVN (Low-Volume Node)**: Any level with volume < 0.5× session average volume

> **MT5 Note**: MT5 uses tick volume (number of ticks), not actual traded contracts. This is a reliable proxy for institutional activity on gold (high correlation with real volume on XAUUSD due to CME/spot correlation).

### 2.2 Cumulative Delta Volume (CDV)
- CDV = Σ (Volume of bullish bars − Volume of bearish bars) over session
- Bullish bar: Close > Open → add bar volume to CDV
- Bearish bar: Close < Open → subtract bar volume from CDV
- CDV is tracked cumulatively from session open

### 2.3 CDV Divergence Signals
**Bearish Divergence (Short Signal)**:
- Price making new session HIGH
- CDV simultaneously making new session LOW or falling
- Interpretation: Price rising on declining net buying = unsustainable move, likely reversal

**Bullish Divergence (Long Signal)**:
- Price making new session LOW
- CDV simultaneously making new session HIGH or rising
- Interpretation: Price falling on increasing net buying = smart money accumulation

### 2.4 Entry Conditions
After detecting CDV divergence:
1. Price must be within 10 pips of a POC or HVN level
2. Confirmation: A 5M candle closes in reversal direction from the divergence extreme
3. Entry: Market order on that candle close

### 2.5 Range Consolidation Filter
- Before using Volume Profile, confirm price is in a range (ATR(14) on 15M < 10 pips)
- In trending conditions, skip POC mean-reversion trades; follow breakout of LVN instead

---

## 3. Execution Windows (Session Filter)

| Parameter | Value |
|-----------|-------|
| Session 1 | Asian Range: 00:00–06:00 UTC |
| Session 2 | New York: 13:00–17:00 UTC |
| Reset | Volume profile resets at each session open |
| Day Filter | Monday–Friday |

---

## 4. Risk Parameters

| Parameter | Value |
|-----------|-------|
| Stop Loss | Beyond opposite HVN or session range extreme + ATR buffer |
| SL Method | ATR(14) × 1.5 or structure-based (whichever is smaller) |
| Take Profit | Next POC or LVN gap (volume vacuum) |
| Risk per Trade | 1% |
| CDV Confirmation | Required before entry |
| Max Daily Trades | 4 (2 per session) |

---

## 5. Input Parameter Matrix

```
// EA Inputs — FX_WOLF Volume Profile + CDV
input double   RiskPercent       = 1.0;
input bool     UseFixedLot       = false;
input double   FixedLot          = 0.01;
input int      VP_Bars           = 48;      // Bars to build Volume Profile
input double   HVN_Multiplier    = 1.5;    // Volume multiplier for HVN
input double   LVN_Multiplier    = 0.5;    // Volume multiplier for LVN
input int      CDV_Period        = 20;     // Bars for CDV calculation
input double   CDV_DivThreshold  = 0.3;   // Divergence threshold (30% delta vs price)
input double   ATR_SL_Multi      = 1.5;   // ATR multiplier for SL
input int      ATR_Period        = 14;
input double   MaxATR_Range      = 10.0;  // Max ATR pips for "range" condition
input int      SessionStart1     = 0;     // Asian session start (UTC)
input int      SessionEnd1       = 6;     // Asian session end (UTC)
input int      SessionStart2     = 13;    // NY session start (UTC)
input int      SessionEnd2       = 17;    // NY session end (UTC)
input int      MaxDailyTrades    = 4;
input double   MaxSpread         = 25;    // Max spread in points
```

---

## 6. Filter Constraints

| Filter | Rule |
|--------|------|
| Spread | Max 25 points |
| ATR Trending | Skip POC-mean reversion if ATR(14) 15M > 15 pips |
| CDV Required | No entry without CDV divergence confirmed |
| POC Proximity | Price must be within 10 pips of POC/HVN |

---

## 7. Mathematical Edge Analysis

- **Win Rate Target**: 50–58% (volume divergence is reliable but timing-sensitive)
- **Average R:R**: 2.0–2.5
- **Expected Value**: EV = (0.54 × 2.2) − (0.46 × 1) = 1.19 − 0.46 = **+0.73R per trade**
- **Profit Factor Target**: 1.5–2.0

---

## 8. Automation Limitations

- True volume profile requires tick data aggregation per price level — approximated using bar volume on MT5
- Proprietary Wolf Radar software cannot be replicated exactly; CDV divergence is the core exportable concept
- Session-based profile reset implemented via time-of-day checks

---

*Spec Version: 1.0 | Generated: 2026-09-13*
