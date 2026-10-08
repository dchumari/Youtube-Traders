import subprocess
import os
import re
import time
import json

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Daily_Fibonacci_Strategy\Daily_Fib_618_Aggressive_Math_EA"

WINDOWS = {
    "M2": {"name": "1-Month Spring Expansion (Apr 2024)", "from": "2024.04.01", "to": "2024.04.30"},
    "M4": {"name": "1-Month Autumn Acceleration (Oct 2024)", "from": "2024.10.01", "to": "2024.10.31"},
    "Q1": {"name": "3-Month Banking Crisis Shift (Q1 2023)", "from": "2023.01.01", "to": "2023.03.31"},
    "Q3": {"name": "3-Month US Dollar Trend Rally (Q3 2023)", "from": "2023.07.01", "to": "2023.09.30"},
    "Y2": {"name": "1-Year Macro Cycle 2023 (Disinflation)", "from": "2023.01.01", "to": "2023.12.31"}
}

def clean_liveupdate():
    liveupdate_dir = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate"
    if os.path.exists(liveupdate_dir):
        for f in os.listdir(liveupdate_dir):
            try: os.remove(os.path.join(liveupdate_dir, f))
            except: pass

def run_test(wid, win_info, deposit, leverage, sizing_mode=1):
    inputs_dict = {
        "InpSizingMode": sizing_mode,
        "InpFixedLot": 0.01,
        "InpStepEquitySize": 50.0,
        "InpMaxLotCap": 3.0,
        "InpSLPoints": 400,
        "InpTargetMode": 0,
        "InpLeg1_RR": 1.0,
        "InpLeg2_RR": 2.0,
        "InpBELockPoints": 10,
        "InpBaseMagic": 618900,
        "InpMinDayRangePts": 1000,
        "InpEntryTolerance": 50,
        "InpMaxSpreadPoints": 50,
        "InpTradeImmediate": "true",
        "InpTradeVirginLevels": "true",
        "InpMaxVirginAgeDays": 30,
        "InpMaxDailyTrades": 2,
        "InpUseSessionFilter": "true",
        "InpSessionStartHour": 7,
        "InpSessionEndHour": 18,
        "InpDrawChartObjects": "false",
        "InpShowDashboard": "false"
    }

    inputs_block = ""
    for k, v in inputs_dict.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    test_id = f"am_{wid}_{int(deposit)}_{int(time.time()*1000)}"
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

print("=========================================================================================")
print("EVALUATING AGGRESSIVE TIERED MATHEMATICAL FLOW ENGINE (TIERED POSITION SIZING)")
print("Equation: $0-$25->0.01 | $25-$50->0.02 | $50-$100->0.03 | $100-$200->0.05 | $200-$350->0.08")
print("=========================================================================================")

print("\n--- $100 STARTING DEPOSIT (1:100 LEVERAGE) ---")
for wid, win_info in WINDOWS.items():
    # Fixed 0.01 lot baseline
    r_fix = run_test(wid, win_info, deposit=100.0, leverage=100, sizing_mode=0)
    # Tiered Mathematical Compounding
    r_flow = run_test(wid, win_info, deposit=100.0, leverage=100, sizing_mode=1)
    
    gain_mult = (r_flow['net_profit'] / r_fix['net_profit']) if r_fix['net_profit'] > 0 else 0
    print(f"[{wid}] {win_info['name']}:")
    print(f"    Fixed 0.01 Lot:   Net=${r_fix['net_profit']:+7.2f} | PF={r_fix['profit_factor']:.2f} | DD={r_fix['drawdown_pct']:.1f}%")
    print(f"    Tiered Flow Sizing: Net=${r_flow['net_profit']:+7.2f} | PF={r_flow['profit_factor']:.2f} | DD={r_flow['drawdown_pct']:.1f}% (Expansion: {gain_mult:.1f}x)")

print("\n--- $20 MICRO ACCOUNT CHALLENGE (1:500 LEVERAGE) ---")
for wid, win_info in WINDOWS.items():
    r20_flow = run_test(wid, win_info, deposit=20.0, leverage=500, sizing_mode=1)
    pct20 = (r20_flow['net_profit'] / 20.0) * 100.0
    print(f"[{wid}] {win_info['name']}:")
    print(f"    $20 Tiered Flow: Net=${r20_flow['net_profit']:+7.2f} ({pct20:+6.1f}%) | PF={r20_flow['profit_factor']:.2f} | DD={r20_flow['drawdown_pct']:.1f}% | Trades={r20_flow['total_trades']}")
