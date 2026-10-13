import subprocess
import os
import re
import json
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_NAME = "SMC_Daily_Sniper_EA"
PRESET_DIR  = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\SMC_Daily_Sniper\presets"
OUT_RESULTS_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\SMC_Daily_Sniper\backtest_results\SMC_DAILY_SNIPER_RESULTS.json"

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
    "M2 (May 2024)":        {"from": "2024.05.01", "to": "2024.05.31"}
}

def clean_liveupdate():
    for d in [r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate",
              r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\liveupdate",
              os.path.join(DATA_FOLDER, "liveupdate")]:
        if os.path.exists(d):
            for f in os.listdir(d):
                try: os.remove(os.path.join(d, f))
                except: pass

def safe_kill_tester():
    """Safely terminates ONLY sandbox tester terminal instances, NEVER user's live terminal!"""
    try:
        cmd = 'Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Where-Object { $_.Path -notlike "*Program Files*" } | Stop-Process -Force'
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

    cmd = [TESTER_EXE, "/portable", f"/config:{ini_path}"]
    safe_kill_tester()
    time.sleep(1)

    proc = subprocess.Popen(cmd)
    start_t = time.time()
    done = False

    while time.time() - start_t < timeout_sec:
        if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
            time.sleep(1.5)
            try: proc.kill()
            except: pass
            safe_kill_tester()
            done = True
            break
        if proc.poll() is not None:
            time.sleep(2)
            if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
                done = True
            break
        time.sleep(1.5)

    if not done:
        try: proc.kill()
        except: pass
        safe_kill_tester()

    if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
        return parse_htm_report(rep_path, deposit)
    else:
        return {
            "net_profit": 0.0,
            "roi_pct": 0.0,
            "trades": 0,
            "win_rate": 0.0,
            "profit_factor": 0.0,
            "max_dd_pct": 0.0,
            "status": "FAIL_OR_NO_TRADES"
        }

