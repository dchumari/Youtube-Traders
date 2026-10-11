import json

with open('strategies/Institutional_SMC_ICT_Suite/backtest_results/CONFLUENCE_MATRIX_20_AND_100_RESULTS.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for tier, models in data.items():
    print(f"\n==================== {tier} ====================")
    for mid, mdata in models.items():
        score = mdata["pass_count"]
        status = mdata["overall_status"]
        name = mdata["name"]
        w_strs = []
        tot_pnl = 0.0
        for w in mdata["windows"]:
            lbl = w["window_label"][:2]
            pnl = w["net_profit"]
            roi = w["roi_pct"]
            tot_pnl += pnl
            w_strs.append(f"{lbl}: ${pnl:>+6.2f} ({roi:>+6.1f}%)")
        print(f"{mid:8} [{score}/4 {status:15}] Tot: ${tot_pnl:>+6.2f} | " + " | ".join(w_strs))
