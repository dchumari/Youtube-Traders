import subprocess
import os
import re
import time
import json
from datetime import datetime

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite"

TARGET_WINDOWS = {
    # 4 distinct 1-Week windows
    "W1": {"from": "2024.03.04", "to": "2024.03.11", "type": "1-Week"},
    "W2": {"from": "2024.06.10", "to": "2024.06.17", "type": "1-Week"},
    "W3": {"from": "2024.08.05", "to": "2024.08.12", "type": "1-Week"},
    "W4": {"from": "2024.11.04", "to": "2024.11.11", "type": "1-Week"},
    
    # 4 distinct 1-Month windows
    "M1": {"from": "2024.01.01", "to": "2024.01.31", "type": "1-Month"},
    "M2": {"from": "2024.04.01", "to": "2024.04.30", "type": "1-Month"},
    "M3": {"from": "2024.07.01", "to": "2024.07.31", "type": "1-Month"},
    "M4": {"from": "2024.10.01", "to": "2024.10.31", "type": "1-Month"}
}

TEST_CANDIDATES = [
    {
        "id": "CAND_1_Original_Optimal",
        "name": "Original Optimal (RR 2.0, Lookback 20, Wick 0.45, BE 1.0R, Trend 50)",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.0,
            "InpSweepLookback": 20,
            "InpMinSweepPoints": 35,
            "InpMinWickRatio": 0.45,
            "InpUseTrendFilter": "true",
            "InpTrendEMAPeriod": 50,
            "InpMacroEMAPeriod": 0,
            "InpMaxSLPoints": 0,
            "InpSkipWideSL": "false",
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
        "id": "CAND_2_Sniper_Wick050",
        "name": "Sniper Wick 0.50 + Fast BE 0.8R (Strict Rejection)",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.0,
            "InpSweepLookback": 20,
            "InpMinSweepPoints": 30,
            "InpMinWickRatio": 0.50,
            "InpUseTrendFilter": "true",
            "InpTrendEMAPeriod": 50,
            "InpMacroEMAPeriod": 0,
            "InpMaxSLPoints": 0,
            "InpSkipWideSL": "false",
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 0.8,
            "InpBELockPoints": 5,
            "InpRiskPercent": 0.0,
            "InpFixedLot": 0.01
        }
    },
    {
        "id": "CAND_3_RR25_Runner",
        "name": "High Reward Runner (RR 2.5, Lookback 20, Wick 0.45, BE 1.0R)",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.5,
            "InpSweepLookback": 20,
            "InpMinSweepPoints": 35,
            "InpMinWickRatio": 0.45,
            "InpUseTrendFilter": "true",
            "InpTrendEMAPeriod": 50,
            "InpMacroEMAPeriod": 0,
            "InpMaxSLPoints": 0,
            "InpSkipWideSL": "false",
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
        "id": "CAND_4_Killzone_Mom_Calibrated",
        "name": "Killzone Momentum (Fast 20, Slow 50, ATR 1.2, RR 2.0, BE 1.0R)",
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
    }
]

def clean_liveupdate():
    liveupdate_dir = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate"
    if os.path.exists(liveupdate_dir):
        for f in os.listdir(liveupdate_dir):
            try: os.remove(os.path.join(liveupdate_dir, f))
            except: pass

def run_test(cfg, wid, win_info, deposit, leverage):
    clean_liveupdate()
    test_id = f"opt_{cfg['id'][:6]}_{wid}_{int(deposit)}_{int(time.time()*1000)}"
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
        subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=60)
    except:
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
        except:
            pass

    if os.path.exists(ini_path):
        try: os.remove(ini_path)
        except: pass

    return {"success": False, "net_profit": 0.0, "profit_factor": 0.0, "drawdown_pct": 0.0, "total_trades": 0, "win_rate_pct": 0.0}

