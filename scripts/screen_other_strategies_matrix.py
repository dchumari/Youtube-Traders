import subprocess
import os
import re
import time
import json

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite"

# Screening period: Q1 2024 (2024.01.01 - 2024.03.31) on Gold M15
FROM_DATE = "2024.01.01"
TO_DATE = "2024.03.31"

MATRIX_CONFIGS = [
    # --- Strategy 1: Trendline Break & Retest Grid ---
    {
        "id": "S1_Grid_1",
        "strat": 1,
        "name": "Trendline Retest (Fast 10, Slow 30, Tol 20, RR 1.5, BE 1.0R)",
        "inputs": {
            "InpStrategy": 1,
            "InpRewardRiskRatio": 1.5,
            "InpFastEMAPeriod": 10,
            "InpSlowEMAPeriod": 30,
            "InpRetestTolerance": 20,
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
        "id": "S1_Grid_2",
        "strat": 1,
        "name": "Trendline Retest (Fast 20, Slow 50, Tol 30, RR 2.0, BE 1.0R)",
        "inputs": {
            "InpStrategy": 1,
            "InpRewardRiskRatio": 2.0,
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
        "id": "S1_Grid_3",
        "strat": 1,
        "name": "Trendline Retest (Fast 20, Slow 50, Tol 50, RR 2.5, No BE)",
        "inputs": {
            "InpStrategy": 1,
            "InpRewardRiskRatio": 2.5,
            "InpFastEMAPeriod": 20,
            "InpSlowEMAPeriod": 50,
            "InpRetestTolerance": 50,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "false",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 10,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },
    {
        "id": "S1_Grid_4",
        "strat": 1,
        "name": "Trendline Retest (Fast 50, Slow 100, Tol 40, RR 2.0, BE 1.0R)",
        "inputs": {
            "InpStrategy": 1,
            "InpRewardRiskRatio": 2.0,
            "InpFastEMAPeriod": 50,
            "InpSlowEMAPeriod": 100,
            "InpRetestTolerance": 40,
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

    # --- Strategy 2: Gold Matrix Volatility Scalper Grid ---
    {
        "id": "S2_Grid_1",
        "strat": 2,
        "name": "Gold Matrix (Keltner 1.5, ATR 14, RSI 65/35, RR 1.5)",
        "inputs": {
            "InpStrategy": 2,
            "InpRewardRiskRatio": 1.5,
            "InpKeltnerMult": 1.5,
            "InpATRPeriod": 14,
            "InpRSIPeriod": 14,
            "InpRSIOverbought": 65.0,
            "InpRSIOversold": 35.0,
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
        "id": "S2_Grid_2",
        "strat": 2,
        "name": "Gold Matrix (Keltner 2.0, ATR 14, RSI 70/30, RR 2.0)",
        "inputs": {
            "InpStrategy": 2,
            "InpRewardRiskRatio": 2.0,
            "InpKeltnerMult": 2.0,
            "InpATRPeriod": 14,
            "InpRSIPeriod": 14,
            "InpRSIOverbought": 70.0,
            "InpRSIOversold": 30.0,
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
        "id": "S2_Grid_3",
        "strat": 2,
        "name": "Gold Matrix (Keltner 1.8, ATR 10, RSI 60/40, RR 2.0)",
        "inputs": {
            "InpStrategy": 2,
            "InpRewardRiskRatio": 2.0,
            "InpKeltnerMult": 1.8,
            "InpATRPeriod": 10,
            "InpRSIPeriod": 10,
            "InpRSIOverbought": 60.0,
            "InpRSIOversold": 40.0,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "false",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 10,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },

    # --- Strategy 3: Killzone Momentum Doubler Grid ---
    {
        "id": "S3_Grid_1",
        "strat": 3,
        "name": "Killzone Momentum (Fast 10, Slow 30, RR 1.5, BE 1.0R)",
        "inputs": {
            "InpStrategy": 3,
            "InpRewardRiskRatio": 1.5,
            "InpFastEMAPeriod": 10,
            "InpSlowEMAPeriod": 30,
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
        "id": "S3_Grid_2",
        "strat": 3,
        "name": "Killzone Momentum (Fast 20, Slow 50, RR 2.0, BE 1.0R)",
        "inputs": {
            "InpStrategy": 3,
            "InpRewardRiskRatio": 2.0,
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
        "id": "S3_Grid_3",
        "strat": 3,
        "name": "Killzone Momentum (Fast 20, Slow 50, RR 2.5, No BE)",
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
            "InpUseBreakeven": "false",
            "InpBETriggerR": 1.0,
            "InpBELockPoints": 10,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    }
]

def clean_liveupdate():
    liveupdate_dir = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate"
    if os.path.exists(liveupdate_dir):
        for f in os.listdir(liveupdate_dir):
            try: os.remove(os.path.join(liveupdate_dir, f))
            except: pass

def run_test(cfg, deposit, leverage):
    clean_liveupdate()
    test_id = f"scr_{cfg['id']}_{int(deposit)}_{int(time.time()*1000)}"
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
FromDate={FROM_DATE}
ToDate={TO_DATE}
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
        subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=60)
    except Exception as e:
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
                "profit_factor": profit_factor,
                "drawdown_pct": dd_pct,
                "total_trades": total_trades,
                "win_rate_pct": win_pct
            }
        except:
            pass

    if os.path.exists(ini_path):
        try: os.remove(ini_path)
        except: pass

    return {"success": False, "net_profit": 0.0, "profit_factor": 0.0, "drawdown_pct": 0.0, "total_trades": 0, "win_rate_pct": 0.0}

def main():
    print("=" * 80)
    print("SCREENING SETTINGS MATRIX FOR STRATEGIES 1, 2, 3 (Q1 2024 BENCHMARK)")
    print("=" * 80)

    results = []
    for cfg in MATRIX_CONFIGS:
        print(f"\nRunning: [{cfg['id']}] {cfg['name']}...")
        r100 = run_test(cfg, 100.0, "1:100")
        print(f"  $100: Net=${r100['net_profit']:+6.2f} | PF={r100['profit_factor']:4.2f} | DD={r100['drawdown_pct']:5.2f}% | Trades={r100['total_trades']:3d} | WR={r100['win_rate_pct']:4.1f}%")
        
        r20 = run_test(cfg, 20.0, "1:500")
        print(f"  $20 : Net=${r20['net_profit']:+6.2f} | PF={r20['profit_factor']:4.2f} | DD={r20['drawdown_pct']:5.2f}% | Trades={r20['total_trades']:3d} | WR={r20['win_rate_pct']:4.1f}%")

        results.append({
            "config": cfg,
            "account_100": r100,
            "account_20": r20
        })

    out_file = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\MRPFX_OTHER_STRATEGIES_SCREENING.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)
    print(f"\nSaved screening results to: {out_file}")

if __name__ == "__main__":
    main()
