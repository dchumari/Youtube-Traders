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

def run_single_test(test_id, win_from, win_to, deposit, leverage, inputs, timeout_sec=90):
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

    safe_kill_tester()
    time.sleep(1)

    cmd = [TESTER_EXE, "/portable", f"/config:{ini_path}"]
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
        time.sleep(1)

    if not done:
        try: proc.kill()
        except: pass
        safe_kill_tester()

    if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
        content = ""
        try:
            with open(rep_path, "r", encoding="utf-16", errors="ignore") as f: content = f.read()
        except:
            with open(rep_path, "r", encoding="utf-8", errors="ignore") as f: content = f.read()

        matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', content))
        def parse_float(s, d=0.0):
            if not s: return d
            cleaned = s.replace(" ", "").replace("&nbsp;", "").replace(",", "").strip()
            m = re.search(r"(-?[\d\.]+)", cleaned)
            return float(m.group(1)) if m else d

        net_profit = parse_float(matches.get("Total Net Profit", "0"))
        trades = int(parse_float(matches.get("Total Trades", "0")))
        pf = parse_float(matches.get("Profit Factor", "0"))
        dd_str = matches.get("Balance Drawdown Maximal", matches.get("Maximal Drawdown", ""))
        m_dd = re.search(r"\(([\d\.]+)%\)", dd_str)
        dd_pct = float(m_dd.group(1)) if m_dd else parse_float(dd_str)
        roi = (net_profit / deposit) * 100.0

        return {
            "net_profit": net_profit,
            "trades": trades,
            "profit_factor": pf,
            "max_dd_pct": dd_pct,
            "roi_pct": roi,
            "success": True
        }
    return {"net_profit": 0, "trades": 0, "profit_factor": 0, "max_dd_pct": 0, "roi_pct": 0, "success": False}

if __name__ == "__main__":
    # Test 3-Ticket Setup with Invalidation & Compounding on $20
    inputs_20 = {
        "InpCoreModel": "5",
        "InpHorizonMode": "0",
        "InpMagicNumber": "889205",
        "InpBaseLotSize": "0.01",
        "InpEquityStepSprint": "15.0",
        "InpEquityStepMonthly": "30.0",
        "InpMaxLotCap": "0.15",
        "InpBaseStopLossPoints": "200",
        "InpSpamTicketsCount": "3",
        "InpTP1Points": "200",
        "InpTP2Points": "450",
        "InpTP3Points": "800",
        "InpTP4Points": "1200",
        "InpTP5Points": "1800",
        "InpEnablePyramiding": "0",
        "InpMaxPyramidLayers": "1",
        "InpReloadStepPoints": "300",
        "InpEnableDumpAndFlip": "0",
        "InpDumpWickRatio": "0.45",
        "InpSwingLookback": "24",
        "InpTrendlinePoints": "3",
        "InpMinSweepPoints": "100",
        "InpMinWickRejection": "0.35",
        "InpEMATrendPeriod": "50",
        "InpVolumeSurgeMult": "1.5",
        "InpUseSessionFilter": "1",
        "InpLondonStartHour": "7",
        "InpLondonEndHour": "11",
        "InpNYStartHour": "12",
        "InpNYEndHour": "18",
        "InpGMTOffset": "3",
        "InpMaxDailyTrades": "3",
        "InpMinTradeCooldownMin": "60",
        "InpEnableDailyDoubleLockout": "1",
        "InpDailyTargetPct": "100.0",
        "InpMinATRPoints": "100.0",
        "InpEnableWeeklyTargetLockout": "0",
        "InpWeeklyTargetPct": "100.0",
        "InpEnableWeeklyTrailingShield": "1",
        "InpWeeklyMaxGivebackPct": "35.0",
        "InpMaxHoldingBars": "8",
        "InpEnableStructuralExit": "1",
        "InpEnableVisuals": "0",
        "InpApplyDraculaTheme": "0"
    }

    print("=== Testing 3-Ticket Compounding Account Doubler on $20 ===", flush=True)
    tot_20 = 0.0
    for w_name, w_info in RANDOM_4_WINDOWS.items():
        test_id = f"smcd_comp_20_{w_name[:3]}"
        res = run_single_test(test_id, w_info["from"], w_info["to"], 20.0, 400, inputs_20)
        print(f"[$20 | {w_name}] Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | Trades: {res['trades']} | PF: {res['profit_factor']:.2f} | DD: {res['max_dd_pct']:.1f}%", flush=True)
        tot_20 += res['net_profit']
    print(f"Total Cumulative Profit on $20: ${tot_20:+.2f} ({(tot_20/20.0)*100.0:+.1f}%)\n", flush=True)
