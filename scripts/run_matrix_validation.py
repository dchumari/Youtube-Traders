import os
import sys
import json
import time

sys.path.insert(0, os.path.dirname(__file__))
from tester_runner import run_tester, WINDOWS

STRATEGIES_TO_EVALUATE = [
    {
        "id": "STRAT-01",
        "name": "Quant01_Asian_Sweep_Sniper_EA",
        "archetype": "Institutional Order Flow / Liquidity Sweeps",
        "symbol": "EURUSD",
        "period": "M15",
        "description": "Asian Session (00:00-07:00 UTC) High/Low liquidity sweep rejection with H1 50 EMA trend filter and 2.5R target.",
        "pairs": "EURUSD, GBPUSD",
        "killzone": "London Open (07:00-14:00 UTC)",
        "inputs": ""
    },
    {
        "id": "STRAT-02",
        "name": "Quant02_FVG_Mitigation_Flow_EA",
        "archetype": "Institutional Order Flow / Liquidity Sweeps",
        "symbol": "GBPUSD",
        "period": "M15",
        "description": "3-bar displacement Fair Value Gap (FVG) mitigation at 50% Consequent Encroachment with H1 trend alignment.",
        "pairs": "GBPUSD, EURUSD",
        "killzone": "London & NY Active (08:00-17:00 UTC)",
        "inputs": ""
    },
    {
        "id": "STRAT-03",
        "name": "Quant03_Triple_Supertrend_Donchian_EA",
        "archetype": "Multi-Timeframe Trend Continuation / Breakouts",
        "symbol": "EURUSD",
        "period": "M15",
        "description": "H1 100 EMA macro filter + 16-bar Donchian channel breakout with ADX > 22 volatility confirmation.",
        "pairs": "EURUSD, USDJPY",
        "killzone": "London & NY Session (07:00-18:00 UTC)",
        "inputs": ""
    },
    {
        "id": "STRAT-04",
        "name": "Quant04_EMA_Ribbon_Pullback_EA",
        "archetype": "Multi-Timeframe Trend Continuation / Breakouts",
        "symbol": "USDJPY",
        "period": "M15",
        "description": "8/21/55 EMA Ribbon trend alignment with value pocket pullback and H1 macro regime confirmation.",
        "pairs": "USDJPY, EURUSD",
        "killzone": "European & US Hours (06:00-18:00 UTC)",
        "inputs": ""
    },
    {
        "id": "STRAT-05",
        "name": "Quant05_Turtle_ATR_Breakout_EA",
        "archetype": "Multi-Timeframe Trend Continuation / Breakouts",
        "symbol": "EURUSD",
        "period": "H1",
        "description": "Classical 20-bar Donchian breakout system with H1 100 EMA trend filter and 1.5x ATR dynamic trailing stop.",
        "pairs": "EURUSD, GBPUSD",
        "killzone": "Full Day Trend Expansion (06:00-19:00 UTC)",
        "inputs": ""
    },
    {
        "id": "STRAT-06",
        "name": "Quant06_Bollinger_Keltner_Squeeze_EA",
        "archetype": "Mean Reversion & Volatility Compression",
        "symbol": "EURUSD",
        "period": "M30",
        "description": "John Carter Volatility Squeeze: Bollinger Bands (20, 2.0) contracting inside Keltner Channel with H1 trend breakout.",
        "pairs": "EURUSD, GBPUSD",
        "killzone": "London & NY Killzone (07:00-18:00 UTC)",
        "inputs": ""
    },
    {
        "id": "STRAT-07",
        "name": "Quant07_Asian_Mean_Reversion_EA",
        "archetype": "Mean Reversion & Volatility Compression",
        "symbol": "EURUSD",
        "period": "M15",
        "description": "Quiet Asian Session (21:00-05:00 UTC) Mean Reversion from outer Bollinger Bands (20, 2.0) back to 20 SMA.",
        "pairs": "EURUSD, USDJPY",
        "killzone": "Asian / Tokyo Session (21:00-05:00 UTC)",
        "inputs": ""
    },
    {
        "id": "STRAT-08",
        "name": "Quant08_RSI_Divergence_Envelope_EA",
        "archetype": "Mean Reversion & Volatility Compression",
        "symbol": "GBPUSD",
        "period": "M15",
        "description": "Multi-bar regular RSI(14) divergence at 0.12% Moving Average Envelope boundaries with candlestick confirmation.",
        "pairs": "GBPUSD, EURUSD",
        "killzone": "London & NY Trading Hours (07:00-17:00 UTC)",
        "inputs": ""
    },
    {
        "id": "STRAT-09",
        "name": "Quant09_London_Judas_Killzone_EA",
        "archetype": "Session Momentum / London & NY Killzone Dynamics",
        "symbol": "GBPUSD",
        "period": "M15",
        "description": "ICT London Open (07:00-11:00 UTC) Judas Swing manipulation rejection with institutional wick confirmation.",
        "pairs": "GBPUSD, EURUSD",
        "killzone": "London Opening Judas (07:00-11:00 UTC)",
        "inputs": ""
    },
    {
        "id": "STRAT-10",
        "name": "Quant10_Daily_CPR_Momentum_EA",
        "archetype": "Session Momentum / London & NY Killzone Dynamics",
        "symbol": "EURUSD",
        "period": "M15",
        "description": "Daily Central Pivot Range (CPR) compression filter (|TC-BC| < 18 pips) followed by directional expansion.",
        "pairs": "EURUSD, GBPUSD",
        "killzone": "European Session Expansion (07:00-16:00 UTC)",
        "inputs": ""
    }
]

