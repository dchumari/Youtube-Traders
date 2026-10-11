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
OUT_RESULTS_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Chart_Fanatics\backtest_results\CHART_FANATICS_BACKTEST_RESULTS.json"

WINDOWS = {
    "W1 (NFP Shock)":          {"from": "2024.03.04", "to": "2024.03.11"},
    "W2 (CPI/FOMC Shock)":      {"from": "2024.06.10", "to": "2024.06.17"},
    "W3 (Yen Carry Crash)":     {"from": "2024.08.05", "to": "2024.08.12"},
    "W4 (US Election Shock)":   {"from": "2024.11.04", "to": "2024.11.11"}
}

STRATEGIES = [
    {
        "id": "Matteo_ORB",
        "name": "Matteo Conti Bank ORB + VWAP",
        "original_preset": "CF_MatteoConti_ORB_Original.set",
        "optimal_preset": "CF_MatteoConti_ORB_Optimal.set"
    },
    {
        "id": "TraderYush_VA",
        "name": "Trader Yush Value Area & Delta Absorption",
        "original_preset": "CF_TraderYush_ValueArea_Original.set",
        "optimal_preset": "CF_TraderYush_ValueArea_Optimal.set"
    },
    {
        "id": "Okala_8020",
        "name": "Okala 80/20 Distribution Tails",
        "original_preset": "CF_Okala_8020_Original.set",
        "optimal_preset": "CF_Okala_8020_Optimal.set"
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
    },
    {
        "id": "Master_Hybrid",
        "name": "Chart Fanatics Master Institutional Hybrid",
        "original_preset": "CF_Master_Hybrid_Original.set",
        "optimal_preset": "CF_Master_Hybrid_Optimal.set"
    }
]

def clean_liveupdate():
    for d in [r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate",
              os.path.join(DATA_FOLDER, "liveupdate")]:
        if os.path.exists(d):
            for f in os.listdir(d):
                try: os.remove(os.path.join(d, f))
                except: pass

def safe_kill_tester_process():
    """Safely kills ONLY tester instances of terminal64, NEVER PID 13220!"""
    try:
        cmd = 'Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne 13220 } | Stop-Process -Force'
        subprocess.run(["powershell", "-Command", cmd], capture_output=True)
    except Exception as e:
        print(f"Safe kill error: {e}")

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

def run_backtest(test_id, win_from, win_to, deposit, leverage, inputs):
    clean_liveupdate()
    inputs_block = ""
    for k, v in inputs.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

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
    proc = None
    try:
        proc = subprocess.Popen([TESTER_EXE, "/portable", f"/config:{ini_path}"],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        proc.wait(timeout=90)
    except subprocess.TimeoutExpired:
        print(f"  [TIMEOUT] {test_id} exceeded 90s. Killing worker process...")
        if proc:
            try:
                proc.kill()
            except:
                pass
        safe_kill_tester_process()
    except Exception as e:
        print(f"  [ERROR] {test_id}: {e}", flush=True)
        safe_kill_tester_process()

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

    # Cleanup temporary report & ini files
    try:
        if os.path.exists(ini_path): os.remove(ini_path)
    except: pass

    return res

def main():
    print("=" * 80, flush=True)
    print("  CHART FANATICS QUANTITATIVE BENCHMARK MATRIX (4 STRESS WINDOWS)  ", flush=True)
    print("  Comparing: Original Trader Settings vs Calibrated Optimal Settings", flush=True)
    print("  Asset: Gold XAUUSD M15 | Leverage: 1:400 | Deposit: $100 USD     ", flush=True)
    print("=" * 80 + "\n", flush=True)

    all_results = {}

    for strat in STRATEGIES:
        strat_id = strat["id"]
        strat_name = strat["name"]
        print(f"\n>>> TESTING STRATEGY: {strat_name} ({strat_id})", flush=True)
        print("-" * 80, flush=True)

        all_results[strat_id] = {
            "name": strat_name,
            "original_settings": {},
            "optimal_settings": {},
            "comparison_summary": {}
        }

        # 1. Test Original Trader Settings
        orig_preset_path = os.path.join(PRESET_DIR, strat["original_preset"])
        orig_inputs = parse_preset(orig_preset_path)
        print(f"  [*] Tier A: Original Trader Settings ({strat['original_preset']})", flush=True)

        orig_wins = 0
        orig_total_profit = 0.0
        for win_name, win_dates in WINDOWS.items():
            test_id = f"CF_{strat_id}_Orig_{win_name[:2]}"
            res = run_backtest(test_id, win_dates["from"], win_dates["to"], 100.0, "1:400", orig_inputs)
            all_results[strat_id]["original_settings"][win_name] = res
            status_icon = "PASS [OK]" if res["status"] == "PASS" else "FAIL [X]"
            if res["status"] == "PASS": orig_wins += 1
            orig_total_profit += res["net_profit"]
            print(f"      {win_name}: Profit = ${res['net_profit']:>7.2f} ({res['roi_pct']:>6.1f}%) | "
                  f"PF = {res['profit_factor']:>4.2f} | DD = {res['drawdown_pct']:>4.1f}% | "
                  f"Trades = {res['total_trades']:>3} | {status_icon}", flush=True)

        # 2. Test Calibrated Optimal Settings
        opt_preset_path = os.path.join(PRESET_DIR, strat["optimal_preset"])
        opt_inputs = parse_preset(opt_preset_path)
        print(f"  [*] Tier B: Calibrated Optimal Settings ({strat['optimal_preset']})", flush=True)

        opt_wins = 0
        opt_total_profit = 0.0
        for win_name, win_dates in WINDOWS.items():
            test_id = f"CF_{strat_id}_Opt_{win_name[:2]}"
            res = run_backtest(test_id, win_dates["from"], win_dates["to"], 100.0, "1:400", opt_inputs)
            all_results[strat_id]["optimal_settings"][win_name] = res
            status_icon = "PASS [OK]" if res["status"] == "PASS" else "FAIL [X]"
            if res["status"] == "PASS": opt_wins += 1
            opt_total_profit += res["net_profit"]
            print(f"      {win_name}: Profit = ${res['net_profit']:>7.2f} ({res['roi_pct']:>6.1f}%) | "
                  f"PF = {res['profit_factor']:>4.2f} | DD = {res['drawdown_pct']:>4.1f}% | "
                  f"Trades = {res['total_trades']:>3} | {status_icon}", flush=True)

        all_results[strat_id]["comparison_summary"] = {
            "original_passed_windows": f"{orig_wins}/4",
            "original_cumulative_profit": round(orig_total_profit, 2),
            "optimal_passed_windows": f"{opt_wins}/4",
            "optimal_cumulative_profit": round(opt_total_profit, 2),
            "alpha_improvement": round(opt_total_profit - orig_total_profit, 2)
        }
        print(f"  --> SUMMARY: Original {orig_wins}/4 (${orig_total_profit:+.2f}) vs "
              f"Optimal {opt_wins}/4 (${opt_total_profit:+.2f}) | "
              f"Alpha Delta: ${opt_total_profit - orig_total_profit:+.2f}\n", flush=True)

    # Save to JSON
    os.makedirs(os.path.dirname(OUT_RESULTS_JSON), exist_ok=True)
    with open(OUT_RESULTS_JSON, "w", encoding="utf-8") as f:
        json.dump(all_results, f, indent=2)
    print(f"\n[DONE] Saved complete matrix results to: {OUT_RESULTS_JSON}")

if __name__ == "__main__":
    main()
