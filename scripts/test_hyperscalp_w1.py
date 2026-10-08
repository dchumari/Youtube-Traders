import subprocess
import os
import re

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_REL = r"YoutubeTraders\Micro_Account_Scalper\Gold_Micro_HyperScalp_EA"

ini_text = f"""[Common]
Login=472929

[Tester]
Expert={EXPERT_REL}
Symbol=XAUUSD
Period=M1
Model=1
FromDate=2024.03.04
ToDate=2024.03.11
Deposit=20
Currency=USD
Leverage=1:500
ExecutionMode=0
Optimization=0
Report=test_hyperscalp_w1
ReplaceReport=1
ShutdownTerminal=1
Visual=0

[TesterInputs]
FixedLotSize=0.01||0.01||0||0||N
SingleTarget_RR=2.8||2.8||0||0||N
SL_Pips=15.0||15.0||0||0||N
"""

ini_path = os.path.join(DATA_FOLDER, "test_hyperscalp.ini")
with open(ini_path, "w") as f:
    f.write(ini_text)

subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, timeout=60)

rep_path = os.path.join(DATA_FOLDER, "test_hyperscalp_w1.htm")
if os.path.exists(rep_path):
    with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
        html = f.read()
    matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', html))
    print("Gold_Micro_HyperScalp_EA W1 Results:")
    print("Net Profit:", matches.get('Total Net Profit', '0'))
    print("Profit Factor:", matches.get('Profit Factor', '0'))
    print("Trades:", matches.get('Total Trades', '0'))
    print("Max Drawdown:", matches.get('Balance Drawdown Maximal', '0'))
else:
    print("Report not found.")