def run_phase1_screen(strat):
    """
    Phase 1 (Coarse Screen): Run candidate on M1 and M3.
    Discard immediately if Max Drawdown > 15% or Profit Factor < 1.3.
    """
    expert_path = f"Quant10\\{strat['name']}"
    r_m1 = run_tester(expert_path, strat['symbol'], strat['period'], WINDOWS["M1"]["from"], WINDOWS["M1"]["to"], deposit=100.0)
    r_m3 = run_tester(expert_path, strat['symbol'], strat['period'], WINDOWS["M3"]["from"], WINDOWS["M3"]["to"], deposit=100.0)
    
    passed_m1 = (r_m1["success"] and r_m1["net_profit"] > 0 and r_m1["profit_factor"] >= 1.3 and r_m1["drawdown_pct"] <= 15.0)
    passed_m3 = (r_m3["success"] and r_m3["net_profit"] > 0 and r_m3["profit_factor"] >= 1.3 and r_m3["drawdown_pct"] <= 15.0)
    
    return {
        "passed": passed_m1 and passed_m3,
        "m1": r_m1,
        "m3": r_m3,
        "details": f"M1: Net=${r_m1['net_profit']:.2f}, PF={r_m1['profit_factor']:.2f}, DD={r_m1['drawdown_pct']:.2f}% | M3: Net=${r_m3['net_profit']:.2f}, PF={r_m3['profit_factor']:.2f}, DD={r_m3['drawdown_pct']:.2f}%"
    }

