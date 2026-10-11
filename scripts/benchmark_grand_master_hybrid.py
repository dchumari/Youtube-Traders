import subprocess
import os
import re
import json
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_NAME = "Grand_Master_Hybrid_EA"
PRESET_DIR  = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Grand_Master_Hybrid\presets"
OUT_RESULTS_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Grand_Master_Hybrid\backtest_results\GRAND_MASTER_HYBRID_RESULTS.json"

# 1. High-Impact Volatility & Random Windows
WEEKLY_WINDOWS = {
    "W1 (NFP Shock)":       {"from": "2024.03.04", "to": "2024.03.11"},
    "W2 (CPI Shock)":       {"from": "2024.06.10", "to": "2024.06.17"},
    "W3 (Carry Crash)":     {"from": "2024.08.05", "to": "2024.08.12"},
    "W4 (Election Shock)":  {"from": "2024.11.04", "to": "2024.11.11"},
    "W_Rand1 (Mid-Feb)":    {"from": "2024.02.12", "to": "2024.02.19"},
    "W_Rand2 (Mid-May)":    {"from": "2024.05.13", "to": "2024.05.20"},
    "W_Rand3 (Mid-July)":   {"from": "2024.07.15", "to": "2024.07.22"},
    "W_Rand4 (Mid-Sept)":   {"from": "2024.09.16", "to": "2024.09.23"}
}

MONTHLY_WINDOWS = {
    "M1 (Feb 2024)":        {"from": "2024.02.01", "to": "2024.02.29"},
    "M2 (May 2024)":        {"from": "2024.05.01", "to": "2024.05.31"},
    "M3 (July 2024)":       {"from": "2024.07.01", "to": "2024.07.31"},
    "M4 (Oct 2024)":        {"from": "2024.10.01", "to": "2024.10.31"}
}

FULL_YEAR = {
    "Y_Full2024":           {"from": "2024.01.01", "to": "2024.12.31"}
}

def clean_liveupdate():
    for d in [r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate",
              os.path.join(DATA_FOLDER, "liveupdate")]:
        if os.path.exists(d):
            for f in os.listdir(d):
                try: os.remove(os.path.join(d, f))
                except: pass

def safe_kill_tester():
    """Safely terminates ONLY tester terminal instances, NEVER PID 13220!"""
    try:
        cmd = 'Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne 13220 } | Stop-Process -Force'
        subprocess.run(["powershell", "-Command", cmd], capture_output=True)
    except:
        pass

