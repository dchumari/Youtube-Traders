import subprocess
import os
import re
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"DanialFX_Aggressive_Suite_v2"

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

def run_flip_test(test_id, win_from, win_to, deposit, leverage, inputs):
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
        subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=120)
    except Exception as e:
        print(f"Error for {test_id}: {e}")
        kill_terminal()

    res = {
        "test_id": test_id,
        "deposit": deposit,
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
    print("TESTING AHMAD DANIAL 100X ACCOUNT FLIP ENGINE ($100 DEPOSIT)")
    print("="*80)

    flip_configs = [
        {
            "name": "Aggressive_Flip_Scale_1.5x",
            "InpStrategyMode": 0,               # Quasimodo Sniper
            "InpAccountFlipMode": "true",
            "InpFlipInitialLotPer100": 0.05,
            "InpFlipMultiplier": 1.50,
            "InpFlipMaxLayers": 6,
            "InpFlipStepPoints": 250,          # 25 pips step
            "InpFlipTargetEquity": 10000.0,
            "InpEnableLayering": "true",
            "InpLockBreakevenOnLayer": "true",
            "InpBreakevenBufferPts": 10,
            "InpEnableTrailing": "true",
            "InpTrailingStartPoints": 350,
            "InpTrailingStepPoints": 120,
            "InpSwingLookback": 25,
            "InpMinBOSPoints": 120,
            "InpQMLTolerancePoints": 100,
            "InpSLHeadBufferPoints": 50,
            "InpStopLossPoints": 200,          # 20 pips tight sniper stop
            "InpTakeProfitPoints": 1500,        # 150 pips daily expansion target
            "InpBBPeriod": 20,
            "InpBBDev": 2.0,
            "InpEMA50Period": 50,
            "InpUseEMATrendFilter": "true",
            "InpMinRejectionWickPct": 0.40,
            "InpUseSessionFilter": "true",
            "InpStartHour": 7,
            "InpEndHour": 19,
            "InpMaxSpreadPoints": 45
        },
        {
            "name": "Ultra_Aggressive_Flip_Scale_2.0x",
            "InpStrategyMode": 0,               # Quasimodo Sniper
            "InpAccountFlipMode": "true",
            "InpFlipInitialLotPer100": 0.08,   # 0.08 base on $100
            "InpFlipMultiplier": 2.00,          # Double size each layer
            "InpFlipMaxLayers": 6,
            "InpFlipStepPoints": 250,
            "InpFlipTargetEquity": 10000.0,
            "InpEnableLayering": "true",
            "InpLockBreakevenOnLayer": "true",
            "InpBreakevenBufferPts": 10,
            "InpEnableTrailing": "true",
            "InpTrailingStartPoints": 300,
            "InpTrailingStepPoints": 100,
            "InpSwingLookback": 25,
            "InpMinBOSPoints": 120,
            "InpQMLTolerancePoints": 100,
            "InpSLHeadBufferPoints": 50,
            "InpStopLossPoints": 180,
            "InpTakeProfitPoints": 1500,
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
    ]

    for cfg in flip_configs:
        cname = cfg["name"]
        print(f"\n--- Testing Configuration: {cname} ---")
        
        # Test on 1-Week NFP Shock Window (Mar 2024)
        print("Running Window 1-Week NFP Shock (Mar 4 - Mar 11, 2024)...", end=" ", flush=True)
        res = run_flip_test(f"flip_{cname}_w1", "2024.03.04", "2024.03.11", 100, 400, cfg)
        print(f"Status: {res['status']} | Net: ${res['net_profit']:.2f} | ROI: {res['roi_pct']:.1f}% | Trades: {res['total_trades']} | Win: {res['win_rate_pct']:.1f}% | DD: {res['drawdown_pct']:.1f}%")

        # Test on 1-Month Expansion Window (Jan 2024)
        print("Running Window 1-Month Jan 2024...", end=" ", flush=True)
        res_m1 = run_flip_test(f"flip_{cname}_m1", "2024.01.01", "2024.01.31", 100, 400, cfg)
        print(f"Status: {res_m1['status']} | Net: ${res_m1['net_profit']:.2f} | ROI: {res_m1['roi_pct']:.1f}% | Trades: {res_m1['total_trades']} | Win: {res_m1['win_rate_pct']:.1f}% | DD: {res_m1['drawdown_pct']:.1f}%")

        # Test on Q4 Dovish Pivot Run (Q4 2023)
        print("Running Window 3-Month Dovish Pivot Run (Oct - Dec 2023)...", end=" ", flush=True)
        res_q4 = run_flip_test(f"flip_{cname}_q4", "2023.10.01", "2023.12.31", 100, 400, cfg)
        print(f"Status: {res_q4['status']} | Net: ${res_q4['net_profit']:.2f} | ROI: {res_q4['roi_pct']:.1f}% | Trades: {res_q4['total_trades']} | Win: {res_q4['win_rate_pct']:.1f}% | DD: {res_q4['drawdown_pct']:.1f}%")
