import json

master_file = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\ALL_MRPFX_STRATEGIES_16_WINDOWS_RESULTS.json"
with open(master_file, "r", encoding="utf-8") as f:
    d = json.load(f)

groups = {
    "Group 1: 1-Week Volatility Stress Windows": {
        "keys": ["W1", "W2", "W3", "W4"],
        "desc": "High-frequency macro event shocks (NFP, CPI/FOMC, Carry Unwind, US Election)"
    },
    "Group 2: 1-Month Regimes": {
        "keys": ["M1", "M2", "M3", "M4"],
        "desc": "Single-month seasonal transitions (Jan Opening, Apr Expansion, Jul Chop, Oct Momentum)"
    },
    "Group 3: Multi-Month / Quarterly Cycles": {
        "keys": ["Q1", "Q2", "Q3", "Q4"],
        "desc": "3-Month economic macro cycles throughout 2023"
    },
    "Group 4: 1-Year Macro Cycles": {
        "keys": ["Y1", "Y2", "Y3", "Y4"],
        "desc": "Annual full-cycle stress testing (2022 Hikes, 2023 Disinflation, 2024 Easing, 2025 Transition)"
    }
}

output = {}

for gname, ginfo in groups.items():
    output[gname] = {"desc": ginfo["desc"], "strategies": {}}
    for strat, data in d.items():
        sname = data.get("info", {}).get("name", strat)
        
        stat_entry = {
            "name": sname,
            "windows": {},
            "aggregate_100": {
                "net_profit": 0.0,
                "gross_profit": 0.0,
                "gross_loss": 0.0,
                "total_trades": 0,
                "winning_trades": 0,
                "max_drawdown_pct": 0.0,
                "profitable_windows": 0
            },
            "aggregate_20": {
                "net_profit": 0.0,
                "gross_profit": 0.0,
                "gross_loss": 0.0,
                "total_trades": 0,
                "winning_trades": 0,
                "max_drawdown_pct": 0.0,
                "profitable_windows": 0
            }
        }
        
        for w in ginfo["keys"]:
            r100 = data["account_100"].get(w, {})
            r20 = data["account_20"].get(w, {})
            
            p100 = r100.get("net_profit", 0.0)
            gp100 = r100.get("gross_profit", 0.0)
            gl100 = abs(r100.get("gross_loss", 0.0))
            pf100 = r100.get("profit_factor", 0.0)
            dd100 = r100.get("drawdown_pct", 0.0)
            wr100 = r100.get("win_rate_pct", 0.0)
            tr100 = r100.get("total_trades", 0)
            
            p20 = r20.get("net_profit", 0.0)
            gp20 = r20.get("gross_profit", 0.0)
            gl20 = abs(r20.get("gross_loss", 0.0))
            pf20 = r20.get("profit_factor", 0.0)
            dd20 = r20.get("drawdown_pct", 0.0)
            wr20 = r20.get("win_rate_pct", 0.0)
            tr20 = r20.get("total_trades", 0)
            ret20 = (p20 / 20.0) * 100.0
            
            stat_entry["windows"][w] = {
                "account_100": {
                    "net_profit": p100,
                    "profit_factor": pf100,
                    "drawdown_pct": dd100,
                    "win_rate_pct": wr100,
                    "trades": tr100
                },
                "account_20": {
                    "net_profit": p20,
                    "return_pct": ret20,
                    "profit_factor": pf20,
                    "drawdown_pct": dd20,
                    "win_rate_pct": wr20,
                    "trades": tr20
                }
            }
            
            # Aggregate 100
            stat_entry["aggregate_100"]["net_profit"] += p100
            stat_entry["aggregate_100"]["gross_profit"] += gp100
            stat_entry["aggregate_100"]["gross_loss"] += gl100
            stat_entry["aggregate_100"]["total_trades"] += tr100
            stat_entry["aggregate_100"]["winning_trades"] += int(round(tr100 * (wr100 / 100.0)))
            if p100 > 0: stat_entry["aggregate_100"]["profitable_windows"] += 1
            if dd100 > stat_entry["aggregate_100"]["max_drawdown_pct"]:
                stat_entry["aggregate_100"]["max_drawdown_pct"] = dd100
                
            # Aggregate 20
            stat_entry["aggregate_20"]["net_profit"] += p20
            stat_entry["aggregate_20"]["gross_profit"] += gp20
            stat_entry["aggregate_20"]["gross_loss"] += gl20
            stat_entry["aggregate_20"]["total_trades"] += tr20
            stat_entry["aggregate_20"]["winning_trades"] += int(round(tr20 * (wr20 / 100.0)))
            if p20 > 0: stat_entry["aggregate_20"]["profitable_windows"] += 1
            if dd20 > stat_entry["aggregate_20"]["max_drawdown_pct"]:
                stat_entry["aggregate_20"]["max_drawdown_pct"] = dd20

        # Compute combined PF & WR
        gl100_val = stat_entry["aggregate_100"]["gross_loss"]
        gp100_val = stat_entry["aggregate_100"]["gross_profit"]
        stat_entry["aggregate_100"]["combined_pf"] = round(gp100_val / gl100_val, 2) if gl100_val > 0 else (99.0 if gp100_val > 0 else 0.0)
        tr100_tot = stat_entry["aggregate_100"]["total_trades"]
        stat_entry["aggregate_100"]["overall_win_rate"] = round((stat_entry["aggregate_100"]["winning_trades"] / tr100_tot) * 100.0, 1) if tr100_tot > 0 else 0.0
        stat_entry["aggregate_100"]["net_profit"] = round(stat_entry["aggregate_100"]["net_profit"], 2)

        gl20_val = stat_entry["aggregate_20"]["gross_loss"]
        gp20_val = stat_entry["aggregate_20"]["gross_profit"]
        stat_entry["aggregate_20"]["combined_pf"] = round(gp20_val / gl20_val, 2) if gl20_val > 0 else (99.0 if gp20_val > 0 else 0.0)
        tr20_tot = stat_entry["aggregate_20"]["total_trades"]
        stat_entry["aggregate_20"]["overall_win_rate"] = round((stat_entry["aggregate_20"]["winning_trades"] / tr20_tot) * 100.0, 1) if tr20_tot > 0 else 0.0
        stat_entry["aggregate_20"]["net_profit"] = round(stat_entry["aggregate_20"]["net_profit"], 2)
        stat_entry["aggregate_20"]["total_return_pct"] = round((stat_entry["aggregate_20"]["net_profit"] / 20.0) * 100.0, 1)

        output[gname]["strategies"][strat] = stat_entry

out_json = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\GROUPED_WINDOW_STATISTICS.json"
with open(out_json, "w", encoding="utf-8") as f:
    json.dump(output, f, indent=2)

print("Grouped statistics computed and saved to:", out_json)
