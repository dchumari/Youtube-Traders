import subprocess
import os
import re
import json

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Mr_P_Fx\MrPFx_Master_Suite"

ini_path = os.path.join(DATA_FOLDER, "ytd_run.ini")
rep_name = "ytd_run_rep"
rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

# Calibrated Killzone Momentum
ini_text = f"""[Common]
Login=472929

[Tester]
Expert={EXPERT_REL}
Symbol=XAUUSD
Period=M15
Model=1
UseDate=1
FromDate=2024.01.01
ToDate=2024.10.08
Deposit=100
Currency=USD
Leverage=1:400
ExecutionMode=0
Optimization=0
Report={rep_name}
ReplaceReport=1
ShutdownTerminal=1
Visual=0

[TesterInputs]
InpStrategy=0||0||0||0||N
InpMagicNumber=888001||888001||0||0||N
InpRiskPercent=0.0||0.0||0||0||N
InpFixedLot=0.01||0.01||0||0||N
InpRewardRiskRatio=2.5||2.5||0||0||N
InpMaxSpreadPoints=50||50||0||0||N
InpSweepLookback=20||20||0||0||N
InpMinSweepPoints=30||30||0||0||N
InpMinWickRatio=0.45||0.45||0||0||N
InpUseTrendFilter=true||true||0||0||N
InpTrendEMAPeriod=50||50||0||0||N
InpUseSessionFilter=true||true||0||0||N
InpSessionStartH1=7||7||0||0||N
InpSessionEndH1=11||11||0||0||N
InpSessionStartH2=13||13||0||0||N
InpSessionEndH2=17||17||0||0||N
InpUseBreakeven=true||true||0||0||N
InpBETriggerR=1.0||1.0||0||0||N
InpBELockPoints=10||10||0||0||N
InpShowTradeBoxes=true||true||0||0||N
"""

with open(ini_path, "w", encoding="utf-8") as f:
    f.write(ini_text)

def clean_liveupdate():
    d = r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate"
    if os.path.exists(d):
        for f in os.listdir(d):
            try: os.remove(os.path.join(d, f))
            except: pass

clean_liveupdate()
print("Running YTD simulation (Jan 1 to Oct 8)...")
p = subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=120)
print(f"Finished with return code {p.returncode}")

if os.path.exists(rep_path):
    with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
        html = f.read()

    profit_m = re.search(r"Total Net Profit:</td>\s*<td[^>]*><b>([^<]+)</b>", html)
    trades_m = re.search(r"Total Trades:</td>\s*<td[^>]*><b>([^<]+)</b>", html)
    pf_m = re.search(r"Profit Factor:</td>\s*<td[^>]*><b>([^<]+)</b>", html)
    dd_m = re.search(r"Balance Drawdown Maximal:</td>\s*<td[^>]*><b>([^<]+)</b>", html)

    print(f"YTD Net Profit: ${profit_m.group(1) if profit_m else 'N/A'}")
    print(f"YTD Trades: {trades_m.group(1) if trades_m else 'N/A'}")
    print(f"YTD Profit Factor: {pf_m.group(1) if pf_m else 'N/A'}")
    print(f"YTD Max DD: {dd_m.group(1) if dd_m else 'N/A'}")

    # Extract all deals to build exact payout schedules
    deal_rows = re.findall(r"<tr[^>]*>\s*<td>(\d{4}\.\d{2}\.\d{2}\s+\d{2}:\d{2}:\d{2})</td>\s*<td>\d+</td>\s*<td>([^<]+)</td>\s*<td>([^<]+)</td>\s*<td>([^<]+)</td>\s*<td>([^<]+)</td>\s*<td>([^<]+)</td>\s*<td>([^<]+)</td>\s*<td[^>]*><b>?([^<]*)</b>?</td>", html)
    print(f"Extracted {len(deal_rows)} deal table rows")
