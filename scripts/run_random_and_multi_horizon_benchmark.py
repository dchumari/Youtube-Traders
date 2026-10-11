import subprocess
import os
import re
import json
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_NAME = "ChartFanatics_Master_Suite"
PRESET_DIR  = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Chart_Fanatics\presets"
OUT_RESULTS_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Chart_Fanatics\backtest_results\RANDOM_AND_MULTI_HORIZON_RESULTS.json"

# 1. Four Pure Random Weeks (Across 52 weeks of 2024)
RANDOM_WEEKS = {
    "W_Rand1 (Mid-Feb)":    {"from": "2024.02.12", "to": "2024.02.19"},
    "W_Rand2 (Mid-May)":    {"from": "2024.05.13", "to": "2024.05.20"},
    "W_Rand3 (Mid-July)":   {"from": "2024.07.15", "to": "2024.07.22"},
    "W_Rand4 (Mid-Sept)":   {"from": "2024.09.16", "to": "2024.09.23"}
}

# 2. Four Random Months (Across Q1, Q2, Q3, Q4)
RANDOM_MONTHS = {
    "M_Rand1 (Feb 2024)":   {"from": "2024.02.01", "to": "2024.02.29"},
    "M_Rand2 (May 2024)":   {"from": "2024.05.01", "to": "2024.05.31"},
    "M_Rand3 (July 2024)":  {"from": "2024.07.01", "to": "2024.07.31"},
    "M_Rand4 (Oct 2024)":   {"from": "2024.10.01", "to": "2024.10.31"}
}

# 3. Full 1-Year Horizon
FULL_YEAR = {
    "Y_Full2024":           {"from": "2024.01.01", "to": "2024.12.31"}
}

