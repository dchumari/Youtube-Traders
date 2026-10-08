# 📋 Implementation Plan: Automated Multi-Setting Optimization & Discovery of 5 Strict Multi-Window 30-Day Doubling Strategies (+100% in 30 Days at 1:400 Leverage)

## 🎯 User Refined Directive & Mission

Following your explicit voice guidance:
> *"I want strategies that at least can yield at least 100% on $1,000 and $20 in 30 days in each window... If all 4 windows pass, that's a good strategy. But if one window fails, that's a good strategy. At most one window fail. If two windows fail or it has a warning sign, that's not a good strategy. One window can be a fail or show a warning sign... for it to come up as a good strategy. Do that loop until you find 5 strategies!*
> *And you can come up with their optimal settings, so that you can improve... optimal metrics of settings, combination of settings, so that you can prove that each window actually pass all the requirements with 100%. Because some settings may not work, some may work. But on a strategy, have multiple settings run, so that you can get the optimal settings before you discard a strategy and go to the next strategy."*

### Core Quantitative Hurdle
1. **Multi-Window 30-Day Protocol**:
   - Window 1: **January 2024** (30 Days: 2024.01.01 – 2024.01.31)
   - Window 2: **March 2024** (30 Days: 2024.03.01 – 2024.03.31)
   - Window 3: **October 2024** (30 Days: 2024.10.01 – 2024.10.31)
   - Window 4: **November 2024** (30 Days: 2024.11.01 – 2024.11.30) [or **August 2024**]
2. **Dual Account Sizing at 1:400 Broker Leverage**:
   - **$1,000 Starting Account**: Must achieve $\ge \mathbf{+100\%}$ Net Return ($\ge +\$1,000$ net profit) independently in the 30-day window.
   - **$20 Micro Starting Account**: Must achieve $\ge \mathbf{+100\%}$ Net Return ($\ge +\$20$ net profit) independently in the 30-day window.
3. **Strict Acceptance Standard**:
   - **At least 3 out of 4 windows must pass with $\ge 100\%$ return on BOTH account tiers.**
   - At most **1 window** can fail or show a warning sign.
   - If 2 or more windows fail on a setting, that setting is rejected.
4. **Multi-Setting Parameter Sweep Requirement**:
   - A strategy will **never** be discarded after only one test.
   - For each candidate strategy, we will run an automated parameter sweep across key levers (Risk %, Step lot scaling, Stop Loss, Target RR, Breakeven trigger, CPR narrow filter, Volume multiplier, and Session Hours) to find its optimal setting combination.
5. **Output**:
   - Exactly **5 unique, orthogonal strategies** certified under this strict standard.

---

## 🔬 Candidate Pool & Parameter Space to Sweep

We will evaluate the following candidate engines in order, sweeping a targeted grid of 6 to 12 parameter configurations per strategy:

