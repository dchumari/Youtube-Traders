import subprocess
import os
import re
import time
import json
import sys
from datetime import datetime

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"Options_Flow_Suite\Options_Flow_Master_Suite"

# Benchmark 16-Window Stress Matrix
WINDOWS = {
    # 4 distinct 1-Week Volatility Stress Windows
    "W1": {"name": "1-Week Volatility Stress 1 (NFP/CB)", "from": "2024.03.04", "to": "2024.03.11", "type": "1-Week"},
    "W2": {"name": "1-Week Volatility Stress 2 (CPI/FOMC)", "from": "2024.06.10", "to": "2024.06.17", "type": "1-Week"},
    "W3": {"name": "1-Week Volatility Stress 3 (Carry Shock)", "from": "2024.08.05", "to": "2024.08.12", "type": "1-Week"},
    "W4": {"name": "1-Week Volatility Stress 4 (US Election)", "from": "2024.11.04", "to": "2024.11.11", "type": "1-Week"},
    
    # 4 distinct 1-Month Trend Windows
    "M1": {"name": "1-Month Q1 Opening Trend", "from": "2024.01.01", "to": "2024.01.31", "type": "1-Month"},
    "M2": {"name": "1-Month Spring Expansion", "from": "2024.04.01", "to": "2024.04.30", "type": "1-Month"},
    "M3": {"name": "1-Month Summer Range/Chop", "from": "2024.07.01", "to": "2024.07.31", "type": "1-Month"},
    "M4": {"name": "1-Month Autumn Acceleration", "from": "2024.10.01", "to": "2024.10.31", "type": "1-Month"},
    
    # 4 distinct Multi-Month / Quarterly Windows
    "Q1": {"name": "3-Month Banking Crisis Shift", "from": "2023.01.01", "to": "2023.03.31", "type": "Quarterly"},
    "Q2": {"name": "3-Month Rate Tightening Plateau", "from": "2023.04.01", "to": "2023.06.30", "type": "Quarterly"},
    "Q3": {"name": "3-Month US Dollar Trend Rally", "from": "2023.07.01", "to": "2023.09.30", "type": "Quarterly"},
    "Q4": {"name": "3-Month Year-End Dovish Pivot", "from": "2023.10.01", "to": "2023.12.31", "type": "Quarterly"},
    
    # 4 distinct 1-Year Macro Cycles
    "Y1": {"name": "1-Year Macro Cycle 2022 (Rate Shock)", "from": "2022.01.01", "to": "2022.12.31", "type": "1-Year"},
    "Y2": {"name": "1-Year Macro Cycle 2023 (Disinflation)", "from": "2023.01.01", "to": "2023.12.31", "type": "1-Year"},
    "Y3": {"name": "1-Year Macro Cycle 2024 (Easing Cycle)", "from": "2024.01.01", "to": "2024.12.31", "type": "1-Year"},
    "Y4": {"name": "1-Year Macro Cycle 2025 (Transition)", "from": "2025.01.01", "to": "2025.12.31", "type": "1-Year"}
}

# Champion Hybrid Configuration
CHAMPION_INPUTS = {
    "InpStrategyMode": 10,              # STRAT_HYBRID_CHAMPION
    "InpMagicNumber": 777001,
    "InpCapitalMode": 1,               # Dynamic Tiered Compounding
    "InpFixedLot": 0.01,
    "InpEquityPerMicroLot": 25.0,       # $25 per 0.01 lot
    "InpMaxLotCap": 3.0,
    "InpStopLossPoints": 220,
    "InpRiskRewardRatio": 2.0,
    "InpUsePartials": "true",
    "InpPart1_RR": 1.0,
    "InpPart2_RR": 2.5,
    "InpBELockPoints": 10,
    "InpUseTrailingStop": "true",
    "InpATRPeriod": 14,
    "InpATRMultiplier": 1.5,
    "InpFlowVolumeThreshold": 135,
    "InpClusterLookback": 12,
    "InpMinWickRatio": 0.35,
    "InpGammaLookback": 50,
    "InpGammaSensitivity": 1.25,
    "InpUseSessionFilter": "true",
    "InpSessionStartH1": 7,
    "InpSessionEndH1": 11,
    "InpSessionStartH2": 13,
    "InpSessionEndH2": 17,
    "InpMaxSpreadPoints": 50
}

