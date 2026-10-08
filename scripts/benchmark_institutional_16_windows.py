import subprocess
import os
import re
import time
import json

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Daily_Fibonacci_Strategy\Daily_Fib_618_Institutional_EA"

WINDOWS = {
    "W1": {"name": "1-Week Volatility Stress 1 (NFP/CB)", "from": "2024.03.04", "to": "2024.03.11", "type": "1-Week"},
    "W2": {"name": "1-Week Volatility Stress 2 (CPI/FOMC)", "from": "2024.06.10", "to": "2024.06.17", "type": "1-Week"},
    "W3": {"name": "1-Week Volatility Stress 3 (Carry Shock)", "from": "2024.08.05", "to": "2024.08.12", "type": "1-Week"},
    "W4": {"name": "1-Week Volatility Stress 4 (US Election)", "from": "2024.11.04", "to": "2024.11.11", "type": "1-Week"},
    
    "M1": {"name": "1-Month Q1 Opening Trend", "from": "2024.01.01", "to": "2024.01.31", "type": "1-Month"},
    "M2": {"name": "1-Month Spring Expansion", "from": "2024.04.01", "to": "2024.04.30", "type": "1-Month"},
    "M3": {"name": "1-Month Summer Range/Chop", "from": "2024.07.01", "to": "2024.07.31", "type": "1-Month"},
    "M4": {"name": "1-Month Autumn Acceleration", "from": "2024.10.01", "to": "2024.10.31", "type": "1-Month"},
    
    "Q1": {"name": "3-Month Banking Crisis Shift", "from": "2023.01.01", "to": "2023.03.31", "type": "Quarterly"},
    "Q2": {"name": "3-Month Rate Tightening Plateau", "from": "2023.04.01", "to": "2023.06.30", "type": "Quarterly"},
    "Q3": {"name": "3-Month US Dollar Trend Rally", "from": "2023.07.01", "to": "2023.09.30", "type": "Quarterly"},
    "Q4": {"name": "3-Month Year-End Dovish Pivot", "from": "2023.10.01", "to": "2023.12.31", "type": "Quarterly"},
    
    "Y1": {"name": "1-Year Macro Cycle 2022 (Rate Shock)", "from": "2022.01.01", "to": "2022.12.31", "type": "1-Year"},
    "Y2": {"name": "1-Year Macro Cycle 2023 (Disinflation)", "from": "2023.01.01", "to": "2023.12.31", "type": "1-Year"},
    "Y3": {"name": "1-Year Macro Cycle 2024 (Easing Cycle)", "from": "2024.01.01", "to": "2024.12.31", "type": "1-Year"},
    "Y4": {"name": "1-Year Macro Cycle 2025 (Transition)", "from": "2025.01.01", "to": "2025.12.31", "type": "1-Year"}
}

def clean_liveupdate():
    liveupdate_dir = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate"
    if os.path.exists(liveupdate_dir):
        for f in os.listdir(liveupdate_dir):
            try: os.remove(os.path.join(liveupdate_dir, f))
            except: pass