STRATEGIES = [
    {
        "id": "Master_Hybrid",
        "name": "Chart Fanatics Master Institutional Hybrid",
        "original_preset": "CF_Master_Hybrid_Original.set",
        "optimal_preset": "CF_Master_Hybrid_Optimal.set"
    },
    {
        "id": "TraderYush_VA",
        "name": "Trader Yush Value Area & Delta Absorption",
        "original_preset": "CF_TraderYush_ValueArea_Original.set",
        "optimal_preset": "CF_TraderYush_ValueArea_Optimal.set"
    },
    {
        "id": "Matteo_ORB",
        "name": "Matteo Conti Bank ORB + VWAP",
        "original_preset": "CF_MatteoConti_ORB_Original.set",
        "optimal_preset": "CF_MatteoConti_ORB_Optimal.set"
    },
    {
        "id": "Crudele_BB",
        "name": "Anthony Crudele 3-Step Bollinger Trend",
        "original_preset": "CF_Crudele_Bollinger_Original.set",
        "optimal_preset": "CF_Crudele_Bollinger_Optimal.set"
    },
    {
        "id": "KrisVerma_Short",
        "name": "Kris Verma Parabolic Gap Exhaustion Short",
        "original_preset": "CF_KrisVerma_GapShort_Original.set",
        "optimal_preset": "CF_KrisVerma_GapShort_Optimal.set"
    }
]

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

    # Launch subprocess safely
    proc = subprocess.Popen([TESTER_EXE, "/portable", f"/config:{ini_path}"],
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    start_time = time.time()
    while time.time() - start_time < timeout_sec:
        if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
            time.sleep(1.5) # Wait for file lock release
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
    print("  MULTI-HORIZON RIGOROUS BENCHMARK: 4 RANDOM WEEKS, 4 RANDOM MONTHS & 1 FULL YEAR ", flush=True)
    print("  Testing Setting A (Original Trader) & Setting B (Calibrated Optimal) on Gold XAUUSD", flush=True)
    print("=" * 80 + "\n", flush=True)

    results = {
        "random_weeks": {},
        "random_months": {},
        "full_year": {}
    }

    # SECTION 1: 4 RANDOM WEEKS BENCHMARK
    print(">>> PART 1: FOUR PURE RANDOM WEEKS (Non-Event Regular Trading Weeks)", flush=True)
    print("-" * 80, flush=True)

    for strat in STRATEGIES:
        sid = strat["id"]
        results["random_weeks"][sid] = {"name": strat["name"], "original": {}, "optimal": {}}
        orig_inputs = parse_preset(os.path.join(PRESET_DIR, strat["original_preset"]))
        opt_inputs  = parse_preset(os.path.join(PRESET_DIR, strat["optimal_preset"]))

        print(f"\n[*] Strategy: {strat['name']} ({sid})", flush=True)
        # Original
        orig_wins = 0
        orig_pnl = 0.0
        for wname, wdates in RANDOM_WEEKS.items():
            tid = f"RW_{sid}_Orig_{wname[:7].replace(' ', '')}"
            res = run_single_test(tid, wdates["from"], wdates["to"], 100.0, "1:400", orig_inputs)
            results["random_weeks"][sid]["original"][wname] = res
            if res["status"] == "PASS": orig_wins += 1
            orig_pnl += res["net_profit"]
            print(f"    [Orig] {wname}: Net PnL = ${res['net_profit']:>6.2f} ({res['roi_pct']:>5.1f}%) | "
                  f"PF = {res['profit_factor']:>4.2f} | DD = {res['drawdown_pct']:>4.1f}% | "
                  f"Trades = {res['total_trades']:>2} | {res['status']}", flush=True)

        # Optimal
        opt_wins = 0
        opt_pnl = 0.0
        for wname, wdates in RANDOM_WEEKS.items():
            tid = f"RW_{sid}_Opt_{wname[:7].replace(' ', '')}"
            res = run_single_test(tid, wdates["from"], wdates["to"], 100.0, "1:400", opt_inputs)
            results["random_weeks"][sid]["optimal"][wname] = res
            if res["status"] == "PASS": opt_wins += 1
            opt_pnl += res["net_profit"]
            print(f"    [Opt]  {wname}: Net PnL = ${res['net_profit']:>6.2f} ({res['roi_pct']:>5.1f}%) | "
                  f"PF = {res['profit_factor']:>4.2f} | DD = {res['drawdown_pct']:>4.1f}% | "
                  f"Trades = {res['total_trades']:>2} | {res['status']}", flush=True)

        print(f"  ==> 4 Random Weeks Total: Orig {orig_wins}/4 (${orig_pnl:+.2f}) | Opt {opt_wins}/4 (${opt_pnl:+.2f})", flush=True)

    # SECTION 2: 4 RANDOM MONTHS BENCHMARK
    print("\n" + "=" * 80, flush=True)
    print(">>> PART 2: FOUR RANDOM MONTHS BENCHMARK (Monthly Sustainability across Q1-Q4)", flush=True)
    print("-" * 80, flush=True)

    for strat in STRATEGIES[:3]: # Test top 3 core engines across months (Master Hybrid, Trader Yush, Matteo ORB)
        sid = strat["id"]
        results["random_months"][sid] = {"name": strat["name"], "original": {}, "optimal": {}}
        orig_inputs = parse_preset(os.path.join(PRESET_DIR, strat["original_preset"]))
        opt_inputs  = parse_preset(os.path.join(PRESET_DIR, strat["optimal_preset"]))

        print(f"\n[*] Strategy: {strat['name']} ({sid}) - Monthly Stress", flush=True)
        orig_pnl = 0.0
        for mname, mdates in RANDOM_MONTHS.items():
            tid = f"RM_{sid}_Orig_{mname[:7].replace(' ', '')}"
            res = run_single_test(tid, mdates["from"], mdates["to"], 100.0, "1:400", orig_inputs, timeout_sec=120)
            results["random_months"][sid]["original"][mname] = res
            orig_pnl += res["net_profit"]
            print(f"    [Orig Month] {mname}: Net PnL = ${res['net_profit']:>7.2f} ({res['roi_pct']:>6.1f}%) | "
                  f"PF = {res['profit_factor']:>4.2f} | DD = {res['drawdown_pct']:>4.1f}% | "
                  f"Trades = {res['total_trades']:>3} | {res['status']}", flush=True)

        opt_pnl = 0.0
        for mname, mdates in RANDOM_MONTHS.items():
            tid = f"RM_{sid}_Opt_{mname[:7].replace(' ', '')}"
            res = run_single_test(tid, mdates["from"], mdates["to"], 100.0, "1:400", opt_inputs, timeout_sec=120)
            results["random_months"][sid]["optimal"][mname] = res
            opt_pnl += res["net_profit"]
            print(f"    [Opt Month]  {mname}: Net PnL = ${res['net_profit']:>7.2f} ({res['roi_pct']:>6.1f}%) | "
                  f"PF = {res['profit_factor']:>4.2f} | DD = {res['drawdown_pct']:>4.1f}% | "
                  f"Trades = {res['total_trades']:>3} | {res['status']}", flush=True)

        print(f"  ==> 4-Month Total: Orig Net = ${orig_pnl:+.2f} | Opt Net = ${opt_pnl:+.2f}", flush=True)

    # SECTION 3: FULL 1-YEAR BENCHMARK (2024.01.01 to 2024.12.31)
    print("\n" + "=" * 80, flush=True)
    print(">>> PART 3: FULL 1-YEAR HORIZON BENCHMARK (Entire Year 2024 Macro Cycle)", flush=True)
    print("-" * 80, flush=True)

    for strat in STRATEGIES[:2]: # Top engines for 1-year test
        sid = strat["id"]
        results["full_year"][sid] = {"name": strat["name"]}
        orig_inputs = parse_preset(os.path.join(PRESET_DIR, strat["original_preset"]))
        opt_inputs  = parse_preset(os.path.join(PRESET_DIR, strat["optimal_preset"]))

        print(f"\n[*] 1-Year Benchmark: {strat['name']} ({sid})", flush=True)
        tid_orig = f"FY_{sid}_Orig"
        res_orig = run_single_test(tid_orig, FULL_YEAR["Y_Full2024"]["from"], FULL_YEAR["Y_Full2024"]["to"], 100.0, "1:400", orig_inputs, timeout_sec=180)
        results["full_year"][sid]["original"] = res_orig
        print(f"    [1-Year Original]: Net PnL = ${res_orig['net_profit']:>7.2f} ({res_orig['roi_pct']:>6.1f}%) | "
              f"PF = {res_orig['profit_factor']:>4.2f} | DD = {res_orig['drawdown_pct']:>4.1f}% | "
              f"Trades = {res_orig['total_trades']:>3} | {res_orig['status']}", flush=True)

        tid_opt = f"FY_{sid}_Opt"
        res_opt = run_single_test(tid_opt, FULL_YEAR["Y_Full2024"]["from"], FULL_YEAR["Y_Full2024"]["to"], 100.0, "1:400", opt_inputs, timeout_sec=180)
        results["full_year"][sid]["optimal"] = res_opt
        print(f"    [1-Year Optimal ]: Net PnL = ${res_opt['net_profit']:>7.2f} ({res_opt['roi_pct']:>6.1f}%) | "
              f"PF = {res_opt['profit_factor']:>4.2f} | DD = {res_opt['drawdown_pct']:>4.1f}% | "
              f"Trades = {res_opt['total_trades']:>3} | {res_opt['status']}", flush=True)

    # Save to JSON
    with open(OUT_RESULTS_JSON, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    print(f"\n[DONE] Saved Multi-Horizon Benchmark Results to: {OUT_RESULTS_JSON}")

if __name__ == "__main__":
    main()
