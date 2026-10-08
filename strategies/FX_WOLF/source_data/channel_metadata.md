# Channel Metadata — FX WOLF (@FX_WOLF__1)

## Channel Info
- **Channel Name**: FX WOLF
- **Handle**: @FX_WOLF__1
- **Platform**: ByteFX / Multi-Broker / Wolf Radar / Ghost Wolf proprietary software
- **Source**: Gemini Shared Analysis + Volume Profile methodology documentation

## Strategy Classification
- **Type**: Order Flow + Volume Profile Analysis
- **Instrument Focus**: XAUUSD, major indices
- **Primary Timeframes**: 1H/4H (context), 15M (volume structure), 5M/1M (entry)

## Session Profile
- **Primary Sessions**: New York + Asian Sessions
- **Key Windows**: Asian range consolidation (00:00–06:00 UTC), NY breakout (13:00–16:00 UTC)

## Key Concepts Observed
1. **POC (Point of Control)** — highest volume node on Volume Profile (VP)
2. **High-Volume Nodes (HVN)** — areas of congestion and potential support/resistance
3. **Low-Volume Nodes (LVN)** — thin areas where price travels fast (vacuum)
4. **Cumulative Delta Volume (CDV)** — net buying vs selling pressure over time
5. **CDV Divergence** — price making new high but CDV declining = bearish; vice versa
6. **Range Consolidation Detection** — identify range using VP width and delta flatness
7. **Ghost Wolf / Wolf Radar** — proprietary volume visualization tool (replicated via standard VP indicators in MT5)

## Risk Parameters Observed
- **Stop Loss**: Beyond opposite HVN or range extreme + small buffer
- **Take Profit**: Next POC or LVN gap (volume vacuum target)
- **Risk per Trade**: ~1% (standard prop firm approach)
- **Filters**: CDV must confirm directional bias before entry

## Automation Note
- Ghost Wolf / Wolf Radar proprietary tools NOT available in MT5 natively
- EA uses built-in Volume Profile approximation via tick volume and bar volume analysis
- ATR-based dynamic SL used as proxy for VP level-based stops

## Scraping Notes
- YouTube Channel: @FX_WOLF__1
- Content focused on live stream order flow reading
- Volume profile concepts follow standard CME/VSA methodology
