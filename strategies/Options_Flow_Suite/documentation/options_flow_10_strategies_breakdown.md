# 🌊 Options Flow Algorithmic Strategy Suite: Complete Quantitative Breakdown

This specification details the mathematical models, order flow mechanisms, and execution parameters for the **10 distinct Options Flow Strategies** extracted from institutional literature, YouTube, TikTok, Twitter/X, and options analytics platforms (Unusual Whales, Cheddar Flow, SpotGamma, FlowAlgo).

---

## 1. Foundational Options Flow Mechanics

### A. Intermarket Sweep Orders (ISO) vs. Block Trades
* **Sweep Orders**: Large orders broken into smaller child orders and routed concurrently across all 16 US options exchanges to capture fragmented liquidity at or above the national best offer (Ask). Sweeps signify **extreme urgency and institutional directional conviction**.
* **Blocks**: Large single-exchange negotiated transactions ($>10,000$ contracts or $>\$1\text{M}$ premium). Can be directional, delta-neutral, or multi-leg spread legs.

### B. Dealer Gamma Exposure (GEX) & Market Maker Hedging
Market makers (dealers) who sell options to institutions are dynamically hedged:
$$\text{Dealer Delta Hedge Requirement} = - \sum \left( \Delta_{\text{options}} \times \text{Spot Price} \right)$$
* **Positive Gamma ($\Gamma > 0$, Above Gamma Flip)**:
  Dealers must **sell rallies and buy dips** to maintain delta neutrality. This acts as a volatility dampener, confining prices between the **Call Wall** and **Put Wall**.
* **Negative Gamma ($\Gamma < 0$, Below Gamma Flip)**:
  Dealers must **buy rallies and sell dips**. Hedging amplifies directional price moves, generating violent trend accelerations and volatility breakouts.

---

## 2. The 10 Quantitative Options Flow Strategies

### Strategy 0: The Golden Sweep Momentum Breakout (Urgent Smart Money Flow)
* **Thesis**: Institutions deploying $>\$1\text{M}$ in aggressive ask-side OTM contracts expect an imminent sharp directional expansion.
* **Entry Trigger**:
  * Bullish: Large volume spike at the Ask accompanied by price breaking above VWAP / session high.
  * Bearish: Large volume spike at the Bid accompanied by price breaking below VWAP / session low.
* **Risk & Target**: $1.0\text{ R:R}$ partial profit target (50% volume) with breakeven stop, runner trailed at $2.5\text{ R:R}$ via 1.5x ATR.

### Strategy 1: Repeat Institutional Accumulation (Flow Clustering)
* **Thesis**: A single sweep might be an isolated hedge, but $3+$ consecutive sweeps within a 15–30 minute cluster confirms high-conviction institutional accumulation.
* **Entry Trigger**:
  * Minimum 3 flow spikes in identical direction within $N$ lookback bars ($N=12$ bars on M5/M15).
  * Net Flow Skew $> 70\%$ bullish (Calls) or $> 70\%$ bearish (Puts).

### Strategy 2: Zero Gamma (Gamma Flip) Volatility Squeeze
* **Thesis**: When spot price crosses the Gamma Flip level into negative gamma, dealer hedging flips from mean-reversion to pro-trend amplification.
* **Entry Trigger**: Price crosses below the dynamic zero gamma threshold with expanding ATR ($> 1.25\times \text{ATR}_{20}$).

### Strategy 3: Call Wall / Put Wall Mean Reversion (Dealer Pin)
* **Thesis**: In positive gamma regimes, dealer hedging at the Call Wall (maximum call open interest) creates insurmountable resistance, and at the Put Wall creates strong support.
* **Entry Trigger**: Price tests within $0.2\%$ of the Call Wall or Put Wall and prints a reversal rejection wick ($\ge 40\%$). Target = mean reversion back to Gamma Flip.

### Strategy 4: 0DTE Open Momentum Squeeze (Opening 60-Minute Killzone)
* **Thesis**: 0DTE (same-day expiration) options carry extreme gamma sensitivity. A morning volume burst forces aggressive intraday dealer delta-hedging.
* **Entry Trigger**: Time window: 07:00–10:00 UTC (London Open) or 13:30–15:00 UTC (NY Open). Triggered on opening range breakout with volume surge $> 2.0\times$ baseline.

### Strategy 5: Dark Pool Signature Level + Options Flow Confluence
* **Thesis**: Institutions establish massive inventory via off-exchange Dark Pools, then hedge or trigger momentum via public options sweeps.
* **Entry Trigger**: Price re-tests a documented Dark Pool high-volume node accompanied by an ask-side sweep in the direction of the bounce.

### Strategy 6: Put/Call Ratio (PCR) Extreme Exhaustion (Contrarian Fade)
* **Thesis**: When retail panic drives Put/Call volume ratio to extreme highs ($> 2.5\sigma$ above 20-day mean) into major structural support, institutional absorption triggers a massive short squeeze.
* **Entry Trigger**: Contrarian reversal buy when PCR reaches extreme upper band; contrarian sell when PCR drops to extreme greed lower band.

### Strategy 7: Macro Tail-Risk Volatility Spillover (Safe Haven Flow)
* **Thesis**: Surges in VIX call sweeps or macro index put sweeps directly drive capital into Gold (`XAUUSD`) and safe-haven FX.
* **Entry Trigger**: Inter-market risk-off impulse: enter long Gold when options risk-off index spikes and Gold breaks intraday consolidation.

### Strategy 8: Bid-Side Trapped Retail Reversal
* **Thesis**: Retail chases breakouts buying calls, while smart money sells calls at the Bid (institutional distribution). Price forms an upper rejection wick as dealers absorb orders.
* **Entry Trigger**: Price prints a new session high but candle forms a $\ge 40\%$ upper wick with bid-side volume dominance. Enter short to punish trapped breakout buyers.

### Strategy 9: Synthetic Institutional Delta/Gamma Flow Engine (Quantitative MT5 Model)
* **Thesis**: On retail spot instruments (Gold, Indices, Forex), synthesize the institutional options delta and gamma exposure profile using tick volume imbalance, real-time implied volatility proxy, ATR variance, and synthetic dealer delta positioning.
* **Entry Trigger**: Quantitative cross of synthetic net dealer delta and gamma regime filter.

### Strategy 10: Hybrid Options Flow Champion (Multi-Confluence Engine)
* **Thesis**: Combines the highest-probability elements of all models:
  1. Gamma Regime Filter (confirms whether market is in trending or mean-reverting regime)
  2. Golden Sweep Volume Pulse (verifies institutional flow urgency)
  3. Rejection Wick Confirmation ($\ge 35\%$ wick confirming price acceptance)
  4. Dynamic Tiered Sizing ($25–$30 equity per 0.01 lot) with dual-target partial execution.
