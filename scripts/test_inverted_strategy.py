import subprocess
import os
import re
import time
import sys
import json
import shutil

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
                    if os.path.isdir(p): shutil.rmtree(p)
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

def run_test(test_id, symbol, w_from, w_to, deposit, invert, model_id, tickets, sl, tp1, tp2, tp3):
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(REPORT_DIR, f"{rep_name}.htm")
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    
    if os.path.exists(rep_path):
        try: os.remove(rep_path)
        except: pass

    inputs_dict = {
        "InpCoreModel": model_id,
        "InpHorizonMode": 0,
        "InpInvertExecution": 1 if invert else 0,
        "InpMagicNumber": 889299 if invert else 889205,
        "InpBaseLotSize": 0.01,
        "InpEquityStepSprint": 20.0,
        "InpEquityStepMonthly": 35.0,
        "InpMaxLotCap": 0.10,
        "InpBaseStopLossPoints": sl,
        "InpSpamTicketsCount": tickets,
        "InpTP1Points": tp1,
        "InpTP2Points": tp2,
        "InpTP3Points": tp3,
        "InpTP4Points": 1000,
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

    inputs_block = "\n".join([f"{k}={v}||{v}||0||0||N" for k, v in inputs_dict.items()])

    ini = f"""[Common]
Login=472929
[Tester]
Expert=SMC_Daily_Sniper_EA
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
    print("=== TESTING EXPERIMENTAL INVERTED STRATEGY (SL->TP1, TP->SL, +TP2 & TP3) ===", flush=True)

    # Test on Model 5 (Quasimodo) and Model 9 (Hybrid)
    test_models = {
        "Model 5 (Quasimodo)": 5,
        "Model 9 (Quasimodo + ORB)": 9
    }

    for m_label, m_id in test_models.items():
        print(f"\n=================== {m_label} ===================", flush=True)
        for mode_name, is_invert in [("NORMAL STRATEGY", False), ("INVERTED FADE STRATEGY", True)]:
            print(f"\n--- Running: {mode_name} ($100 Deposit, 3 Tickets: TP1=20p, TP2=40p, TP3=60p) ---", flush=True)
            tot = 0.0
            p_cnt = 0
            for w_name, (w_from, w_to) in windows.items():
                t_id = f"test_{'inv' if is_invert else 'norm'}_m{m_id}_{w_from.replace('.','')}"
                res = run_test(t_id, "XAUUSD", w_from, w_to, 100.0, is_invert, m_id, 3, 200, 200, 400, 600)
                if res:
                    profit = res["profit"]
                    trades = res["trades"]
                    pf = res["pf"]
                    wr = res["win_pct"]
                    dd = res["dd"]
                    tot += profit
                    if profit > 0: p_cnt += 1
                    status = "WIN" if profit > 0 else "LOSS"
                    print(f"  {w_name}: Net=${profit:+.2f} | Trades={trades} | WR={wr:.1f}% | PF={pf:.2f} | DD=${dd:.2f} | {status}", flush=True)
                else:
                    print(f"  {w_name}: No report generated", flush=True)
            print(f"  >> {mode_name} CUMULATIVE: Net=${tot:+.2f} | PASS RATE: {p_cnt}/4", flush=True)
