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

WINDOWS = {
    "W1_Shock":    {"name": "1-Week NFP Shock (Mar 2024)", "from": "2024.03.04", "to": "2024.03.11", "period": "1-Week"},
    "M1_Trend":    {"name": "1-Month Jan 2024",             "from": "2024.01.01", "to": "2024.01.31", "period": "1-Month"},
    "Q4_Pivot":    {"name": "3-Month Dovish Pivot (Q4 2023)","from": "2023.10.01", "to": "2023.12.31", "period": "3-Month"},
    "Y3_Year2024": {"name": "Full 1-Year Cycle 2024",       "from": "2024.01.01", "to": "2024.12.31", "period": "1-Year"}
}

DEPOSITS = [20, 50, 100, 1000]

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
        "period": win_info["period"],
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
    print("DANIAL FX CHAMPION MODEL 0 (QM SNIPER + AGGRESSIVE LAYERING) BENCHMARK")
    print("Tested Deposits: $20, $50, $100, $1,000 | Leverage: 1:400 | Symbol: XAUUSD M15")
    print("="*80)

    base = {
        "InpStrategyMode": 0,               # STRAT_QM_SNIPER (Undisputed Champion)
        "InpMagicNumber": 991100,
        "InpTradeComment": "DanialFX_QM",
        "InpRiskMode": 0,                   # Dynamic Compounding
        "InpFixedLot": 0.01,
        "InpMinLot": 0.01,
        "InpMaxLot": 3.00,
        "InpEnableLayering": "true",
        "InpLayerStepPoints": 350,          # 35 pips
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
        "InpMinRejectionWickPct": 0.40,
        "InpUseSessionFilter": "true",
        "InpStartHour": 7,
        "InpEndHour": 19,
        "InpMaxSpreadPoints": 45
    }

    results = []

    for dep in DEPOSITS:
        cfg = dict(base)
        if dep <= 20:
            cfg["InpEquityStepPerMinLot"] = 20.0
            cfg["InpMaxLayers"] = 2
        elif dep <= 50:
            cfg["InpEquityStepPerMinLot"] = 25.0
            cfg["InpMaxLayers"] = 2
        elif dep <= 100:
            cfg["InpEquityStepPerMinLot"] = 30.0
            cfg["InpMaxLayers"] = 3
        else: # 1000
            cfg["InpEquityStepPerMinLot"] = 50.0
            cfg["InpMaxLayers"] = 4

        print(f"\n>>> TESTING CAPITAL: ${dep} (Equity Step: ${cfg['InpEquityStepPerMinLot']}, Max Layers: {cfg['InpMaxLayers']}) <<<")

        for w_code, w_info in WINDOWS.items():
            tid = f"danial_qm_{w_code}_{dep}"
            print(f"Running {w_code} ({w_info['name']})...", end=" ", flush=True)
            res = run_test(tid, w_info, dep, cfg)
            results.append(res)
            print(f"Status: {res['status']} | Net: ${res['net_profit']:.2f} | ROI: {res['roi_pct']:.1f}% | Trades: {res['total_trades']} | Win: {res['win_rate_pct']:.1f}% | DD: {res['drawdown_pct']:.1f}%")

    out_file = "strategies/Danial_FX/backtest_results/DANIAL_FX_CHAMPION_QM_RESULTS.json"
    os.makedirs(os.path.dirname(out_file), exist_ok=True)
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    print("\n" + "="*80)
    print(f"CHAMPION MATRIX COMPLETE. Saved to {out_file}")
    print("="*80)
