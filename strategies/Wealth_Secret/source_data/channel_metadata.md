# Channel Metadata — Wealth Secret

## Channel Info
- **Channel Name**: Wealth Secret
- **Platform**: Elefin / XM Broker
- **Source**: Gemini Shared Analysis + YouTube public content

## Strategy Classification
- **Type**: High-Impact Macro Catalyst Breakout / News Trading
- **Instrument Focus**: XAUUSD (highly reactive to US macro releases)
- **Primary Timeframes**: 5M (pre-news range), 1M (post-release entry), 15M (target)

## Session Profile
- **Event-Driven**: Not session-based — tied to economic calendar
- **Target Events**: US CPI, PPI, NFP, FOMC rate decisions, Initial Jobless Claims
- **Pre-Event Window**: 30 minutes before release (range building)
- **Post-Release Window**: 0–15 minutes after release (momentum execution)

## Key Concepts — News Breakout Framework

### Pre-Event Setup (T-30 to T-0 minutes)
1. Mark the 5M consolidation range in the 30 minutes prior to news release
2. Range high and low become straddle boundaries
3. Do NOT place pending orders (slippage risk during release spike)

### Post-Release Execution (T+1 to T+5 minutes)
1. **Initial Spike**: First 1M candle after release — observe direction and magnitude
2. **Retracement**: Wait for first pullback (30–50% of initial spike)
3. **Secondary Impulse Entry**: Enter in direction of initial spike on 1M candle close after pullback
4. **Invalidation**: If price retraces more than 61.8% of initial spike, cancel trade
5. **Target**: Pre-news range opposite extreme, then prior day high/low extension

### News Event Filtering
- Only trade Tier-1 events: CPI, NFP, FOMC, PPI
- Required deviation: Actual result must deviate from forecast by significant margin
  - CPI: ≥ 0.2% deviation from forecast
  - NFP: ≥ 50K deviation from forecast
- Skip if actual = expected (no catalyst for directional move)

## Risk Parameters Observed
- **Stop Loss**: Pre-news range midpoint (if long) / midpoint (if short)
- **Take Profit**: 2x the pre-news range width (or prior day H/L)
- **Risk per Trade**: 1–2% (higher risk due to infrequent setups)
- **Max Spread**: Avoid entering if spread > 50 points (0.50 USD)

## Critical Automation Note
- EA requires integration of economic calendar data OR manual news hour blocking
- EA implements a "news blackout mode" instead of live news detection
- Configurable news times as input parameters (hour:minute arrays)

## Scraping Notes
- YouTube Channel: Wealth Secret
- Live streams show exact pre/post news range construction
- Strategy is highly systematic with clear numeric thresholds
