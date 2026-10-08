import json

master_file = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\ALL_MRPFX_STRATEGIES_16_WINDOWS_RESULTS.json"
with open(master_file, "r", encoding="utf-8") as f:
    d = json.load(f)

windows = ['W1', 'W2', 'W3', 'W4', 'M1', 'M2', 'M3', 'M4', 'Q1', 'Q2', 'Q3', 'Q4', 'Y1', 'Y2', 'Y3', 'Y4']

print(f"{'Win':3s} | {'Strategy':25s} | {'$100 Net':9s} {'PF':5s} {'DD%':6s} {'Win%':5s} {'Tr':4s} | {'$20 Net':9s} {'Return%':8s} {'PF':5s} {'DD%':6s}")
print("-" * 95)

for w in windows:
    for strat, data in d.items():
        s_name = data.get("info", {}).get("name", strat)
        if len(s_name) > 25:
            s_name = s_name[:25]
        r100 = data['account_100'].get(w, {})
        r20 = data['account_20'].get(w, {})
        ret20 = (r20.get('net_profit', 0) / 20.0) * 100.0
        print(f"{w:3s} | {s_name:25s} | ${r100.get('net_profit', 0):+7.2f} {r100.get('profit_factor', 0):5.2f} {r100.get('drawdown_pct', 0):5.1f}% {r100.get('win_rate_pct', 0):4.0f}% {r100.get('total_trades', 0):3d} | ${r20.get('net_profit', 0):+7.2f} {ret20:+7.1f}% {r20.get('profit_factor', 0):5.2f} {r20.get('drawdown_pct', 0):5.1f}%")
    print("-" * 95)
