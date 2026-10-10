import subprocess
import os
import re
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"Aggressive_Flipper_Master_EA"

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

def run_flipper_test(test_id, win_from, win_to, deposit, leverage, inputs):
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
    print("TESTING AGGRESSIVE FLIPPER MASTER SUITE (10 BEHAVIORAL PATTERNS)")
    print("="*80)

    flipper_config = {
        "InpMagicNumber": 882200,
        "InpLotMode": 1,
        "InpFixedLotPerTicket": 0.01,
        "InpEquityPerMinLot": 25.0,
        "InpSpamTicketsCount": 6,
        "InpMaxLotPerTicket": 0.50,
        "InpStopLossPoints": 200,
        "InpTP1_Points": 200,
        "InpTP2_Points": 350,
        "InpTP3_Points": 600,
        "InpTP4_Points": 1000,
        "InpTP5_Points": 1600,
        "InpEnableReloadPyramid": "true",
        "InpMaxPyramidLayers": 4,
        "InpReloadStepPoints": 300,
        "InpReloadTicketsCount": 3,
        "InpBreakevenBufferPts": 10,
        "InpSteppedTrailLock": "true",
        "InpEnableTraceback": "true",
        "InpTracebackExtensionPts": 350,
        "InpTracebackWickRatio": 0.38,
        "InpTracebackTP_Points": 180,
        "InpTracebackSL_Points": 150,
        "InpReloadHeavyAtHL": "true",
        "InpSwingLookback": 25,
        "InpMinRejectionWickPct": 0.35,
        "InpEMA50Period": 50,
        "InpUseKillzones": "true",
        "InpLondonStartHour": 7,
        "InpLondonEndHour": 11,
        "InpNYStartHour": 12,
        "InpNYEndHour": 17,
        "InpMaxSpreadPoints": 45,
        "InpDumpOnExhaustion": "true",
        "InpAccountFlipMode": "true",
        "InpTargetEquity": 10000.0,
        "InpLockMilestoneProfits": "true",
        "InpEnableVisualRoadmap": "false",
        "InpApplyDraculaTheme": "false",
        "InpDrawPositionBoxes": "false",
        "InpDrawTPLines": "false",
        "InpDrawSwingLabels": "false",
        "InpShowHUDDashboard": "false"
    }

    # Test 1: $100 Account on 1-Week NFP Shock Window
    print("\n--- Test 1: $100 Capital on 1-Week NFP Shock (Mar 4 - Mar 11, 2024) ---")
    res1 = run_flipper_test("flip_100u_w1", "2024.03.04", "2024.03.11", 100, 400, flipper_config)
    print(f"Status: {res1['status']} | Net: ${res1['net_profit']:.2f} | ROI: {res1['roi_pct']:.1f}% | Trades: {res1['total_trades']} | Win: {res1['win_rate_pct']:.1f}% | DD: {res1['drawdown_pct']:.1f}%")

    # Test 2: $100 Account on 1-Month Trend (Jan 2024)
    print("\n--- Test 2: $100 Capital on 1-Month Trend (Jan 1 - Jan 31, 2024) ---")
    res2 = run_flipper_test("flip_100u_m1", "2024.01.01", "2024.01.31", 100, 400, flipper_config)
    print(f"Status: {res2['status']} | Net: ${res2['net_profit']:.2f} | ROI: {res2['roi_pct']:.1f}% | Trades: {res2['total_trades']} | Win: {res2['win_rate_pct']:.1f}% | DD: {res2['drawdown_pct']:.1f}%")

    # Test 3: $50 Account on 1-Week NFP Shock Window
    print("\n--- Test 3: $50 Capital on 1-Week NFP Shock (Mar 4 - Mar 11, 2024) ---")
    res3 = run_flipper_test("flip_50u_w1", "2024.03.04", "2024.03.11", 50, 400, flipper_config)
    print(f"Status: {res3['status']} | Net: ${res3['net_profit']:.2f} | ROI: {res3['roi_pct']:.1f}% | Trades: {res3['total_trades']} | Win: {res3['win_rate_pct']:.1f}% | DD: {res3['drawdown_pct']:.1f}%")

    # Save results to json
    out_json = {
        "test_100u_w1": res1,
        "test_100u_m1": res2,
        "test_50u_w1": res3
    }
    with open("strategies/Aggressive_Flipper_Suite/backtest_results/FLIPPER_BENCHMARK_RESULTS.json", "w") as f:
        json.dump(out_json, f, indent=2)
    print("\nResults successfully saved to strategies/Aggressive_Flipper_Suite/backtest_results/FLIPPER_BENCHMARK_RESULTS.json")
