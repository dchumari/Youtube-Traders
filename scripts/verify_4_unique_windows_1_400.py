import subprocess
import os
import re
import time
import json

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite"

# 4 Unique 1-Week Windows & 4 Unique 1-Month Windows
WINDOWS = {
    "W1 (NFP Shock)": {"from": "2024.03.04", "to": "2024.03.11", "type": "1-Week"},
    "W2 (CPI/FOMC Shock)": {"from": "2024.06.10", "to": "2024.06.17", "type": "1-Week"},
    "W3 (Yen Carry Crash)": {"from": "2024.08.05", "to": "2024.08.12", "type": "1-Week"},
    "W4 (US Election Shock)": {"from": "2024.11.04", "to": "2024.11.11", "type": "1-Week"},
    "M1 (Q1 Open Trend)": {"from": "2024.01.01", "to": "2024.01.31", "type": "1-Month"},
    "M2 (Spring Expansion)": {"from": "2024.04.01", "to": "2024.04.30", "type": "1-Month"},
    "M3 (Summer Range Chop)": {"from": "2024.07.01", "to": "2024.07.31", "type": "1-Month"},
    "M4 (Autumn Liquidity)": {"from": "2024.10.01", "to": "2024.10.31", "type": "1-Month"}
}

INPUTS = {
    "InpStrategy": 3,
    "InpMagicNumber": 888004,
    "InpRiskPercent": 0.0,
    "InpFixedLot": 0.01,
    "InpRewardRiskRatio": 2.0,
    "InpMaxSpreadPoints": 50,
    "InpFastEMAPeriod": 20,
    "InpSlowEMAPeriod": 50,
    "InpATRPeriod": 14,
    "InpUseSessionFilter": "true",
    "InpSessionStartH1": 7,
    "InpSessionEndH1": 11,
    "InpSessionStartH2": 13,
    "InpSessionEndH2": 17,
    "InpUseBreakeven": "true",
    "InpBETriggerR": 1.0,
    "InpBELockPoints": 10,
    "InpShowTradeBoxes": "true",
    "InpShowEntryArrows": "true",
    "InpShowBadges": "true",
    "InpShowConnLines": "true",
    "InpAllowDragBoxes": "true"
}

def clean_liveupdate():
    d = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate"
    if os.path.exists(d):
        for f in os.listdir(d):
            try: os.remove(os.path.join(d, f))
            except: pass

def run_single(name, win_info, deposit, leverage="1:400"):
    clean_liveupdate()
    test_id = f"w4u_{int(deposit)}_{int(time.time()*1000)}"
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

    inputs_block = ""
    for k, v in INPUTS.items():
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
        subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=90)
    except:
        pass

    res = {"name": name, "from": win_info["from"], "to": win_info["to"], "deposit": deposit, "leverage": leverage}
    if os.path.exists(rep_path):
        try:
            with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
                html = f.read()

            matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', html))

            def parse_num(s, default=0.0):
                if not s: return default
                clean = re.sub(r'[^0-9.-]', '', s.split('(')[0])
                try: return float(clean)
                except: return default

            res["net_profit"] = parse_num(matches.get('Total Net Profit', '0'))
            res["profit_factor"] = parse_num(matches.get('Profit Factor', '0'))
            res["trades"] = int(parse_num(matches.get('Total Trades', '0')))
            
            dd_str = matches.get('Balance Drawdown Maximal', '')
            res["dd_pct"] = parse_num(dd_str.split('(')[1].split('%')[0]) if '(' in dd_str and '%' in dd_str else 0.0
            
            win_str = matches.get('Profit Trades (% of total)', '')
            res["win_rate"] = parse_num(win_str.split('(')[1].split('%')[0]) if '(' in win_str and '%' in win_str else 0.0

            # Clean report files
            for ext in ['.htm', '.png']:
                fp = os.path.join(DATA_FOLDER, f"{rep_name}{ext}")
                if os.path.exists(fp):
                    try: os.remove(fp)
                    except: pass
            if os.path.exists(ini_path):
                try: os.remove(ini_path)
                except: pass
            return res
        except Exception as e:
            res["error"] = str(e)

    if os.path.exists(ini_path):
        try: os.remove(ini_path)
        except: pass
    res["error"] = "No report generated"
    return res

if __name__ == "__main__":
    results = []
    print("Testing 4 Unique Weekly Windows on $20 Deposit with 1:400 Leverage...")
    for wname, win in list(WINDOWS.items())[:4]:
        r = run_single(wname, win, deposit=20, leverage="1:400")
        print(f"[{r['name']}] ({r['from']} to {r['to']}): Net Profit: ${r.get('net_profit', 'N/A')} | Trades: {r.get('trades', 0)} | Win Rate: {r.get('win_rate', 0)}% | PF: {r.get('profit_factor', 0)}")
        results.append(r)

    print("\nTesting 4 Unique Weekly Windows on $100 Deposit with 1:400 Leverage...")
    for wname, win in list(WINDOWS.items())[:4]:
        r = run_single(wname, win, deposit=100, leverage="1:400")
        print(f"[{r['name']}] ({r['from']} to {r['to']}): Net Profit: ${r.get('net_profit', 'N/A')} | Trades: {r.get('trades', 0)} | Win Rate: {r.get('win_rate', 0)}% | PF: {r.get('profit_factor', 0)}")
        results.append(r)

    with open(r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\LEVERAGE_1_400_VERIFICATION.json", "w") as f:
        json.dump(results, f, indent=2)
    print("\nCompleted! Results saved to LEVERAGE_1_400_VERIFICATION.json")
