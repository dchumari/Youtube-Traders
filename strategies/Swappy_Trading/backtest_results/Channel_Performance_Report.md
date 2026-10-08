# 📊 Strategy Optimization & Performance Report: Swappy_Trading

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
| **Optimal Champion** | `M1_Runner_2.5R_NY` | Single Runner | 2.5R | **$2,025.00** | **1.10** | **30.9%** | 2 544.00 (25.22%) | 165 |
| **High Win-Rate Partials** | `M3_DualPartials_BE` | Dual Partials (BE lock) | 1:1 / 2:0 | **$-2,446.30** | **0.76** | **52.7%** | 2 631.20 (26.04%) | 256 |
| **Conservative Balanced** | `M4_Conservative_WideStop` | Single Runner (Wide SL) | 2.5R | **$1,321.00** | **1.11** | **31.4%** | 1 607.00 (15.36%) | 86 |

---

## ⚙️ Champion Configuration Details (`Swappy_Trading_Optimal_Champion.set`)
```ini
StrategyModel=1
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
| 1 | `M1_Runner_2.5R_NY` | 165 | $2,025.00 | 1.10 | 30.9% | 2 544.00 (25.22%) |
| 2 | `M4_Conservative_WideStop` | 86 | $1,321.00 | 1.11 | 31.4% | 1 607.00 (15.36%) |
| 3 | `M2_TightSL_MultiSession` | 91 | $546.00 | 1.06 | 35.2% | 2 420.40 (20.45%) |
| 4 | `M1_Conservative_WideStop` | 84 | $280.00 | 1.02 | 29.8% | 2 021.00 (19.32%) |
| 5 | `M3_Runner_3.5R_NY` | 126 | $16.50 | 1.00 | 23.0% | 2 254.50 (21.33%) |
| 6 | `M2_Runner_2.5R_NY` | 0 | $0.00 | 0.00 | 0.0% | 0.00 (0.00%) |
| 7 | `M2_Runner_3.5R_NY` | 0 | $0.00 | 0.00 | 0.0% | 0.00 (0.00%) |
| 8 | `M2_DualPartials_BE` | 0 | $0.00 | 0.00 | 0.0% | 0.00 (0.00%) |
| 9 | `M2_Conservative_WideStop` | 0 | $0.00 | 0.00 | 0.0% | 0.00 (0.00%) |
| 10 | `M4_Runner_3.5R_NY` | 128 | $-352.50 | 0.98 | 22.7% | 3 412.50 (32.04%) |
| 11 | `M1_Runner_3.5R_NY` | 128 | $-355.50 | 0.98 | 22.7% | 3 414.00 (32.06%) |
| 12 | `M4_Runner_2.5R_NY` | 162 | $-930.75 | 0.95 | 28.4% | 3 264.00 (32.36%) |
| 13 | `M3_TightSL_MultiSession` | 196 | $-1,360.80 | 0.93 | 32.1% | 2 812.80 (26.70%) |
| 14 | `M3_Conservative_WideStop` | 80 | $-1,538.00 | 0.84 | 26.2% | 2 992.00 (29.92%) |
| 15 | `M3_DualPartials_BE` | 256 | $-2,446.30 | 0.76 | 52.7% | 2 631.20 (26.04%) |
| 16 | `M3_Runner_2.5R_NY` | 156 | $-2,751.00 | 0.85 | 26.3% | 3 504.75 (35.05%) |
| 17 | `M4_DualPartials_BE` | 254 | $-2,837.40 | 0.73 | 48.0% | 3 422.40 (33.91%) |
| 18 | `M1_DualPartials_BE` | 246 | $-3,452.10 | 0.66 | 45.9% | 3 756.80 (37.22%) |
| 19 | `M4_TightSL_MultiSession` | 173 | $-3,739.20 | 0.76 | 27.8% | 4 346.40 (40.98%) |
| 20 | `M1_TightSL_MultiSession` | 173 | $-4,008.00 | 0.75 | 27.2% | 4 917.60 (45.08%) |
