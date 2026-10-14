import subprocess
import os
import re
import json
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_NAME = "SMC_Daily_Sniper_EA"

RANDOM_4_WINDOWS = {
    "RW1 (Jan 22-29)": {"from": "2024.01.22", "to": "2024.01.29"},
    "RW2 (Apr 22-29)": {"from": "2024.04.22", "to": "2024.04.29"},
    "RW3 (Aug 19-26)": {"from": "2024.08.19", "to": "2024.08.26"},
    "RW4 (Oct 21-28)": {"from": "2024.10.21", "to": "2024.10.28"}
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

def parse_htm_report(rep_path):
    if not os.path.exists(rep_path):
        return None
    try:
        with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
            content = f.read()
    except:
        with open(rep_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

    def get_val(pattern, default=0.0):
        m = re.search(pattern, content, re.IGNORECASE)
        if m:
            clean = m.group(1).replace(" ", "").replace(",", "")
            try: return float(clean)
            except: return default
        return default

    profit = get_val(r"Total Net Profit</td><td[^>]*><b>(-?[\d\s\.,]+)</b>")
    trades = int(get_val(r"Total Trades</td><td[^>]*><b>([\d\s]+)</b>", 0))
    pf = get_val(r"Profit Factor</td><td[^>]*><b>([\d\s\.,]+)</b>")
    win_pct = get_val(r"Profit Trades.*?<b>[\d\s]+\s*\(([\d\.]+)%\)</b>")
    dd_pct = get_val(r"Maximal Drawdown</td><td[^>]*>[\d\s\.,]+\s*\(<b>([\d\.]+)%</b>\)")
    return {"profit": profit, "trades": trades, "pf": pf, "win_pct": win_pct, "dd_pct": dd_pct}

def run_test(test_id, symbol, win_from, win_to, deposit, inputs, timeout_sec=60):
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
Expert={EXPERT_NAME}
Symbol={symbol}
Period=M15
Model=1
FromDate={win_from}
ToDate={win_to}
Deposit={deposit}
Currency=USD
Leverage=400
ExecutionMode=0
Optimization=0
Report={rep_name}
ReplaceReport=1
ShutdownTerminal=1

[TesterInputs]
{inputs_block}
"""
    with open(ini_path, "w", encoding="utf-8") as f:
        f.write(ini_text)

    safe_kill_tester()
    time.sleep(0.3)
    p = subprocess.Popen([TESTER_EXE, f"/config:{ini_path}"])
    start = time.time()
    while time.time() - start < timeout_sec:
        if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
            break
        if p.poll() is not None:
            break
        time.sleep(0.5)

    try: p.kill()
    except: pass
    safe_kill_tester()
    time.sleep(0.3)
    return parse_htm_report(rep_path)

if __name__ == "__main__":
    pairs = ["XAUUSD", "EURUSD", "GBPUSD"]
    models = {
        "Model 0 (Trendline Trap)": 0,
        "Model 1 (Inducement OB)": 1,
        "Model 5 (Quasimodo)": 5,
        "Model 7 (Matteo Bank ORB)": 7,
        "Model 9 (Quasimodo + ORB)": 9
    }
    
    base_inputs = {
        "InpHorizonMode": 0,
        "InpMagicNumber": 889205,
        "InpBaseLotSize": 0.01,
        "InpSpamTicketsCount": 2,
        "InpBaseStopLossPoints": 200,
        "InpTP1Points": 200,
        "InpTP2Points": 500,
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
        "InpEnableWeeklyTrailingShield": 1,
        "InpWeeklyMaxGivebackPct": 35.0,
        "InpMaxHoldingBars": 8,
        "InpEnableStructuralExit": 1,
        "InpEnableVisuals": 0,
        "InpApplyDraculaTheme": 0
    }

    print("=== SCREENING PAIRS ON 4 RANDOM WEEKS ($20 DEPOSIT) ===")
    results = {}
    for pair in pairs:
        print(f"\n--- TESTING PAIR: {pair} ---")
        results[pair] = {}
        for m_name, m_id in models.items():
            inputs = dict(base_inputs)
            inputs["InpCoreModel"] = m_id
            m_res = {}
            tot_p = 0.0
            weeks_won = 0
            for w_name, w_dates in RANDOM_4_WINDOWS.items():
                res = run_test(f"test_{pair}_m{m_id}_{w_name[:3]}", pair, w_dates["from"], w_dates["to"], 20.0, inputs)
                p = res["profit"] if res else 0.0
                trades = res["trades"] if res else 0
                pf = res["pf"] if res else 0.0
                wr = res["win_pct"] if res else 0.0
                dd = res["dd_pct"] if res else 0.0
                tot_p += p
                if p > 0: weeks_won += 1
                m_res[w_name] = {"p": p, "trades": trades, "pf": pf, "wr": wr, "dd": dd}
                print(f"  [{pair}] {m_name} | {w_name}: Net=${p:+.2f} ({trades} trades, PF={pf:.2f}, WR={wr:.1f}%, DD={dd:.1f}%)")
            m_res["total"] = tot_p
            m_res["pass_count"] = f"{weeks_won}/4"
            print(f"  >> [{pair}] {m_name} TOTAL: ${tot_p:+.2f} | PASS: {weeks_won}/4")
            results[pair][m_name] = m_res

    with open("strategies/SMC_Daily_Sniper/backtest_results/pairs_comparison_results.json", "w") as f:
        json.dump(results, f, indent=2)
    print("\nSaved pairs comparison to strategies/SMC_Daily_Sniper/backtest_results/pairs_comparison_results.json")
