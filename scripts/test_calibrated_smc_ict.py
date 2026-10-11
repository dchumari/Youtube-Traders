import subprocess
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_NAME = "Institutional_SMC_ICT_Master_Suite"

def clean_liveupdate():
    for d in [r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate",
              os.path.join(DATA_FOLDER, "liveupdate")]:
        if os.path.exists(d):
            for f in os.listdir(d):
                try: os.remove(os.path.join(d, f))
                except: pass

def run_test(label, win_from, win_to, inputs):
    clean_liveupdate()
    test_id = f"test_{label}"
    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

    inputs_block = ""
    for k, v in inputs.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    ini_text = f"""[Common]
Login=472929

[Tester]
Expert={EXPERT_NAME}
Symbol=XAUUSD
Period=M15
Model=1
FromDate={win_from}
ToDate={win_to}
Deposit=100.0
Currency=USD
Leverage=1:400
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

    subprocess.run([TESTER_EXE, "/portable", f"/config:{ini_path}"], capture_output=True, text=True, timeout=90)

    if os.path.exists(rep_path):
        with open(rep_path, "r", encoding="utf-16", errors="ignore") as f:
            html = f.read()
        matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', html))
        def parse_float(k):
            val = matches.get(k, '0')
            clean = re.sub(r'[^0-9.-]', '', val.split('(')[0])
            try: return float(clean)
            except: return 0.0
        def parse_int(k):
            val = matches.get(k, '0')
            clean = re.sub(r'[^0-9]', '', val.split('(')[0])
            try: return int(clean)
            except: return 0
        np_val = parse_float('Total Net Profit')
        pf_val = parse_float('Profit Factor')
        dd_val = parse_float('Equity Drawdown Maximal')
        if dd_val == 0.0: dd_val = parse_float('Maximal Drawdown')
        tt_val = parse_int('Total Trades')
        print(f"[{label}] Net PnL: ${np_val:>7.2f} ({(np_val/100.0)*100:>+6.1f}%) | Trades: {tt_val:>3} | PF: {pf_val:>4.2f} | DD: {dd_val:>4.1f}%")
        return np_val
    else:
        print(f"[{label}] No report generated!")
        return -999.0

# Base parameters
base_cfg = {
    "InpStrategyModel": 0,
    "InpSessionFilter": 1, # London & NY
    "InpExecutionEngine": 0,
    "InpBaseLotSize": 0.01,
    "InpEquityPerMinLot": 35.0,
    "InpMaxLotCap": 0.50,
    "InpStopLossPoints": 250, # 25 pips
    "InpMagicNumber": 777000,
    "InpSpamTicketsCount": 5,
    "InpTP1Points": 200,
    "InpTP2Points": 350,
    "InpTP3Points": 600,
    "InpTP4Points": 1000,
    "InpTP5Points": 1600,
    "InpEnableTraceback": "false",
    "InpTracebackExtensionPts": 250,
    "InpTracebackTPPoints": 150,
    "InpTracebackSLPoints": 120,
    "InpEnablePyramiding": "true",
    "InpReloadStepPoints": 350,
    "InpMaxPyramidLayers": 3,
    "InpReloadTicketsCount": 3,
    "InpEnableDumpAndFlip": "false",
    "InpDumpWickRatio": 0.45,
    "InpEnableVolumeClimax": "false",
    "InpVolumeSpikeMulti": 3.0,
    "InpEnableFlipMilestone": "true",
    "InpTargetEquity": 1000.0,
    "InpLookbackBars": 30,
    "InpMinSweepPoints": 20,
    "InpMinFVGPoints": 25,
    "InpMinWickRejection": 0.35,
    "InpMinDisplacementPts": 40,
    "InpEMATrendPeriod": 50,
    "InpEnableVisuals": "false",
    "InpApplyDraculaTheme": "false",
    "InpDrawSetupBoxes": "false"
}

print("Testing Strategy Models on W1 (NFP Shock: 2024.03.04 -> 2024.03.11) with Calibrated Risk & Filters:")
for m in range(10):
    cfg = dict(base_cfg)
    cfg["InpStrategyModel"] = m
    cfg["InpMagicNumber"] = 777000 + m
    run_test(f"Model_{m}_W1", "2024.03.04", "2024.03.11", cfg)
