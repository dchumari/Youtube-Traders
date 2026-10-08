import subprocess
import os
import time
import re

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite"

ini_path = os.path.join(DATA_FOLDER, "test_mrpfx_viz.ini")
rep_name = "test_mrpfx_viz_rep"
rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

if os.path.exists(rep_path):
    try: os.remove(rep_path)
    except: pass

# Killzone Momentum Calibrated Preset (Candidate 4)
ini_text = f"""[Common]
Login=472929

[Tester]
Expert={EXPERT_REL}
Symbol=XAUUSD
Period=M15
Model=1
FromDate=2024.03.04
ToDate=2024.03.11
Deposit=20
Currency=USD
Leverage=1:500
ExecutionMode=0
Optimization=0
Report={rep_name}
ReplaceReport=1
ShutdownTerminal=1
Visual=0

[TesterInputs]
InpStrategy=3||3||0||0||N
InpMagicNumber=888004||888004||0||0||N
InpRiskPercent=0.0||0.0||0||0||N
InpFixedLot=0.01||0.01||0||0||N
InpRewardRiskRatio=2.0||2.0||0||0||N
InpFastEMAPeriod=20||20||0||0||N
InpSlowEMAPeriod=50||50||0||0||N
InpATRPeriod=14||14||0||0||N
InpUseSessionFilter=true||true||0||0||N
InpSessionStartH1=7||7||0||0||N
InpSessionEndH1=11||11||0||0||N
InpSessionStartH2=13||13||0||0||N
InpSessionEndH2=17||17||0||0||N
InpUseBreakeven=true||true||0||0||N
InpBETriggerR=1.0||1.0||0||0||N
InpBELockPoints=10||10||0||0||N
InpShowTradeBoxes=true||true||0||0||N
InpShowEntryArrows=true||true||0||0||N
InpShowBadges=true||true||0||0||N
InpShowConnLines=true||true||0||0||N
"""

with open(ini_path, "w", encoding="utf-8") as f:
    f.write(ini_text)

print("Running MrPFx Master Suite W1 with TradingView visualizer...")
t0 = time.time()
p = subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=90)
elapsed = time.time() - t0
print(f"Completed in {elapsed:.2f}s, exit code: {p.returncode}")

if os.path.exists(rep_path):
    with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
        html = f.read()
    
    profit_match = re.search(r"Total Net Profit</td>\s*<td[^>]*><b>([^<]+)</b>", html, re.I)
    trades_match = re.search(r"Total Trades</td>\s*<td[^>]*><b>([^<]+)</b>", html, re.I)
    pf_match = re.search(r"Profit Factor</td>\s*<td[^>]*><b>([^<]+)</b>", html, re.I)
    
    np_val = profit_match.group(1) if profit_match else "N/A"
    tr_val = trades_match.group(1) if trades_match else "N/A"
    pf_val = pf_match.group(1) if pf_match else "N/A"
    
    print(f"SUCCESS! Net Profit: ${np_val}, Trades: {tr_val}, Profit Factor: {pf_val}")
else:
    print("Report file not generated. Check tester logs.")
