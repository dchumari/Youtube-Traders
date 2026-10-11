import json
import os

EVENT_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Chart_Fanatics\backtest_results\CHART_FANATICS_BACKTEST_RESULTS.json"
RANDOM_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Chart_Fanatics\backtest_results\RANDOM_AND_MULTI_HORIZON_RESULTS.json"

with open(EVENT_JSON, "r", encoding="utf-8") as f:
    event_data = json.load(f)

with open(RANDOM_JSON, "r", encoding="utf-8") as f:
    rand_data = json.load(f)

print("=" * 80)
print("MULTI-HORIZON & RANDOM WINDOWS SUMMARY REPORT")
print("=" * 80)

# 1. 4 Random Weeks
print("\n### 1. FOUR RANDOM WEEKS PERFORMANCE (Non-Event Weeks across 2024)")
for sid, strat in rand_data.get("random_weeks", {}).items():
    name = strat["name"]
    print(f"\n#### {name} ({sid})")
    print("| Window | Setting A Net PnL (ROI) | Setting A PF | Setting A DD | Setting B Net PnL (ROI) | Setting B PF | Setting B DD |")
    print("| :--- | :--- | :--- | :--- | :--- | :--- | :--- |")
    
    orig_total_pnl = 0.0
    opt_total_pnl = 0.0
    orig_wins = 0
    opt_wins = 0
    
    for wname, o_res in strat.get("original", {}).items():
        b_res = strat.get("optimal", {}).get(wname, {})
        o_pnl = o_res.get("net_profit", 0.0)
        o_roi = o_res.get("roi_pct", 0.0)
        o_pf  = o_res.get("profit_factor", 0.0)
        o_dd  = o_res.get("drawdown_pct", 0.0)
        
        b_pnl = b_res.get("net_profit", 0.0)
        b_roi = b_res.get("roi_pct", 0.0)
        b_pf  = b_res.get("profit_factor", 0.0)
        b_dd  = b_res.get("drawdown_pct", 0.0)
        
        if o_pnl > 0: orig_wins += 1
        if b_pnl > 0: opt_wins += 1
        orig_total_pnl += o_pnl
        opt_total_pnl += b_pnl
        
        print(f"| **{wname}** | ${o_pnl:+.2f} ({o_roi:+.1f}%) | {o_pf:.2f} | {o_dd:.1f}% | **${b_pnl:+.2f} ({b_roi:+.1f}%)** | {b_pf:.2f} | {b_dd:.1f}% |")
    
    print(f"| **TOTAL / SUMMARY** | **${orig_total_pnl:+.2f} ({orig_wins}/4 Wins)** | - | - | **${opt_total_pnl:+.2f} ({opt_wins}/4 Wins)** | - | - |")

# 2. 4 Random Months
print("\n" + "=" * 80)
print("### 2. FOUR RANDOM MONTHS PERFORMANCE (Monthly Horizon across Q1-Q4)")
for sid, strat in rand_data.get("random_months", {}).items():
    name = strat["name"]
    print(f"\n#### {name} ({sid}) - Monthly Stress")
    print("| Month Window | Setting A Net PnL (ROI) | Setting A PF | Setting A DD | Setting B Net PnL (ROI) | Setting B PF | Setting B DD |")
    print("| :--- | :--- | :--- | :--- | :--- | :--- | :--- |")
    orig_total = 0.0
    opt_total = 0.0
    for mname, o_res in strat.get("original", {}).items():
        b_res = strat.get("optimal", {}).get(mname, {})
        o_pnl = o_res.get("net_profit", 0.0)
        o_roi = o_res.get("roi_pct", 0.0)
        o_pf  = o_res.get("profit_factor", 0.0)
        o_dd  = o_res.get("drawdown_pct", 0.0)
        
        b_pnl = b_res.get("net_profit", 0.0)
        b_roi = b_res.get("roi_pct", 0.0)
        b_pf  = b_res.get("profit_factor", 0.0)
        b_dd  = b_res.get("drawdown_pct", 0.0)
        
        orig_total += o_pnl
        opt_total += b_pnl
        print(f"| **{mname}** | ${o_pnl:+.2f} ({o_roi:+.1f}%) | {o_pf:.2f} | {o_dd:.1f}% | ${b_pnl:+.2f} ({b_roi:+.1f}%) | {b_pf:.2f} | {b_dd:.1f}% |")
    print(f"| **4-MONTH TOTAL** | **${orig_total:+.2f}** | - | - | **${opt_total:+.2f}** | - | - |")

# 3. Full Year 2024
print("\n" + "=" * 80)
print("### 3. FULL 1-YEAR HORIZON BENCHMARK (Entire Year 2024)")
print("| Strategy | Setting A 1-Yr Net (ROI) | Setting A PF | Setting A DD | Setting A Trades | Setting B 1-Yr Net (ROI) | Setting B PF | Setting B DD |")
print("| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |")
for sid, strat in rand_data.get("full_year", {}).items():
    name = strat["name"]
    o_res = strat.get("original", {})
    b_res = strat.get("optimal", {})
    print(f"| **{name}** | **${o_res.get('net_profit', 0.0):+.2f} ({o_res.get('roi_pct', 0.0):+.1f}%)** | {o_res.get('profit_factor', 0.0):.2f} | {o_res.get('drawdown_pct', 0.0):.1f}% | {o_res.get('total_trades', 0)} | ${b_res.get('net_profit', 0.0):+.2f} ({b_res.get('roi_pct', 0.0):+.1f}%) | {b_res.get('profit_factor', 0.0):.2f} | {b_res.get('drawdown_pct', 0.0):.1f}% |")
