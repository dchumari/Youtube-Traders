import subprocess
import os
import re
import time

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Daily_Fibonacci_Strategy\Daily_Fib_618_V2_EA"

WINDOWS = {
    "Y1": {"name": "1-Year Macro Cycle 2022", "from": "2022.01.01", "to": "2022.12.31"},
    "Y2": {"name": "1-Year Macro Cycle 2023", "from": "2023.01.01", "to": "2023.12.31"},
    "Y3": {"name": "1-Year Macro Cycle 2024", "from": "2024.01.01", "to": "2024.12.31"},
    "Y4": {"name": "1-Year Macro Cycle 2025", "from": "2025.01.01", "to": "2025.12.31"},
    "M1": {"name": "1-Month Q1 Opening Trend", "from": "2024.01.01", "to": "2024.01.31"},
    "M2": {"name": "1-Month Spring Expansion", "from": "2024.04.01", "to": "2024.04.30"},
    "M3": {"name": "1-Month Summer Range/Chop", "from": "2024.07.01", "to": "2024.07.31"},
    "M4": {"name": "1-Month Autumn Acceleration", "from": "2024.10.01", "to": "2024.10.31"},
}

def clean_liveupdate():
    liveupdate_dir = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate"
    if os.path.exists(liveupdate_dir):
        for f in os.listdir(liveupdate_dir):
            try: os.remove(os.path.join(liveupdate_dir, f))
            except: pass

def run_test(wid, win_info, sl_points=400, deposit=100.0, leverage=100):
    inputs_dict = {
        "InpCapitalMode": 0,
        "InpFixedLot": 0.01,
        "InpEquityStep": 100.0,
        "InpMaxLotCap": 2.0,
        "InpSLPoints": sl_points,
        "InpLeg1_RR": 1.0,
        "InpLeg2_RR": 2.0,
        "InpBELockPoints": 10,
        "InpBaseMagic": 618700,
        "InpEntryTolerance": 50,
        "InpMaxSpreadPoints": 50,
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

    test_id = f"gy_{wid}_{int(time.time()*1000)}"
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

    res = {"net_profit": 0.0, "profit_factor": 0.0, "trades": 0, "win_rate": 0.0, "drawdown_pct": 0.0}
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

            res["net_profit"] = parse_float(matches.get('Total Net Profit', '0'))
            res["profit_factor"] = parse_float(matches.get('Profit Factor', '0'))
            res["trades"] = int(re.sub(r'[^0-9]', '', matches.get('Total Trades', '0').split('(')[0]) or 0)
            dd_str = matches.get('Balance Drawdown Maximal', '')
            if '(' in dd_str and '%' in dd_str:
                res["drawdown_pct"] = parse_float(dd_str.split('(')[1].split('%')[0])
            win_str = matches.get('Profit Trades (% of total)', '')
            if '(' in win_str and '%' in win_str:
                res["win_rate"] = parse_float(win_str.split('(')[1].split('%')[0])

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

print("==========================================================================")
print("TESTING GOLDEN POCKET DUAL PARTIAL (SL=400, TP1=1.0R, TP2=2.0R)")
print("==========================================================================")
for wid, win_info in WINDOWS.items():
    r = run_test(wid, win_info, sl_points=400)
    print(f"[{wid}] {win_info['name']}: Net=${r['net_profit']:+.2f} | PF={r['profit_factor']:.2f} | Trades={r['trades']} | WinRate={r['win_rate']:.1f}% | DD={r['drawdown_pct']:.1f}%")
