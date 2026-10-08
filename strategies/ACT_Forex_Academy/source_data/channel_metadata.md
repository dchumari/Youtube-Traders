# Channel Metadata — A.C.T. Forex Academy

## Channel Info
- **Channel Name**: A.C.T. Forex Academy
- **Platform**: MetaTrader / MagicKeys position management hardware
- **Source**: Gemini Shared Analysis + YouTube public content

## Strategy Classification
- **Type**: Analyse-Confirm-Trade (A.C.T.) — Systematic 3-Step Framework
- **Instrument Focus**: XAUUSD (primary), major forex pairs
- **Primary Timeframes**: 4H (Analyse), 15M (Confirm), 5M (Trade entry)

## Session Profile
- **Primary Sessions**: London + New York
- **London Open**: 06:45 UK time (07:45 UTC) — pre-session analysis stream
- **Trade Window**: 07:00–12:00 UTC (London), 13:00–17:00 UTC (New York overlap)

## Key Concepts — A.C.T. System

### Step 1: ANALYSE (4H Timeframe)
- Draw trend corridors / channels on 4H chart
- Identify upper and lower boundaries of trend corridor
- Determine macro directional bias (bullish/bearish/ranging)
- Mark weekly open, monthly open, prior day high/low

### Step 2: CONFIRM (15M Timeframe)
- Wait for price to reach corridor boundary (upper for short, lower for long)
- Confirm via a **breakout** of a minor consolidation and **retest** on 15M
- Breakout candle must be strong displacement (body > 60% of candle range)
- Retest must not violate the breakout origin level

### Step 3: TRADE (5M Execution)
- On 5M: enter on limit order at retest zone or market order on confirmation close
- Use MagicKeys to execute partial exits automatically
- Position split: close 50% at 1:1, move SL to breakeven, run 50% to 1:2 or corridor boundary

## Risk Parameters Observed
- **Risk per Trade**: 0.5–1% explicitly stated
- **Stop Loss**: Beyond breakout origin + spread buffer
- **Take Profit 1**: 1:1 R:R (50% close)
- **Take Profit 2**: 1:2 or opposite corridor boundary
- **Breakeven**: Automatic via MagicKeys at TP1 hit
- **Max Spread**: 15 points (0.15 USD on XAUUSD)
- **News Filter**: 30 min before/after high-impact news

## Scraping Notes
- YouTube Channel: A.C.T. Forex Academy
- Daily 06:45 UK pre-market analysis streams available with S/R marking
- Systematic enough for direct EA quantification
