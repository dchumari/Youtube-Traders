import subprocess
import os
import re
import time
import json

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite"

# Complete matrix of configurations across the 4 Mr P Fx strategies
CANDIDATE_CONFIGS = [
    # --- Strategy 0: Liquidity Grab (Sweep & Rejection) ---
    {
        "id": "LG-Gold-Killzone",
        "strat": 0,
        "name": "Liquidity Grab (Gold M15, Killzone Session, RR 2.5, Wick 0.45)",
        "symbol": "XAUUSD",
        "period": "M15",
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
        "id": "LG-EURUSD-Optimized",
        "strat": 0,
        "name": "Liquidity Grab (EURUSD M15, Trend Filter, RR 2.5, Wick 0.40)",
        "symbol": "EURUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.5,
            "InpSweepLookback": 20,
            "InpMinSweepPoints": 25,
            "InpMinWickRatio": 0.40,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 5,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },

    # --- Strategy 1: 15-Minute Trendline Break & Retest ---
    {
        "id": "TL-Gold-M15",
        "strat": 1,
        "name": "Trendline Retest (Gold M15, FastEMA 20, SlowEMA 50, RR 2.5)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 1,
            "InpRewardRiskRatio": 2.5,
            "InpFastEMAPeriod": 20,
            "InpSlowEMAPeriod": 50,
            "InpRetestTolerance": 30,
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
        "id": "TL-EURUSD-M15",
        "strat": 1,
        "name": "Trendline Retest (EURUSD M15, FastEMA 20, SlowEMA 50, RR 2.0)",
        "symbol": "EURUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 1,
            "InpRewardRiskRatio": 2.0,
            "InpFastEMAPeriod": 20,
            "InpSlowEMAPeriod": 50,
            "InpRetestTolerance": 25,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 5,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },

    # --- Strategy 2: Gold Matrix Volatility Scalper ---
    {
        "id": "GM-Gold-M15",
        "strat": 2,
        "name": "Gold Matrix (Gold M15, KeltnerMult 1.8, ATR 14, RSI 14, RR 2.5)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 2,
            "InpRewardRiskRatio": 2.5,
            "InpKeltnerMult": 1.8,
            "InpATRPeriod": 14,
            "InpRSIPeriod": 14,
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
        "id": "GM-EURUSD-M15",
        "strat": 2,
        "name": "Gold Matrix on EURUSD (KeltnerMult 1.8, ATR 14, RR 2.5)",
        "symbol": "EURUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 2,
            "InpRewardRiskRatio": 2.5,
            "InpKeltnerMult": 1.8,
            "InpATRPeriod": 14,
            "InpRSIPeriod": 14,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 5,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },

    # --- Strategy 3: Killzone Momentum Doubler ---
    {
        "id": "KZ-Gold-M15",
        "strat": 3,
        "name": "Killzone Momentum (Gold M15, FastEMA 20, SlowEMA 50, RR 2.5)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 3,
            "InpRewardRiskRatio": 2.5,
            "InpFastEMAPeriod": 20,
            "InpSlowEMAPeriod": 50,
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
        "id": "KZ-EURUSD-M15",
        "strat": 3,
        "name": "Killzone Momentum (EURUSD M15, FastEMA 20, SlowEMA 50, RR 2.5)",
        "symbol": "EURUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 3,
            "InpRewardRiskRatio": 2.5,
            "InpFastEMAPeriod": 20,
            "InpSlowEMAPeriod": 50,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 5,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    }
]

def run_test_case(cfg, deposit, leverage, from_date="2024.01.01", to_date="2024.03.31"):
    test_id = f"c_{int(time.time()*1000)}"
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
Symbol={cfg["symbol"]}
Period={cfg["period"]}
Model=1
FromDate={from_date}
ToDate={to_date}
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

    t0 = time.time()
    try:
        p = subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=90)
    except Exception as e:
        return {"success": False, "error": str(e)}

    elapsed = time.time() - t0

    if not os.path.exists(rep_path):
        if os.path.exists(ini_path):
            try: os.remove(ini_path)
            except: pass
        return {"success": False, "error": "No report file", "elapsed": elapsed}

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
    dd_money      = parse_float(dd_str)
    total_trades  = parse_int(matches.get('Total Trades', '0'))
    
    # Parse winning trades
    win_str = matches.get('Profit Trades (% of total)', '')
    win_pct = 0.0
    if '(' in win_str and '%' in win_str:
        win_pct = parse_float(win_str.split('(')[1].split('%')[0])

    # Clean up
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
        "drawdown_money": dd_money,
        "total_trades": total_trades,
        "win_rate_pct": win_pct,
        "elapsed": elapsed
    }

def main():
    print("=" * 80)
    print("MR P FX STRATEGIES DUAL ACCOUNT BACKTEST: $100 & $20 ACCOUNTS")
    print(f"Total Strategy Configurations: {len(CANDIDATE_CONFIGS)}")
    print("Testing Range: 2024.01.01 to 2024.03.31 (Q1 Multi-Regime Quarter)")
    print("=" * 80)

    summary_records = []

    for idx, cfg in enumerate(CANDIDATE_CONFIGS):
        print(f"\n[{idx+1}/{len(CANDIDATE_CONFIGS)}] Evaluating: {cfg['name']}")

        # 1. Test $100 Account (1:100 leverage)
        print("   -> Testing $100 Account (1:100 leverage)...")
        r100 = run_test_case(cfg, deposit=100.0, leverage="1:100")
        print(f"      $100: Net=${r100.get('net_profit', 0):+.2f} | PF={r100.get('profit_factor', 0):.2f} | DD={r100.get('drawdown_pct', 0):.2f}% | WinRate={r100.get('win_rate_pct', 0):.1f}% | Trades={r100.get('total_trades', 0)}")

        time.sleep(0.5)

        # 2. Test $20 Account (1:500 leverage)
        print("   -> Testing $20 Account (1:500 leverage)...")
        r20 = run_test_case(cfg, deposit=20.0, leverage="1:500")
        print(f"      $20:  Net=${r20.get('net_profit', 0):+.2f} | PF={r20.get('profit_factor', 0):.2f} | DD={r20.get('drawdown_pct', 0):.2f}% | WinRate={r20.get('win_rate_pct', 0):.1f}% | Trades={r20.get('total_trades', 0)}")

        record = {
            "config_id": cfg["id"],
            "strategy_id": cfg["strat"],
            "name": cfg["name"],
            "symbol": cfg["symbol"],
            "period": cfg["period"],
            "test_period": "2024.01.01 - 2024.03.31",
            "account_100": r100,
            "account_20": r20,
            "inputs": cfg["inputs"]
        }
        summary_records.append(record)

    output_path = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\MRPFX_100_AND_20_RESULTS.json"
    with open(output_path, "w", encoding="utf-8") as out:
        json.dump(summary_records, out, indent=2)

    print("\n" + "=" * 80)
    print("DUAL ACCOUNT VALIDATION COMPLETED!")
    print(f"Results saved to: {output_path}")
    print("=" * 80)

if __name__ == "__main__":
    main()
