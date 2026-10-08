import subprocess
import os
import re
import json

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite"

def clean_liveupdate():
    d = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate"
    if os.path.exists(d):
        for f in os.listdir(d):
            try: os.remove(os.path.join(d, f))
            except: pass

def run_backtest(params, from_date="2024.03.04", to_date="2024.03.11", deposit=100, leverage="1:400"):
    clean_liveupdate()
    test_id = f"exp_{int(deposit)}_{params.get('InpStrategy', 0)}_{int(params.get('InpRiskPercent', 0)*10)}_{int(params.get('InpFixedLot', 0)*100)}"
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

    inputs_block = ""
    for k, v in params.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    ini_text = f"""[Common]
Login=472929

[Tester]
Expert={EXPERT_REL}
Symbol=XAUUSD
Period=M15
Model=1
UseDate=1
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

    try:
        subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=60)
    except:
        pass

    res = {}
    if os.path.exists(rep_path):
        with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
            html = f.read()

        def parse(pattern):
            m = re.search(pattern, html)
            if not m: return "0"
            return re.sub(r'[^0-9.-]', '', m.group(1).split('(')[0])

        res["profit"] = float(parse(r"Total Net Profit:</td>\s*<td[^>]*><b>([^<]+)</b>"))
        res["pf"] = float(parse(r"Profit Factor:</td>\s*<td[^>]*><b>([^<]+)</b>"))
        res["trades"] = int(float(parse(r"Total Trades:</td>\s*<td[^>]*><b>([^<]+)</b>")))
        
        dd_m = re.search(r"Balance Drawdown Maximal:</td>\s*<td[^>]*><b>([^<]+)</b>", html)
        if dd_m and '(' in dd_m.group(1):
            res["dd_pct"] = float(re.sub(r'[^0-9.]', '', dd_m.group(1).split('(')[1].split('%')[0]))
        else:
            res["dd_pct"] = 0.0

        for ext in ['.htm', '.png']:
            fp = os.path.join(DATA_FOLDER, f"{rep_name}{ext}")
            if os.path.exists(fp):
                try: os.remove(fp)
                except: pass
    if os.path.exists(ini_path):
        try: os.remove(ini_path)
        except: pass
    return res

if __name__ == "__main__":
    # Test on W1 (NFP Shock) with $100 deposit on 1:400 leverage
    tests = [
        {"name": "Baseline (Fixed 0.01 Lot, RR 2.0)", "InpStrategy": 3, "InpRiskPercent": 0.0, "InpFixedLot": 0.01, "InpRewardRiskRatio": 2.0, "InpFastEMAPeriod": 20, "InpSlowEMAPeriod": 50, "InpATRPeriod": 14, "InpUseSessionFilter": "true", "InpSessionStartH1": 7, "InpSessionEndH1": 11, "InpSessionStartH2": 13, "InpSessionEndH2": 17, "InpUseBreakeven": "true", "InpBETriggerR": 1.0, "InpBELockPoints": 10},
        {"name": "Scaled 0.03 Lot (3x Size)", "InpStrategy": 3, "InpRiskPercent": 0.0, "InpFixedLot": 0.03, "InpRewardRiskRatio": 2.0, "InpFastEMAPeriod": 20, "InpSlowEMAPeriod": 50, "InpATRPeriod": 14, "InpUseSessionFilter": "true", "InpSessionStartH1": 7, "InpSessionEndH1": 11, "InpSessionStartH2": 13, "InpSessionEndH2": 17, "InpUseBreakeven": "true", "InpBETriggerR": 1.0, "InpBELockPoints": 10},
        {"name": "Scaled 0.05 Lot (5x Size)", "InpStrategy": 3, "InpRiskPercent": 0.0, "InpFixedLot": 0.05, "InpRewardRiskRatio": 2.0, "InpFastEMAPeriod": 20, "InpSlowEMAPeriod": 50, "InpATRPeriod": 14, "InpUseSessionFilter": "true", "InpSessionStartH1": 7, "InpSessionEndH1": 11, "InpSessionStartH2": 13, "InpSessionEndH2": 17, "InpUseBreakeven": "true", "InpBETriggerR": 1.0, "InpBELockPoints": 10},
        {"name": "Dynamic 3.0% Risk Compounding", "InpStrategy": 3, "InpRiskPercent": 3.0, "InpFixedLot": 0.01, "InpRewardRiskRatio": 2.0, "InpFastEMAPeriod": 20, "InpSlowEMAPeriod": 50, "InpATRPeriod": 14, "InpUseSessionFilter": "true", "InpSessionStartH1": 7, "InpSessionEndH1": 11, "InpSessionStartH2": 13, "InpSessionEndH2": 17, "InpUseBreakeven": "true", "InpBETriggerR": 1.0, "InpBELockPoints": 10},
        {"name": "Dynamic 5.0% Risk Compounding", "InpStrategy": 3, "InpRiskPercent": 5.0, "InpFixedLot": 0.01, "InpRewardRiskRatio": 2.0, "InpFastEMAPeriod": 20, "InpSlowEMAPeriod": 50, "InpATRPeriod": 14, "InpUseSessionFilter": "true", "InpSessionStartH1": 7, "InpSessionEndH1": 11, "InpSessionStartH2": 13, "InpSessionEndH2": 17, "InpUseBreakeven": "true", "InpBETriggerR": 1.0, "InpBELockPoints": 10},
        {"name": "Dynamic 5% + RR 3.0 Runner", "InpStrategy": 3, "InpRiskPercent": 5.0, "InpFixedLot": 0.01, "InpRewardRiskRatio": 3.0, "InpFastEMAPeriod": 20, "InpSlowEMAPeriod": 50, "InpATRPeriod": 14, "InpUseSessionFilter": "true", "InpSessionStartH1": 7, "InpSessionEndH1": 11, "InpSessionStartH2": 13, "InpSessionEndH2": 17, "InpUseBreakeven": "true", "InpBETriggerR": 1.0, "InpBELockPoints": 10},
    ]

    print("=== Testing Profit Expansion Models on W1 (NFP Shock, $100 Deposit) ===")
    for t in tests:
        res = run_backtest(t, from_date="2024.03.04", to_date="2024.03.11", deposit=100)
        p = res.get("profit", 0)
        print(f"[{t['name']}]: Net Profit: ${p:>+7.2f} ({p/100*100:>+5.1f}%) | Max DD: {res.get('dd_pct', 0):>4.1f}% | PF: {res.get('pf', 0):>4.2f}")
