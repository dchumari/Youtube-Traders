import subprocess
import os
import re
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_NAME = "Institutional_SMC_ICT_Master_Suite"
OUT_RESULTS_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Institutional_SMC_ICT_Suite\backtest_results\CALIBRATED_4_WINDOWS_RESULTS.json"

WINDOWS = {
    "W1 (NFP Shock)":          {"from": "2024.03.04", "to": "2024.03.11"},
    "W2 (CPI/FOMC Shock)":      {"from": "2024.06.10", "to": "2024.06.17"},
    "W3 (Yen Carry Crash)":     {"from": "2024.08.05", "to": "2024.08.12"},
    "W4 (US Election Shock)":   {"from": "2024.11.04", "to": "2024.11.11"}
}

MODELS = [
    {"id": "Model_0", "name": "SMC Liquidity Sweep & OB Sniper"},
    {"id": "Model_1", "name": "ICT FVG Consequent Encroachment"},
    {"id": "Model_2", "name": "S&D Fresh Base Support/Res Flip"},
    {"id": "Model_3", "name": "SMC Inducement Trap Reload"},
    {"id": "Model_4", "name": "ICT Power of 3 (AMD) Session"},
    {"id": "Model_5", "name": "ICT Breaker Block Invalidation Flip"},
    {"id": "Model_6", "name": "24/5 ICT OTE Golden Pocket"},
    {"id": "Model_7", "name": "S&D DBR / RBD Velocity"},
    {"id": "Model_8", "name": "ICT Liquidity Void & BPR Reversion"},
    {"id": "Model_9", "name": "Master Institutional Hybrid Confluence"}
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

def run_backtest(test_id, win_from, win_to, deposit, inputs):
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
Leverage=1:400
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
        print(f"Error for {test_id}: {e}", flush=True)
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
            print(f"Parse error for {test_id}: {e}", flush=True)

    return res

def main():
    print("================================================================================", flush=True)
    print("  CALIBRATED INSTITUTIONAL SMC/ICT SUITE - 4-WINDOW STRESS VALIDATION MATRIX    ", flush=True)
    print("  Capital: $100.00 USD | Leverage: 1:400 | Symbol: XAUUSD (Gold M15)             ", flush=True)
    print("================================================================================\n", flush=True)

    base_cfg = {
        "InpSessionFilter": 1, # London & NY Killzones
        "InpExecutionEngine": 0,
        "InpBaseLotSize": 0.01,
        "InpEquityPerMinLot": 35.0,
        "InpMaxLotCap": 0.50,
        "InpStopLossPoints": 250,
        "InpSpamTicketsCount": 5,
        "InpTP1Points": 200,
        "InpTP2Points": 350,
        "InpTP3Points": 600,
        "InpTP4Points": 1000,
        "InpTP5Points": 1600,
        "InpEnableTraceback": "false",
        "InpEnablePyramiding": "true",
        "InpReloadStepPoints": 350,
        "InpMaxPyramidLayers": 3,
        "InpReloadTicketsCount": 3,
        "InpEnableDumpAndFlip": "false",
        "InpEnableVolumeClimax": "false",
        "InpEnableFlipMilestone": "true",
        "InpTargetEquity": 1000.0,
        "InpLookbackBars": 30,
        "InpMinSweepPoints": 20,
        "InpMinFVGPoints": 25,
        "InpMinWickRejection": 0.35,
        "InpMinDisplacementPts": 40,
        "InpEMATrendPeriod": 50,
        "InpAsianStartHour": 0,
        "InpAsianEndHour": 7,
        "InpLondonStartHour": 7,
        "InpLondonEndHour": 11,
        "InpNYStartHour": 12,
        "InpNYEndHour": 17,
        "InpEnableVisuals": "false",
        "InpApplyDraculaTheme": "false",
        "InpDrawSetupBoxes": "false"
    }

    all_matrix = {}

    for idx, model in enumerate(MODELS):
        m_id = model["id"]
        m_name = model["name"]
        print(f"\n--- Benchmarking {m_id}: {m_name} ---", flush=True)

        cfg = dict(base_cfg)
        cfg["InpStrategyModel"] = idx
        cfg["InpMagicNumber"] = 778000 + idx

        # Allow 24/5 for OTE (Model 6) as specified in rules
        if idx == 6:
            cfg["InpSessionFilter"] = 0

        pass_count = 0
        window_results = []

        for w_label, w_info in WINDOWS.items():
            test_id = f"calib_{m_id}_{w_label[:2]}"
            res = run_backtest(test_id, w_info["from"], w_info["to"], 100.0, cfg)
            res["window_label"] = w_label
            window_results.append(res)

            if res["status"] == "PASS":
                pass_count += 1

            status_sym = "✅ PASS" if res["status"] == "PASS" else "❌ FAIL"
            print(f"  [{status_sym}] {w_label:22} | Net PnL: ${res['net_profit']:>7.2f} ({res['roi_pct']:>+6.1f}%) | Trades: {res['total_trades']:>3} | PF: {res['profit_factor']:>4.2f} | DD: {res['drawdown_pct']:>4.1f}%", flush=True)

        pass_rate_str = f"{pass_count}/4"
        overall_status = "CHAMPION (PASS)" if pass_count >= 3 else ("VIABLE" if pass_count == 2 else "NEEDS CALIBRATION")
        print(f"  >> Overall 4-Window Score: {pass_rate_str} [{overall_status}]", flush=True)

        all_matrix[m_id] = {
            "name": m_name,
            "pass_count": pass_count,
            "overall_status": overall_status,
            "windows": window_results
        }

    with open(OUT_RESULTS_JSON, "w", encoding="utf-8") as f:
        json.dump(all_matrix, f, indent=2)

    print(f"\nFull Calibrated Matrix written to: {OUT_RESULTS_JSON}", flush=True)

if __name__ == "__main__":
    main()