def run_single(wid, win_info, deposit, leverage, trend_mode=0):
    inputs_dict = {
        "InpCapitalMode": 0,
        "InpFixedLot": 0.01,
        "InpEquityStep": 100.0,
        "InpMaxLotCap": 2.0,
        "InpSLPoints": 400,
        "InpLeg1_RR": 1.0,
        "InpLeg2_RR": 2.0,
        "InpBELockPoints": 10,
        "InpBaseMagic": 618800,
        "InpTrendFilterMode": trend_mode,
        "InpDailyEMAPeriod": 100,
        "InpEntryTolerance": 50,
        "InpMaxSpreadPoints": 50,
        "InpMinDayRangePoints": 0,
        "InpTradeImmediate": "true",
        "InpTradeVirginLevels": "true",
        "InpMaxVirginAgeDays": 30,
        "InpMaxDailyTrades": 2,
        "InpUseSessionFilter": "true",
        "InpSessionStartHour": 7,
        "InpSessionEndHour": 18
    }

    inputs_block = ""
    for k, v in inputs_dict.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    test_id = f"inst_{wid}_{int(deposit)}_{int(time.time()*1000)}"
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

    clean_liveupdate()
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
Leverage=1:{leverage}
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
    except:
        pass

    res = {
        "success": False, "net_profit": 0.0, "profit_factor": 0.0,
        "drawdown_pct": 0.0, "total_trades": 0, "win_rate_pct": 0.0
    }
    if os.path.exists(rep_path):
        try:
            with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
                html = f.read()

            matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', html))
            def parse_float(s, d=0.0):
                if not s: return d
                c = re.sub(r'[^0-9.-]', '', s.split('(')[0])
                try: return float(c)
                except: return d

            res["success"] = True
            res["net_profit"] = parse_float(matches.get('Total Net Profit', '0'))
            res["profit_factor"] = parse_float(matches.get('Profit Factor', '0'))
            res["total_trades"] = int(re.sub(r'[^0-9]', '', matches.get('Total Trades', '0').split('(')[0]) or 0)
            dd_str = matches.get('Balance Drawdown Maximal', '')
            if '(' in dd_str and '%' in dd_str:
                res["drawdown_pct"] = parse_float(dd_str.split('(')[1].split('%')[0])
            win_str = matches.get('Profit Trades (% of total)', '')
            if '(' in win_str and '%' in win_str:
                res["win_rate_pct"] = parse_float(win_str.split('(')[1].split('%')[0])

            for ext in ['.htm', '.png']:
                fp = os.path.join(DATA_FOLDER, f"{rep_name}{ext}")
                if os.path.exists(fp):
                    try: os.remove(fp)
                    except: pass
            if os.path.exists(ini_path):
                try: os.remove(ini_path)
                except: pass
        except Exception as e:
            pass
    return res

results = {"account_100": {}, "account_20": {}}

print("=====================================================================================")
print("BENCHMARKING INSTITUTIONAL DUAL-LEG 1:1 PARTIAL ENGINE (SL=400, TP1=1.0R, TP2=2.0R)")
print("=====================================================================================")

total_100_profit = 0.0
total_20_profit = 0.0

for wid, win_info in WINDOWS.items():
    r100 = run_single(wid, win_info, deposit=100.0, leverage=100, trend_mode=0)
    results["account_100"][wid] = r100
    total_100_profit += r100["net_profit"]

    r20 = run_single(wid, win_info, deposit=20.0, leverage=500, trend_mode=0)
    results["account_20"][wid] = r20
    total_20_profit += r20["net_profit"]

    pct_20 = (r20["net_profit"] / 20.0) * 100.0
    print(f"[{wid}] {win_info['name']}:")
    print(f"   $100: Net=${r100['net_profit']:+6.2f} | PF={r100['profit_factor']:.2f} | WinRate={r100['win_rate_pct']:.1f}% | DD={r100['drawdown_pct']:.1f}% | Trades={r100['total_trades']}")
    print(f"    $20: Net=${r20['net_profit']:+6.2f} ({pct_20:+6.1f}%) | PF={r20['profit_factor']:.2f} | WinRate={r20['win_rate_pct']:.1f}% | DD={r20['drawdown_pct']:.1f}% | Trades={r20['total_trades']}")

print("=====================================================================================")
print(f"TOTAL $100 NET PROFIT ACROSS ALL 16 WINDOWS: ${total_100_profit:+.2f}")
print(f"TOTAL  $20 NET PROFIT ACROSS ALL 16 WINDOWS: ${total_20_profit:+.2f}")
print("=====================================================================================")

with open(r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\FIB618_INSTITUTIONAL_16_WINDOWS_RESULTS.json", "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2)
print("Saved to d:\\Projects\\AUTOMATIONS\\TRADING\\Youtube-Traders\\FIB618_INSTITUTIONAL_16_WINDOWS_RESULTS.json")
