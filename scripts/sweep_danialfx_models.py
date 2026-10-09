import subprocess
import os
import re
import time
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"DanialFX_Aggressive_Suite_v2"

# Test Models on $100 and $1,000 across W1 and M1
MODELS = {
    "Model0_QM_Sniper": 0,
    "Model1_QM_AO": 1,
    "Model2_BBMA_REM": 2,
    "Model3_Hybrid": 3
}

WINDOWS = {
    "W1_Shock": {"name": "1-Week NFP Shock", "from": "2024.03.04", "to": "2024.03.11"},
    "M1_Trend": {"name": "1-Month Jan 2024",  "from": "2024.01.01", "to": "2024.01.31"},
    "Q4_Pivot": {"name": "3-Month Q4 2023",  "from": "2023.10.01", "to": "2023.12.31"}
}

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

def run_test(test_id, win_info, deposit, inputs):
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
Expert={EXPERT_REL}
Symbol=XAUUSD
Period=M15
Model=1
FromDate={win_info['from']}
ToDate={win_info['to']}
Deposit={deposit}
Currency=USD
Leverage=400
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
        subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=120)
    except Exception as e:
        print(f"Error for {test_id}: {e}")
        kill_terminal()

    res = {
        "test_id": test_id,
        "deposit": deposit,
        "window": win_info["name"],
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

            net_profit    = parse_float(matches.get('Total Net Profit', '0'))
            profit_factor = parse_float(matches.get('Profit Factor', '0'))
            dd_str        = matches.get('Balance Drawdown Maximal', '')
            dd_pct        = 0.0
            if '(' in dd_str and '%' in dd_str:
                dd_pct    = parse_float(dd_str.split('(')[1].split('%')[0])
            total_trades  = parse_int(matches.get('Total Trades', '0'))
            win_str       = matches.get('Profit Trades (% of total)', '')
            win_pct       = 0.0
            if '(' in win_str and '%' in win_str:
                win_pct   = parse_float(win_str.split('(')[1].split('%')[0])

            roi_pct = (net_profit / deposit) * 100.0 if deposit > 0 else 0.0

            res.update({
                "net_profit": net_profit,
                "profit_factor": profit_factor,
                "drawdown_pct": dd_pct,
                "total_trades": total_trades,
                "win_rate_pct": win_pct,
                "roi_pct": roi_pct,
                "status": "PASS" if net_profit > 0 else ("BREAKEVEN" if net_profit == 0 and total_trades > 0 else "LOSS")
            })
        except Exception as err:
            print(f"Error parsing {rep_path}: {err}")

    return res

if __name__ == "__main__":
    kill_terminal()
    print("="*80)
    print("SWEEPING DANIAL FX INDIVIDUAL MODELS (Model 0, 1, 2, 3)")
    print("="*80)

    results = []

    base = {
        "InpMagicNumber": 991100,
        "InpTradeComment": "DanialFX",
        "InpRiskMode": 0,
        "InpFixedLot": 0.01,
        "InpMinLot": 0.01,
        "InpMaxLot": 3.00,
        "InpEnableLayering": "true",
        "InpMaxLayers": 3,
        "InpLayerStepPoints": 350,
        "InpLockBreakevenOnLayer": "true",
        "InpBreakevenBufferPts": 10,
        "InpEnableTrailing": "true",
        "InpTrailingStartPoints": 450,
        "InpTrailingStepPoints": 150,
        "InpSwingLookback": 25,
        "InpMinBOSPoints": 120,
        "InpQMLTolerancePoints": 100,
        "InpSLHeadBufferPoints": 50,
        "InpStopLossPoints": 220,
        "InpTakeProfitPoints": 750,
        "InpAOFastPeriod": 5,
        "InpAOSlowPeriod": 34,
        "InpBBPeriod": 20,
        "InpBBDev": 2.0,
        "InpEMA50Period": 50,
        "InpUseEMATrendFilter": "true",
        "InpMinRejectionWickPct": 0.40,      # Higher sniper threshold: 40% wick
        "InpUseSessionFilter": "true",
        "InpStartHour": 7,
        "InpEndHour": 19,
        "InpMaxSpreadPoints": 45,
        "InpEquityStepPerMinLot": 30.0
    }

    for m_name, m_val in MODELS.items():
        print(f"\n--- Testing {m_name} ---")
        cfg = dict(base)
        cfg["InpStrategyMode"] = m_val

        for w_code, w_info in WINDOWS.items():
            tid = f"danial_{m_name}_{w_code}_100"
            print(f"Running {w_code} ({w_info['name']})...", end=" ", flush=True)
            res = run_test(tid, w_info, 100, cfg)
            res["model"] = m_name
            results.append(res)
            print(f"Status: {res['status']} | Net: ${res['net_profit']:.2f} | ROI: {res['roi_pct']:.1f}% | Trades: {res['total_trades']} | Win: {res['win_rate_pct']:.1f}% | DD: {res['drawdown_pct']:.1f}%")

    out_file = "strategies/Danial_FX/backtest_results/DANIAL_FX_MODELS_SWEEP.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    print(f"\nSaved sweep results to {out_file}")
