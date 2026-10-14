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

def run_test(test_id, symbol, w_from, w_to, deposit, model_id, tickets=3, base_lot=0.02, tier_step=50.0, sl=200, tp1=200, tp2=400, tp3=700, displacement=True):
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(REPORT_DIR, f"{rep_name}.htm")
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    
    if os.path.exists(rep_path):
        try: os.remove(rep_path)
        except: pass

    inputs_dict = {
        "InpCoreModel": model_id,
        "InpHorizonMode": 0,
        "InpMagicNumber": 889300 + model_id,
        "InpEnableDynamicTiering": 1,
        "InpBaseLotSize": base_lot,
        "InpEquityTierStep": tier_step,
        "InpMaxLotCap": 0.20,
        "InpBaseStopLossPoints": sl,
        "InpSpamTicketsCount": tickets,
        "InpTP1Points": tp1,
        "InpTP2Points": tp2,
        "InpTP3Points": tp3,
        "InpTP4Points": 1200,
        "InpTP5Points": 1800,
        "InpEnablePyramiding": 0,
        "InpEnableDumpAndFlip": 0,
        "InpRequireDisplacement": 1 if displacement else 0,
        "InpMinDisplacementPct": 0.40,
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
Expert=SMC_Inverted_Momentum_EA
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
    print("=== SCREENING ALL MODELS OF SMC_INVERTED_MOMENTUM_EA ACROSS 4 RANDOM WEEKS ($100 DEPOSIT) ===", flush=True)

    models_to_test = {
        "Model 0 (Trendline Trap Fade)": 0,
        "Model 1 (Inducement / OB Violation)": 1,
        "Model 5 (Quasimodo Invalidation Squeeze)": 5,
        "Model 7 (Matteo Bank ORB)": 7,
        "Model 8 (Master Trap Confluence)": 8,
        "Model 9 (Hybrid QM + Bank ORB)": 9
    }

    results_table = {}

    for m_label, m_id in models_to_test.items():
        print(f"\n=================== {m_label} ===================", flush=True)
        tot = 0.0
        p_cnt = 0
        w_res = {}
        for w_name, (w_from, w_to) in windows.items():
            t_id = f"inv_m{m_id}_{w_from.replace('.','')}"
            res = run_test(t_id, "XAUUSD", w_from, w_to, 100.0, m_id, tickets=3, base_lot=0.02, tier_step=50.0, sl=200, tp1=200, tp2=400, tp3=700)
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
                w_res[w_name] = res
            else:
                print(f"  {w_name}: No report generated", flush=True)
                w_res[w_name] = None
        print(f"  >> {m_label} CUMULATIVE: Net=${tot:+.2f} | PASS RATE: {p_cnt}/4", flush=True)
        results_table[m_label] = {"total_profit": tot, "pass_count": p_cnt, "windows": w_res}

    print("\n\n=================== SCREENING SUMMARY MATRIX ===================", flush=True)
    for m_label, data in results_table.items():
        print(f"{m_label:45} | Net Profit: ${data['total_profit']:+7.2f} | Passed: {data['pass_count']}/4", flush=True)
