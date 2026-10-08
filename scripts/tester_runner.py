import os
import sys
import subprocess
import time
import re

TERMINAL_EXE = r"C:\Program Files\MetaTrader 5\terminal64.exe"
METAEDITOR_EXE = r"C:\Program Files\MetaTrader 5\MetaEditor64.exe"
DATA_FOLDER = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"
DEFAULT_LOGIN = "472929"

WINDOWS = {
    # 4 distinct 1-Week windows (High-frequency volatility stress)
    "W1": {"name": "1-Week Volatility Stress 1 (NFP/CB)", "from": "2024.03.04", "to": "2024.03.11", "type": "week"},
    "W2": {"name": "1-Week Volatility Stress 2 (CPI/FOMC)", "from": "2024.06.10", "to": "2024.06.17", "type": "week"},
    "W3": {"name": "1-Week Volatility Stress 3 (Carry Shock)", "from": "2024.08.05", "to": "2024.08.12", "type": "week"},
    "W4": {"name": "1-Week Volatility Stress 4 (US Election)", "from": "2024.11.04", "to": "2024.11.11", "type": "week"},
    
    # 4 distinct 1-Month windows
    "M1": {"name": "1-Month Q1 Opening Trend", "from": "2024.01.01", "to": "2024.01.31", "type": "month"},
    "M2": {"name": "1-Month Spring Expansion", "from": "2024.04.01", "to": "2024.04.30", "type": "month"},
    "M3": {"name": "1-Month Summer Range/Chop", "from": "2024.07.01", "to": "2024.07.31", "type": "month"},
    "M4": {"name": "1-Month Autumn Acceleration", "from": "2024.10.01", "to": "2024.10.31", "type": "month"},
    
    # 4 distinct 3-Month windows (Quarterly regime shifts)
    "Q1": {"name": "3-Month Banking Crisis Shift", "from": "2023.01.01", "to": "2023.03.31", "type": "quarter"},
    "Q2": {"name": "3-Month Rate Tightening Plateau", "from": "2023.04.01", "to": "2023.06.30", "type": "quarter"},
    "Q3": {"name": "3-Month US Dollar Trend Rally", "from": "2023.07.01", "to": "2023.09.30", "type": "quarter"},
    "Q4": {"name": "3-Month Year-End Dovish Pivot", "from": "2023.10.01", "to": "2023.12.31", "type": "quarter"},
    
    # 4 distinct 1-Year windows (Macro cycle robustness)
    "Y1": {"name": "1-Year Macro Cycle 2022 (Rate Shock)", "from": "2022.01.01", "to": "2022.12.31", "type": "year"},
    "Y2": {"name": "1-Year Macro Cycle 2023 (Disinflation)", "from": "2023.01.01", "to": "2023.12.31", "type": "year"},
    "Y3": {"name": "1-Year Macro Cycle 2024 (Easing Cycle)", "from": "2024.01.01", "to": "2024.12.31", "type": "year"},
    "Y4": {"name": "1-Year Macro Cycle 2025 (Macro Transition)", "from": "2025.01.01", "to": "2025.12.31", "type": "year"}
}

def compile_ea(ea_rel_path):
    """
    ea_rel_path: relative to Experts, e.g. 'Quant10\\Institutional_Liquidity_Sweep_EA.mq5'
    """
    mq5_full = os.path.join(DATA_FOLDER, "MQL5", "Experts", ea_rel_path)
    log_file = os.path.join(DATA_FOLDER, "MQL5", "Files", "compile_temp.log")
    if os.path.exists(log_file):
        try: os.remove(log_file)
        except: pass
        
    cmd = [METAEDITOR_EXE, f"/compile:{mq5_full}", f"/log:{log_file}"]
    p = subprocess.run(cmd, timeout=45)
    
    log_content = ""
    if os.path.exists(log_file):
        try:
            with open(log_file, "r", encoding="utf-16", errors="ignore") as f:
                log_content = f.read()
        except:
            with open(log_file, "r", encoding="utf-8", errors="ignore") as f:
                log_content = f.read()
        try: os.remove(log_file)
        except: pass
        
    ex5_path = os.path.join(DATA_FOLDER, "MQL5", "Experts", ea_rel_path.replace(".mq5", ".ex5"))
    success = (os.path.exists(ex5_path) and "0 errors" in log_content) or (os.path.exists(ex5_path) and p.returncode == 0)
    return success, log_content, ex5_path

def run_tester(expert_path, symbol, period, from_date, to_date, deposit=100.0, leverage="1:100", model=1, inputs=""):
    """
    expert_path: relative to Experts, e.g. 'Quant10\\Institutional_Liquidity_Sweep_EA' (without .ex5)
    """
    test_id = f"t_{int(time.time()*1000)}"
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
Login={DEFAULT_LOGIN}

[Tester]
Expert={expert_path}
Symbol={symbol}
Period={period}
Model={model}
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
        subprocess.run([TERMINAL_EXE, f"/config:{ini_path}"], timeout=120)
    except Exception as e:
        print(f"Error running tester: {e}")
        
    if not os.path.exists(rep_path):
        if os.path.exists(ini_path):
            try: os.remove(ini_path)
            except: pass
        return {
            "success": False,
            "error": "Report file not generated",
            "net_profit": 0.0,
            "profit_factor": 0.0,
            "drawdown_pct": 0.0,
            "drawdown_money": 0.0,
            "total_trades": 0,
            "margin_level": "N/A"
        }
        
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
    gross_profit = parse_float(matches.get('Gross Profit', '0'))
    gross_loss = parse_float(matches.get('Gross Loss', '0'))
    profit_factor = parse_float(matches.get('Profit Factor', '0'))
    
    dd_str = matches.get('Balance Drawdown Maximal', '')
    dd_money = parse_float(dd_str)
    dd_pct = 0.0
    if '(' in dd_str and '%' in dd_str:
        pct_part = dd_str.split('(')[1].split('%')[0]
        dd_pct = parse_float(pct_part)
        
    total_trades = parse_int(matches.get('Total Trades', '0'))
    margin_level = matches.get('Margin Level', '1000%')
    
    # Clean up files
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
        "margin_level": margin_level,
        "raw_matches": matches
    }
