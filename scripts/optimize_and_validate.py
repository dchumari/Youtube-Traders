import os
import sys
import json
import time

sys.path.insert(0, os.path.dirname(__file__))
from tester_runner import run_tester, compile_ea, DATA_FOLDER, WINDOWS

def evaluate_strategy(expert_name, symbol, period, inputs=""):
    """
    Evaluates an EA across both $100 and $20 accounts across all 16 windows.
    Returns structured results and pass/fail gate checks.
    """
    expert_path = f"Quant10\\{expert_name}"
    
    print(f"\n=======================================================")
    print(f"EVALUATING: {expert_name} on {symbol} {period}")
    print(f"=======================================================")
    
    # 1. Test on $100 Account (1:100 leverage)
    res_100 = {}
    tot_net_100 = 0.0
    tot_gp_100 = 0.0
    tot_gl_100 = 0.0
    tot_trades_100 = 0
    max_dd_pct_100 = 0.0
    win_count_100 = 0
    quarterly_trades_100 = []
    
    for wid, win in WINDOWS.items():
        r = run_tester(expert_path, symbol, period, win["from"], win["to"], deposit=100.0, leverage="1:100", inputs=inputs)
        res_100[wid] = r
        if r["success"]:
            tot_net_100 += r["net_profit"]
            tot_gp_100 += r["gross_profit"]
            tot_gl_100 += abs(r["gross_loss"])
            tot_trades_100 += r["total_trades"]
            if r["drawdown_pct"] > max_dd_pct_100:
                max_dd_pct_100 = r["drawdown_pct"]
            if r["net_profit"] > 0:
                win_count_100 += 1
            if win["type"] == "quarter":
                quarterly_trades_100.append(r["total_trades"])
        time.sleep(0.2)
        
    combined_pf_100 = round(tot_gp_100 / tot_gl_100, 2) if tot_gl_100 > 0 else (99.0 if tot_gp_100 > 0 else 0.0)
    
    # 2. Test on $20 Account (1:500 leverage)
    res_20 = {}
    tot_net_20 = 0.0
    tot_gp_20 = 0.0
    tot_gl_20 = 0.0
    tot_trades_20 = 0
    max_dd_pct_20 = 0.0
    win_count_20 = 0
    min_margin_level = 9999.0
    
    for wid, win in WINDOWS.items():
        r = run_tester(expert_path, symbol, period, win["from"], win["to"], deposit=20.0, leverage="1:500", inputs=inputs)
        res_20[wid] = r
        if r["success"]:
            tot_net_20 += r["net_profit"]
            tot_gp_20 += r["gross_profit"]
            tot_gl_20 += abs(r["gross_loss"])
            tot_trades_20 += r["total_trades"]
            if r["drawdown_pct"] > max_dd_pct_20:
                max_dd_pct_20 = r["drawdown_pct"]
            if r["net_profit"] > 0:
                win_count_20 += 1
            m_lvl_str = r.get("margin_level", "1000%").replace("%", "").strip()
            try:
                m_lvl_float = float(m_lvl_str)
                if m_lvl_float < min_margin_level:
                    min_margin_level = m_lvl_float
            except:
                pass
        time.sleep(0.2)
        
    combined_pf_20 = round(tot_gp_20 / tot_gl_20, 2) if tot_gl_20 > 0 else (99.0 if tot_gp_20 > 0 else 0.0)
    
    # Gates Evaluation
    gate1_win_rate = (win_count_100 >= 14 or win_count_20 >= 14)
    gate2_dd_100 = (max_dd_pct_100 <= 15.0)
    gate3_dd_20 = (max_dd_pct_20 <= 20.0)
    gate4_pf = (combined_pf_100 >= 1.4 or combined_pf_20 >= 1.4)
    gate5_trades = (min(quarterly_trades_100) >= 30 if quarterly_trades_100 else False)
    gate6_margin = (min_margin_level >= 100.0)
    
    qualified = gate1_win_rate and gate2_dd_100 and gate3_dd_20 and gate4_pf and gate6_margin
    
    print(f"Results for {expert_name}:")
    print(f"  $100 Account: Net=${tot_net_100:.2f}, PF={combined_pf_100}, MaxDD={max_dd_pct_100}%, WinWindows={win_count_100}/16, Trades={tot_trades_100}")
    print(f"  $20  Account: Net=${tot_net_20:.2f}, PF={combined_pf_20}, MaxDD={max_dd_pct_20}%, WinWindows={win_count_20}/16, MinMargin={min_margin_level}%")
    print(f"  Gates: WinRate={'PASS' if gate1_win_rate else 'FAIL'} | DD100={'PASS' if gate2_dd_100 else 'FAIL'} | DD20={'PASS' if gate3_dd_20 else 'FAIL'} | PF={'PASS' if gate4_pf else 'FAIL'} | Margin={'PASS' if gate6_margin else 'FAIL'}")
    print(f"  Status: {'[QUALIFIED]' if qualified else '[NEEDS CALIBRATION]'}")
    
    return {
        "name": expert_name,
        "symbol": symbol,
        "period": period,
        "qualified": qualified,
        "account_100": {
            "total_net": round(tot_net_100, 2),
            "combined_pf": combined_pf_100,
            "max_dd_pct": round(max_dd_pct_100, 2),
            "total_trades": tot_trades_100,
            "win_windows": win_count_100,
            "quarterly_trades": quarterly_trades_100,
            "windows": res_100
        },
        "account_20": {
            "total_net": round(tot_net_20, 2),
            "combined_pf": combined_pf_20,
            "max_dd_pct": round(max_dd_pct_20, 2),
            "total_trades": tot_trades_20,
            "win_windows": win_count_20,
            "min_margin_level": min_margin_level,
            "windows": res_20
        },
        "gates": {
            "win_rate_ge_14": gate1_win_rate,
            "dd_100_le_15": gate2_dd_100,
            "dd_20_le_20": gate3_dd_20,
            "pf_ge_1_4": gate4_pf,
            "quarterly_trades_ge_30": gate5_trades,
            "margin_ge_100": gate6_margin
        }
    }
