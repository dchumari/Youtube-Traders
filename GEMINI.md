# YouTube Traders Quantitative Algorithmic Trading Knowledge Base & Project Rules

This document synthesizes and preserves all project learnings, mathematical formulations, backtest matrices, and architecture standards across all project conversations.

---

## 1. Project Lineage & Historical Conversation Matrix

| Conversation ID | Topic / Core Objective | Key Deliverables & Breakthroughs |
| :--- | :--- | :--- |
| `a74c5e3c-98c5-4e64-a04a-162c3404886a` | **Foundational Architecture & 10 ICT Channels** | Isolated directory structure `./strategies/{channel}/`; MQL5 EAs for DonVo, RockzFX, WicksDontLie, Wealth_Secret, TradeIQ_Academy, Stock_Sniper_Trading, MSB_FX, Lorenzo_Corrado, FX_WOLF, ACT_Forex_Academy. |
| `f0432a77-3fff-4d23-ac17-fdd2b1bcea6c` | **Top 10 Strategies Report & 1-Week Doubling** | Calibrated `Gold_Micro_HyperScalp_EA`, `Master_Super_Strategy`, `TradeIQ_Academy`, `DodgysDD`. Upgraded visualizer v3.80 (boxed zones, past trade color coding, auto-scroll bug fix). |
| `053a8716-10c3-4ff0-be00-577d9ec58565` | **1,000 KES Challenge & Multi-Horizon Stress Matrix** | Analyzed micro-capital ($7.75 USD) margin math on Gold at 1:400 leverage. Introduced Cent Account (775 USC) paradigm. Tested 18 EAs across 4-window matrices (1W, 1M, 3M, 6M, 1Y). |
| `fbf4d4da-fa3e-4da1-b237-499f56fe6afe` | **Autonomous Institutional Algo Suite (Quant01-10)** | Created `QuantCore.mqh` execution harness; built Quant01 (Asian Sweep Sniper) through Quant10 (Daily CPR Momentum); multi-regime stress validation. |
| `3bdb51a7-be68-4872-a687-720f237a28e3` | **Mr P FX YouTube Mining & 16-Window Optimization** | Scraped 80+ videos; extracted 4 core strategies; built `MrPFx_Master_Suite.mq5`. Champion: Strategy 3 (Fair Value Gap Trend Continuation) passed 3/4 windows. Profit expansion math from 0.01 lot. |
| `908548ce-da6e-4067-ad2d-a1589ba235cd` | **Daily Range Fibonacci 61.8% & Virgin Levels** | Daily bullish/bearish candle 61.8% pullback + virgin key levels. Pine Script & MQL5 indicator. EAs: Baseline, V2 (Partials/Trail), Institutional (Session/EMA/Wick), Aggressive Math (Tiered sizing). |

---

## 2. Mandatory Architectural & Directory Standards

1. **Strict Channel & Strategy Isolation**:
   - Every YouTube channel or strategy MUST reside in its own isolated directory under `./strategies/{channel_name}/`.
   - Required subdirectories:
     - `source_data/`: Scraped transcripts, video JSONs, descriptions.
     - `documentation/`: Strategy rules, entry/exit criteria, indicators.
     - `ea_code/`: MQL5 `.mq5` source and `.ex5` compiled binaries.
     - `presets/`: Calibrated `.set` configuration files.
     - `backtest_results/`: Logs, HTM reports, and equity curves.
     - `strategy_report.md`: Dedicated summary for that channel.

2. **MT5 Local Testing Environment**:
   - Terminal executable: `C:\Program Files\MetaTrader 5\terminal64.exe`
   - MT5 Data Folder: `C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075`
   - Secondary MT5 Sandbox: `d:\MT5_Tester`
   - Strategy Tester run headless via `/config:{ini_path}` with automated report generation.

---

## 3. Mathematical Models & Capital Sizing Principles

### A. Micro-Capital & 1,000 KES Reality Check
- **Context**: 1,000 Kenyan Shillings $\approx \$7.75\text{ USD}$.
- **Gold Margin at 1:400 Leverage**:
  $$\text{Contract Value} = 0.01 \text{ lot} \times 100 \text{ oz} \times \$2,500 = \$2,500$$
  $$\text{Margin Required} = \frac{\$2,500}{400} = \$6.25\text{ USD}$$
  $$\text{Free Margin Buffer} = \$7.75 - \$6.25 = \$1.50\text{ USD} \quad (\approx 15 \text{ pips before stop-out})$$
