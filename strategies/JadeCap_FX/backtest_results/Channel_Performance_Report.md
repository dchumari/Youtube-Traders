# 📊 Strategy Optimization & Performance Report: JadeCap_FX

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
| **Optimal Champion** | `M1_Conservative_WideStop` | Single Runner | 2.5R | **$-491.00** | **0.96** | **28.4%** | 2 901.00 (26.26%) | 81 |
| **High Win-Rate Partials** | `M4_DualPartials_BE` | Dual Partials (BE lock) | 1:1 / 2:0 | **$-823.20** | **0.92** | **54.5%** | 2 647.20 (26.47%) | 264 |
| **Conservative Balanced** | `M1_Conservative_WideStop` | Single Runner (Wide SL) | 2.5R | **$-491.00** | **0.96** | **28.4%** | 2 901.00 (26.26%) | 81 |

---

## ⚙️ Champion Configuration Details (`JadeCap_FX_Optimal_Champion.set`)
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
| 1 | `M1_Conservative_WideStop` | 81 | $-491.00 | 0.96 | 28.4% | 2 901.00 (26.26%) |
| 2 | `M3_Conservative_WideStop` | 27 | $-601.00 | 0.85 | 25.9% | 1 090.00 (10.63%) |
| 3 | `M4_DualPartials_BE` | 264 | $-823.20 | 0.92 | 54.5% | 2 647.20 (26.47%) |
| 4 | `M2_DualPartials_BE` | 174 | $-1,030.90 | 0.88 | 49.4% | 2 618.80 (23.48%) |
| 5 | `M3_DualPartials_BE` | 86 | $-1,271.30 | 0.67 | 48.8% | 2 281.00 (22.81%) |
| 6 | `M1_DualPartials_BE` | 254 | $-1,461.60 | 0.84 | 53.1% | 3 599.70 (36.00%) |
| 7 | `M4_Conservative_WideStop` | 79 | $-1,943.00 | 0.82 | 25.3% | 2 981.00 (27.77%) |
| 8 | `M1_Runner_2.5R_NY` | 155 | $-2,079.75 | 0.88 | 27.1% | 4 005.00 (40.05%) |
| 9 | `M2_Conservative_WideStop` | 60 | $-2,162.00 | 0.76 | 23.3% | 3 794.00 (32.62%) |
| 10 | `M2_Runner_2.5R_NY` | 113 | $-2,451.00 | 0.86 | 25.7% | 6 276.75 (45.44%) |
| 11 | `M3_TightSL_MultiSession` | 87 | $-2,481.60 | 0.70 | 26.4% | 3 342.00 (32.03%) |
| 12 | `M4_Runner_2.5R_NY` | 155 | $-2,599.50 | 0.86 | 26.4% | 3 882.75 (38.83%) |
| 13 | `M3_Runner_3.5R_NY` | 43 | $-2,883.00 | 0.58 | 13.9% | 3 439.50 (32.58%) |
| 14 | `M3_Runner_2.5R_NY` | 55 | $-2,959.50 | 0.63 | 20.0% | 3 685.50 (34.36%) |
| 15 | `M2_Runner_3.5R_NY` | 92 | $-3,046.50 | 0.80 | 18.5% | 6 432.75 (48.05%) |
| 16 | `M2_TightSL_MultiSession` | 169 | $-3,640.80 | 0.75 | 27.8% | 4 390.80 (43.91%) |
| 17 | `M1_Runner_3.5R_NY` | 127 | $-4,185.75 | 0.73 | 18.1% | 5 463.00 (53.00%) |
| 18 | `M4_TightSL_MultiSession` | 178 | $-4,442.40 | 0.70 | 26.4% | 4 442.40 (44.42%) |
| 19 | `M1_TightSL_MultiSession` | 180 | $-4,606.80 | 0.69 | 26.1% | 4 606.80 (46.07%) |
| 20 | `M4_Runner_3.5R_NY` | 127 | $-5,112.00 | 0.69 | 16.5% | 6 587.25 (59.72%) |
