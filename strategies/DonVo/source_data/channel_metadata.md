# Channel Metadata — DonVo (DVS / @itsdonvo)

## Channel Info
- **Channel Name**: DonVo
- **Handle**: @itsdonvo / DVS
- **Platform**: MetaTrader 5
- **Source**: Gemini Shared Analysis + YouTube public content

## Strategy Classification
- **Type**: Drive Range Liquidity (DRL) + Market Structure
- **Instrument Focus**: XAUUSD primarily
- **Primary Timeframes**: 4H (range/bias), 1H (session ranges), 15M/5M (entry)

## Session Profile
- **Primary Session**: New York Open
- **Session Start**: 08:00 EST (13:00 UTC)
- **Trade Window**: 08:00–12:00 EST

## Key Concepts — Drive Range Liquidity (DRL)

### The DRL Framework
1. **Asian Session Range** — Mark high and low of Asian session (00:00–06:00 UTC)
2. **London Session Range** — Mark London open range (07:00–10:00 UTC)
3. **Liquidity Sweep** — Price runs above session high or below session low during NY open to grab stop orders
4. **Mean Reversion** — After sweep, price reverses sharply back into session range
5. **Entry Trigger** — Enter on confirmation candle after sweep rejection (bearish engulfing for short, bullish engulfing for long)
6. **Target** — Mid-range or opposite session extreme

### Specific Rules
- Must identify clear equal highs/lows (buy-side/sell-side liquidity) before trade
- Sweep must exceed range extreme by at least 5 pips (not just a tag)
- Entry on first 5M/15M candle close back below/above swept level
- Stop above/below sweep wick extreme

## Risk Parameters Observed
- **Stop Loss**: Above sweep wick high (for short) / below sweep wick low (for long)
- **Take Profit**: Opposite session range extreme (1:2–1:3 R:R typical)
- **Risk per Trade**: ~1%
- **News Filter**: Avoid 30 min before/after high-impact news

## Scraping Notes
- YouTube Channel: @itsdonvo
- Live stream narration clearly identifies session ranges and sweep moments
- Very systematic — easily quantifiable into EA rules
