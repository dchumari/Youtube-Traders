# 📊 Strategy Optimization & Performance Report: Arjo_MMT

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
| **Optimal Champion** | `M2_Conservative_WideStop` | Single Runner | 2.5R | **$2,633.00** | **1.19** | **33.3%** | 3 001.00 (19.20%) | 84 |
| **High Win-Rate Partials** | `M4_DualPartials_BE` | Dual Partials (BE lock) | 1:1 / 2:0 | **$-2,200.70** | **0.79** | **50.8%** | 2 200.70 (22.01%) | 244 |
| **Conservative Balanced** | `M2_Conservative_WideStop` | Single Runner (Wide SL) | 2.5R | **$2,633.00** | **1.19** | **33.3%** | 3 001.00 (19.20%) | 84 |

---

## ⚙️ Champion Configuration Details (`Arjo_MMT_Optimal_Champion.set`)
```ini
StrategyModel=2
ExecutionMode=0
SingleTarget_RR=2.5
RiskPercent=2.0
SL_Pips=20.0
Min_FVG_Pips=3.5
Sweep_Pips=3.0
UseVolumeFilter=1
StartHourUTC=13
EndHourUTC=18
MaxDailyTrades=2
MaxDailyLosses=1
```

---

## 🔬 Full Matrix Evaluation Table (All Evaluated Parameter Sets)

| # | Configuration Name | Trades | Net Profit ($) | Profit Factor | Win Rate (%) | Max Drawdown |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: |
| 1 | `M2_Conservative_WideStop` | 84 | $2,633.00 | 1.19 | 33.3% | 3 001.00 (19.20%) |
| 2 | `M4_DualPartials_BE` | 244 | $-2,200.70 | 0.79 | 50.8% | 2 200.70 (22.01%) |
| 3 | `M3_DualPartials_BE` | 246 | $-2,495.60 | 0.76 | 50.8% | 2 940.50 (29.40%) |
| 4 | `M4_Conservative_WideStop` | 79 | $-2,957.00 | 0.70 | 22.8% | 3 532.00 (35.03%) |
| 5 | `M2_Runner_3.5R_NY` | 127 | $-3,075.75 | 0.85 | 19.7% | 5 128.50 (42.55%) |
| 6 | `M1_Runner_2.5R_NY` | 150 | $-3,334.50 | 0.79 | 25.3% | 4 849.50 (48.50%) |
| 7 | `M2_DualPartials_BE` | 240 | $-3,465.20 | 0.69 | 44.6% | 3 675.60 (36.00%) |
| 8 | `M3_Conservative_WideStop` | 75 | $-3,790.00 | 0.60 | 20.0% | 3 790.00 (37.90%) |
| 9 | `M1_Conservative_WideStop` | 73 | $-3,971.00 | 0.56 | 19.2% | 3 971.00 (39.71%) |
| 10 | `M2_Runner_2.5R_NY` | 154 | $-4,266.00 | 0.77 | 24.0% | 4 524.75 (44.11%) |
| 11 | `M1_DualPartials_BE` | 210 | $-4,312.10 | 0.51 | 41.0% | 4 380.20 (43.80%) |
| 12 | `M2_TightSL_MultiSession` | 186 | $-4,377.60 | 0.72 | 26.9% | 4 825.20 (46.18%) |
| 13 | `M3_TightSL_MultiSession` | 178 | $-4,436.40 | 0.72 | 26.4% | 5 043.60 (47.55%) |
| 14 | `M1_Runner_3.5R_NY` | 124 | $-4,805.25 | 0.66 | 16.9% | 4 805.25 (48.05%) |
| 15 | `M4_TightSL_MultiSession` | 183 | $-4,839.60 | 0.70 | 25.7% | 5 726.40 (52.60%) |
| 16 | `M4_Runner_2.5R_NY` | 155 | $-5,094.00 | 0.69 | 22.6% | 5 442.75 (54.43%) |
| 17 | `M3_Runner_3.5R_NY` | 127 | $-5,535.75 | 0.58 | 15.8% | 6 018.75 (60.19%) |
| 18 | `M1_TightSL_MultiSession` | 172 | $-5,550.00 | 0.56 | 23.3% | 5 730.00 (57.30%) |
| 19 | `M3_Runner_2.5R_NY` | 154 | $-5,642.25 | 0.63 | 21.4% | 6 397.50 (63.98%) |
| 20 | `M4_Runner_3.5R_NY` | 128 | $-5,979.75 | 0.55 | 14.8% | 6 267.00 (62.67%) |
