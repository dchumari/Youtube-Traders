import subprocess
import os
import re
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
REPORT_DIR = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672"

windows = {
    "RW1 (Late Jan)": ("2024.01.22", "2024.01.29"),
    "RW2 (Late Apr)": ("2024.04.22", "2024.04.29"),
    "RW3 (Late Aug)": ("2024.08.19", "2024.08.26"),
    "RW4 (Late Oct)": ("2024.10.21", "2024.10.28")
}

def clean_liveupdate():
    for d in [r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate",
              r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\liveupdate",
              r"d:\MT5_Tester\liveupdate"]:
        if os.path.exists(d):
            for f in os.listdir(d):
                p = os.path.join(d, f)
                try:
                    if os.path.isdir(p):
                        import shutil
                        shutil.rmtree(p)
                    else: os.remove(p)
                except: pass

def safe_kill():
    try:
        cmd = 'Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Where-Object { $_.Path -notlike "*Program Files*" } | Stop-Process -Force'
        subprocess.run(["powershell", "-Command", cmd], capture_output=True)
    except: pass

def parse_report(rep_path):
    if not os.path.exists(rep_path):
        return None
    try:
        with open(rep_path, "r", encoding="utf-16", errors="ignore") as f: c = f.read()
    except:
        with open(rep_path, "r", encoding="utf-8", errors="ignore") as f: c = f.read()

    def get_num(pattern, default=0.0):
        m = re.search(pattern, c, re.IGNORECASE | re.DOTALL)
        if m:
            clean = m.group(1).replace(" ", "").replace(",", "").replace("&nbsp;", "").strip()
            try: return float(clean)
            except: return default
        return default

    profit = get_num(r"Total Net Profit:?\s*</td>\s*<td[^>]*><b>(-?[\d\s\.,]+)</b>")
    trades = int(get_num(r"Total Trades:?\s*</td>\s*<td[^>]*><b>([\d\s]+)</b>", 0))
    pf = get_num(r"Profit Factor:?\s*</td>\s*<td[^>]*><b>([\d\s\.,]+)</b>")
    win_pct = get_num(r"Profit Trades.*?<b>[\d\s]+\s*\(([\d\.]+)%\)</b>")
    dd = get_num(r"Equity Drawdown Absolute:?\s*</td>\s*<td[^>]*>(?:colspan=\"\d+\">)?<b>(-?[\d\s\.,]+)</b>")
    return {"profit": profit, "trades": trades, "pf": pf, "win_pct": win_pct, "dd": dd}

def run_test(test_id, symbol, w_from, w_to, deposit, ea_name, inputs_dict):
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(REPORT_DIR, f"{rep_name}.htm")
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    
    if os.path.exists(rep_path):
        try: os.remove(rep_path)
        except: pass

    inputs_block = "\n".join([f"{k}={v}||{v}||0||0||N" for k, v in inputs_dict.items()])

    ini = f"""[Common]
Login=472929
[Tester]
Expert={ea_name}
Symbol={symbol}
Period=M15
Model=1
FromDate={w_from}
ToDate={w_to}
Deposit={deposit}
Currency=USD
Leverage=400
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
        f.write(ini)

    clean_liveupdate()
    safe_kill()
    time.sleep(0.3)

    p = subprocess.Popen([TESTER_EXE, f"/config:{ini_path}"])
    st = time.time()
    while time.time() - st < 25:
        if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
            break
        time.sleep(0.4)
    try: p.kill()
    except: pass
    safe_kill()
    time.sleep(0.2)
    
    return parse_report(rep_path)

if __name__ == "__main__":
    print("Optimization test harness ready.", flush=True)
