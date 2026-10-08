# 📊 Strategy Optimization & Performance Report: Tanja_Trades

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
| **Optimal Champion** | `M1_Conservative_WideStop` | Single Runner | 2.5R | **$-1,000.00** | **0.81** | **25.0%** | 2 314.00 (21.25%) | 36 |
| **High Win-Rate Partials** | `M2_DualPartials_BE` | Dual Partials (BE lock) | 1:1 / 2:0 | **$-1,261.10** | **0.88** | **51.2%** | 2 908.80 (27.39%) | 242 |
| **Conservative Balanced** | `M1_Conservative_WideStop` | Single Runner (Wide SL) | 2.5R | **$-1,000.00** | **0.81** | **25.0%** | 2 314.00 (21.25%) | 36 |

---

## ⚙️ Champion Configuration Details (`Tanja_Trades_Optimal_Champion.set`)
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
| 1 | `M1_Conservative_WideStop` | 36 | $-1,000.00 | 0.81 | 25.0% | 2 314.00 (21.25%) |
| 2 | `M2_DualPartials_BE` | 242 | $-1,261.10 | 0.88 | 51.2% | 2 908.80 (27.39%) |
| 3 | `M2_Runner_2.5R_NY` | 145 | $-1,552.50 | 0.93 | 27.6% | 6 166.50 (46.00%) |
| 4 | `M3_Runner_2.5R_NY` | 159 | $-1,608.75 | 0.94 | 27.7% | 6 408.00 (44.63%) |
| 5 | `M1_DualPartials_BE` | 108 | $-1,903.80 | 0.67 | 42.6% | 2 528.60 (24.33%) |
| 6 | `M4_Runner_2.5R_NY` | 158 | $-2,007.00 | 0.92 | 27.2% | 6 097.50 (44.59%) |
| 7 | `M2_Runner_3.5R_NY` | 120 | $-2,027.25 | 0.89 | 20.8% | 5 684.25 (44.42%) |
| 8 | `M3_TightSL_MultiSession` | 186 | $-2,320.80 | 0.86 | 30.6% | 2 976.00 (29.74%) |
| 9 | `M4_TightSL_MultiSession` | 186 | $-2,320.80 | 0.86 | 30.6% | 2 976.00 (29.74%) |
| 10 | `M2_Conservative_WideStop` | 73 | $-3,085.00 | 0.69 | 21.9% | 4 205.00 (39.64%) |
| 11 | `M3_DualPartials_BE` | 234 | $-3,420.90 | 0.69 | 47.0% | 4 313.70 (39.60%) |
| 12 | `M4_DualPartials_BE` | 234 | $-3,420.90 | 0.69 | 47.0% | 4 313.70 (39.60%) |
| 13 | `M1_Runner_3.5R_NY` | 47 | $-3,438.00 | 0.50 | 12.8% | 4 207.50 (40.67%) |
| 14 | `M1_TightSL_MultiSession` | 73 | $-3,499.20 | 0.52 | 20.6% | 3 686.40 (36.86%) |
| 15 | `M3_Runner_3.5R_NY` | 128 | $-4,298.25 | 0.77 | 18.0% | 7 275.75 (57.72%) |
| 16 | `M4_Runner_3.5R_NY` | 128 | $-4,298.25 | 0.77 | 18.0% | 7 275.75 (57.72%) |
| 17 | `M2_TightSL_MultiSession` | 163 | $-4,664.40 | 0.67 | 25.1% | 5 832.00 (55.12%) |
| 18 | `M1_Runner_2.5R_NY` | 59 | $-4,703.25 | 0.40 | 13.6% | 4 954.50 (49.55%) |
| 19 | `M3_Conservative_WideStop` | 74 | $-4,833.00 | 0.52 | 16.2% | 5 968.00 (53.60%) |
| 20 | `M4_Conservative_WideStop` | 74 | $-4,833.00 | 0.52 | 16.2% | 5 968.00 (53.60%) |
