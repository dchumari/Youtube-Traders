# 📊 Strategy Optimization & Performance Report: LumiTraders

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
| **Optimal Champion** | `M1_Runner_3.5R_NY` | Single Runner | 3.5R | **$3,040.50** | **1.15** | **25.4%** | 3 699.00 (24.50%) | 126 |
| **High Win-Rate Partials** | `M4_DualPartials_BE` | Dual Partials (BE lock) | 1:1 / 2:0 | **$-383.20** | **0.97** | **57.1%** | 1 876.10 (18.76%) | 280 |
| **Conservative Balanced** | `M1_Conservative_WideStop` | Single Runner (Wide SL) | 2.5R | **$-1,273.00** | **0.88** | **26.8%** | 2 373.00 (23.06%) | 82 |

---

## ⚙️ Champion Configuration Details (`LumiTraders_Optimal_Champion.set`)
```ini
StrategyModel=1
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
| 1 | `M1_Runner_3.5R_NY` | 126 | $3,040.50 | 1.15 | 25.4% | 3 699.00 (24.50%) |
| 2 | `M4_Runner_3.5R_NY` | 126 | $948.00 | 1.05 | 23.8% | 4 062.00 (29.39%) |
| 3 | `M1_Runner_2.5R_NY` | 159 | $303.00 | 1.01 | 29.6% | 4 920.75 (34.86%) |
| 4 | `M4_Runner_2.5R_NY` | 159 | $285.75 | 1.01 | 29.6% | 3 783.75 (30.21%) |
| 5 | `M4_DualPartials_BE` | 280 | $-383.20 | 0.97 | 57.1% | 1 876.10 (18.76%) |
| 6 | `M1_TightSL_MultiSession` | 184 | $-550.80 | 0.97 | 33.1% | 3 220.80 (28.97%) |
| 7 | `M4_TightSL_MultiSession` | 184 | $-550.80 | 0.97 | 33.1% | 3 220.80 (28.97%) |
| 8 | `M3_Conservative_WideStop` | 27 | $-602.00 | 0.85 | 25.9% | 1 365.00 (12.68%) |
| 9 | `M3_DualPartials_BE` | 92 | $-813.70 | 0.79 | 53.3% | 1 878.50 (18.78%) |
| 10 | `M1_DualPartials_BE` | 274 | $-1,067.10 | 0.90 | 54.7% | 1 924.10 (19.08%) |
| 11 | `M2_DualPartials_BE` | 242 | $-1,261.10 | 0.88 | 51.2% | 2 908.80 (27.39%) |
| 12 | `M1_Conservative_WideStop` | 82 | $-1,273.00 | 0.88 | 26.8% | 2 373.00 (23.06%) |
| 13 | `M3_Runner_3.5R_NY` | 42 | $-1,353.75 | 0.80 | 19.1% | 2 972.25 (26.49%) |
| 14 | `M2_Runner_2.5R_NY` | 145 | $-1,552.50 | 0.93 | 27.6% | 6 166.50 (46.00%) |
| 15 | `M2_Runner_3.5R_NY` | 120 | $-2,027.25 | 0.89 | 20.8% | 5 684.25 (44.42%) |
| 16 | `M3_TightSL_MultiSession` | 87 | $-2,148.00 | 0.74 | 27.6% | 2 737.20 (26.98%) |
| 17 | `M4_Conservative_WideStop` | 81 | $-2,757.00 | 0.74 | 23.5% | 3 251.00 (31.59%) |
| 18 | `M3_Runner_2.5R_NY` | 54 | $-2,813.25 | 0.66 | 20.4% | 4 173.00 (36.73%) |
| 19 | `M2_Conservative_WideStop` | 73 | $-3,085.00 | 0.69 | 21.9% | 4 205.00 (39.64%) |
| 20 | `M2_TightSL_MultiSession` | 163 | $-4,664.40 | 0.67 | 25.1% | 5 832.00 (55.12%) |
