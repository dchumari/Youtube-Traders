import subprocess
import os
import re

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"

def test_cf_model(model_num, name):
    ini_path = os.path.join(DATA_FOLDER, f"test_cf_m{model_num}.ini")
    rep_name = f"test_cf_m{model_num}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")
    if os.path.exists(rep_path):
        os.remove(rep_path)

    ini_text = f"""[Common]
Login=472929
[Tester]
Expert=ChartFanatics_Master_Suite
Symbol=XAUUSD
Period=M15
Model=1
FromDate=2024.10.21
ToDate=2024.10.28
Deposit=20.0
Currency=USD
Leverage=400
ExecutionMode=0
Optimization=0
Report={rep_name}
ReplaceReport=1
ShutdownTerminal=1
Visual=0
[TesterInputs]
InpStrategyModel={model_num}||{model_num}||0||0||N
InpSettingsMode=1||1||0||0||N
InpFixedLot=0.01||0.01||0||0||N
InpTicketSlices=2||2||0||0||N
InpEnablePyramiding=false||false||0||0||N
InpUseSteppedBE=true||true||0||0||N
InpBE_TriggerPoints=200||200||0||0||N
InpBE_LockPoints=10||10||0||0||N
"""
    with open(ini_path, "w") as f:
        f.write(ini_text)
    subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], timeout=60)
    if os.path.exists(rep_path):
        with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
            text = f.read()
        matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', text))
        print(f"[{name}] Net Profit: {matches.get('Total Net Profit')} | Trades: {matches.get('Total Trades')} | PF: {matches.get('Profit Factor')}")
    else:
        print(f"[{name}] No report")

test_cf_model(0, "Matteo Bank ORB")
test_cf_model(2, "Trader Yush Value Area")
test_cf_model(5, "Kris Verma Gap Short")
test_cf_model(6, "CF Master Hybrid")