def clean_liveupdate():
    for d in [r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate",
              os.path.join(DATA_FOLDER, "liveupdate")]:
        if os.path.exists(d):
            for f in os.listdir(d):
                try: os.remove(os.path.join(d, f))
                except: pass

def run_test(wid, win_info, deposit, leverage, inputs):
    inputs_block = ""
    for k, v in inputs.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    clean_liveupdate()
    test_id = f"opt_{wid}_{int(deposit)}_{int(time.time()*1000)}"
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
    except Exception:
        pass

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
            gross_profit  = parse_float(matches.get('Gross Profit', '0'))
            gross_loss    = parse_float(matches.get('Gross Loss', '0'))
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

            # Cleanup
            for ext in ['.htm', '.png']:
                f_del = os.path.join(DATA_FOLDER, f"{rep_name}{ext}")
                if os.path.exists(f_del):
                    try: os.remove(f_del)
                    except: pass
            if os.path.exists(ini_path):
                try: os.remove(ini_path)
                except: pass

            return {
                "success": True,
                "net_profit": net_profit,
                "gross_profit": gross_profit,
                "gross_loss": gross_loss,
                "profit_factor": profit_factor,
                "drawdown_pct": dd_pct,
                "total_trades": total_trades,
                "win_rate_pct": win_pct
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

    return {"success": False, "error": "Report file not generated"}

print("="*80)
print("🚀 LAUNCHING OPTIONS FLOW 16-WINDOW MATRIX BENCHMARK")
print(f"Expert: {EXPERT_REL}")
print(f"Symbol: XAUUSD (M15) | Leverage: 1:400 | Engine: Hybrid Champion")
print("="*80)

results = {
    "metadata": {
        "strategy": "Options_Flow_Master_Suite (Hybrid Champion)",
        "symbol": "XAUUSD",
        "period": "M15",
        "leverage": "1:400",
        "timestamp": datetime.now().isoformat(),
        "inputs": CHAMPION_INPUTS
    },
    "account_100": {},
    "account_20": {},
    "summary": {}
}

# Run tests
for wid, win_info in WINDOWS.items():
    print(f"\n--- Testing Window {wid}: {win_info['name']} ({win_info['from']} to {win_info['to']}) ---")
    
    # $100 Account
    res100 = run_test(wid, win_info, 100.0, "1:400", CHAMPION_INPUTS)
    results["account_100"][wid] = res100
    if res100["success"]:
        print(f"  [$100] Net Profit: ${res100['net_profit']:+.2f} | PF: {res100['profit_factor']:.2f} | Trades: {res100['total_trades']} | DD: {res100['drawdown_pct']:.1f}% | Win: {res100['win_rate_pct']:.1f}%")
    else:
        print(f"  [$100] Failed: {res100.get('error')}")

    # $20 Micro Account
    res20 = run_test(wid, win_info, 20.0, "1:400", CHAMPION_INPUTS)
    results["account_20"][wid] = res20
    if res20["success"]:
        print(f"  [ $20] Net Profit: ${res20['net_profit']:+.2f} | PF: {res20['profit_factor']:.2f} | Trades: {res20['total_trades']} | DD: {res20['drawdown_pct']:.1f}% | Win: {res20['win_rate_pct']:.1f}%")
    else:
        print(f"  [ $20] Failed: {res20.get('error')}")

# Save results
out_json = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Options_Flow_Suite\backtest_results\OPTIONS_FLOW_16_WINDOWS_RESULTS.json"
with open(out_json, "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2)

print("\n" + "="*80)
print(f"✅ BENCHMARK COMPLETE! Results saved to: {out_json}")
print("="*80)
