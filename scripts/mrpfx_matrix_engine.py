import subprocess
import os
import re
import time
import json
from datetime import datetime

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite"

# Strategy models
STRATEGY_MODELS = {
    0: {"name": "Liquidity_Grab_Sweep_Rejection", "desc": "$50k Gold/Nasdaq High-Low Sweep & Rejection Setup"},
    1: {"name": "Trendline_Break_Retest", "desc": "15-Minute Dynamic Trendline Break & Retest Setup"},
    2: {"name": "Gold_Matrix_Scalper", "desc": "Gold Matrix Volatility Expansion & Momentum Scalper"},
    3: {"name": "Killzone_Momentum_Doubler", "desc": "London & NY Killzone Momentum Small Account Doubler"}
}

# Testing Windows (1-Month distinct market regimes)
TEST_WINDOWS = [
    {"id": "W1_Trend", "name": "2024.01 Trend Regime", "from": "2024.01.01", "to": "2024.01.31"},
    {"id": "W2_Expansion", "name": "2024.04 Expansion Regime", "from": "2024.04.01", "to": "2024.04.30"},
    {"id": "W3_Chop", "name": "2024.07 Range/Chop Regime", "from": "2024.07.01", "to": "2024.07.31"},
    {"id": "W4_Acceleration", "name": "2024.10 Acceleration Regime", "from": "2024.10.01", "to": "2024.10.31"}
]

def run_test_instance(symbol, period, from_date, to_date, deposit, inputs_dict):
    test_id = f"m_{int(time.time()*1000)}"
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")
    
    inputs_block = ""
    for k, v in inputs_dict.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"
        
    ini_text = f"""[Common]
Login=472929

[Tester]
Expert={EXPERT_REL}
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
        subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=90)
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
    win_rate_str  = matches.get('Short Trades (won %)', matches.get('Profit Trades (% of total)', ''))
    win_pct       = 0.0
    if '(' in win_rate_str and '%' in win_rate_str:
        win_pct   = parse_float(win_rate_str.split('(')[1].split('%')[0])
    
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
