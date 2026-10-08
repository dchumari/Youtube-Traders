# 📊 Strategy Optimization & Performance Report: TTrades

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
| **Optimal Champion** | `M3_Runner_3.5R_NY` | Single Runner | 3.5R | **$972.75** | **1.05** | **23.8%** | 2 973.00 (27.79%) | 126 |
| **High Win-Rate Partials** | `M3_DualPartials_BE` | Dual Partials (BE lock) | 1:1 / 2:0 | **$-1,010.70** | **0.91** | **54.1%** | 3 092.50 (27.60%) | 268 |
| **Conservative Balanced** | `M3_Conservative_WideStop` | Single Runner (Wide SL) | 2.5R | **$-750.00** | **0.92** | **27.9%** | 3 296.00 (31.39%) | 79 |

---

## ⚙️ Champion Configuration Details (`TTrades_Optimal_Champion.set`)
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
| 1 | `M3_Runner_3.5R_NY` | 126 | $972.75 | 1.05 | 23.8% | 2 973.00 (27.79%) |
| 2 | `M3_Runner_2.5R_NY` | 161 | $606.75 | 1.03 | 29.8% | 2 728.50 (25.49%) |
| 3 | `M3_Conservative_WideStop` | 79 | $-750.00 | 0.92 | 27.9% | 3 296.00 (31.39%) |
| 4 | `M3_DualPartials_BE` | 268 | $-1,010.70 | 0.91 | 54.1% | 3 092.50 (27.60%) |
| 5 | `M2_TightSL_MultiSession` | 191 | $-1,094.40 | 0.94 | 32.5% | 3 222.00 (27.43%) |
| 6 | `M4_DualPartials_BE` | 260 | $-2,492.60 | 0.79 | 51.1% | 3 714.70 (33.10%) |
| 7 | `M1_TightSL_MultiSession` | 184 | $-2,760.00 | 0.83 | 29.9% | 4 394.40 (40.84%) |
| 8 | `M3_TightSL_MultiSession` | 179 | $-3,162.00 | 0.80 | 29.1% | 3 162.00 (31.62%) |
| 9 | `M4_TightSL_MultiSession` | 178 | $-3,643.20 | 0.77 | 28.1% | 3 916.80 (39.17%) |
| 10 | `M2_DualPartials_BE` | 264 | $-4,033.40 | 0.64 | 48.5% | 4 253.20 (41.62%) |
| 11 | `M1_DualPartials_BE` | 206 | $-4,975.70 | 0.46 | 36.9% | 5 216.40 (52.16%) |
| 12 | `M1_Conservative_WideStop` | 72 | $-4,989.00 | 0.46 | 15.3% | 5 028.00 (50.28%) |
| 13 | `M2_Conservative_WideStop` | 73 | $-5,085.00 | 0.46 | 15.1% | 5 085.00 (50.85%) |
| 14 | `M4_Runner_2.5R_NY` | 149 | $-5,496.00 | 0.69 | 21.5% | 6 313.50 (58.36%) |
| 15 | `M4_Conservative_WideStop` | 70 | $-6,033.00 | 0.30 | 10.0% | 6 033.00 (60.33%) |
| 16 | `M1_Runner_2.5R_NY` | 152 | $-6,299.25 | 0.61 | 19.7% | 6 299.25 (62.99%) |
| 17 | `M4_Runner_3.5R_NY` | 128 | $-6,312.75 | 0.57 | 14.1% | 6 432.75 (64.33%) |
| 18 | `M1_Runner_3.5R_NY` | 128 | $-6,322.50 | 0.56 | 14.1% | 6 581.25 (65.81%) |
| 19 | `M2_Runner_3.5R_NY` | 128 | $-6,618.75 | 0.58 | 13.3% | 7 101.75 (67.75%) |
| 20 | `M2_Runner_2.5R_NY` | 151 | $-6,924.00 | 0.55 | 17.9% | 7 224.75 (70.23%) |
