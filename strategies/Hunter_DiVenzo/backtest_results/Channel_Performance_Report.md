# 📊 Strategy Optimization & Performance Report: Hunter_DiVenzo

## 🏆 Certified Performance Summary (Q4 2024 Historical Backtest)
* **Symbol**: `XAUUSD` (Gold)
* **Timeframe**: `M1`
* **Test Model**: Open/OHLC Bar Execution (Model=2)
* **Initial Deposit**: $10,000.00
* **Leverage**: 1:100

---

## 🥇 Top Performing Strategy Configurations

| Preset Profile | Strategy Model | Execution Mode | Target R:R | Net Profit | Profit Factor | Win Rate | Max Drawdown | Total Trades |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Optimal Champion** | `M3_Runner_3.5R_NY` | Single Runner | 3.5R | **$3,040.50** | **1.15** | **25.4%** | 3 699.00 (24.50%) | 126 |
| **High Win-Rate Partials** | `M3_DualPartials_BE` | Dual Partials (BE lock) | 1:1 / 2:0 | **$-1,067.10** | **0.90** | **54.7%** | 1 924.10 (19.08%) | 274 |
| **Conservative Balanced** | `M2_Conservative_WideStop` | Single Runner (Wide SL) | 2.5R | **$1,802.00** | **1.13** | **32.1%** | 2 390.00 (18.10%) | 84 |

---

## ⚙️ Champion Configuration Details (`Hunter_DiVenzo_Optimal_Champion.set`)
```ini
StrategyModel=3
ExecutionMode=0
SingleTarget_RR=3.5
RiskPercent=2.0
SL_Pips=15.0
Min_FVG_Pips=3.0
Sweep_Pips=3.0
UseVolumeFilter=1
StartHourUTC=13
EndHourUTC=18
MaxDailyTrades=2
MaxDailyLosses=2
```

---

## 🔬 Full Matrix Evaluation Table (All Evaluated Parameter Sets)

| # | Configuration Name | Trades | Net Profit ($) | Profit Factor | Win Rate (%) | Max Drawdown |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: |
| 1 | `M3_Runner_3.5R_NY` | 126 | $3,040.50 | 1.15 | 25.4% | 3 699.00 (24.50%) |
| 2 | `M2_Conservative_WideStop` | 84 | $1,802.00 | 1.13 | 32.1% | 2 390.00 (18.10%) |
| 3 | `M4_Runner_3.5R_NY` | 127 | $711.75 | 1.03 | 23.6% | 2 916.75 (21.40%) |
| 4 | `M3_Runner_2.5R_NY` | 159 | $303.00 | 1.01 | 29.6% | 4 920.75 (34.86%) |
| 5 | `M3_TightSL_MultiSession` | 184 | $-550.80 | 0.97 | 33.1% | 3 220.80 (28.97%) |
| 6 | `M3_DualPartials_BE` | 274 | $-1,067.10 | 0.90 | 54.7% | 1 924.10 (19.08%) |
| 7 | `M3_Conservative_WideStop` | 82 | $-1,273.00 | 0.88 | 26.8% | 2 373.00 (23.06%) |
| 8 | `M4_Conservative_WideStop` | 81 | $-1,703.00 | 0.84 | 25.9% | 2 405.00 (23.37%) |
| 9 | `M4_DualPartials_BE` | 250 | $-2,344.40 | 0.79 | 50.8% | 3 147.80 (29.14%) |
| 10 | `M4_TightSL_MultiSession` | 181 | $-2,746.80 | 0.84 | 29.8% | 3 478.80 (32.42%) |
| 11 | `M1_DualPartials_BE` | 134 | $-2,982.80 | 0.58 | 37.3% | 3 185.30 (31.85%) |
| 12 | `M4_Runner_2.5R_NY` | 155 | $-3,093.75 | 0.86 | 25.8% | 5 407.50 (43.91%) |
| 13 | `M1_Conservative_WideStop` | 53 | $-3,142.00 | 0.56 | 18.9% | 3 551.00 (35.21%) |
| 14 | `M2_Runner_3.5R_NY` | 126 | $-3,526.50 | 0.83 | 19.1% | 7 398.75 (53.33%) |
| 15 | `M1_Runner_2.5R_NY` | 80 | $-3,566.25 | 0.62 | 21.2% | 4 521.75 (44.83%) |
| 16 | `M2_DualPartials_BE` | 224 | $-3,942.10 | 0.63 | 44.2% | 4 311.50 (41.58%) |
| 17 | `M1_TightSL_MultiSession` | 101 | $-4,182.00 | 0.52 | 21.8% | 4 430.40 (44.30%) |
| 18 | `M2_TightSL_MultiSession` | 176 | $-4,268.40 | 0.69 | 26.7% | 5 042.40 (47.66%) |
| 19 | `M1_Runner_3.5R_NY` | 69 | $-4,506.00 | 0.49 | 13.0% | 5 509.50 (53.61%) |
| 20 | `M2_Runner_2.5R_NY` | 149 | $-5,487.00 | 0.71 | 21.5% | 6 549.00 (59.20%) |
