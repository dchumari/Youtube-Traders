import subprocess
import os
import re
import time
import json

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite"

TARGET_WINDOWS = {
    # 4 distinct 1-Week windows
    "W1": {"name": "1-Week NFP Volatility Stress", "from": "2024.03.04", "to": "2024.03.11", "type": "1-Week"},
    "W2": {"name": "1-Week CPI/FOMC Volatility Stress", "from": "2024.06.10", "to": "2024.06.17", "type": "1-Week"},
    "W3": {"name": "1-Week Carry Shock Volatility Stress", "from": "2024.08.05", "to": "2024.08.12", "type": "1-Week"},
    "W4": {"name": "1-Week US Election Volatility Stress", "from": "2024.11.04", "to": "2024.11.11", "type": "1-Week"},
    
    # 4 distinct 1-Month windows
    "M1": {"name": "1-Month Q1 Opening Trend", "from": "2024.01.01", "to": "2024.01.31", "type": "1-Month"},
    "M2": {"name": "1-Month Spring Expansion (ATH Run)", "from": "2024.04.01", "to": "2024.04.30", "type": "1-Month"},
    "M3": {"name": "1-Month Summer Range Chop", "from": "2024.07.01", "to": "2024.07.31", "type": "1-Month"},
    "M4": {"name": "1-Month Autumn Acceleration", "from": "2024.10.01", "to": "2024.10.31", "type": "1-Month"}
}

# Enhanced Strategy Preset: Mr P Fx Institutional Liquidity Shield
# Lookback 20, Wick 0.45, RR 2.0, Breakeven at 1.0R (+10pts), 200 EMA Macro Filter, 35pt Max SL Protection
ENHANCED_INPUTS = {
    "InpStrategy": 0,
    "InpRewardRiskRatio": 2.0,
    "InpSweepLookback": 20,
    "InpMinSweepPoints": 35,
    "InpMinWickRatio": 0.45,
    "InpUseTrendFilter": "true",
    "InpTrendEMAPeriod": 50,
    "InpMacroEMAPeriod": 200,      # 200 EMA Macro Trend Filter
    "InpMaxSLPoints": 35,          # 35 Points Max SL ($3.50 max risk on 0.01 lot)
    "InpSkipWideSL": "false",      # Cap SL to 35 points
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

def clean_liveupdate():
    liveupdate_dir = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate"
    if os.path.exists(liveupdate_dir):
        for f in os.listdir(liveupdate_dir):
            try: os.remove(os.path.join(liveupdate_dir, f))
            except: pass

def run_test(wid, win_info, deposit, leverage):
    clean_liveupdate()
    test_id = f"enh_{wid}_{int(deposit)}_{int(time.time()*1000)}"
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

    inputs_block = ""
    for k, v in ENHANCED_INPUTS.items():
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
    print("=" * 85)
    print("TESTING ENHANCED MRPFX LIQUIDITY SHIELD (WEEKLY & MONTHLY WINDOWS)")
    print("Features: Liquidity Grab + 200 EMA Macro Filter + 35pt Max SL Cap + 1.0R BE")
    print("=" * 85)

    res = {"account_100": {}, "account_20": {}}
    wins_100 = 0
    wins_20 = 0
    tot_net_100 = 0.0
    tot_net_20 = 0.0

    for wid, win_info in TARGET_WINDOWS.items():
        print(f"\nEvaluating Window {wid} ({win_info['type']}): {win_info['name']}...")
        r100 = run_test(wid, win_info, 100.0, "1:100")
        r20  = run_test(wid, win_info, 20.0, "1:500")

        res["account_100"][wid] = r100
        res["account_20"][wid] = r20

        ret20 = (r20["net_profit"] / 20.0) * 100.0

        if r100["net_profit"] > 0: wins_100 += 1
        if r20["net_profit"] > 0: wins_20 += 1
        tot_net_100 += r100["net_profit"]
        tot_net_20 += r20["net_profit"]

        print(f"  $100: Net=${r100['net_profit']:+6.2f} | PF={r100['profit_factor']:4.2f} | DD={r100['drawdown_pct']:5.1f}% | WR={r100['win_rate_pct']:4.0f}% | Tr={r100['total_trades']:2d}")
        print(f"  $20 : Net=${r20['net_profit']:+6.2f} ({ret20:+6.1f}%) | PF={r20['profit_factor']:4.2f} | DD={r20['drawdown_pct']:5.1f}% | WR={r20['win_rate_pct']:4.0f}% | Tr={r20['total_trades']:2d}")

    # Weekly Subtotal (W1-W4)
    w_wins_100 = sum(1 for w in ["W1","W2","W3","W4"] if res["account_100"][w]["net_profit"] > 0)
    w_wins_20  = sum(1 for w in ["W1","W2","W3","W4"] if res["account_20"][w]["net_profit"] > 0)
    w_net_100  = sum(res["account_100"][w]["net_profit"] for w in ["W1","W2","W3","W4"])
    w_net_20   = sum(res["account_20"][w]["net_profit"] for w in ["W1","W2","W3","W4"])

    # Monthly Subtotal (M1-M4)
    m_wins_100 = sum(1 for m in ["M1","M2","M3","M4"] if res["account_100"][m]["net_profit"] > 0)
    m_wins_20  = sum(1 for m in ["M2","M2","M3","M4"] if res["account_20"][m]["net_profit"] > 0)
    m_net_100  = sum(res["account_100"][m]["net_profit"] for m in ["M1","M2","M3","M4"])
    m_net_20   = sum(res["account_20"][m]["net_profit"] for m in ["M1","M2","M3","M4"])

    print("\n" + "=" * 85)
    print("ENHANCED MRPFX BENCHMARK SUMMARY:")
    print(f"  Weekly Windows (W1-W4) Profitable: $100 -> {w_wins_100}/4 ({w_wins_100/4*100:.0f}%) | $20 -> {w_wins_20}/4 ({w_wins_20/4*100:.0f}%)")
    print(f"  Weekly Net Total: $100 -> ${w_net_100:+.2f} | $20 -> ${w_net_20:+.2f} ({(w_net_20/20.0)*100:+.1f}%)")
    print(f"  Monthly Windows (M1-M4) Profitable: $100 -> {m_wins_100}/4 ({m_wins_100/4*100:.0f}%) | $20 -> {m_wins_20}/4")
    print(f"  Monthly Net Total: $100 -> ${m_net_100:+.2f} | $20 -> ${m_net_20:+.2f} ({(m_net_20/20.0)*100:+.1f}%)")
    print("=" * 85)

    with open(r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\ENHANCED_WEEKLY_MONTHLY_RESULTS.json", "w") as f:
        json.dump(res, f, indent=2)

if __name__ == "__main__":
    main()
