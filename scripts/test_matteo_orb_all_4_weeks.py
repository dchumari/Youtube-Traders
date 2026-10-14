import subprocess
import os
import re

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"

RANDOM_4_WINDOWS = {
    "RW1 (Late Jan - W4)": {"from": "2024.01.22", "to": "2024.01.29"},
    "RW2 (Late Apr - W17)": {"from": "2024.04.22", "to": "2024.04.29"},
    "RW3 (Late Aug - W34)": {"from": "2024.08.19", "to": "2024.08.26"},
    "RW4 (Late Oct - W43)": {"from": "2024.10.21", "to": "2024.10.28"}
}

def test_window(win_name, win_from, win_to, deposit=20.0):
    ini_path = os.path.join(DATA_FOLDER, f"test_orb_{win_name[:3]}.ini")
    rep_name = f"test_orb_{win_name[:3]}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")
    if os.path.exists(rep_path): os.remove(rep_path)

    ini_text = f"""[Common]
Login=472929
[Tester]
Expert=ChartFanatics_Master_Suite
Symbol=XAUUSD
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
Visual=0
[TesterInputs]
InpStrategyModel=0||0||0||0||N
InpSettingsMode=1||1||0||0||N
InpFixedLot=0.01||0.01||0||0||N
InpTicketSlices=2||2||0||0||N
InpEnablePyramiding=false||false||0||0||N
InpUseSteppedBE=true||true||0||0||N
InpBE_TriggerPoints=200||200||0||0||N
InpBE_LockPoints=10||10||0||0||N
"""
    with open(ini_path, "w") as f: f.write(ini_text)
    subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], timeout=60)
    if os.path.exists(rep_path):
        with open(rep_path, "r", encoding="utf-16", errors="ignore") as f: text = f.read()
        matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', text))
        net = matches.get('Total Net Profit', '0')
        trades = matches.get('Total Trades', '0')
        pf = matches.get('Profit Factor', '0')
        dd = matches.get('Balance Drawdown Maximal', matches.get('Maximal Drawdown', ''))
        print(f"[Matteo Bank ORB $20 {win_name}] Net Profit: ${net} | Trades: {trades} | PF: {pf} | DD: {dd}")
    else:
        print(f"[Matteo Bank ORB $20 {win_name}] No report")

for w_name, w_info in RANDOM_4_WINDOWS.items():
    test_window(w_name, w_info["from"], w_info["to"])
