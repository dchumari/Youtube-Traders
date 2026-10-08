import json

d = json.load(open('d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/GROUPED_WINDOW_STATISTICS.json', 'r', encoding='utf-8'))

out_md = []

for gname, gdata in d.items():
    out_md.append(f"## {gname}\n")
    out_md.append(f"> **Focus:** {gdata['desc']}\n")
    
    for skey, sdata in gdata['strategies'].items():
        s_name = sdata['name']
        out_md.append(f"### {s_name}\n")
        out_md.append("| Window | Window Context | $100 Net Profit | $100 PF | $100 Max DD | $100 Win% | Trades | $20 Net Profit | $20 Return % | $20 PF | $20 Max DD |")
        out_md.append("| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |")
        
        for w, wdata in sdata['windows'].items():
            r100 = wdata['account_100']
            r20 = wdata['account_20']
            w_desc = {
                "W1": "NFP / Central Bank Shock",
                "W2": "CPI / FOMC Decision Week",
                "W3": "Global Carry Trade Shock",
                "W4": "US Election Volatility",
                "M1": "Q1 Opening Trend (Jan)",
                "M2": "Spring Expansion (Apr)",
                "M3": "Summer Range Chop (Jul)",
                "M4": "Autumn Acceleration (Oct)",
                "Q1": "Banking Crisis / Safe-Haven",
                "Q2": "Rate Tightening Plateau",
                "Q3": "USD Bull Trend / Gold Dip",
                "Q4": "Year-End Dovish Pivot",
                "Y1": "Rate Hiking Shock (2022)",
                "Y2": "Disinflation Cycle (2023)",
                "Y3": "Global Easing Cycle (2024)",
                "Y4": "Macro Transition (2025)"
            }.get(w, "")
            
            pf100_str = f"{r100['profit_factor']:.2f}" if r100['profit_factor'] > 0 else "0.00 (Loss)"
            if r100['net_profit'] > 0 and r100['profit_factor'] == 0:
                pf100_str = "MAX (No Loss)"
                
            pf20_str = f"{r20['profit_factor']:.2f}" if r20['profit_factor'] > 0 else "0.00 (Loss)"
            if r20['net_profit'] > 0 and r20['profit_factor'] == 0:
                pf20_str = "MAX (No Loss)"

            out_md.append(f"| **{w}** | {w_desc} | **${r100['net_profit']:+6.2f}** | {pf100_str} | {r100['drawdown_pct']:.1f}% | {r100['win_rate_pct']:.0f}% | {r100['trades']} | **${r20['net_profit']:+6.2f}** | **{r20['return_pct']:+6.1f}%** | {pf20_str} | {r20['drawdown_pct']:.1f}% |")
            
        a100 = sdata['aggregate_100']
        a20 = sdata['aggregate_20']
        out_md.append(f"| **SUBTOTAL** | **Group Aggregate** | **${a100['net_profit']:+6.2f}** | **{a100['combined_pf']:.2f}** | **{a100['max_drawdown_pct']:.1f}%** | **{a100['overall_win_rate']:.0f}%** | **{a100['total_trades']}** | **${a20['net_profit']:+6.2f}** | **{a20['total_return_pct']:+6.1f}%** | **{a20['combined_pf']:.2f}** | **{a20['max_drawdown_pct']:.1f}%** |")
        out_md.append(f"\n*Profitable Windows in Group: **$100 Account: {a100['profitable_windows']}/4** ({a100['profitable_windows']/4*100:.0f}%) | **$20 Account: {a20['profitable_windows']}/4** ({a20['profitable_windows']/4*100:.0f}%)*\n")
    out_md.append("---\n")

md_content = "\n".join(out_md)
with open(r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\GROUPED_WINDOW_STATISTICS.md", "w", encoding="utf-8") as f:
    f.write(md_content)

print("Exported markdown grouped statistics to: d:\\Projects\\AUTOMATIONS\\TRADING\\Youtube-Traders\\GROUPED_WINDOW_STATISTICS.md")
