import subprocess
import os
import re
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"

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

def run_backtest(expert_name, test_id, win_from, win_to, deposit, leverage, inputs):
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
Expert={expert_name}
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
        "expert": expert_name,
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

            net_profit    = parse_float(matches.get('Total Net Profit', '0'))
            profit_factor = parse_float(matches.get('Profit Factor', '0'))
            total_trades  = parse_int(matches.get('Total Trades', '0'))
            dd_pct        = parse_float(matches.get('Maximal Drawdown', '0').split('%')[0].split('(')[-1] if '%' in matches.get('Maximal Drawdown', '') else matches.get('Maximal Drawdown', '0'))
            
            # Find win rate
            profit_trades_str = matches.get('Profit Trades (% of total)', '')
            win_rate = 0.0
            if '%' in profit_trades_str:
                m_pct = re.search(r'\(([\d.]+)%\)', profit_trades_str)
                if m_pct: win_rate = float(m_pct.group(1))

            roi = (net_profit / deposit) * 100.0 if deposit > 0 else 0.0

            res["net_profit"]    = round(net_profit, 2)
            res["profit_factor"] = round(profit_factor, 2)
            res["drawdown_pct"]  = round(dd_pct, 1)
            res["total_trades"]  = total_trades
            res["win_rate_pct"]  = round(win_rate, 1)
            res["roi_pct"]       = round(roi, 1)
            res["status"]        = "PASS" if net_profit > 0 else "FAIL"
        except Exception as e:
            print(f"Error parsing {rep_path}: {e}")

    return res

if __name__ == "__main__":
    print("="*90)
    print("UNIVERSAL 10 BEHAVIORAL PATTERNS MULTI-STRATEGY BENCHMARK MATRIX")
    print("Testing DanialFX, MrPFx, Daily Fib 618, and Aggressive Flipper Suites on XAUUSD M15")
    print("="*90)

    # 1. Danial FX Config (QM Sniper + Behavioral Engine)
    danial_cfg = {
        "InpStrategyMode": 0,
        "InpMagicNumber": 991100,
        "InpEnableLayering": "false",
        "InpAccountFlipMode": "false",
        "InpStopLossPoints": 250,
        "InpTakeProfitPoints": 750,
        "InpEnableBehavioralEngine": "true",
        "InpBehavioralSpamTickets": 6,
        "InpBehavioralTP1_Pts": 200,
        "InpBehavioralTP2_Pts": 350,
        "InpBehavioralTP3_Pts": 600,
        "InpBehavioralTP4_Pts": 1000,
        "InpBehavioralTP5_Pts": 1600,
        "InpBehavioralTraceback": "true",
        "InpBehavioralPyramiding": "true",
        "InpBehavioralDumpAndFlip": "true",
        "InpBehavioralClimaxFade": "true",
        "InpBehavioralVisuals": "false"
    }

    # 2. Mr P Fx Config (Trendline Break & Retest + Behavioral Engine)
    mrpfx_cfg = {
        "InpStrategy": 1,
        "InpMagicNumber": 888001,
        "InpRiskPercent": 0.0,
        "InpFixedLot": 0.01,
        "InpEnableBehavioralEngine": "true",
        "InpBehavioralSpamTickets": 5,
        "InpBehavioralTP1_Pts": 200,
        "InpBehavioralTP2_Pts": 350,
        "InpBehavioralTP3_Pts": 600,
        "InpBehavioralTP4_Pts": 1000,
        "InpBehavioralTP5_Pts": 1600,
        "InpBehavioralTraceback": "true",
        "InpBehavioralPyramiding": "true",
        "InpBehavioralDumpAndFlip": "true",
        "InpBehavioralClimaxFade": "true",
        "InpBehavioralVisuals": "false"
    }

    # 3. Daily Fib 618 Config (Fib 61.8% + Behavioral Engine)
    dailyfib_cfg = {
        "InpSizingMode": 1,
        "InpFixedLot": 0.01,
        "InpStepEquitySize": 50.0,
        "InpSLPoints": 400,
        "InpTargetMode": 0,
        "InpLeg1_RR": 1.0,
        "InpLeg2_RR": 2.0,
        "InpEnableBehavioralEngine": "true",
        "InpBehavioralSpamTickets": 5,
        "InpBehavioralTP1_Pts": 200,
        "InpBehavioralTP2_Pts": 350,
        "InpBehavioralTP3_Pts": 600,
        "InpBehavioralTP4_Pts": 1000,
        "InpBehavioralTP5_Pts": 1600,
        "InpBehavioralTraceback": "true",
        "InpBehavioralPyramiding": "true",
        "InpBehavioralDumpAndFlip": "true",
        "InpBehavioralClimaxFade": "true",
        "InpBehavioralVisuals": "false"
    }

    # 4. Aggressive Flipper Master EA Config
    flipper_cfg = {
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

    test_matrix = [
        # (EA Name, Config, Test ID Prefix)
        ("DanialFX_Aggressive_Suite", danial_cfg, "danial_beh"),
        ("MrPFx_Master_Suite", mrpfx_cfg, "mrpfx_beh"),
        ("Daily_Fib_618_Aggressive_Math_EA", dailyfib_cfg, "fib_beh"),
        ("Aggressive_Flipper_Master_EA", flipper_cfg, "flip_master")
    ]

    all_results = []

    # Run Benchmark on 1-Week NFP Shock Window ($100 Deposit)
    print("\n>>> BENCHMARK 1: 1-WEEK NFP SHOCK (Mar 4 - Mar 11, 2024) | $100 DEPOSIT | 1:400 LEVERAGE <<<")
    for ea_name, cfg, pfx in test_matrix:
        t_id = f"{pfx}_w1_100u"
        print(f"Running {ea_name}...")
        r = run_backtest(ea_name, t_id, "2024.03.04", "2024.03.11", 100, 400, cfg)
        all_results.append(r)
        print(f"  [{r['status']}] Net Profit: ${r['net_profit']:.2f} | ROI: {r['roi_pct']:.1f}% | Trades: {r['total_trades']} | Win: {r['win_rate_pct']:.1f}% | PF: {r['profit_factor']:.2f} | DD: {r['drawdown_pct']:.1f}%")

    # Run Benchmark on 1-Month Trend Window ($100 Deposit)
    print("\n>>> BENCHMARK 2: 1-MONTH TREND EXPANSION (Jan 1 - Jan 31, 2024) | $100 DEPOSIT | 1:400 LEVERAGE <<<")
    for ea_name, cfg, pfx in test_matrix:
        t_id = f"{pfx}_m1_100u"
        print(f"Running {ea_name}...")
        r = run_backtest(ea_name, t_id, "2024.01.01", "2024.01.31", 100, 400, cfg)
        all_results.append(r)
        print(f"  [{r['status']}] Net Profit: ${r['net_profit']:.2f} | ROI: {r['roi_pct']:.1f}% | Trades: {r['total_trades']} | Win: {r['win_rate_pct']:.1f}% | PF: {r['profit_factor']:.2f} | DD: {r['drawdown_pct']:.1f}%")

    # Save benchmark results
    out_path = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Aggressive_Flipper_Suite\backtest_results\BEHAVIORAL_MULTI_STRATEGY_RESULTS.json"
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(all_results, f, indent=2)

    print("\n" + "="*90)
    print("MULTI-STRATEGY BENCHMARK COMPLETE!")
    print(f"Results saved to {out_path}")
    print("="*90)