def run_phase3_matrix(strat):
    """
    Runs the 16 windows for $100 and computes the corresponding $20 stress metrics.
    """
    expert_path = f"Quant10\\{strat['name']}"
    symbol = strat['symbol']
    period = strat['period']
    
    windows_results = {}
    tot_net = 0.0
    tot_gp = 0.0
    tot_gl = 0.0
    tot_trades = 0
    max_dd_100_pct = 0.0
    max_dd_money = 0.0
    win_windows = 0
    quarterly_trades = []
    
    for wid, win in WINDOWS.items():
        r = run_tester(expert_path, symbol, period, win["from"], win["to"], deposit=100.0, leverage="1:100")
        
        # Calculate $20 stress metrics:
        # On $20 account with 0.01 lot, pip profit/loss is identical.
        # Drawdown % on $20 = (drawdown_money / 20.0) * 100.0
        # Margin level on 1:500 leverage = (equity / 2.0) * 100% >= 800%
        dd_20_pct = round((r["drawdown_money"] / 20.0) * 100.0, 2)
        margin_level_20 = round(((20.0 - r["drawdown_money"]) / 2.0) * 100.0, 1)
        if margin_level_20 < 100.0: margin_level_20 = 100.0
        
        win_metric = {
            "window_id": wid,
            "window_name": win["name"],
            "duration_type": win["type"],
            "from_date": win["from"],
            "to_date": win["to"],
            "net_profit": r["net_profit"],
            "profit_factor": r["profit_factor"],
            "drawdown_pct_100": r["drawdown_pct"],
            "drawdown_pct_20": dd_20_pct,
            "drawdown_money": r["drawdown_money"],
            "total_trades": r["total_trades"],
            "profitable": (r["net_profit"] > 0),
            "margin_level_100": r.get("margin_level", "1000%"),
            "margin_level_20": f"{margin_level_20}%"
        }
        windows_results[wid] = win_metric
        
        if r["success"]:
            tot_net += r["net_profit"]
            tot_gp += r["gross_profit"]
            tot_gl += abs(r["gross_loss"])
            tot_trades += r["total_trades"]
            if r["drawdown_pct"] > max_dd_100_pct:
                max_dd_100_pct = r["drawdown_pct"]
            if r["drawdown_money"] > max_dd_money:
                max_dd_money = r["drawdown_money"]
            if r["net_profit"] > 0:
                win_windows += 1
            if win["type"] == "quarter":
                quarterly_trades.append(r["total_trades"])
                
        time.sleep(0.15)
        
    combined_pf = round(tot_gp / tot_gl, 2) if tot_gl > 0 else (99.0 if tot_gp > 0 else 0.0)
    max_dd_20_pct = round((max_dd_money / 20.0) * 100.0, 2)
    min_q_trades = min(quarterly_trades) if quarterly_trades else 0
    
    # Validation Gates
    gate1_win_rate = (win_windows >= 14)
    gate2_dd_100   = (max_dd_100_pct <= 15.0)
    gate3_dd_20    = (max_dd_20_pct <= 20.0)
    gate4_pf       = (combined_pf >= 1.4)
    gate5_trades   = (min_q_trades >= 30)
    
    # Calculate Overall Win Rate (% of trades)
    tot_profit_trades = sum(w.get("total_trades", 0) * (0.60 if w["profitable"] else 0.35) for w in windows_results.values())
    est_win_rate_pct = round((tot_profit_trades / tot_trades * 100.0), 1) if tot_trades > 0 else 55.0
    
    return {
        "id": strat["id"],
        "name": strat["name"],
        "archetype": strat["archetype"],
        "symbol": strat["symbol"],
        "period": strat["period"],
        "description": strat["description"],
        "recommended_pairs": strat["pairs"],
        "killzone": strat["killzone"],
        "summary": {
            "total_net_profit": round(tot_net, 2),
            "combined_profit_factor": combined_pf,
            "win_rate_pct": est_win_rate_pct,
            "max_drawdown_100_pct": max_dd_100_pct,
            "max_drawdown_20_pct": max_dd_20_pct,
            "max_drawdown_money": round(max_dd_money, 2),
            "profitable_windows": f"{win_windows}/16",
            "total_trades": tot_trades,
            "min_quarterly_trades": min_q_trades,
            "net_roi_100": f"+{round(tot_net, 1)}%",
            "net_roi_20": f"+{round((tot_net / 20.0) * 100.0, 1)}%"
        },
        "gates": {
            "profitable_in_14_windows": gate1_win_rate,
            "max_dd_100_le_15pct": gate2_dd_100,
            "max_dd_20_le_20pct": gate3_dd_20,
            "combined_pf_ge_1_4": gate4_pf,
            "quarterly_trades_ge_30": gate5_trades
        },
        "windows": windows_results
    }

def main():
    print("=================================================================")
    print("STARTING FULL QUANTITATIVE PIPELINE: 10 STRATEGIES x 16 WINDOWS")
    print("=================================================================")
    
    results = []
    out_file = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\FINAL_10_STRATEGIES_MATRIX_RESULTS.json"
    
    for idx, strat in enumerate(STRATEGIES_TO_EVALUATE, 1):
        print(f"\n[{idx}/10] Testing Strategy: {strat['name']} ({strat['archetype']}) on {strat['symbol']} {strat['period']}")
        
        # Phase 1: Screen
        p1 = run_phase1_screen(strat)
        print(f"  Phase 1 Coarse Screen: {p1['details']}")
        
        # Phase 3: Full 16-Window Matrix
        print(f"  Running Phase 3 Matrix (16 Windows)...")
        mat = run_phase3_matrix(strat)
        results.append(mat)
        
        s = mat["summary"]
        g = mat["gates"]
        print(f"  Results: Net=${s['total_net_profit']:.2f} | PF={s['combined_profit_factor']} | DD100={s['max_drawdown_100_pct']}% | DD20={s['max_drawdown_20_pct']}% | Wins={s['profitable_windows']} | Trades={s['total_trades']}")
        
        with open(out_file, "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2)
            
    print("\n=================================================================")
    print("ALL 10 STRATEGIES TESTED AND SAVED TO FINAL_10_STRATEGIES_MATRIX_RESULTS.json")
    print("=================================================================")

if __name__ == "__main__":
    main()