- **The Cent Account (USC) Solution**:
  - Deposit 1,000 KES into an Exness Standard Cent Account $\rightarrow$ Balance = `775.00 USC`.
  - Margin for 0.01 lot = `6.25 USC`. Free margin buffer = `768.75 USC` ($>99\%$ margin buffer).

### B. Profit Expansion Flow: Dynamic Equity Tiering
- A static `0.01` lot cap on Gold produces only $\$1.00$ per 100-point (\$10 Gold) move, capping 9-month returns to $\sim \$55$.
- **Aggressive Tiered Mathematical Compounding Formula**:
  $$\text{Lot Size} = \max\left(0.01, \min\left(\text{MaxLotCap}, \left\lfloor \frac{\text{Equity}}{\text{EquityTierStep}} \right\rfloor \times 0.01\right)\right)$$
  - Conservative step: $\$50.00$ equity per $0.01$ lot.
  - Aggressive step: $\$25.00 - \$30.00$ equity per $0.01$ lot.
- **Dual-Target Execution**:
  - **Part 1 (50% Volume)**: Quick TP at $1.0\text{ R:R}$ $\rightarrow$ moves Stop Loss to Breakeven $+ 10\text{ points}$.
  - **Part 2 (50% Volume)**: Extended Runner TP at $2.5\text{ R:R}$ with ATR trailing stop.

---

## 4. Proprietary Strategies & Key Findings

### 1. Daily Range Fibonacci 61.8% & Virgin Level Strategy
- **Bearish Day ($C_{D-1} < O_{D-1}$)**:
  - Fib 100% at Day High, Fib 0% at Day Low.
  - Pullback Entry Level:
    $$\text{Level}_{61.8} = \text{Low} + 0.618 \times (\text{High} - \text{Low})$$
  - Action: Sell on rejection wick ($\ge 35\%$ upper wick) entering London/NY session.
- **Bullish Day ($C_{D-1} > O_{D-1}$)**:
  - Fib 100% at Day Low, Fib 0% at Day High.
  - Pullback Entry Level:
    $$\text{Level}_{61.8} = \text{High} - 0.618 \times (\text{High} - \text{Low})$$
  - Action: Buy on rejection wick ($\ge 35\%$ lower wick) entering London/NY session.
- **Virgin 61.8% Level Theory**:
  - If price fails to touch the 61.8% level during day $D$, the level remains "virgin" for up to 30 days.
  - When retested in future days/weeks, it provides institutional reaction setups.

### 2. Mr P FX Strategy Suite (`MrPFx_Master_Suite.mq5`)
- **Strategy 0**: Institutional Liquidity Grab (Asian high/low sweep + wick rejection).
- **Strategy 1**: Smart Money Break of Structure (BOS + Order Block retest).
- **Strategy 2**: London Killzone Momentum (07:00-10:00 UTC).
- **Strategy 3 (Top Performer)**: Fair Value Gap (FVG) Trend Continuation. Consistently passes 3 out of 4 distinct windows across multi-month horizons.

### 3. Institutional Quantitative Suite (`QuantCore.mqh` / Quant01-Quant10)
- `Quant01`: Asian Sweep Sniper EA (London Open liquidity run).
- `Quant02`: FVG Mitigation Flow EA.
- `Quant09`: London Judas Killzone EA (ICT false breakout model).
- `Quant10`: Daily CPR Momentum EA (Virgin CPR & width expansion).

---

## 5. UI, Visualization & Operational Preferences

1. **Chart Visualizer Standards (`VisualTradeSuite.mqh`)**:
   - Must render trade entries as rectangular colored boxes/zones (not thin lines).
   - Past trades MUST be color-coded: **Green** for winning trades, **Red** for stop-outs / loss trades.
   - Disable automatic chart tick reset to avoid fighting manual user scrolling.
2. **Backtesting Validation Framework**:
   - Always validate candidate strategies against at least **4 distinct windows** (stress windows: NFP week, CPI/FOMC week, Carry trade unwind, Election run-up).
   - A strategy is considered viable only if it achieves profit in at least **3 out of 4 distinct windows**.
3. **Execution Mode Preference**:
   - Prefer background/headless execution for automated testing and backtesting tasks.
   - Provide concrete `.set` presets for every tested tier (Conservative, Balanced, Aggressive Doubler).
