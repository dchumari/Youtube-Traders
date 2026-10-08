# 📊 Strategy Optimization & Performance Report: Cove_Trader

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
| **Optimal Champion** | `M1_Conservative_WideStop` | Single Runner | 2.5R | **$-219.00** | **0.98** | **28.8%** | 3 029.00 (25.44%) | 66 |
| **High Win-Rate Partials** | `M1_DualPartials_BE` | Dual Partials (BE lock) | 1:1 / 2:0 | **$-3,007.00** | **0.68** | **45.2%** | 3 493.00 (34.93%) | 210 |
| **Conservative Balanced** | `M1_Conservative_WideStop` | Single Runner (Wide SL) | 2.5R | **$-219.00** | **0.98** | **28.8%** | 3 029.00 (25.44%) | 66 |

---

## ⚙️ Champion Configuration Details (`Cove_Trader_Optimal_Champion.set`)
```ini
StrategyModel=1
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
| 1 | `M3_Runner_3.5R_NY` | 0 | $0.00 | 0.00 | 0.0% | 0.00 (0.00%) |
| 2 | `M3_Conservative_WideStop` | 0 | $0.00 | 0.00 | 0.0% | 0.00 (0.00%) |
| 3 | `M1_Conservative_WideStop` | 66 | $-219.00 | 0.98 | 28.8% | 3 029.00 (25.44%) |
| 4 | `M1_Runner_3.5R_NY` | 99 | $-641.25 | 0.96 | 22.2% | 5 391.00 (39.73%) |
| 5 | `M4_Conservative_WideStop` | 68 | $-2,351.00 | 0.73 | 23.5% | 3 709.00 (35.04%) |
| 6 | `M1_Runner_2.5R_NY` | 128 | $-2,649.75 | 0.86 | 25.8% | 5 775.75 (45.90%) |
| 7 | `M2_Conservative_WideStop` | 55 | $-2,950.00 | 0.60 | 20.0% | 3 369.00 (33.41%) |
| 8 | `M1_DualPartials_BE` | 210 | $-3,007.00 | 0.68 | 45.2% | 3 493.00 (34.93%) |
| 9 | `M2_DualPartials_BE` | 148 | $-3,237.60 | 0.57 | 39.2% | 3 434.10 (34.34%) |
| 10 | `M4_DualPartials_BE` | 240 | $-3,721.10 | 0.64 | 44.2% | 4 090.40 (40.90%) |
| 11 | `M3_TightSL_MultiSession` | 176 | $-4,281.60 | 0.73 | 26.7% | 5 584.80 (49.73%) |
| 12 | `M3_DualPartials_BE` | 226 | $-4,427.90 | 0.55 | 44.2% | 4 548.20 (45.44%) |
| 13 | `M4_Runner_3.5R_NY` | 113 | $-4,564.50 | 0.69 | 16.8% | 6 020.25 (55.88%) |
| 14 | `M1_TightSL_MultiSession` | 177 | $-5,053.20 | 0.68 | 24.9% | 5 409.60 (53.32%) |
| 15 | `M2_Runner_3.5R_NY` | 83 | $-5,064.00 | 0.51 | 13.2% | 5 661.75 (55.09%) |
| 16 | `M2_TightSL_MultiSession` | 115 | $-5,064.00 | 0.49 | 20.0% | 5 275.20 (52.75%) |
| 17 | `M2_Runner_2.5R_NY` | 94 | $-5,143.50 | 0.51 | 18.1% | 5 675.25 (56.27%) |
| 18 | `M4_TightSL_MultiSession` | 185 | $-5,418.00 | 0.66 | 24.3% | 5 685.60 (56.04%) |
| 19 | `M4_Runner_2.5R_NY` | 150 | $-6,400.50 | 0.58 | 19.3% | 7 806.75 (71.07%) |
| 20 | `M3_Runner_2.5R_NY` | 140 | $-6,426.00 | 0.61 | 18.6% | 7 629.00 (69.47%) |
