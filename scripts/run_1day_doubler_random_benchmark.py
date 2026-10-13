import subprocess
import os
import re
import json
import time
import sys

sys.stdout.reconfigure(encoding='utf-8')

TESTER_EXE = r"d:\MT5_Tester\terminal64.exe"
DATA_FOLDER = r"d:\MT5_Tester"
EXPERT_NAME = "SMC_Daily_Sniper_EA"
PRESET_DIR  = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\SMC_Daily_Sniper\presets"
OUT_RESULTS_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\SMC_Daily_Sniper\backtest_results\SMC_1DAY_DOUBLER_RANDOM_RESULTS.json"

RANDOM_4_WINDOWS = {
    "Random Window 1 (Late Jan - Week 4)": {
        "from": "2024.01.22",
        "to": "2024.01.29",
        "regime": "Normal Winter Flow (Non-NFP/CPI)"
    },
    "Random Window 2 (Late Apr - Week 17)": {
        "from": "2024.04.22",
        "to": "2024.04.29",
        "regime": "Spring Trend Extension (Non-NFP/CPI)"
    },
    "Random Window 3 (Late Aug - Week 34)": {
        "from": "2024.08.19",
        "to": "2024.08.26",
        "regime": "Late Summer Liquidity (Non-NFP/CPI)"
    },
    "Random Window 4 (Late Oct - Week 43)": {
        "from": "2024.10.21",
        "to": "2024.10.28",
        "regime": "Autumn Momentum (Non-NFP/CPI)"
    }
}

def clean_liveupdate():
    for d in [r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\8547D8E8CD54EE935BB2ECEA51CE4672\liveupdate",
              r"C:\Users\user\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\liveupdate",
              os.path.join(DATA_FOLDER, "liveupdate")]:
        if os.path.exists(d):
            for f in os.listdir(d):
                try: os.remove(os.path.join(d, f))
                except: pass

def safe_kill_tester():
    try:
        cmd = 'Get-Process -Name terminal64 -ErrorAction SilentlyContinue | Where-Object { $_.Path -notlike "*Program Files*" } | Stop-Process -Force'
        subprocess.run(["powershell", "-Command", cmd], capture_output=True)
    except:
        pass

