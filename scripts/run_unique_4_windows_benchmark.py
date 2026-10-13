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
OUT_RESULTS_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\SMC_Daily_Sniper\backtest_results\SMC_4_UNIQUE_WINDOWS_RESULTS.json"

# 4 Unique Windows across different market "temperatures" (Volatility shock, Two-way CPI, Random Trend, Random Range)
UNIQUE_4_WINDOWS = {
    "Window 1 (Trending Volatility Shock / NFP)": {"from": "2024.03.04", "to": "2024.03.11", "regime": "High-Impact Trend Acceleration"},
    "Window 2 (Two-Way Volatility Expansion / CPI)": {"from": "2024.06.10", "to": "2024.06.17", "regime": "High-Impact Two-Way Expansion"},
    "Window 3 (Pure Random Trending Week / Mid-Feb)": {"from": "2024.02.12", "to": "2024.02.19", "regime": "Normal Random Trend"},
    "Window 4 (Pure Random Summer Range / Mid-July)": {"from": "2024.07.15", "to": "2024.07.22", "regime": "Consolidation / Range Squeeze"}
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

def run_single_test(test_id, win_from, win_to, deposit, leverage, inputs, timeout_sec=80):
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
    print("=" * 85)
    print("  SMC DAILY SNIPER: 4 UNIQUE WINDOWS EMPIRICAL STRESS BENCHMARK ($20 vs $100 TIERS)")
    print("  Target Daily Frequency: 1 to 2 setups/day | Models: Trendline, IDM, OTE 70.5%, Master")
    print("=" * 85)

    p_20_sprint  = os.path.join(PRESET_DIR, "SMCD_Daily_Sprint_Doubler_20USD.set")
    p_100_sprint = os.path.join(PRESET_DIR, "SMCD_Daily_Sprint_Doubler_100USD.set")

    inputs_20  = parse_preset(p_20_sprint)
    inputs_100 = parse_preset(p_100_sprint)

    # Models to test:
    # 4: 24/5 ICT OTE 70.5% Golden Pocket nested in S&D Base
    # 0: Trendline Liquidity Trap ("Fan Land" Purge) + S&D Base Tap
    # 1: SMC Inducement (IDM) Sweep + Origin Order Block
    # 5: Master Confluence Sniper (Multi-Signal Fusion)
    models = {
        4: "Model 4: 24/5 ICT OTE 70.5% Golden Pocket + S&D Base",
        0: "Model 0: Trendline Liquidity Trap + S&D Base",
        1: "Model 1: SMC Inducement (IDM) Sweep + Origin OB",
        5: "Model 5: Master Institutional Confluence Engine"
    }

    all_matrix_results = {}

    for m_id, m_name in models.items():
        print(f"\n=================================================================================")
        print(f"  {m_name}")
        print(f"=================================================================================")
        all_matrix_results[m_name] = {"20USD": {}, "100USD": {}}

        # --- $20 USD CAPITAL TIER ---
        print("\n--- [$20 USD Capital Tier / Micro Doubler (775 USC)] ---")
        cur_inp_20 = dict(inputs_20)
        cur_inp_20["InpCoreModel"] = str(m_id)

        for w_key, w_info in UNIQUE_4_WINDOWS.items():
            t_id = f"smcd_m{m_id}_20_{w_key.split()[1]}"
            print(f"Testing {w_key} ({w_info['from']} to {w_info['to']}) [{w_info['regime']}]...", end="", flush=True)
            res = run_single_test(t_id, w_info["from"], w_info["to"], 20.0, 400, cur_inp_20, timeout_sec=70)
            all_matrix_results[m_name]["20USD"][w_key] = res
            print(f" -> Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | WR: {res['win_rate']}% | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% | Trades: {res['trades']} [{res['status']}]")

        # --- $100 USD CAPITAL TIER ---
        print("\n--- [$100 USD Capital Tier / Standard Sprint] ---")
        cur_inp_100 = dict(inputs_100)
        cur_inp_100["InpCoreModel"] = str(m_id)

        for w_key, w_info in UNIQUE_4_WINDOWS.items():
            t_id = f"smcd_m{m_id}_100_{w_key.split()[1]}"
            print(f"Testing {w_key} ({w_info['from']} to {w_info['to']}) [{w_info['regime']}]...", end="", flush=True)
            res = run_single_test(t_id, w_info["from"], w_info["to"], 100.0, 400, cur_inp_100, timeout_sec=70)
            all_matrix_results[m_name]["100USD"][w_key] = res
            print(f" -> Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | WR: {res['win_rate']}% | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% | Trades: {res['trades']} [{res['status']}]")

    with open(OUT_RESULTS_JSON, "w", encoding="utf-8") as f:
        json.dump(all_matrix_results, f, indent=2)

    safe_kill_tester()
    print("\n" + "=" * 85)
    print(f"Benchmark finished! Matrix results saved to: {OUT_RESULTS_JSON}")

if __name__ == "__main__":
    main()
