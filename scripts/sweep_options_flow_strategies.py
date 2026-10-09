import subprocess
import os
import re
import time
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"Options_Flow_Suite\Options_Flow_Master_Suite"

TEST_WINDOWS = {
    "W1": {"name": "1-Week NFP Shock", "from": "2024.03.04", "to": "2024.03.11"},
    "W2": {"name": "1-Week CPI/FOMC", "from": "2024.06.10", "to": "2024.06.17"},
    "W3": {"name": "1-Week Carry Shock", "from": "2024.08.05", "to": "2024.08.12"},
    "W4": {"name": "1-Week US Election", "from": "2024.11.04", "to": "2024.11.11"},
    "M1": {"name": "1-Month Trend Q1", "from": "2024.01.01", "to": "2024.01.31"},
    "M2": {"name": "1-Month Spring", "from": "2024.04.01", "to": "2024.04.30"},
    "M3": {"name": "1-Month Summer Chop", "from": "2024.07.01", "to": "2024.07.31"},
    "M4": {"name": "1-Month Autumn", "from": "2024.10.01", "to": "2024.10.31"}
}

# Parameter Variations to test
CANDIDATES = [
    {
        "id": "CAND-1-GOLDEN_SWEEP_STRICT",
        "name": "Strategy 0: Golden Sweep with High Threshold (200% Volume)",
        "inputs": {
            "InpStrategyMode": 0,
            "InpCapitalMode": 1,
            "InpEquityPerMicroLot": 35.0,
            "InpFixedLot": 0.01,
            "InpStopLossPoints": 180,
            "InpRiskRewardRatio": 2.5,
            "InpUsePartials": "true",
            "InpPart1_RR": 1.0,
            "InpPart2_RR": 2.5,
            "InpBELockPoints": 10,
            "InpUseTrailingStop": "true",
            "InpATRMultiplier": 1.5,
            "InpFlowVolumeThreshold": 200,
            "InpMinWickRatio": 0.40,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpMaxSpreadPoints": 45
        }
    },
    {
        "id": "CAND-2-ZERO_GAMMA_BREAKOUT",
        "name": "Strategy 2: Zero Gamma Squeeze (Gamma Sensitivity 1.5)",
        "inputs": {
            "InpStrategyMode": 2,
            "InpCapitalMode": 1,
            "InpEquityPerMicroLot": 35.0,
            "InpFixedLot": 0.01,
            "InpStopLossPoints": 200,
            "InpRiskRewardRatio": 2.0,
            "InpUsePartials": "true",
            "InpPart1_RR": 1.0,
            "InpPart2_RR": 2.5,
            "InpBELockPoints": 10,
            "InpUseTrailingStop": "true",
            "InpATRMultiplier": 1.5,
            "InpGammaLookback": 60,
            "InpGammaSensitivity": 1.5,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpMaxSpreadPoints": 45
        }
    },
    {
        "id": "CAND-3-DEALER_WALL_PIN",
        "name": "Strategy 3: Call/Put Wall Mean Reversion",
        "inputs": {
            "InpStrategyMode": 3,
            "InpCapitalMode": 1,
            "InpEquityPerMicroLot": 35.0,
            "InpFixedLot": 0.01,
            "InpStopLossPoints": 180,
            "InpRiskRewardRatio": 1.5,
            "InpUsePartials": "true",
            "InpPart1_RR": 1.0,
            "InpPart2_RR": 2.0,
            "InpBELockPoints": 10,
            "InpUseTrailingStop": "true",
            "InpMinWickRatio": 0.40,
            "InpGammaLookback": 40,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpMaxSpreadPoints": 45
        }
    },
    {
        "id": "CAND-4-0DTE_OPEN_MOMENTUM",
        "name": "Strategy 4: 0DTE Open Momentum Squeeze (Opening Killzone)",
        "inputs": {
            "InpStrategyMode": 4,
            "InpCapitalMode": 1,
            "InpEquityPerMicroLot": 35.0,
            "InpFixedLot": 0.01,
            "InpStopLossPoints": 150,
            "InpRiskRewardRatio": 2.0,
            "InpUsePartials": "true",
            "InpPart1_RR": 1.0,
            "InpPart2_RR": 2.5,
            "InpBELockPoints": 10,
            "InpUseTrailingStop": "true",
            "InpFlowVolumeThreshold": 180,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 9,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 15,
            "InpMaxSpreadPoints": 45
        }
    }
]

def run_test(win_info, deposit, inputs):
    inputs_block = ""
    for k, v in inputs.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    test_id = f"sweep_{int(time.time()*1000)}"
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
            profit_factor = parse_float(matches.get('Profit Factor', '0'))
            dd_str        = matches.get('Balance Drawdown Maximal', '')
            dd_pct        = parse_float(dd_str.split('(')[1].split('%')[0]) if ('(' in dd_str and '%' in dd_str) else 0.0
            total_trades  = parse_int(matches.get('Total Trades', '0'))
            win_str       = matches.get('Profit Trades (% of total)', '')
            win_pct       = parse_float(win_str.split('(')[1].split('%')[0]) if ('(' in win_str and '%' in win_str) else 0.0

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
                "profit_factor": profit_factor,
                "drawdown_pct": dd_pct,
                "total_trades": total_trades,
                "win_rate_pct": win_pct
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

    return {"success": False, "error": "No report"}

sweep_results = []

for cand in CANDIDATES:
    print(f"\n==================================================")
    print(f"BENCHMARKING: {cand['name']}")
    print(f"==================================================")
    cand_summary = {
        "id": cand["id"],
        "name": cand["name"],
        "inputs": cand["inputs"],
        "windows": {},
        "pass_count": 0,
        "total_profit": 0.0
    }
    
    for wid, win in TEST_WINDOWS.items():
        res = run_test(win, 100.0, cand["inputs"])
        cand_summary["windows"][wid] = res
        if res.get("success"):
            np = res["net_profit"]
            cand_summary["total_profit"] += np
            is_win = (np > 0)
            if is_win:
                cand_summary["pass_count"] += 1
            print(f"  [{wid}] {win['name']}: ${np:+.2f} | PF: {res['profit_factor']:.2f} | Trades: {res['total_trades']} | DD: {res['drawdown_pct']:.1f}% | {'✅ PASS' if is_win else '❌ FAIL'}")
        else:
            print(f"  [{wid}] {win['name']}: FAILED ({res.get('error')})")

    pass_ratio = f"{cand_summary['pass_count']}/{len(TEST_WINDOWS)}"
    print(f"--> Result: {pass_ratio} windows profitable | Total Profit: ${cand_summary['total_profit']:+.2f}")
    sweep_results.append(cand_summary)

# Save
out_file = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Options_Flow_Suite\backtest_results\OPTIONS_FLOW_STRATEGY_SWEEP_RESULTS.json"
with open(out_file, "w", encoding="utf-8") as f:
    json.dump(sweep_results, f, indent=2)

print("\n" + "="*80)
print(f"SWEEP COMPLETE! Results saved to: {out_file}")