```
STRATEGY CANDIDATE POOL & SWEEP PARAMETERS:
├── 1. Gold_Master_Super_EA (Impulse Displacement + Dynamic ATR Envelope + Partials/BE)
│   ├── Levers: Risk (7%-12%), SL (12-18p), RR (2.2R-3.0R), BE Trigger (1.0R-1.5R), Step ($12-$18)
│   └── Current Baseline: Passed Jan (+129%), Mar (+136%), Oct (+144%/$1k, +201%/$20).
│
├── 2. TradeIQ_Academy_EA (Dynamic 200 EMA Trend + CPR Retest + Dual MACD Momentum)
│   ├── Levers: Risk (7%-10%), CPR Narrow Max (14-22p), Fast MACD, London/NY Session filter, BE Trigger
│   └── Current Baseline: Passed Jan (+102%/$1k, +148%/$20), Oct (+109%/$1k, +167%/$20).
│
├── 3. Gold_Micro_HyperScalp_EA (Micro CPR Compression + Asian Sweep + Volume Scalper)
│   ├── Levers: CapitalPerMicroLot ($10-$16), Asian Sweep Buffer (2.0-4.0p), Vol Spike Ratio (1.15-1.30x)
│   └── Current Baseline: Passed Oct (+150%/$1k, +192%/$20), March was +84.5% ($20).
│
├── 4. Ali_Khan_ICT_EA (Candle Body Displacement + NY Killzone FVG Expansion)
│   ├── Levers: StrategyModel (M1-M4), FVG Min (2.0-4.0p), Target RR (2.5R-3.5R), NY Session (13-18 UTC)
│   └── Current Baseline: Top ICT performer (+31.5% in raw Q4 baseline, ready for doubling calibration).
│
├── 5. LumiTraders_EA / Hunter_DiVenzo_EA (ICT 2022 Mentorship FVG + Order Block Retest)
│   ├── Levers: StrategyModel (M1/M3), SL Pips (12-18p), Target RR (2.5R-3.5R), Vol Filter (true/false)
│   └── Current Baseline: +30.4% in raw Q4 baseline, high win-rate partials (57.1%).
│
├── 6. DodgysDD_EA (Institutional Macro News Judas Manipulation + Order Block Invalidation)
│   ├── Levers: News Sweep Pips (2.0-4.0p), Vol Multiplier (1.10-1.25x), RR (2.5R-3.2R)
│   └── Current Baseline: Passed Oct (+172%/$1k, +171%/$20).
│
└── 7. CPR_Velocity_Doubler_EA (Daily CPR Narrow Compression + FVG Velocity Expansion)
    ├── Levers: CPR Narrow Max (18-35p), Min FVG (2.0-3.5p), Target RR (2.5R-3.2R), Session Open
    └── Current Baseline: Passed Oct (+105%/$1k, +142%/$20).
```

---

## ⚙️ Automated Multi-Setting Optimization Engine

We will deploy an automated script:
`scratch/run_multiwindow_optimization_loop.py`
which executes the following loop:

```
[For Each Strategy in Candidate Pool]
       │
       ▼
[Generate Parameter Grid: 6 to 12 Combinations]
       │
       ▼
[For Each Setting Combination]
       │
       ├── Run Window 1 (Jan 2024) @ $1,000 & $20 -> Pass? (Both >= 100%)
       ├── Run Window 2 (Mar 2024) @ $1,000 & $20 -> Pass? (Both >= 100%)
       ├── Run Window 3 (Oct 2024) @ $1,000 & $20 -> Pass? (Both >= 100%)
       └── Run Window 4 (Nov/Aug)  @ $1,000 & $20 -> Pass? (Both >= 100%)
       │
       ▼
[Calculate Score: Total Passing Windows]
       │
       ├── If Passing Windows >= 3 (At most 1 fail):
       │     ==> STRATEGY CERTIFIED AS WINNER!
       │     ==> Save Optimal Preset (.set) & HTML Reports
       │     ==> Add to Certified Top 5
       │
       └── If Passing Windows < 3:
             ==> Evaluate Next Parameter Setting
             ==> If all settings exhausted with < 3 passes, advance to Next Candidate Strategy
       │
       ▼
[Stop Loop when Certified Strategies == 5]
```

---

## 🏆 Deliverables & Final Output

Once the optimization loop locks in all 5 certified strategies:
1. **Isolated Strategy Directories**:
   - `ea_code/`: Clean, compiled `.mq5` and `.ex5` files.
   - `presets/`: Certified 1-click `.set` files for both `$1,000` and `$20` accounts.
   - `backtest_results/`: MT5 Strategy Tester `.htm` reports for every passing window.
2. **Updated Master Report**:
   - `FIVE_30DAY_DOUBLING_STRATEGIES_REPORT.md` updated with the multi-window certified matrix proving $\ge 3$ passes per strategy.
3. **Walkthrough & Task Checklist**:
   - Complete documentation in `walkthrough.md` and `task.md`.

---

## 🚦 Verification Plan

### Automated Backtest Execution
- Run `python -u scratch/run_multiwindow_optimization_loop.py` via `run_command` in background.
- Continuously monitor execution logs and report progression in real-time.
- Parse all generated `.htm` reports with BeautifulSoup to verify trades, net profit, ROI %, profit factor, and max drawdown.
