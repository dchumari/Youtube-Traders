import subprocess
import os
import re

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
PRESET_DIR  = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\SMC_Daily_Sniper\presets"

# Test RW4 (2024.10.21 to 2024.10.28) across different models & filters
def parse_preset(preset_path):
    inputs = {}
    with open(preset_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("//"):
                p = line.split("=", 1)
                if len(p) == 2: inputs[p[0].strip()] = p[1].strip()
    return inputs

def run_test(test_id, inputs, ea_name="SMC_Daily_Sniper_EA"):
    inputs_block = "".join([f"{k}={v}||{v}||0||0||N\n" for k, v in inputs.items()])
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")
    if os.path.exists(rep_path): os.remove(rep_path)

    ini_text = f"""[Common]
Login=472929
[Tester]
Expert={ea_name}
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
{inputs_block}
"""
    with open(ini_path, "w", encoding="utf-8") as f: f.write(ini_text)
    subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], timeout=60)
    if os.path.exists(rep_path):
        with open(rep_path, "r", encoding="utf-16", errors="ignore") as f: text = f.read()
        matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', text))
        print(f"[{test_id}] Net Profit: {matches.get('Total Net Profit')} | Trades: {matches.get('Total Trades')} | PF: {matches.get('Profit Factor')}")
    else:
        print(f"[{test_id}] No report")

p20 = os.path.join(PRESET_DIR, "SMCD_1Day_1Trade_Doubler_20USD.set")
base_inp = parse_preset(p20)

for m in [0, 1, 4, 5]:
    inp = dict(base_inp)
    inp["InpCoreModel"] = str(m)
    run_test(f"test_rw4_m{m}", inp)
