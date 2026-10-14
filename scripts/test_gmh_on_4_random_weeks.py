import subprocess
import os
import re
import json
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"

# Test Grand Master Hybrid EA and Chart Fanatics Master Suite on the 4 Random 2024 non-NFP/CPI weeks
RANDOM_4_WINDOWS = {
    "RW1 (Late Jan - W4)": {"from": "2024.01.22", "to": "2024.01.29"},
    "RW2 (Late Apr - W17)": {"from": "2024.04.22", "to": "2024.04.29"},
    "RW3 (Late Aug - W34)": {"from": "2024.08.19", "to": "2024.08.26"},
    "RW4 (Late Oct - W43)": {"from": "2024.10.21", "to": "2024.10.28"}
}

def clean_liveupdate():
    for d in [r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate",
              r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\liveupdate",
              os.path.join(DATA_FOLDER, "liveupdate")]:
        if os.path.exists(d):
            for f in os.listdir(d):
                try: os.remove(os.path.join(d, f))
                except: pass

def safe_kill_tester():
    try:
        cmd = 'Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Where-Object { $_.Path -notlike "*Program Files*" } | Stop-Process -Force'
        subprocess.run(["powershell", "-Command", cmd], capture_output=True)
    except:
        pass

def parse_preset(preset_path):
    inputs = {}
    if os.path.exists(preset_path):
        with open(preset_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("//") and not line.startswith(";"):
                    parts = line.split("=", 1)
                    if len(parts) == 2:
                        inputs[parts[0].strip()] = parts[1].strip()
    return inputs

def parse_htm_report(htm_file, initial_deposit):
    try:
        content = ""
        try:
            with open(htm_file, "r", encoding="utf-16", errors="ignore") as f:
                content = f.read()
        except:
            with open(htm_file, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()

        matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', content))

        def parse_float(val_str, default=0.0):
            if not val_str: return default
            cleaned = val_str.replace(" ", "").replace("&nbsp;", "").replace(",", "").strip()
            m = re.search(r"(-?[\d\.]+)", cleaned)
            return float(m.group(1)) if m else default

        net_profit = parse_float(matches.get("Total Net Profit", "0"))
        trades = int(parse_float(matches.get("Total Trades", "0")))
        pf = parse_float(matches.get("Profit Factor", "0"))

        win_str = matches.get("Profit Trades (% of total)", "")
        m_win = re.search(r"\(([\d\.]+)%\)", win_str)
        win_pct = float(m_win.group(1)) if m_win else 0.0

        dd_str = matches.get("Balance Drawdown Maximal", matches.get("Maximal Drawdown", matches.get("Drawdown Maximal", "")))
        m_dd = re.search(r"\(([\d\.]+)%\)", dd_str)
        dd_pct = float(m_dd.group(1)) if m_dd else parse_float(dd_str)

        roi_pct = (net_profit / initial_deposit) * 100.0 if initial_deposit > 0 else 0.0

        return {
            "net_profit": round(net_profit, 2),
            "roi_pct": round(roi_pct, 1),
            "trades": trades,
            "win_rate": round(win_pct, 1),
            "profit_factor": round(pf, 2),
            "max_dd_pct": round(dd_pct, 1),
            "status": "PASS" if net_profit > 0 else "FAIL"
        }
    except Exception as e:
        return {"net_profit": 0.0, "roi_pct": 0.0, "trades": 0, "win_rate": 0.0, "profit_factor": 0.0, "max_dd_pct": 0.0, "status": f"ERROR: {str(e)}"}

def run_single_test(ea_name, test_id, win_from, win_to, deposit, leverage, inputs, timeout_sec=70):
    clean_liveupdate()
    inputs_block = ""
    for k, v in inputs.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

    if os.path.exists(rep_path):
        try: os.remove(rep_path)
        except: pass

    ini_text = f"""[Common]
Login=472929

[Tester]
Expert={ea_name}
Symbol=XAUUSD
Period=M15
Model=1
FromDate={win_from}
ToDate={win_to}
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

    cmd = [TESTER_EXE, "/portable", f"/config:{ini_path}"]
    safe_kill_tester()
    time.sleep(1)

    proc = subprocess.Popen(cmd)
    start_t = time.time()
    done = False

    while time.time() - start_t < timeout_sec:
        if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
            time.sleep(1.5)
            try: proc.kill()
            except: pass
            safe_kill_tester()
            done = True
            break
        if proc.poll() is not None:
            time.sleep(2)
            if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
                done = True
            break
        time.sleep(1.5)

    if not done:
        try: proc.kill()
        except: pass
        safe_kill_tester()

    if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
        return parse_htm_report(rep_path, deposit)
    else:
        return {"net_profit": 0.0, "roi_pct": 0.0, "trades": 0, "win_rate": 0.0, "profit_factor": 0.0, "max_dd_pct": 0.0, "status": "FAIL_OR_NO_TRADES"}

def main():
    print("Testing Grand Master Hybrid EA on $20 across 4 Random 2024 Weeks...")
    gmh_preset = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Grand_Master_Hybrid\presets\GMH_Weekly_Sprint_Doubler_20USD.set"
    inputs = parse_preset(gmh_preset)
    for w_key, w_info in RANDOM_4_WINDOWS.items():
        t_id = f"test_gmh_20_{w_key[:3]}"
        res = run_single_test("Grand_Master_Hybrid_EA", t_id, w_info["from"], w_info["to"], 20.0, 400, inputs)
        print(f"GMH $20 {w_key}: Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | WR: {res['win_rate']}% | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% [{res['status']}]")

if __name__ == "__main__":
    main()
