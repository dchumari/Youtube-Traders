import os
import re
from bs4 import BeautifulSoup
import json

REPORTS = {
    "RW1 (Late Jan - W4)": r"d:\MT5_Tester\bench_20_RW1_rep.htm",
    "RW2 (Late Apr - W17)": r"d:\MT5_Tester\bench_20_RW2_rep.htm",
    "RW3 (Late Aug - W34)": r"d:\MT5_Tester\bench_20_RW3_rep.htm",
    "RW4 (Late Oct - W43)": r"d:\MT5_Tester\bench_20_RW4_rep.htm",
}

REPORTS_100 = {
    "RW1 (Late Jan - W4)": r"d:\MT5_Tester\bench_100_RW1_rep.htm",
    "RW2 (Late Apr - W17)": r"d:\MT5_Tester\bench_100_RW2_rep.htm",
    "RW3 (Late Aug - W34)": r"d:\MT5_Tester\bench_100_RW3_rep.htm",
    "RW4 (Late Oct - W43)": r"d:\MT5_Tester\bench_100_RW4_rep.htm",
}

def parse_deals_from_htm(path):
    if not os.path.exists(path):
        return []
    try:
        with open(path, "r", encoding="utf-16", errors="ignore") as f:
            html = f.read()
    except:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            html = f.read()

    soup = BeautifulSoup(html, "html.parser")
    tables = soup.find_all("table")
    if len(tables) < 2:
        return []

    tbl = tables[1]
    deals_found = False
    deal_headers = []
    deals = []

    for tr in tbl.find_all("tr"):
        txt = tr.get_text()
        if "Deals" in txt:
            deals_found = True
            continue
        if deals_found:
            tds = [td.get_text(strip=True) for td in tr.find_all(["td", "th"])]
            if not deal_headers and "Profit" in tds:
                deal_headers = tds
            elif deal_headers and len(tds) >= 10:
                deals.append(tds)

    # Headers: Time, Deal, Symbol, Type, Direction, Volume, Price, Order, Commission, Swap, Profit, Balance, Comment
    # Pair 'in' deals with 'out' deals
    in_deals = {} # order or deal key -> deal data
    closed_trades = []

    for d in deals:
        if len(d) < 11:
            continue
        d_time = d[0]
        d_type = d[3] # buy or sell or balance
        d_dir = d[4]  # in or out
        d_vol = d[5]
        d_price = d[6]
        d_order = d[7]
        d_profit = d[10]
        d_comment = d[12] if len(d) > 12 else ""

        if d_dir == "in":
            in_deals[d_order] = {
                "open_time": d_time,
                "type": d_type,
                "vol": d_vol,
                "open_price": d_price,
                "comment": d_comment
            }
        elif d_dir == "out":
            # Match with in_deal
            # MT5 order for 'out' deal might link to position or ticket
            # In simple FIFO, match by type opposite or position
            matched_in = None
            matched_key = None
            for k, in_d in list(in_deals.items()):
                # If out is buy, in was sell, etc.
                if (d_type == "buy" and in_d["type"] == "sell") or (d_type == "sell" and in_d["type"] == "buy"):
                    matched_in = in_d
                    matched_key = k
                    break
            
            p_val = 0.0
            try:
                p_val = float(d_profit.replace(" ", "").replace("&nbsp;", "").replace(",", ""))
            except:
                pass

            trade_info = {
                "close_time": d_time,
                "type": matched_in["type"] if matched_in else ("buy" if d_type == "sell" else "sell"),
                "vol": d_vol,
                "open_time": matched_in["open_time"] if matched_in else "",
                "open_price": matched_in["open_price"] if matched_in else "",
                "close_price": d_price,
                "profit": p_val,
                "comment": matched_in["comment"] if matched_in else d_comment
            }
            if matched_key:
                del in_deals[matched_key]
            closed_trades.append(trade_info)

    return closed_trades

if __name__ == "__main__":
    print("=== EXTRACTING TRADE BREAKDOWN FOR $20 TIER ===")
    results_20 = {}
    for w_name, path in REPORTS.items():
        trades = parse_deals_from_htm(path)
        results_20[w_name] = trades
        print(f"\n--- {w_name} (Total Trades: {len(trades)}) ---")
        cum_p = 0.0
        for idx, t in enumerate(trades):
            cum_p += t["profit"]
            print(f"Trade #{idx+1:02d} | Open: {t['open_time']} | Close: {t['close_time']} | {t['type'].upper()} {t['vol']} @ {t['open_price']} -> {t['close_price']} | PnL: ${t['profit']:+.2f} | Cum: ${cum_p:+.2f} | {t['comment']}")

    out_json = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\SMC_Daily_Sniper\backtest_results\trade_breakdown_20usd.json"
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(results_20, f, indent=2)
    print(f"\nSaved $20 trade breakdown to {out_json}")

    print("\n=== EXTRACTING TRADE BREAKDOWN FOR $100 TIER ===")
    results_100 = {}
    for w_name, path in REPORTS_100.items():
        trades = parse_deals_from_htm(path)
        results_100[w_name] = trades
        print(f"\n--- {w_name} (Total Trades: {len(trades)}) ---")
        cum_p = 0.0
        for idx, t in enumerate(trades):
            cum_p += t["profit"]
            if idx < 6 or idx >= len(trades) - 4:
                print(f"Trade #{idx+1:02d} | Open: {t['open_time']} | Close: {t['close_time']} | {t['type'].upper()} {t['vol']} @ {t['open_price']} -> {t['close_price']} | PnL: ${t['profit']:+.2f} | Cum: ${cum_p:+.2f} | {t['comment']}")
        print(f"Total Net Profit: ${cum_p:+.2f}")

    out_json_100 = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\SMC_Daily_Sniper\backtest_results\trade_breakdown_100usd.json"
    with open(out_json_100, "w", encoding="utf-8") as f:
        json.dump(results_100, f, indent=2)
    print(f"\nSaved $100 trade breakdown to {out_json_100}")

