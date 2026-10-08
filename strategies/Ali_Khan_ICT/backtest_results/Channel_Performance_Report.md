# 📊 Strategy Optimization & Performance Report: Ali_Khan_ICT

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
| **Optimal Champion** | `M2_Runner_2.5R_NY` | Single Runner | 2.5R | **$3,154.50** | **1.13** | **31.7%** | 4 417.50 (31.23%) | 164 |
| **High Win-Rate Partials** | `M2_DualPartials_BE` | Dual Partials (BE lock) | 1:1 / 2:0 | **$-1,365.80** | **0.88** | **56.2%** | 1 783.50 (17.28%) | 274 |
| **Conservative Balanced** | `M1_Conservative_WideStop` | Single Runner (Wide SL) | 2.5R | **$-945.00** | **0.92** | **27.5%** | 3 030.00 (25.07%) | 80 |

---

## ⚙️ Champion Configuration Details (`Ali_Khan_ICT_Optimal_Champion.set`)
```ini
StrategyModel=2
ExecutionMode=0
SingleTarget_RR=2.5
RiskPercent=2.0
SL_Pips=15.0
Min_FVG_Pips=2.5
Sweep_Pips=2.5
UseVolumeFilter=1
StartHourUTC=13
EndHourUTC=19
MaxDailyTrades=3
MaxDailyLosses=2
```

---

## 🔬 Full Matrix Evaluation Table (All Evaluated Parameter Sets)

| # | Configuration Name | Trades | Net Profit ($) | Profit Factor | Win Rate (%) | Max Drawdown |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: |
| 1 | `M2_Runner_2.5R_NY` | 164 | $3,154.50 | 1.13 | 31.7% | 4 417.50 (31.23%) |
| 2 | `M1_Conservative_WideStop` | 80 | $-945.00 | 0.92 | 27.5% | 3 030.00 (25.07%) |
| 3 | `M2_DualPartials_BE` | 274 | $-1,365.80 | 0.88 | 56.2% | 1 783.50 (17.28%) |
| 4 | `M1_DualPartials_BE` | 246 | $-2,442.20 | 0.79 | 49.6% | 3 825.50 (33.82%) |
| 5 | `M3_DualPartials_BE` | 246 | $-2,495.60 | 0.76 | 50.8% | 2 940.50 (29.40%) |
| 6 | `M4_DualPartials_BE` | 236 | $-3,022.60 | 0.70 | 48.3% | 3 310.80 (33.11%) |
| 7 | `M2_Runner_3.5R_NY` | 128 | $-3,206.25 | 0.78 | 19.5% | 4 727.25 (47.27%) |
| 8 | `M2_Conservative_WideStop` | 75 | $-3,364.00 | 0.66 | 21.3% | 3 793.00 (36.37%) |
| 9 | `M4_TightSL_MultiSession` | 180 | $-3,560.40 | 0.79 | 28.3% | 4 513.20 (41.21%) |
| 10 | `M3_Conservative_WideStop` | 75 | $-3,790.00 | 0.60 | 20.0% | 3 790.00 (37.90%) |
| 11 | `M1_Runner_3.5R_NY` | 126 | $-4,063.50 | 0.75 | 18.2% | 4 287.75 (41.94%) |
| 12 | `M2_TightSL_MultiSession` | 174 | $-4,094.40 | 0.72 | 27.0% | 4 377.60 (43.15%) |
| 13 | `M1_TightSL_MultiSession` | 175 | $-4,184.40 | 0.69 | 26.9% | 4 422.00 (44.22%) |
| 14 | `M4_Conservative_WideStop` | 75 | $-4,206.00 | 0.57 | 18.7% | 4 635.00 (44.44%) |
| 15 | `M1_Runner_2.5R_NY` | 151 | $-4,305.00 | 0.76 | 23.8% | 4 352.25 (43.52%) |
| 16 | `M3_TightSL_MultiSession` | 178 | $-4,436.40 | 0.72 | 26.4% | 5 043.60 (47.55%) |
| 17 | `M4_Runner_2.5R_NY` | 154 | $-5,004.75 | 0.71 | 22.7% | 5 354.25 (53.54%) |
| 18 | `M3_Runner_3.5R_NY` | 127 | $-5,535.75 | 0.58 | 15.8% | 6 018.75 (60.19%) |
| 19 | `M3_Runner_2.5R_NY` | 154 | $-5,642.25 | 0.63 | 21.4% | 6 397.50 (63.98%) |
| 20 | `M4_Runner_3.5R_NY` | 128 | $-5,982.00 | 0.56 | 14.8% | 6 091.50 (60.92%) |
