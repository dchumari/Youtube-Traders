import os
import sys
import json
import time

sys.path.insert(0, os.path.dirname(__file__))
from tester_runner import run_tester, compile_ea, DATA_FOLDER, WINDOWS

def phase1_screen(expert_path, symbol, period, inputs=""):
    """
    Phase 1 (Coarse Screen): Run candidate on two 1-month windows (M1 and M3).
    Discard immediately if Max Drawdown > 15% or Profit Factor < 1.3.
    """
    print(f"\n--- Phase 1 Coarse Screen: {expert_path} on {symbol} {period} ---")
    
    # Window M1
    r_m1 = run_tester(expert_path, symbol, period, WINDOWS["M1"]["from"], WINDOWS["M1"]["to"], deposit=100.0, inputs=inputs)
    print(f"  M1 ({WINDOWS['M1']['name']}): Profit=${r_m1['net_profit']:.2f}, PF={r_m1['profit_factor']:.2f}, DD={r_m1['drawdown_pct']:.2f}%, Trades={r_m1['total_trades']}")
    
    if not r_m1["success"] or r_m1["net_profit"] <= 0 or r_m1["profit_factor"] < 1.3 or r_m1["drawdown_pct"] > 15.0 or r_m1["total_trades"] < 5:
        reason = f"M1 Fail: NetProfit={r_m1['net_profit']}, PF={r_m1['profit_factor']}, DD={r_m1['drawdown_pct']}%, Trades={r_m1['total_trades']}"
        print(f"  [DISCARDED at M1]: {reason}")
        return False, reason, {"M1": r_m1}
        
    # Window M3
    r_m3 = run_tester(expert_path, symbol, period, WINDOWS["M3"]["from"], WINDOWS["M3"]["to"], deposit=100.0, inputs=inputs)
    print(f"  M3 ({WINDOWS['M3']['name']}): Profit=${r_m3['net_profit']:.2f}, PF={r_m3['profit_factor']:.2f}, DD={r_m3['drawdown_pct']:.2f}%, Trades={r_m3['total_trades']}")
    
    if not r_m3["success"] or r_m3["net_profit"] <= 0 or r_m3["profit_factor"] < 1.3 or r_m3["drawdown_pct"] > 15.0 or r_m3["total_trades"] < 5:
        reason = f"M3 Fail: NetProfit={r_m3['net_profit']}, PF={r_m3['profit_factor']}, DD={r_m3['drawdown_pct']}%, Trades={r_m3['total_trades']}"
        print(f"  [DISCARDED at M3]: {reason}")
        return False, reason, {"M1": r_m1, "M3": r_m3}
        
    print(f"  [PHASE 1 PASSED!]")
    return True, "Passed Phase 1", {"M1": r_m1, "M3": r_m3}

def run_full_16_windows(expert_path, symbol, period, deposit, leverage="1:100", inputs=""):
    """
    Runs all 16 windows for a given deposit configuration.
    """
    results = {}
    total_net = 0.0
    total_gross_profit = 0.0
    total_gross_loss = 0.0
    total_trades = 0
    max_dd_pct = 0.0
    max_dd_money = 0.0
    profitable_windows = 0
    
    for wid, win in WINDOWS.items():
        res = run_tester(expert_path, symbol, period, win["from"], win["to"], deposit=deposit, leverage=leverage, inputs=inputs)
        results[wid] = res
        if res["success"]:
            total_net += res["net_profit"]
            total_gross_profit += res["gross_profit"]
            total_gross_loss += abs(res["gross_loss"])
            total_trades += res["total_trades"]
            if res["drawdown_pct"] > max_dd_pct:
                max_dd_pct = res["drawdown_pct"]
            if res["drawdown_money"] > max_dd_money:
                max_dd_money = res["drawdown_money"]
            if res["net_profit"] > 0:
                profitable_windows += 1
                
        time.sleep(0.5)
        
    combined_pf = round(total_gross_profit / total_gross_loss, 2) if total_gross_loss > 0 else (99.0 if total_gross_profit > 0 else 0.0)
    
    summary = {
        "deposit": deposit,
        "leverage": leverage,
        "total_net": round(total_net, 2),
        "total_gross_profit": round(total_gross_profit, 2),
        "total_gross_loss": round(total_gross_loss, 2),
        "combined_pf": combined_pf,
        "max_dd_pct": round(max_dd_pct, 2),
        "max_dd_money": round(max_dd_money, 2),
        "total_trades": total_trades,
        "profitable_windows": profitable_windows,
        "window_count": len(WINDOWS),
        "windows": results
    }
    return summary
