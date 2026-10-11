import subprocess
import os
import re
import json
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_NAME = "Institutional_SMC_ICT_Master_Suite"
PRESET_DIR  = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Institutional_SMC_ICT_Suite\presets"
OUT_RESULTS_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Institutional_SMC_ICT_Suite\backtest_results\INSTITUTIONAL_SMC_ICT_4_WINDOWS_RESULTS.json"

WINDOWS = {
    "W1 (NFP Shock)":          {"from": "2024.03.04", "to": "2024.03.11"},
    "W2 (CPI/FOMC Shock)":      {"from": "2024.06.10", "to": "2024.06.17"},
    "W3 (Yen Carry Crash)":     {"from": "2024.08.05", "to": "2024.08.12"},
    "W4 (US Election Shock)":   {"from": "2024.11.04", "to": "2024.11.11"}
}

MODELS = [
    {"id": "Model_0", "name": "SMC Liquidity Sweep & OB",       "preset": "SMC_Model0_LiquiditySweep_OB_Sniper.set"},
    {"id": "Model_1", "name": "ICT FVG Consequent Encroachment", "preset": "ICT_Model1_FVG_ConsequentEncroachment.set"},
    {"id": "Model_2", "name": "S&D Fresh Base Support/Res Flip", "preset": "SND_Model2_FreshBase_SupportResistanceFlip.set"},
    {"id": "Model_3", "name": "SMC Inducement Trap Reload",     "preset": "SMC_Model3_InducementTrap_InstitutionalReload.set"},
    {"id": "Model_4", "name": "ICT Power of 3 (AMD) Session",   "preset": "ICT_Model4_PowerOf3_AMD_SessionExpander.set"},
    {"id": "Model_5", "name": "ICT Breaker Block Flip",         "preset": "ICT_Model5_BreakerBlock_InvalidationFlip.set"},
    {"id": "Model_6", "name": "24/5 ICT OTE Golden Pocket",     "preset": "SMC_Model6_24_5_OTE_GoldenZone.set"},
    {"id": "Model_7", "name": "S&D DBR / RBD Velocity",         "preset": "SND_Model7_DropBaseRally_Velocity.set"},
    {"id": "Model_8", "name": "ICT Liquidity Void BPR Revert",  "preset": "ICT_Model8_LiquidityVoid_BPR_Reversion.set"},
    {"id": "Model_9", "name": "Master Institutional Hybrid",    "preset": "Master_Model9_InstitutionalHybrid_Compounding.set"}
]

def clean_liveupdate():
    for d in [r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate",
              os.path.join(DATA_FOLDER, "liveupdate")]:
        if os.path.exists(d):
            for f in os.listdir(d):
                try: os.remove(os.path.join(d, f))
                except: pass

def kill_terminal():
    try:
        subprocess.run(["powershell", "-Command", "Stop-Process -Name terminal64 -Force -ErrorAction SilentlyContinue"], capture_output=True)
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

    try:
        subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=90)
    except Exception as e:
        print(f"Error for {test_id}: {e}")
        kill_terminal()

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
            print(f"Parse error for {test_id}: {e}")

    return res

def main():
    print("================================================================================")
    print("  INSTITUTIONAL SMC, ICT & SUPPLY-DEMAND MASTER SUITE - 4-WINDOW STRESS MATRIX  ")
    print("  Capital: $100.00 USD | Leverage: 1:400 | Symbol: XAUUSD (Gold M15)             ")
    print("================================================================================\n")

    all_results = {}

    for model in MODELS:
        m_id = model["id"]
        m_name = model["name"]
        preset_file = os.path.join(PRESET_DIR, model["preset"])
        inputs = parse_preset(preset_file)

        print(f"\n--- Testing {m_id}: {m_name} ---")
        model_results = []
        pass_count = 0

        for w_label, w_info in WINDOWS.items():
            test_id = f"smc_{m_id}_{w_label[:2]}"
            res = run_backtest(test_id, w_info["from"], w_info["to"], 100.0, "1:400", inputs)
            res["window_label"] = w_label
            model_results.append(res)

            if res["status"] == "PASS":
                pass_count += 1

            status_sym = "✅ PASS" if res["status"] == "PASS" else "❌ FAIL"
            print(f"  [{status_sym}] {w_label:22} | Net PnL: ${res['net_profit']:>7.2f} ({res['roi_pct']:>+6.1f}%) | Trades: {res['total_trades']:>3} | PF: {res['profit_factor']:>4.2f} | DD: {res['drawdown_pct']:>4.1f}%")

        pass_rate_str = f"{pass_count}/4"
        overall_status = "CHAMPION (PASS)" if pass_count >= 3 else ("VIABLE" if pass_count == 2 else "NEEDS CALIBRATION")
        print(f"  >> Overall 4-Window Score: {pass_rate_str} [{overall_status}]")

        all_results[m_id] = {
            "name": m_name,
            "preset": model["preset"],
            "pass_count": pass_count,
            "overall_status": overall_status,
            "windows": model_results
        }

    with open(OUT_RESULTS_JSON, "w", encoding="utf-8") as f:
        json.dump(all_results, f, indent=2)

    print(f"\nMatrix results successfully saved to: {OUT_RESULTS_JSON}")

if __name__ == "__main__":
    main()