def main():
    print("=" * 90)
    print("SEARCHING FOR THE OPTIMAL STRATEGY CONFIGURATION (WEEKLY & MONTHLY FOCUS)")
    print("Objective: >= 3/4 Weekly Windows Profitable AND >= 3/4 Monthly Windows Profitable")
    print("=" * 90)

    summary_results = []

    for cfg in TEST_CANDIDATES:
        print("\n" + "#" * 80)
        print(f"EVALUATING CANDIDATE: [{cfg['id']}] {cfg['name']}")
        print("#" * 80)

        c_data = {"id": cfg["id"], "name": cfg["name"], "weekly": {}, "monthly": {}, "summary": {}}
        
        w_wins_100 = 0
        w_wins_20 = 0
        w_net_100 = 0.0
        w_net_20 = 0.0
        
        # Test Weekly (W1-W4)
        print(">> Running 1-Week Windows (W1-W4)...")
        for wid in ["W1", "W2", "W3", "W4"]:
            win_info = TARGET_WINDOWS[wid]
            r100 = run_test(cfg, wid, win_info, 100.0, "1:100")
            r20  = run_test(cfg, wid, win_info, 20.0, "1:500")
            c_data["weekly"][wid] = {"100": r100, "20": r20}
            if r100["net_profit"] > 0: w_wins_100 += 1
            if r20["net_profit"] > 0: w_wins_20 += 1
            w_net_100 += r100["net_profit"]
            w_net_20 += r20["net_profit"]
            print(f"   [{wid}] $100: Net=${r100['net_profit']:+6.2f} (PF {r100['profit_factor']:4.2f}, Tr {r100['total_trades']:2d}) | $20: Net=${r20['net_profit']:+6.2f} ({(r20['net_profit']/20.0)*100:+6.1f}%)")

        m_wins_100 = 0
        m_wins_20 = 0
        m_net_100 = 0.0
        m_net_20 = 0.0
        
        # Test Monthly (M1-M4)
        print(">> Running 1-Month Windows (M1-M4)...")
        for wid in ["M1", "M2", "M3", "M4"]:
            win_info = TARGET_WINDOWS[wid]
            r100 = run_test(cfg, wid, win_info, 100.0, "1:100")
            r20  = run_test(cfg, wid, win_info, 20.0, "1:500")
            c_data["monthly"][wid] = {"100": r100, "20": r20}
            if r100["net_profit"] > 0: m_wins_100 += 1
            if r20["net_profit"] > 0: m_wins_20 += 1
            m_net_100 += r100["net_profit"]
            m_net_20 += r20["net_profit"]
            print(f"   [{wid}] $100: Net=${r100['net_profit']:+6.2f} (PF {r100['profit_factor']:4.2f}, Tr {r100['total_trades']:2d}) | $20: Net=${r20['net_profit']:+6.2f} ({(r20['net_profit']/20.0)*100:+6.1f}%)")

        c_data["summary"] = {
            "w_wins_100": w_wins_100,
            "w_wins_20": w_wins_20,
            "w_net_100": round(w_net_100, 2),
            "w_net_20": round(w_net_20, 2),
            "w_ret_20_pct": round((w_net_20 / 20.0) * 100.0, 1),
            "m_wins_100": m_wins_100,
            "m_wins_20": m_wins_20,
            "m_net_100": round(m_net_100, 2),
            "m_net_20": round(m_net_20, 2),
            "m_ret_20_pct": round((m_net_20 / 20.0) * 100.0, 1)
        }

        print(f"\n>> CANDIDATE SUMMARY: {cfg['id']}")
        print(f"   Weekly Win Windows: $100 -> {w_wins_100}/4 | $20 -> {w_wins_20}/4 | Total $20 Return: {c_data['summary']['w_ret_20_pct']:+6.1f}%")
        print(f"   Monthly Win Windows: $100 -> {m_wins_100}/4 | $20 -> {m_wins_20}/4 | Total $20 Return: {c_data['summary']['m_ret_20_pct']:+6.1f}%")

        summary_results.append(c_data)

    out_file = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\WEEKLY_MONTHLY_CANDIDATE_SEARCH.json"
    with open(out_file, "w") as f:
        json.dump(summary_results, f, indent=2)
    print(f"\nAll candidate results saved to: {out_file}")

if __name__ == "__main__":
    main()
