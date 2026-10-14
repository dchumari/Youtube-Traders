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
        with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
            c = f.read()
    except:
        with open(rep_path, "r", encoding="utf-8", errors="ignore") as f:
            c = f.read()

    def get_num(pattern, default=0.0):
        m = re.search(pattern, c, re.IGNORECASE | re.DOTALL)
        if m:
            clean = m.group(1).replace(" ", "").replace(",", "").replace("&nbsp;", "").strip()
            try: return float(clean)
            except: return default
        return default

    profit = get_num(r"Total Net Profit:?\s*</td>\s*<td[^>]*>(-?[\d\s\.,]+)</td>")
    trades = int(get_num(r"Total Trades:?\s*</td>\s*<td[^>]*>([\d\s]+)</td>", 0))
    pf = get_num(r"Profit Factor:?\s*</td>\s*<td[^>]*>([\d\s\.,]+)</td>")
    win_pct = get_num(r"Profit Trades.*?<b>[\d\s]+\s*\(([\d\.]+)%\)</b>")
    dd_pct = get_num(r"Equity Drawdown Absolute:?\s*</td>\s*<td[^>]*>(-?[\d\s\.,]+)</td>")
    return {"profit": profit, "trades": trades, "pf": pf, "win_pct": win_pct, "dd": dd_pct}

def run_test(test_id, symbol, w_from, w_to, deposit, model_id, lot_size, tickets, sl_pts, tp1_pts, tp2_pts, extra_inputs=None):
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(REPORT_DIR, f"{rep_name}.htm")
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    
    if os.path.exists(rep_path):
        try: os.remove(rep_path)
        except: pass

    inputs_dict = {
        "InpCoreModel": model_id,
        "InpHorizonMode": 0,
        "InpMagicNumber": 889205,
        "InpBaseLotSize": lot_size,
        "InpEquityStepSprint": 20.0,
        "InpEquityStepMonthly": 35.0,
        "InpMaxLotCap": 0.10,
        "InpBaseStopLossPoints": sl_pts,
        "InpSpamTicketsCount": tickets,
        "InpTP1Points": tp1_pts,
        "InpTP2Points": tp2_pts,
        "InpTP3Points": 800,
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
    if extra_inputs:
        inputs_dict.update(extra_inputs)

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
    print("=== STARTING PAIRS COMPARISON & HYBRID SCREENING ===", flush=True)

    # 1. Compare Pairs: XAUUSD vs EURUSD vs GBPUSD on $100
    print("\n--- 1. COMPARING PAIRS ON $100 (Quasimodo Model 5) ---", flush=True)
    pair_results = {}
    for sym in ["XAUUSD", "EURUSD", "GBPUSD"]:
        tot = 0.0
        p_count = 0
        p_res = {}
        for w_name, (w_from, w_to) in windows.items():
            sl = 200 if sym == "XAUUSD" else 150
            tp1 = 200 if sym == "XAUUSD" else 150
            tp2 = 500 if sym == "XAUUSD" else 350
            res = run_test(f"pair_{sym}_{w_from.replace('.','')}", sym, w_from, w_to, 100.0, 5, 0.02, 2, sl, tp1, tp2)
            profit = res["profit"] if res else 0.0
            trades = res["trades"] if res else 0
            pf = res["pf"] if res else 0.0
            tot += profit
            if profit > 0: p_count += 1
            p_res[w_name] = {"profit": profit, "trades": trades, "pf": pf}
            print(f"  [{sym}] {w_name}: Net=${profit:+.2f} ({trades} trades, PF={pf:.2f})", flush=True)
        print(f"  >> [{sym}] TOTAL: Net=${tot:+.2f} | PASS RATE: {p_count}/4\n", flush=True)
        pair_results[sym] = {"total": tot, "pass_rate": f"{p_count}/4", "weeks": p_res}

    # 2. Test Model 9 (Hybrid Quasimodo + Bank ORB) on $100 and $20
    print("\n--- 2. TESTING MODEL 9 (HYBRID QUASIMODO + BANK ORB) ON XAUUSD ---", flush=True)
    for dep, lot, t_cnt, lbl in [(100.0, 0.02, 2, "$100 Tier (0.04 Lot)"), (20.0, 0.01, 1, "$20 Tier (0.01 Lot)")]:
        print(f"\nEvaluating Model 9 on {lbl}...", flush=True)
        tot = 0.0
        p_cnt = 0
        for w_name, (w_from, w_to) in windows.items():
            res = run_test(f"m9_{lbl[:3]}_{w_from.replace('.','')}", "XAUUSD", w_from, w_to, dep, 9, lot, t_cnt, 200, 200, 500)
            profit = res["profit"] if res else 0.0
            trades = res["trades"] if res else 0
            pf = res["pf"] if res else 0.0
            roi = (profit / dep) * 100.0
            tot += profit
            if profit > 0: p_cnt += 1
            print(f"  {w_name}: Net=${profit:+.2f} ({roi:+.1f}%) | {trades} trades | PF={pf:.2f}", flush=True)
        print(f"  >> TOTAL {lbl}: Net=${tot:+.2f} ({(tot/dep)*100.0:+.1f}%) | PASS: {p_cnt}/4", flush=True)

    with open("strategies/SMC_Daily_Sniper/backtest_results/pairs_and_hybrid_benchmark.json", "w") as f:
        json.dump(pair_results, f, indent=2)
    print("\nSaved benchmark results to strategies/SMC_Daily_Sniper/backtest_results/pairs_and_hybrid_benchmark.json")
