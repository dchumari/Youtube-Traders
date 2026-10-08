import subprocess
import os
import re
import time
import json
from datetime import datetime

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Daily_Fibonacci_Strategy\Daily_Fib_618_Pro_Aggressive_EA"

# Institutional 16-Window Benchmark Suite
WINDOWS = {
    # 4 distinct 1-Week windows (High-frequency volatility stress)
    "W1": {"name": "1-Week Volatility Stress 1 (NFP/CB)", "from": "2024.03.04", "to": "2024.03.11", "type": "1-Week"},
    "W2": {"name": "1-Week Volatility Stress 2 (CPI/FOMC)", "from": "2024.06.10", "to": "2024.06.17", "type": "1-Week"},
    "W3": {"name": "1-Week Volatility Stress 3 (Carry Shock)", "from": "2024.08.05", "to": "2024.08.12", "type": "1-Week"},
    "W4": {"name": "1-Week Volatility Stress 4 (US Election)", "from": "2024.11.04", "to": "2024.11.11", "type": "1-Week"},
    
    # 4 distinct 1-Month windows
    "M1": {"name": "1-Month Q1 Opening Trend", "from": "2024.01.01", "to": "2024.01.31", "type": "1-Month"},
    "M2": {"name": "1-Month Spring Expansion", "from": "2024.04.01", "to": "2024.04.30", "type": "1-Month"},
    "M3": {"name": "1-Month Summer Range/Chop", "from": "2024.07.01", "to": "2024.07.31", "type": "1-Month"},
    "M4": {"name": "1-Month Autumn Acceleration", "from": "2024.10.01", "to": "2024.10.31", "type": "1-Month"},
    
    # 4 distinct Multi-Month / Quarterly windows
    "Q1": {"name": "3-Month Banking Crisis Shift", "from": "2023.01.01", "to": "2023.03.31", "type": "Quarterly"},
    "Q2": {"name": "3-Month Rate Tightening Plateau", "from": "2023.04.01", "to": "2023.06.30", "type": "Quarterly"},
    "Q3": {"name": "3-Month US Dollar Trend Rally", "from": "2023.07.01", "to": "2023.09.30", "type": "Quarterly"},
    "Q4": {"name": "3-Month Year-End Dovish Pivot", "from": "2023.10.01", "to": "2023.12.31", "type": "Quarterly"},
    
    # 4 distinct 1-Year Macro windows
    "Y1": {"name": "1-Year Macro Cycle 2022 (Rate Shock)", "from": "2022.01.01", "to": "2022.12.31", "type": "1-Year"},
    "Y2": {"name": "1-Year Macro Cycle 2023 (Disinflation)", "from": "2023.01.01", "to": "2023.12.31", "type": "1-Year"},
    "Y3": {"name": "1-Year Macro Cycle 2024 (Easing Cycle)", "from": "2024.01.01", "to": "2024.12.31", "type": "1-Year"},
    "Y4": {"name": "1-Year Macro Cycle 2025 (Transition)", "from": "2025.01.01", "to": "2025.12.31", "type": "1-Year"}
}

# The Certified Pro Aggressive Inputs
PRO_INPUTS = {
    "InpCapitalMode": 1,
    "InpEquityPerMicroLot": 25.0,
    "InpFixedLot": 0.01,
    "InpMaxLotCap": 3.0,
    "InpPart1_RR": 1.0,
    "InpPart2_RR": 2.5,
    "InpSLPoints": 220,
    "InpBELockPoints": 10,
    "InpBaseMagic": 618500,
    "InpRequireRejection": "true",
    "InpMinWickRatio": 0.35,
    "InpEntryTolerance": 60,
    "InpMaxSpreadPoints": 50,
    "InpUseTrendFilter": "true",
    "InpDailyEMAPeriod": 50,
    "InpTradeImmediate": "true",
    "InpTradeVirginLevels": "true",
    "InpMaxVirginAgeDays": 30,
    "InpMaxDailyTrades": 4,
    "InpUseSessionFilter": "true",
    "InpSessionStartHour": 7,
    "InpSessionEndHour": 18
}

def clean_liveupdate():
    liveupdate_dir = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate"
    if os.path.exists(liveupdate_dir):
        for f in os.listdir(liveupdate_dir):
            try:
                os.remove(os.path.join(liveupdate_dir, f))
            except:
                pass

