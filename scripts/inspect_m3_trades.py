import subprocess
import os

ini_text = """[Common]
Login=472929

[Tester]
Expert=YoutubeTraders\\Mr_P_Fx\\MrPFx_Master_Suite
Symbol=XAUUSD
Period=M15
Model=1
FromDate=2024.07.01
ToDate=2024.07.31
Deposit=20
Currency=USD
Leverage=1:500
ExecutionMode=0
Optimization=0
Report=m3_20_diag
ReplaceReport=1
ShutdownTerminal=1
Visual=0

[TesterInputs]
InpStrategy=0||0||0||0||N
InpRewardRiskRatio=2.0||2.0||0||0||N
InpSweepLookback=20||20||0||0||N
InpMinSweepPoints=35||35||0||0||N
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
InpRiskPercent=0.0||0.0||0||0||N
InpFixedLot=0.01||0.01||0||0||N
"""

ini_path = r"d:\MT5_Tester\m3_20_diag.ini"
with open(ini_path, "w") as f:
    f.write(ini_text)

subprocess.run([r"d:\MT5_Tester\terminal64.exe", "/portable", f"/config:{ini_path}"], capture_output=True, timeout=60)

rep_path = r"d:\MT5_Tester\m3_20_diag.htm"
if os.path.exists(rep_path):
    with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
        content = f.read()
    import re
    trades = re.findall(r'<tr[^>]*>\s*<td[^>]*>(\d+)</td>\s*<td[^>]*>([\d\.\s:]+)</td>\s*<td[^>]*>(buy|sell)</td>.*?<td[^>]*>([-\d\.]+)</td>\s*</tr>', content, re.DOTALL)
    print("Found trades:", len(trades))
    for t in trades[:15]:
        print(t)
