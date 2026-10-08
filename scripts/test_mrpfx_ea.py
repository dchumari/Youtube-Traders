import subprocess
import os
import re
import time

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"

def run_single_test(expert_rel, symbol, period, from_date, to_date, deposit=100.0, inputs=""):
    test_id = f"test_{int(time.time()*1000)}"
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")
    
    inputs_block = ""
    if inputs:
        for line in inputs.strip().splitlines():
            line = line.strip()
            if line:
                inputs_block += f"{line}\n"
                
    ini_text = f"""[Common]
Login=472929

[Tester]
Expert={expert_rel}
Symbol={symbol}
Period={period}
Model=1
FromDate={from_date}
ToDate={to_date}
Deposit={deposit}
Currency=USD
Leverage=1:100
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
        p = subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=120)
    except Exception as e:
        print(f"Error running tester: {e}")
        return {"success": False, "error": str(e)}
        
    elapsed = time.time() - t0
    
    if not os.path.exists(rep_path):
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

    net_profit = parse_float(matches.get('Total Net Profit', '0'))
    profit_factor = parse_float(matches.get('Profit Factor', '0'))
    dd_str = matches.get('Balance Drawdown Maximal', '')
    dd_pct = 0.0
    if '(' in dd_str and '%' in dd_str:
        dd_pct = parse_float(dd_str.split('(')[1].split('%')[0])
    total_trades = parse_int(matches.get('Total Trades', '0'))
    
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
        "profit_factor": profit_factor,
        "drawdown_pct": dd_pct,
        "total_trades": total_trades,
        "elapsed": elapsed
    }

print("Running single test of MrPFx_Master_Suite on EURUSD M15...")
res = run_single_test(
    r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite",
    "EURUSD",
    "M15",
    "2024.01.01",
    "2024.01.31",
    deposit=100.0,
    inputs="InpStrategy=0||0||0||3||N\nInpRewardRiskRatio=2.5||2.5||1.5||4.0||N\n"
)
print("Result:", res)
