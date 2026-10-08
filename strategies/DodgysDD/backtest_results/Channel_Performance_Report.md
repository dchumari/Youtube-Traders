# 📊 Strategy Optimization & Performance Report: DodgysDD

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
| **Optimal Champion** | `M2_Conservative_WideStop` | Single Runner | 2.5R | **$2,977.00** | **1.24** | **33.7%** | 2 375.00 (20.42%) | 86 |
| **High Win-Rate Partials** | `M4_DualPartials_BE` | Dual Partials (BE lock) | 1:1 / 2:0 | **$-1,814.40** | **0.82** | **51.2%** | 2 988.00 (29.88%) | 254 |
| **Conservative Balanced** | `M2_Conservative_WideStop` | Single Runner (Wide SL) | 2.5R | **$2,977.00** | **1.24** | **33.7%** | 2 375.00 (20.42%) | 86 |

---

## ⚙️ Champion Configuration Details (`DodgysDD_Optimal_Champion.set`)
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
| 1 | `M2_Conservative_WideStop` | 86 | $2,977.00 | 1.24 | 33.7% | 2 375.00 (20.42%) |
| 2 | `M4_Conservative_WideStop` | 87 | $1,877.00 | 1.15 | 32.2% | 2 498.00 (21.48%) |
| 3 | `M1_Conservative_WideStop` | 71 | $-537.00 | 0.94 | 28.2% | 2 740.00 (27.40%) |
| 4 | `M2_Runner_3.5R_NY` | 127 | $-1,010.25 | 0.96 | 22.1% | 8 106.00 (47.42%) |
| 5 | `M3_DualPartials_BE` | 174 | $-1,030.90 | 0.88 | 49.4% | 2 618.80 (23.48%) |
| 6 | `M4_Runner_3.5R_NY` | 127 | $-1,746.75 | 0.92 | 21.3% | 6 176.25 (42.98%) |
| 7 | `M4_DualPartials_BE` | 254 | $-1,814.40 | 0.82 | 51.2% | 2 988.00 (29.88%) |
| 8 | `M1_Runner_3.5R_NY` | 116 | $-2,087.25 | 0.87 | 20.7% | 4 293.75 (39.28%) |
| 9 | `M2_DualPartials_BE` | 238 | $-2,161.50 | 0.81 | 48.7% | 2 890.10 (26.94%) |
| 10 | `M3_Conservative_WideStop` | 60 | $-2,162.00 | 0.76 | 23.3% | 3 794.00 (32.62%) |
| 11 | `M3_Runner_2.5R_NY` | 113 | $-2,451.00 | 0.86 | 25.7% | 6 276.75 (45.44%) |
| 12 | `M1_DualPartials_BE` | 232 | $-2,632.80 | 0.73 | 47.0% | 3 150.90 (31.48%) |
| 13 | `M3_Runner_3.5R_NY` | 92 | $-3,046.50 | 0.80 | 18.5% | 6 432.75 (48.05%) |
| 14 | `M4_Runner_2.5R_NY` | 160 | $-3,312.75 | 0.84 | 25.6% | 4 140.00 (38.84%) |
| 15 | `M1_Runner_2.5R_NY` | 151 | $-3,473.25 | 0.80 | 25.2% | 4 326.75 (42.12%) |
| 16 | `M3_TightSL_MultiSession` | 167 | $-3,727.20 | 0.73 | 27.5% | 4 470.00 (44.70%) |
| 17 | `M2_TightSL_MultiSession` | 176 | $-3,736.80 | 0.73 | 27.8% | 4 292.40 (41.67%) |
| 18 | `M1_TightSL_MultiSession` | 186 | $-4,113.60 | 0.75 | 27.4% | 4 514.40 (45.14%) |
| 19 | `M2_Runner_2.5R_NY` | 155 | $-4,380.00 | 0.79 | 23.9% | 5 523.75 (49.57%) |
| 20 | `M4_TightSL_MultiSession` | 173 | $-5,979.60 | 0.51 | 22.0% | 6 124.80 (60.37%) |
