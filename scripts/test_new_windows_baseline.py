import subprocess
import os
import re
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
REPORT_DIR = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672"

NEW_UNIQUE_WINDOWS = {
    "NW1 (Early Feb - W6)": ("2024.02.05", "2024.02.12"),
    "NW2 (Mid May - W20)": ("2024.05.13", "2024.05.20"),
    "NW3 (Early July - W28)": ("2024.07.08", "2024.07.15"),
    "NW4 (Mid Sept - W38)": ("2024.09.16", "2024.09.23")
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

def run_test(test_id, symbol, ea_name, w_from, w_to, deposit, inputs_dict):
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
    print("=== TESTING NORMAL STRATEGY ON 4 NEW UNIQUE 2024 WINDOWS ($100 DEPOSIT) ===", flush=True)

    normal_inputs = {
        "InpCoreModel": 5,
        "InpHorizonMode": 0,
        "InpMagicNumber": 889205,
        "InpBaseLotSize": 0.02,
        "InpEquityStepSprint": 50.0,
        "InpEquityStepMonthly": 50.0,
        "InpMaxLotCap": 0.20,
        "InpBaseStopLossPoints": 200,
        "InpSpamTicketsCount": 2,
        "InpTP1Points": 200,
        "InpTP2Points": 500,
        "InpTP3Points": 800,
        "InpTP4Points": 1200,
        "InpTP5Points": 1600,
        "InpEnablePyramiding": 0,
        "InpEnableDumpAndFlip": 0,
        "InpEnableVolumeClimaxFade": 0,
        "InpUseSessionFilter": 1,
        "InpLondonStartHour": 7,
        "InpLondonEndHour": 11,
        "InpNYStartHour": 12,
        "InpNYEndHour": 18,
        "InpGMTOffset": 3,
        "InpMaxDailyTrades": 2,
        "InpMinTradeCooldownMin": 90,
        "InpEnableDailyDoubleLockout": 1,
        "InpDailyTargetPct": 100.0,
        "InpEnableWeeklyTargetLockout": 0,
        "InpWeeklyTargetPct": 100.0,
        "InpEnableWeeklyTrailingShield": 1,
        "InpWeeklyMaxGivebackPct": 35.0,
        "InpMaxHoldingBars": 8,
        "InpEnableStructuralExit": 1,
        "InpEnableVisuals": 0,
        "InpApplyDraculaTheme": 0
    }

    tot = 0.0
    p_cnt = 0
    for w_name, (w_from, w_to) in NEW_UNIQUE_WINDOWS.items():
        clean_d = w_from.replace('.', '')
        t_id = f"norm_new_{clean_d}"
        res = run_test(t_id, "XAUUSD", "SMC_Daily_Sniper_EA", w_from, w_to, 100.0, normal_inputs)
        if res:
            p = res["profit"]
            tot += p
            if p > 0: p_cnt += 1
            status = "WIN" if p > 0 else "LOSS"
            print(f"  {w_name}: Net=${p:+.2f} | Trades={res['trades']} | WR={res['win_pct']:.1f}% | PF={res['pf']:.2f} | DD=${res['dd']:.2f} | {status}", flush=True)
        else:
            print(f"  {w_name}: No rep", flush=True)
    print(f"  >> NORMAL EA CUMULATIVE: Net=${tot:+.2f} | PASS RATE: {p_cnt}/4\n", flush=True)