def execute_window_backtest(wid, win_info, deposit, leverage, retries=2):
    inputs_block = ""
    for k, v in PRO_INPUTS.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    for attempt in range(retries):
        clean_liveupdate()
        test_id = f"pro_{wid}_{int(deposit)}_{int(time.time()*1000)}"
        ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
        rep_name = f"{test_id}_rep"
        rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

        ini_text = f"""[Common]
Login=472929

[Tester]
Expert={EXPERT_REL}
Symbol=XAUUSD
Period=M15
Model=1
FromDate={win_info['from']}
ToDate={win_info['to']}
Deposit={deposit}
Currency=USD
Leverage={leverage}
ExecutionMode=0
Optimization=0
Report={rep_name}
ReplaceReport=1
ShutdownTerminal=1
Visual=0

[TesterInputs]
{inputs_block}
"""
        with open(ini_path, "w", encoding="utf-8") as f:
            f.write(ini_text)

        t0 = time.time()
        try:
            subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=120)
        except Exception as e:
            pass

        elapsed = time.time() - t0

        if os.path.exists(rep_path):
            try:
                with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
                    html = f.read()

                matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', html))

                def parse_float(val_str, default=0.0):
                    if not val_str: return default
                    clean = re.sub(r'[^0-9.-]', '', val_str.split('(')[0])
                    try: return float(clean)
                    except: return default

                def parse_int(val_str, default=0):
                    if not val_str: return default
                    clean = re.sub(r'[^0-9]', '', val_str.split('(')[0])
                    try: return int(clean)
                    except: return default

                net_profit    = parse_float(matches.get('Total Net Profit', '0'))
                gross_profit  = parse_float(matches.get('Gross Profit', '0'))
                gross_loss    = parse_float(matches.get('Gross Loss', '0'))
                profit_factor = parse_float(matches.get('Profit Factor', '0'))
                dd_str        = matches.get('Balance Drawdown Maximal', '')
                dd_pct        = 0.0
                if '(' in dd_str and '%' in dd_str:
                    dd_pct    = parse_float(dd_str.split('(')[1].split('%')[0])
                dd_money      = parse_float(dd_str)
                total_trades  = parse_int(matches.get('Total Trades', '0'))
                win_str       = matches.get('Profit Trades (% of total)', '')
                win_pct       = 0.0
                if '(' in win_str and '%' in win_str:
                    win_pct   = parse_float(win_str.split('(')[1].split('%')[0])

                # Cleanup
                for ext in ['.htm', '.png']:
                    f_del = os.path.join(DATA_FOLDER, f"{rep_name}{ext}")
                    if os.path.exists(f_del):
                        try: os.remove(f_del)
                        except: pass
                if os.path.exists(ini_path):
                    try: os.remove(ini_path)
                    except: pass

                return {
                    "success": True,
                    "net_profit": net_profit,
                    "gross_profit": gross_profit,
                    "gross_loss": gross_loss,
                    "profit_factor": profit_factor,
                    "drawdown_pct": dd_pct,
                    "drawdown_money": dd_money,
                    "total_trades": total_trades,
                    "win_rate_pct": win_pct,
                    "elapsed": elapsed
                }
            except Exception as e:
                pass

        if os.path.exists(ini_path):
            try: os.remove(ini_path)
            except: pass
        time.sleep(1)

    return {
        "success": False,
        "net_profit": 0.0,
        "gross_profit": 0.0,
        "gross_loss": 0.0,
        "profit_factor": 0.0,
        "drawdown_pct": 0.0,
        "drawdown_money": 0.0,
        "total_trades": 0,
        "win_rate_pct": 0.0,
        "error": "Failed after retries"
    }