def parse_htm_report(htm_file, initial_deposit):
    try:
        content = ""
        try:
            with open(htm_file, "r", encoding="utf-16", errors="ignore") as f:
                content = f.read()
        except:
            with open(htm_file, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()

        matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', content))

        def parse_float(val_str, default=0.0):
            if not val_str: return default
            cleaned = val_str.replace(" ", "").replace("&nbsp;", "").replace(",", "").strip()
            m = re.search(r"(-?[\d\.]+)", cleaned)
            return float(m.group(1)) if m else default

        net_profit = parse_float(matches.get("Total Net Profit", "0"))
        trades = int(parse_float(matches.get("Total Trades", "0")))
        pf = parse_float(matches.get("Profit Factor", "0"))

        win_str = matches.get("Profit Trades (% of total)", "")
        m_win = re.search(r"\(([\d\.]+)%\)", win_str)
        win_pct = float(m_win.group(1)) if m_win else 0.0

        dd_str = matches.get("Balance Drawdown Maximal", matches.get("Maximal Drawdown", matches.get("Drawdown Maximal", "")))
        m_dd = re.search(r"\(([\d\.]+)%\)", dd_str)
        dd_pct = float(m_dd.group(1)) if m_dd else parse_float(dd_str)

        roi_pct = (net_profit / initial_deposit) * 100.0 if initial_deposit > 0 else 0.0

        return {
            "net_profit": round(net_profit, 2),
            "roi_pct": round(roi_pct, 1),
            "trades": trades,
            "win_rate": round(win_pct, 1),
            "profit_factor": round(pf, 2),
            "max_dd_pct": round(dd_pct, 1),
            "status": "PASS" if net_profit > 0 else "FAIL"
        }
    except Exception as e:
        return {"net_profit": 0.0, "roi_pct": 0.0, "trades": 0, "win_rate": 0.0, "profit_factor": 0.0, "max_dd_pct": 0.0, "status": f"ERROR: {str(e)}"}

def main():
    print("=" * 80)
    print("  SMC DAILY SNIPER: EMPIRICAL DUAL-TIER STRESS BENCHMARK MATRIX")
    print("=" * 80)

    # 1. Preset Paths
    p_20_sprint  = os.path.join(PRESET_DIR, "SMCD_Daily_Sprint_Doubler_20USD.set")
    p_100_sprint = os.path.join(PRESET_DIR, "SMCD_Daily_Sprint_Doubler_100USD.set")
    p_100_month  = os.path.join(PRESET_DIR, "SMCD_Monthly_Consistency_100USD.set")

    inputs_20_sprint  = parse_preset(p_20_sprint)
    inputs_100_sprint = parse_preset(p_100_sprint)
    inputs_100_month  = parse_preset(p_100_month)

    all_results = {
        "model1_idm_100usd_weekly": {},
        "model1_idm_20usd_weekly": {},
        "model0_trendline_100usd_weekly": {},
        "model0_trendline_20usd_weekly": {},
        "monthly_100usd": {}
    }

    windows_to_test = ["W1 (NFP Shock)", "W2 (CPI Shock)", "W3 (Carry Crash)", "W4 (Election Shock)", "W_Rand1 (Mid-Feb)", "W_Rand2 (Mid-May)"]

    # --- MODEL 1: SMC INDUCEMENT (IDM) SNIPER ---
    print("\n=======================================================")
    print("  MODEL 1: SMC INDUCEMENT (IDM) SWEEP + ORIGIN OB")
    print("=======================================================")
    inp_m1_100 = dict(inputs_100_sprint)
    inp_m1_100["InpCoreModel"] = "1"
    inp_m1_20 = dict(inputs_20_sprint)
    inp_m1_20["InpCoreModel"] = "1"

    print("\n--- [$100 USD Capital Tier | Model 1 IDM] ---")
    for wname in windows_to_test:
        w = WEEKLY_WINDOWS[wname]
        t_id = f"smcd_m1_100_{wname.split()[0]}"
        print(f"Running {wname} ({w['from']} to {w['to']})...", end="", flush=True)
        res = run_single_test(t_id, w["from"], w["to"], 100.0, 400, inp_m1_100, timeout_sec=60)
        all_results["model1_idm_100usd_weekly"][wname] = res
        print(f" -> Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | WR: {res['win_rate']}% | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% | Trades: {res['trades']} [{res['status']}]")

    print("\n--- [$20 USD Capital Tier | Model 1 IDM] ---")
    for wname in windows_to_test:
        w = WEEKLY_WINDOWS[wname]
        t_id = f"smcd_m1_20_{wname.split()[0]}"
        print(f"Running {wname} ({w['from']} to {w['to']})...", end="", flush=True)
        res = run_single_test(t_id, w["from"], w["to"], 20.0, 400, inp_m1_20, timeout_sec=60)
        all_results["model1_idm_20usd_weekly"][wname] = res
        print(f" -> Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | WR: {res['win_rate']}% | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% | Trades: {res['trades']} [{res['status']}]")

    # --- MODEL 0: TRENDLINE LIQUIDITY TRAP ---
    print("\n=======================================================")
    print("  MODEL 0: TRENDLINE LIQUIDITY TRAP + S&D BASE TAP")
    print("=======================================================")
    inp_m0_100 = dict(inputs_100_sprint)
    inp_m0_100["InpCoreModel"] = "0"
    inp_m0_20 = dict(inputs_20_sprint)
    inp_m0_20["InpCoreModel"] = "0"

    print("\n--- [$100 USD Capital Tier | Model 0 Trendline] ---")
    for wname in windows_to_test:
        w = WEEKLY_WINDOWS[wname]
        t_id = f"smcd_m0_100_{wname.split()[0]}"
        print(f"Running {wname} ({w['from']} to {w['to']})...", end="", flush=True)
        res = run_single_test(t_id, w["from"], w["to"], 100.0, 400, inp_m0_100, timeout_sec=60)
        all_results["model0_trendline_100usd_weekly"][wname] = res
        print(f" -> Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | WR: {res['win_rate']}% | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% | Trades: {res['trades']} [{res['status']}]")

    print("\n--- [$20 USD Capital Tier | Model 0 Trendline] ---")
    for wname in windows_to_test:
        w = WEEKLY_WINDOWS[wname]
        t_id = f"smcd_m0_20_{wname.split()[0]}"
        print(f"Running {wname} ({w['from']} to {w['to']})...", end="", flush=True)
        res = run_single_test(t_id, w["from"], w["to"], 20.0, 400, inp_m0_20, timeout_sec=60)
        all_results["model0_trendline_20usd_weekly"][wname] = res
        print(f" -> Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | WR: {res['win_rate']}% | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% | Trades: {res['trades']} [{res['status']}]")

    # --- MONTHLY HORIZONS ---
    print("\n=======================================================")
    print("  MONTHLY EXPANSION HORIZONS ($100 CAPITAL)")
    print("=======================================================")
    inp_month = dict(inputs_100_month)
    inp_month["InpCoreModel"] = "1"
    for mname, m in MONTHLY_WINDOWS.items():
        t_id = f"smcd_month_{mname.split()[0]}"
        print(f"Running {mname} ({m['from']} to {m['to']})...", end="", flush=True)
        res = run_single_test(t_id, m["from"], m["to"], 100.0, 400, inp_month, timeout_sec=100)
        all_results["monthly_100usd"][mname] = res
        print(f" -> Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | WR: {res['win_rate']}% | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% | Trades: {res['trades']} [{res['status']}]")

    # Save JSON results
    with open(OUT_RESULTS_JSON, "w", encoding="utf-8") as f:
        json.dump(all_results, f, indent=2)

    safe_kill_tester()
    print("\n" + "=" * 80)
    print(f"Benchmark complete! Saved results to {OUT_RESULTS_JSON}")

if __name__ == "__main__":
    main()
