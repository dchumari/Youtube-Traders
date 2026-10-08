import subprocess
import os
import re
import time
import json

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite"

GRID_VARIATIONS = [
    {
        "id": "OPT-1-RR2.0",
        "name": "Gold M15 Liquidity Grab (RR 2.0, Wick 0.45, Lookback 20)",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.0,
            "InpSweepLookback": 20,
            "InpMinSweepPoints": 35,
            "InpMinWickRatio": 0.45,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 10,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },
    {
        "id": "OPT-2-RR2.5-Standard",
        "name": "Gold M15 Liquidity Grab (RR 2.5, Wick 0.45, Lookback 20)",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.5,
            "InpSweepLookback": 20,
            "InpMinSweepPoints": 35,
            "InpMinWickRatio": 0.45,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 10,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },
    {
        "id": "OPT-3-RR3.0-Runner",
        "name": "Gold M15 Liquidity Grab (RR 3.0, Wick 0.45, Lookback 20)",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 3.0,
            "InpSweepLookback": 20,
            "InpMinSweepPoints": 35,
            "InpMinWickRatio": 0.45,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 10,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },
    {
        "id": "OPT-4-StrictWick0.50",
        "name": "Gold M15 Liquidity Grab (RR 2.5, Wick 0.50, Lookback 20)",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.5,
            "InpSweepLookback": 20,
            "InpMinSweepPoints": 35,
            "InpMinWickRatio": 0.50,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 10,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },
    {
        "id": "OPT-5-FastLookback15",
        "name": "Gold M15 Liquidity Grab (RR 2.5, Wick 0.45, Lookback 15)",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.5,
            "InpSweepLookback": 15,
            "InpMinSweepPoints": 30,
            "InpMinWickRatio": 0.45,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 10,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },
    {
        "id": "OPT-6-MacroLookback25",
        "name": "Gold M15 Liquidity Grab (RR 2.5, Wick 0.45, Lookback 25)",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.5,
            "InpSweepLookback": 25,
            "InpMinSweepPoints": 40,
            "InpMinWickRatio": 0.45,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 10,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    }
]

def run_test(cfg, deposit, leverage):
    test_id = f"opt_{int(time.time()*1000)}"
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

    inputs_block = ""
    for k, v in cfg["inputs"].items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    ini_text = f"""[Common]
Login=472929

[Tester]
Expert={EXPERT_REL}
Symbol=XAUUSD
Period=M15
Model=1
FromDate=2024.01.01
ToDate=2024.03.31
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
        return {"success": False, "error": str(e)}

    if not os.path.exists(rep_path):
        if os.path.exists(ini_path):
            try: os.remove(ini_path)
            except: pass
        return {"success": False, "error": "No report file"}

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

def main():
    print("=" * 80)
    print("FINE-TUNING OPTIMIZATION: WINNING LIQUIDITY GRAB ON XAUUSD")
    print("=" * 80)

    fine_results = []
    for idx, cfg in enumerate(GRID_VARIATIONS):
        print(f"\n[{idx+1}/{len(GRID_VARIATIONS)}] Testing {cfg['id']}: {cfg['name']}")
        
        # Test $100
        r100 = run_test(cfg, deposit=100.0, leverage="1:100")
        print(f"   $100 Account: Net=${r100.get('net_profit',0):+.2f} | PF={r100.get('profit_factor',0):.2f} | DD={r100.get('drawdown_pct',0):.2f}% | WinRate={r100.get('win_rate_pct',0):.1f}% | Trades={r100.get('total_trades',0)}")

        time.sleep(0.3)

        # Test $20
        r20 = run_test(cfg, deposit=20.0, leverage="1:500")
        print(f"   $20  Account: Net=${r20.get('net_profit',0):+.2f} | PF={r20.get('profit_factor',0):.2f} | DD={r20.get('drawdown_pct',0):.2f}% | WinRate={r20.get('win_rate_pct',0):.1f}% | Trades={r20.get('total_trades',0)}")

        fine_results.append({
            "id": cfg["id"],
            "name": cfg["name"],
            "inputs": cfg["inputs"],
            "account_100": r100,
            "account_20": r20
        })

    out_file = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\MRPFX_FINE_TUNING_RESULTS.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(fine_results, f, indent=2)

    print("\nFine-tuning completed successfully! Saved to:", out_file)

if __name__ == "__main__":
    main()