def parse_preset(preset_path):
    inputs = {}
    if os.path.exists(preset_path):
        with open(preset_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("//") and not line.startswith(";"):
                    parts = line.split("=", 1)
                    if len(parts) == 2:
                        inputs[parts[0].strip()] = parts[1].strip()
    return inputs

def parse_detailed_htm_report(htm_file, initial_deposit):
    try:
        content = ""
        try:
            with open(htm_file, "r", encoding="utf-16", errors="ignore") as f:
                content = f.read()
        except:
            with open(htm_file, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()

        matches = dict(re.findall(r'<td[^>]*>([^<:]+):?</td>\s*<td[^>]*><b>([^<]+)</b>', content))

        def parse_float(val_str, default=0.0):
            if not val_str: return default
            cleaned = val_str.replace(" ", "").replace("&nbsp;", "").replace(",", "").strip()
            m = re.search(r"(-?[\d\.]+)", cleaned)
            return float(m.group(1)) if m else default

        net_profit = parse_float(matches.get("Total Net Profit", "0"))
        trades = int(parse_float(matches.get("Total Trades", "0")))
        pf = parse_float(matches.get("Profit Factor", "0"))

        win_str = matches.get("Profit Trades (% of total)", "")
        m_win = re.search(r"\(([\d\.]+)%\)", win_str)
        win_pct = float(m_win.group(1)) if m_win else 0.0

        dd_str = matches.get("Balance Drawdown Maximal", matches.get("Maximal Drawdown", matches.get("Drawdown Maximal", "")))
        m_dd = re.search(r"\(([\d\.]+)%\)", dd_str)
        dd_pct = float(m_dd.group(1)) if m_dd else parse_float(dd_str)

        roi_pct = (net_profit / initial_deposit) * 100.0 if initial_deposit > 0 else 0.0

        # Parse individual trade & daily returns from deals section
        max_single_trade_pnl = 0.0
        daily_pnl = {}
        deals_section = content.split("<b>Deals</b>")
        if len(deals_section) > 1:
            deal_rows = re.findall(r'<tr[^>]*>(.*?)</tr>', deals_section[1], re.DOTALL)
            for r in deal_rows[1:]:
                cols = [re.sub(r'<[^>]+>', '', c).strip() for c in re.findall(r'<td[^>]*>(.*?)</td>', r, re.DOTALL)]
                if len(cols) >= 12 and cols[4] == 'out':
                    try:
                        p = float(cols[10].replace(' ', ''))
                        day = cols[0].split()[0]
                        daily_pnl[day] = daily_pnl.get(day, 0.0) + p
                        if p > max_single_trade_pnl:
                            max_single_trade_pnl = p
                    except:
                        pass

        max_single_day_pnl = max(daily_pnl.values()) if daily_pnl else 0.0
        max_single_day_roi = (max_single_day_pnl / initial_deposit) * 100.0 if initial_deposit > 0 else 0.0
        max_single_trade_roi = (max_single_trade_pnl / initial_deposit) * 100.0 if initial_deposit > 0 else 0.0

        doubled_in_single_day = max_single_day_roi >= 100.0
        doubled_in_single_trade = max_single_trade_roi >= 100.0

        return {
            "net_profit": round(net_profit, 2),
            "roi_pct": round(roi_pct, 1),
            "trades": trades,
            "win_rate": round(win_pct, 1),
            "profit_factor": round(pf, 2),
            "max_dd_pct": round(dd_pct, 1),
            "max_single_day_profit": round(max_single_day_pnl, 2),
            "max_single_day_roi": round(max_single_day_roi, 1),
            "max_single_trade_profit": round(max_single_trade_pnl, 2),
            "max_single_trade_roi": round(max_single_trade_roi, 1),
            "doubled_in_single_day": doubled_in_single_day,
            "doubled_in_single_trade": doubled_in_single_trade,
            "status": "PASS" if net_profit > 0 else "FAIL"
        }
    except Exception as e:
        return {"net_profit": 0.0, "roi_pct": 0.0, "trades": 0, "win_rate": 0.0, "profit_factor": 0.0, "max_dd_pct": 0.0, "status": f"ERROR: {str(e)}"}

def run_single_test(test_id, win_from, win_to, deposit, leverage, inputs, timeout_sec=80):
    clean_liveupdate()
    inputs_block = ""
    for k, v in inputs.items():
        inputs_block += f"{k}={v}||{v}||0||0||N\n"

    ini_path = os.path.join(DATA_FOLDER, f"{test_id}.ini")
    rep_name = f"{test_id}_rep"
    rep_path = os.path.join(DATA_FOLDER, f"{rep_name}.htm")

    if os.path.exists(rep_path):
        try: os.remove(rep_path)
        except: pass

    ini_text = f"""[Common]
Login=472929

[Tester]
Expert={EXPERT_NAME}
Symbol=XAUUSD
Period=M15
Model=1
FromDate={win_from}
ToDate={win_to}
Deposit={deposit}
Currency=USD
Leverage={leverage}
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

    cmd = [TESTER_EXE, "/portable", f"/config:{ini_path}"]
    safe_kill_tester()
    time.sleep(1)

    proc = subprocess.Popen(cmd)
    start_t = time.time()
    done = False

    while time.time() - start_t < timeout_sec:
        if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
            time.sleep(1.5)
            try: proc.kill()
            except: pass
            safe_kill_tester()
            done = True
            break
        if proc.poll() is not None:
            time.sleep(2)
            if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
                done = True
            break
        time.sleep(1.5)

    if not done:
        try: proc.kill()
        except: pass
        safe_kill_tester()

    if os.path.exists(rep_path) and os.path.getsize(rep_path) > 1000:
        return parse_detailed_htm_report(rep_path, deposit)
    else:
        return {
            "net_profit": 0.0,
            "roi_pct": 0.0,
            "trades": 0,
            "win_rate": 0.0,
            "profit_factor": 0.0,
            "max_dd_pct": 0.0,
            "status": "FAIL_OR_NO_TRADES"
        }

def main():
    print("=" * 90)
    print("  1-DAY / 1-TRADE 100% ACCOUNT DOUBLER BENCHMARK (4 RANDOM 2024 NON-NFP/CPI WINDOWS)")
    print("  Gold XAUUSD M15 | 1:400 Leverage | Target: Double Balance in 1 Day or 1 Single Trade")
    print("=" * 90)

    p_20  = os.path.join(PRESET_DIR, "SMCD_1Day_1Trade_Doubler_20USD.set")
    p_100 = os.path.join(PRESET_DIR, "SMCD_1Day_1Trade_Doubler_100USD.set")

    inputs_20  = parse_preset(p_20)
    inputs_100 = parse_preset(p_100)

    results = {"20USD": {}, "100USD": {}}

    # --- $20 USD CAPITAL TIER ---
    print("\n>>> [$20 USD Capital Tier / Micro Doubler (775 USC)] <<<")
    for w_key, w_info in RANDOM_4_WINDOWS.items():
        clean_tag = f"rw{list(RANDOM_4_WINDOWS.keys()).index(w_key)+1}"
        t_id = f"smcd_1day_20_{clean_tag}"
        print(f"Testing {w_key} ({w_info['from']} to {w_info['to']}) [{w_info['regime']}]...", end="", flush=True)
        res = run_single_test(t_id, w_info["from"], w_info["to"], 20.0, 400, inputs_20, timeout_sec=70)
        results["20USD"][w_key] = res
        day_tag = "🚀 [DOUBLED IN 1 DAY!]" if res.get("doubled_in_single_day") else ""
        trade_tag = "⚡ [DOUBLED IN 1 TRADE!]" if res.get("doubled_in_single_trade") else ""
        print(f" -> Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | Max Day: ${res.get('max_single_day_profit', 0):+.2f} ({res.get('max_single_day_roi', 0):+.1f}%) {day_tag} | Max Trade: ${res.get('max_single_trade_profit', 0):+.2f} ({res.get('max_single_trade_roi', 0):+.1f}%) {trade_tag} | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% | Trades: {res['trades']} [{res['status']}]")

    # --- $100 USD CAPITAL TIER ---
    print("\n>>> [$100 USD Capital Tier / Standard Sprint Doubler] <<<")
    for w_key, w_info in RANDOM_4_WINDOWS.items():
        clean_tag = f"rw{list(RANDOM_4_WINDOWS.keys()).index(w_key)+1}"
        t_id = f"smcd_1day_100_{clean_tag}"
        print(f"Testing {w_key} ({w_info['from']} to {w_info['to']}) [{w_info['regime']}]...", end="", flush=True)
        res = run_single_test(t_id, w_info["from"], w_info["to"], 100.0, 400, inputs_100, timeout_sec=70)
        results["100USD"][w_key] = res
        day_tag = "🚀 [DOUBLED IN 1 DAY!]" if res.get("doubled_in_single_day") else ""
        trade_tag = "⚡ [DOUBLED IN 1 TRADE!]" if res.get("doubled_in_single_trade") else ""
        print(f" -> Net: ${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | Max Day: ${res.get('max_single_day_profit', 0):+.2f} ({res.get('max_single_day_roi', 0):+.1f}%) {day_tag} | Max Trade: ${res.get('max_single_trade_profit', 0):+.2f} ({res.get('max_single_trade_roi', 0):+.1f}%) {trade_tag} | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% | Trades: {res['trades']} [{res['status']}]")

    with open(OUT_RESULTS_JSON, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    safe_kill_tester()
    print("\n" + "=" * 90)
    print(f"1-Day / 1-Trade Doubler benchmark finished! Saved to: {OUT_RESULTS_JSON}")

if __name__ == "__main__":
    main()