def main():
    print("=" * 85)
    print("PRO AGGRESSIVE DAILY 61.8% FIBONACCI EA: 16-WINDOW INSTITUTIONAL BENCHMARK")
    print("Features: Dual Partials (1:1 + 2.5R), M15 Rejection Wicks, Daily 50 EMA, Compounding")
    print("Accounts: $100 (1:100 Leverage) & $20 (1:500 Leverage)")
    print("=" * 85)

    results = {
        "metadata": {
            "strategy": "Daily_Fib_618_Pro_Aggressive_EA",
            "symbol": "XAUUSD",
            "period": "M15",
            "timestamp": datetime.now().isoformat(),
            "inputs": PRO_INPUTS
        },
        "account_100": {},
        "account_20": {},
        "summary": {}
    }

    agg_100 = {"net": 0.0, "gp": 0.0, "gl": 0.0, "trades": 0, "max_dd_pct": 0.0, "wins": 0}
    agg_20  = {"net": 0.0, "gp": 0.0, "gl": 0.0, "trades": 0, "max_dd_pct": 0.0, "wins": 0}

    window_keys = list(WINDOWS.keys())

    for idx, wid in enumerate(window_keys, 1):
        win = WINDOWS[wid]
        print(f"\n[{idx}/{len(window_keys)}] Window {wid} ({win['type']}): {win['name']} [{win['from']} -> {win['to']}]")

        # 1. Test $100 Account
        r100 = execute_window_backtest(wid, win, deposit=100.0, leverage="1:100")
        results["account_100"][wid] = r100
        if r100["success"]:
            agg_100["net"] += r100["net_profit"]
            agg_100["gp"] += r100["gross_profit"]
            agg_100["gl"] += abs(r100["gross_loss"])
            agg_100["trades"] += r100["total_trades"]
            if r100["drawdown_pct"] > agg_100["max_dd_pct"]:
                agg_100["max_dd_pct"] = r100["drawdown_pct"]
            if r100["net_profit"] > 0:
                agg_100["wins"] += 1
            print(f"   [$100 Deposit]: Net=${r100['net_profit']:+6.2f} | PF={r100['profit_factor']:4.2f} | DD={r100['drawdown_pct']:5.2f}% | WinRate={r100['win_rate_pct']:4.1f}% | Trades={r100['total_trades']:3d}")
        else:
            print(f"   [$100 Deposit]: FAILED or No Trades")

        time.sleep(0.2)

        # 2. Test $20 Account
        r20 = execute_window_backtest(wid, win, deposit=20.0, leverage="1:500")
        results["account_20"][wid] = r20
        if r20["success"]:
            agg_20["net"] += r20["net_profit"]
            agg_20["gp"] += r20["gross_profit"]
            agg_20["gl"] += abs(r20["gross_loss"])
            agg_20["trades"] += r20["total_trades"]
            if r20["drawdown_pct"] > agg_20["max_dd_pct"]:
                agg_20["max_dd_pct"] = r20["drawdown_pct"]
            if r20["net_profit"] > 0:
                agg_20["wins"] += 1
            pct_return = (r20['net_profit'] / 20.0) * 100.0
            print(f"   [ $20 Deposit]: Net=${r20['net_profit']:+6.2f} ({pct_return:+6.1f}%) | PF={r20['profit_factor']:4.2f} | DD={r20['drawdown_pct']:5.2f}% | WinRate={r20['win_rate_pct']:4.1f}% | Trades={r20['total_trades']:3d}")
        else:
            print(f"   [ $20 Deposit]: FAILED or No Trades")

    pf_100 = round(agg_100["gp"] / agg_100["gl"], 2) if agg_100["gl"] > 0 else (99.0 if agg_100["gp"] > 0 else 0.0)
    pf_20  = round(agg_20["gp"]  / agg_20["gl"], 2) if agg_20["gl"] > 0 else (99.0 if agg_20["gp"] > 0 else 0.0)

    results["summary"]["account_100"] = {
        "total_net": round(agg_100["net"], 2),
        "combined_pf": pf_100,
        "max_drawdown_pct": round(agg_100["max_dd_pct"], 2),
        "total_trades": agg_100["trades"],
        "profitable_windows": agg_100["wins"],
        "total_windows": len(window_keys)
    }
    results["summary"]["account_20"] = {
        "total_net": round(agg_20["net"], 2),
        "combined_pf": pf_20,
        "max_drawdown_pct": round(agg_20["max_dd_pct"], 2),
        "total_trades": agg_20["trades"],
        "profitable_windows": agg_20["wins"],
        "total_windows": len(window_keys)
    }

    out_path = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\FIB618_PRO_AGGRESSIVE_16_WINDOWS_RESULTS.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print("\n" + "=" * 85)
    print("PRO AGGRESSIVE 16-WINDOW BENCHMARK COMPLETED!")
    print(f"[$100 Aggregate]: Net=${agg_100['net']:+.2f} | Combined PF={pf_100} | Max DD={agg_100['max_dd_pct']:.2f}% | Win Windows={agg_100['wins']}/{len(window_keys)}")
    print(f"[ $20 Aggregate]: Net=${agg_20['net']:+.2f} | Combined PF={pf_20} | Max DD={agg_20['max_dd_pct']:.2f}% | Win Windows={agg_20['wins']}/{len(window_keys)}")
    print(f"Full results saved to: {out_path}")
    print("=" * 85)

if __name__ == "__main__":
    main()