def parse_preset(preset_path):
    inputs = {}
    if os.path.exists(preset_path):
        with open(preset_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("//") and not line.startswith(";"):
                    parts = line.split("=", 1)
                    if len(parts) == 2:
                        inputs[parts[0].strip()] = parts[1].strip()
    return inputs

def run_single_test(test_id, win_from, win_to, deposit, leverage, inputs, timeout_sec=90):
    clean_liveupdate()
    inputs_block = ""
    for k, v in inputs.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

    if os.path.exists(rep_path):
        try: os.remove(rep_path)
        except: pass

    ini_text = f"""[Common]
Login=472929

[Tester]
Expert={EXPERT_NAME}
Symbol=XAUUSD
Period=M15
Model=1
FromDate={win_from}
ToDate={win_to}
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

    proc = subprocess.Popen([TESTER_EXE, "/portable", f"/config:{ini_path}"],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    start_time = time.time()
    while time.time() - start_time < timeout_sec:
        if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
            time.sleep(1.5)
            try: proc.kill()
            except: pass
            safe_kill_tester()
            break
        time.sleep(1.5)
    else:
        try: proc.kill()
        except: pass
        safe_kill_tester()

    res = {
        "test_id": test_id,
        "deposit": deposit,
        "window": f"{win_from} -> {win_to}",
        "net_profit": 0.0,
        "profit_factor": 0.0,
        "drawdown_pct": 0.0,
        "total_trades": 0,
        "win_rate_pct": 0.0,
        "roi_pct": 0.0,
        "status": "FAIL"
    }

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

            np_val = parse_float(matches.get('Total Net Profit', '0'))
            pf_val = parse_float(matches.get('Profit Factor', '0'))
            dd_val = parse_float(matches.get('Equity Drawdown Maximal', '0'))
            if dd_val == 0.0:
                dd_val = parse_float(matches.get('Maximal Drawdown', '0'))
            tt_val = parse_int(matches.get('Total Trades', '0'))

            short_win = parse_float(matches.get('Short Trades (won %)', '0'))
            long_win  = parse_float(matches.get('Long Trades (won %)', '0'))
            win_pct = round((short_win + long_win) / 2.0, 1) if (short_win > 0 or long_win > 0) else 0.0
            roi_pct = round((np_val / deposit) * 100.0, 1)

            res["net_profit"] = np_val
            res["profit_factor"] = pf_val
            res["drawdown_pct"] = dd_val
            res["total_trades"] = tt_val
            res["win_rate_pct"] = win_pct
            res["roi_pct"] = roi_pct
            res["status"] = "PASS" if np_val > 0.0 else "FAIL"

        except Exception as e:
            print(f"  [PARSE ERROR] {test_id}: {e}", flush=True)

    try:
        if os.path.exists(ini_path): os.remove(ini_path)
    except: pass

    return res

def main():
    print("=" * 80, flush=True)
    print("  GRAND MASTER HYBRID SUITE: COMPREHENSIVE MULTI-HORIZON BENCHMARK  ", flush=True)
    print("  Testing $100 & $20 Accounts at 1:400 Leverage on Gold (XAUUSD M15) ", flush=True)
    print("=" * 80 + "\n", flush=True)

    results = {
        "weekly_sprints_100USD": {},
        "weekly_sprints_20USD": {},
        "monthly_horizons_100USD": {},
        "annual_horizon_100USD": {}
    }

    # PART 1: WEEKLY SPRINTS ($100 Tier)
    print(">>> PART 1: WEEKLY SPRINTS ON $100 TIER (Target >= 100% ROI)", flush=True)
    print("-" * 80, flush=True)
    preset_100 = parse_preset(os.path.join(PRESET_DIR, "GMH_Weekly_Sprint_Doubler_100USD.set"))
    
    total_100 = 0.0
    wins_100 = 0
    for wname, wdates in WEEKLY_WINDOWS.items():
        tid = f"GMH_W100_{wname[:7].replace(' ', '').replace('(', '').replace(')', '')}"
        res = run_single_test(tid, wdates["from"], wdates["to"], 100.0, "1:400", preset_100)
        results["weekly_sprints_100USD"][wname] = res
        total_100 += res["net_profit"]
        if res["status"] == "PASS": wins_100 += 1
        print(f"  [Weekly $100] {wname:<19}: Net = ${res['net_profit']:>7.2f} ({res['roi_pct']:>6.1f}%) | "
              f"PF = {res['profit_factor']:>4.2f} | DD = {res['drawdown_pct']:>4.1f}% | "
              f"Trades = {res['total_trades']:>2} | {res['status']}", flush=True)

    print(f"  ==> Weekly $100 Total: {wins_100}/{len(WEEKLY_WINDOWS)} Wins | Total Net = ${total_100:+.2f}\n", flush=True)

    # PART 2: WEEKLY SPRINTS ($20 Tier)
    print(">>> PART 2: WEEKLY SPRINTS ON $20 TIER (Cent / Micro Account Doubler)", flush=True)
    print("-" * 80, flush=True)
    preset_20 = parse_preset(os.path.join(PRESET_DIR, "GMH_Weekly_Sprint_Doubler_20USD.set"))
    
    total_20 = 0.0
    wins_20 = 0
    for wname, wdates in list(WEEKLY_WINDOWS.items())[:4]: # Test 4 event shock weeks
        tid = f"GMH_W20_{wname[:7].replace(' ', '').replace('(', '').replace(')', '')}"
        res = run_single_test(tid, wdates["from"], wdates["to"], 20.0, "1:400", preset_20)
        results["weekly_sprints_20USD"][wname] = res
        total_20 += res["net_profit"]
        if res["status"] == "PASS": wins_20 += 1
        print(f"  [Weekly $20]  {wname:<19}: Net = ${res['net_profit']:>7.2f} ({res['roi_pct']:>6.1f}%) | "
              f"PF = {res['profit_factor']:>4.2f} | DD = {res['drawdown_pct']:>4.1f}% | "
              f"Trades = {res['total_trades']:>2} | {res['status']}", flush=True)

    print(f"  ==> Weekly $20 Total: {wins_20}/4 Wins | Total Net = ${total_20:+.2f}\n", flush=True)

    # PART 3: MONTHLY HORIZONS ($100 Tier)
    print(">>> PART 3: MONTHLY HORIZONS (Continuous 30-Day Testing across Q1-Q4)", flush=True)
    print("-" * 80, flush=True)
    preset_month = parse_preset(os.path.join(PRESET_DIR, "GMH_Monthly_Expansion_100USD.set"))
    
    total_month = 0.0
    wins_month = 0
    for mname, mdates in MONTHLY_WINDOWS.items():
        tid = f"GMH_M100_{mname[:7].replace(' ', '').replace('(', '').replace(')', '')}"
        res = run_single_test(tid, mdates["from"], mdates["to"], 100.0, "1:400", preset_month, timeout_sec=120)
        results["monthly_horizons_100USD"][mname] = res
        total_month += res["net_profit"]
        if res["status"] == "PASS": wins_month += 1
        print(f"  [Month $100]  {mname:<19}: Net = ${res['net_profit']:>7.2f} ({res['roi_pct']:>6.1f}%) | "
              f"PF = {res['profit_factor']:>4.2f} | DD = {res['drawdown_pct']:>4.1f}% | "
              f"Trades = {res['total_trades']:>2} | {res['status']}", flush=True)

    print(f"  ==> Monthly $100 Total: {wins_month}/{len(MONTHLY_WINDOWS)} Wins | Total Net = ${total_month:+.2f}\n", flush=True)

    # PART 4: FULL 1-YEAR HORIZON (2024.01.01 to 2024.12.31)
    print(">>> PART 4: FULL 1-YEAR HORIZON (Entire Year 2024 Compounding Endurance)", flush=True)
    print("-" * 80, flush=True)
    preset_annual = parse_preset(os.path.join(PRESET_DIR, "GMH_Annual_Endurance_Compounding.set"))
    
    tid_yr = "GMH_Annual_2024"
    res_yr = run_single_test(tid_yr, FULL_YEAR["Y_Full2024"]["from"], FULL_YEAR["Y_Full2024"]["to"], 100.0, "1:400", preset_annual, timeout_sec=180)
    results["annual_horizon_100USD"]["Full_Year_2024"] = res_yr
    print(f"  [1-Year $100] Full Year 2024    : Net = ${res_yr['net_profit']:>7.2f} ({res_yr['roi_pct']:>6.1f}%) | "
          f"PF = {res_yr['profit_factor']:>4.2f} | DD = {res_yr['drawdown_pct']:>4.1f}% | "
          f"Trades = {res_yr['total_trades']:>3} | {res_yr['status']}\n", flush=True)

    os.makedirs(os.path.dirname(OUT_RESULTS_JSON), exist_ok=True)
    with open(OUT_RESULTS_JSON, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print(f"[DONE] Saved Grand Master Hybrid Benchmark Results to: {OUT_RESULTS_JSON}")

if __name__ == "__main__":
    main()
