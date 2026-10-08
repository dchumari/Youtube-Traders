import subprocess
import os
import re
import json

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_PRO = r"YoutubeTraders\Daily_Fibonacci_Strategy\Daily_Fib_618_Pro_Aggressive_EA"
EXPERT_BASE = r"YoutubeTraders\Daily_Fibonacci_Strategy\Daily_Fib_618_EA"

def parse_report_htm(htm_path):
    if not os.path.exists(htm_path):
        return None
    try:
        with open(htm_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        res = {}
        np_match = re.search(r"Total Net Profit:</td><td[^>]*><b>(-?[\d\s\.,]+)</b>", content, re.IGNORECASE)
        if not np_match:
            np_match = re.search(r"Total Net Profit:</td>\s*<td[^>]*>(-?[\d\s\.,]+)</td>", content, re.IGNORECASE)
        if np_match:
            val_str = np_match.group(1).replace(" ", "").replace(",", "")
            res["net_profit"] = float(val_str)
        pf_match = re.search(r"Profit Factor:</td><td[^>]*><b>([\d\.,]+)</b>", content, re.IGNORECASE)
        if not pf_match:
            pf_match = re.search(r"Profit Factor:</td>\s*<td[^>]*>([\d\.,]+)</td>", content, re.IGNORECASE)
        if pf_match:
            res["profit_factor"] = float(pf_match.group(1).replace(",", ""))
        dd_match = re.search(r"Maximal Drawdown:</td><td[^>]*>[\d\s\.,]+\s*\(([\d\.,]+)%\)</td>", content, re.IGNORECASE)
        if dd_match:
            res["drawdown_pct"] = float(dd_match.group(1).replace(",", ""))
        tt_match = re.search(r"Total Trades:</td><td[^>]*><b>(\d+)</b>", content, re.IGNORECASE)
        if not tt_match:
            tt_match = re.search(r"Total Trades:</td>\s*<td[^>]*>(\d+)</td>", content, re.IGNORECASE)
        if tt_match:
            res["total_trades"] = int(tt_match.group(1))
        wr_match = re.search(r"Short Trades \(won %\):</td><td[^>]*>[\d\s\.,]+\s*\(([\d\.,]+)%\)</td>", content, re.IGNORECASE)
        if wr_match:
            res["short_win_rate"] = float(wr_match.group(1).replace(",", ""))
        return res
    except Exception as e:
        print("Parse error:", e)
        return None

def run_single_test(expert_rel, params, from_date, to_date, deposit=100.0, leverage=100):
    report_file = os.path.join(DATA_FOLDER, "diag_report.htm")
    ini_file = os.path.join(DATA_FOLDER, "diag_test.ini")
    if os.path.exists(report_file):
        os.remove(report_file)

    inputs_str = "\n".join([f"{k}={v}" for k, v in params.items()])
    ini_content = f"""[Tester]
Expert={expert_rel}.ex5
Symbol=XAUUSD
Period=M15
Deposit={deposit}
Leverage=1:{leverage}
Model=1
ExecutionMode=0
Optimization=0
FromDate={from_date}
ToDate={to_date}
ForwardMode=0
Report={report_file}
ReplaceReport=1
ShutdownTerminal=1

[TesterInputs]
{inputs_str}
"""
    with open(ini_file, "w", encoding="utf-8") as f:
        f.write(ini_content)

    cmd = [TESTER_EXE, f"/config:{ini_file}"]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=120)
    return parse_report_htm(report_file)

# Test diagnostic variations on Q1 (2023.01.01 -> 2023.03.31) where Baseline made +$22.70
print("=== BASELINE TEST ON Q1 (2023.01.01 -> 2023.03.31) ===")
base_res = run_single_test(
    EXPERT_BASE,
    {
        "InpMagicNumber": 618001,
        "InpFixedLot": 0.01,
        "InpRewardRiskRatio": 2.0,
        "InpSLPoints": 350,
        "InpEntryTolerance": 50,
        "InpMaxSpreadPoints": 50,
        "InpTradeImmediate": "true",
        "InpTradeVirginLevels": "true",
        "InpMaxVirginAgeDays": 30,
        "InpMaxDailyTrades": 2,
        "InpUseBreakeven": "true",
        "InpBETriggerR": 1.0,
        "InpBELockPoints": 10,
        "InpUseSessionFilter": "true",
        "InpSessionStartHour": 7,
        "InpSessionEndHour": 18
    },
    "2023.01.01", "2023.03.31"
)
print("Baseline Q1 Result:", base_res)

# Test Pro EA variations on Q1
configs = [
    ("Pro Full (Rejection ON, EMA ON, Step Compounding, SL 220)", {
        "InpCapitalMode": 1, "InpEquityPerMicroLot": 25.0, "InpFixedLot": 0.01, "InpMaxLotCap": 3.0,
        "InpPart1_RR": 1.0, "InpPart2_RR": 2.5, "InpSLPoints": 220, "InpBELockPoints": 10,
        "InpBaseMagic": 618500, "InpRequireRejection": "true", "InpMinWickRatio": 0.35,
        "InpEntryTolerance": 60, "InpMaxSpreadPoints": 50, "InpUseTrendFilter": "true",
        "InpDailyEMAPeriod": 50, "InpTradeImmediate": "true", "InpTradeVirginLevels": "true",
        "InpMaxVirginAgeDays": 30, "InpMaxDailyTrades": 4, "InpUseSessionFilter": "true",
        "InpSessionStartHour": 7, "InpSessionEndHour": 18
    }),
    ("Pro Fixed 0.01 Lot (No Compounding, SL 220)", {
        "InpCapitalMode": 0, "InpFixedLot": 0.01,
        "InpPart1_RR": 1.0, "InpPart2_RR": 2.5, "InpSLPoints": 220, "InpBELockPoints": 10,
        "InpBaseMagic": 618500, "InpRequireRejection": "true", "InpMinWickRatio": 0.35,
        "InpEntryTolerance": 60, "InpMaxSpreadPoints": 50, "InpUseTrendFilter": "true",
        "InpDailyEMAPeriod": 50, "InpTradeImmediate": "true", "InpTradeVirginLevels": "true",
        "InpMaxVirginAgeDays": 30, "InpMaxDailyTrades": 4, "InpUseSessionFilter": "true",
        "InpSessionStartHour": 7, "InpSessionEndHour": 18
    }),
    ("Pro SL 350 (Original SL, Fixed 0.01, Rejection OFF, Trend OFF)", {
        "InpCapitalMode": 0, "InpFixedLot": 0.01,
        "InpPart1_RR": 1.0, "InpPart2_RR": 2.0, "InpSLPoints": 350, "InpBELockPoints": 10,
        "InpBaseMagic": 618500, "InpRequireRejection": "false", "InpMinWickRatio": 0.35,
        "InpEntryTolerance": 50, "InpMaxSpreadPoints": 50, "InpUseTrendFilter": "false",
        "InpDailyEMAPeriod": 50, "InpTradeImmediate": "true", "InpTradeVirginLevels": "true",
        "InpMaxVirginAgeDays": 30, "InpMaxDailyTrades": 2, "InpUseSessionFilter": "true",
        "InpSessionStartHour": 7, "InpSessionEndHour": 18
    })
]

for name, cfg in configs:
    res = run_single_test(EXPERT_PRO, cfg, "2023.01.01", "2023.03.31")
    print(f"--> {name}: {res}")
