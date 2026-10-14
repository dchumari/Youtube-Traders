import subprocess
import os
import re
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"

windows = {
    "RW1 (Late Jan)": ("2024.01.22", "2024.01.29"),
    "RW2 (Late Apr)": ("2024.04.22", "2024.04.29"),
    "RW3 (Late Aug)": ("2024.08.19", "2024.08.26"),
    "RW4 (Late Oct)": ("2024.10.21", "2024.10.28")
}

models = {
    "Model 0 (Trendline Trap)": 0,
    "Model 1 (Inducement OB)": 1,
    "Model 5 (Quasimodo)": 5,
    "Model 7 (Matteo Bank ORB)": 7,
    "Model 9 (Quasimodo + ORB)": 9
}

print("=== SCREENING ALL MODELS ON $100 DEPOSIT (Gold XAUUSD M15) ===", flush=True)

for m_name, m_id in models.items():
    print(f"\n--- {m_name} ---", flush=True)
    tot = 0.0
    pass_cnt = 0
    for w_name, (w_from, w_to) in windows.items():
        w_tag = w_from.replace(".", "")
        ini = f"""[Common]
Login=472929
[Tester]
Expert=SMC_Daily_Sniper_EA
Symbol=XAUUSD
Period=M15
Model=1
FromDate={w_from}
ToDate={w_to}
Deposit=100.0
Currency=USD
Leverage=400
ExecutionMode=0
Optimization=0
Report=test_m{m_id}_{w_tag}_rep
ReplaceReport=1
ShutdownTerminal=1
Visual=0
[TesterInputs]
InpCoreModel={m_id}||{m_id}||0||0||N
InpHorizonMode=0||0||0||0||N
InpMagicNumber=889205||889205||0||0||N
InpBaseLotSize=0.02||0.02||0||0||N
InpEquityStepSprint=20.0||20.0||0||0||N
InpEquityStepMonthly=35.0||35.0||0||0||N
InpMaxLotCap=0.10||0.10||0||0||N
InpBaseStopLossPoints=200||200||0||0||N
InpSpamTicketsCount=2||2||0||0||N
InpTP1Points=200||200||0||0||N
InpTP2Points=500||500||0||0||N
InpTP3Points=800||800||0||0||N
InpEnablePyramiding=0||0||0||0||N
InpEnableDumpAndFlip=0||0||0||0||N
InpEnableVolumeClimaxFade=0||0||0||0||N
InpUseSessionFilter=1||1||0||0||N
InpLondonStartHour=7||7||0||0||N
InpLondonEndHour=11||11||0||0||N
InpNYStartHour=12||12||0||0||N
InpNYEndHour=18||18||0||0||N
InpGMTOffset=3||3||0||0||N
InpMaxDailyTrades=2||2||0||0||N
InpMinTradeCooldownMin=90||90||0||0||N
InpEnableDailyDoubleLockout=1||1||0||0||N
InpDailyTargetPct=100.0||100.0||0||0||N
InpEnableWeeklyTargetLockout=0||0||0||0||N
InpWeeklyTargetPct=100.0||100.0||0||0||N
InpEnableWeeklyTrailingShield=1||1||0||0||N
InpWeeklyMaxGivebackPct=35.0||35.0||0||0||N
InpMaxHoldingBars=8||8||0||0||N
InpEnableStructuralExit=1||1||0||0||N
InpEnableVisuals=0||0||0||0||N
InpApplyDraculaTheme=0||0||0||0||N
"""
        ini_file = os.path.join(DATA_FOLDER, f"test_m{m_id}_{w_tag}.ini")
        rep_file = os.path.join(DATA_FOLDER, f"test_m{m_id}_{w_tag}_rep.htm")
        if os.path.exists(rep_file):
            try: os.remove(rep_file)
            except: pass
        with open(ini_file, "w", encoding="utf-8") as f:
            f.write(ini)
        
        p = subprocess.Popen([TESTER_EXE, f"/config:{ini_file}"])
        st = time.time()
        while time.time() - st < 25:
            if os.path.exists(rep_file) and os.path.getsize(rep_file) > 1000:
                break
            time.sleep(0.5)
        try: p.kill()
        except: pass
        
        if os.path.exists(rep_file):
            with open(rep_file, "r", encoding="utf-16", errors="ignore") as f:
                c = f.read()
            m = re.search(r"Total Net Profit</td><td[^>]*><b>(-?[\d\s\.,]+)</b>", c)
            profit = float(m.group(1).replace(" ", "").replace(",", "")) if m else 0.0
            m_tr = re.search(r"Total Trades</td><td[^>]*><b>([\d\s]+)</b>", c)
            tr = int(m_tr.group(1).replace(" ", "")) if m_tr else 0
            m_pf = re.search(r"Profit Factor</td><td[^>]*><b>([\d\s\.,]+)</b>", c)
            pf = float(m_pf.group(1).replace(" ", "").replace(",", "")) if m_pf else 0.0
            m_wr = re.search(r"Profit Trades.*?<b>[\d\s]+\s*\(([\d\.]+)%\)</b>", c)
            wr = float(m_wr.group(1)) if m_wr else 0.0
            tot += profit
            if profit > 0: pass_cnt += 1
            print(f"  {w_name}: Net=${profit:+.2f} ({tr} trades, WR={wr:.1f}%, PF={pf:.2f})", flush=True)
        else:
            print(f"  {w_name}: Failed to generate report", flush=True)
    print(f"  >> TOTAL: Net=${tot:+.2f} | PASS RATE: {pass_cnt}/4", flush=True)
