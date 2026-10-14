import test_inverted_models_screening as tims

print('=== TESTING MODEL 5 & 9 WITH MARGIN-CALIBRATED LOT SIZING (0.01 BASE LOT) ===', flush=True)

models = {
    "Model 5 (Quasimodo Head Breakout Squeeze)": 5,
    "Model 9 (Hybrid QM + Bank ORB)": 9
}

for m_label, m_id in models.items():
    print(f"\n--- {m_label} ($100 Deposit, 2 Tickets: TP1=20p, TP2=50p) ---", flush=True)
    tot = 0.0
    p_cnt = 0
    for w_name, (w_from, w_to) in tims.windows.items():
        clean_date = w_from.replace('.', '')
        t_id = f'test_fix_m{m_id}_{clean_date}'
        # Using 2 tickets of 0.01 base lot (compounding to 0.02 on $100)
        res = tims.run_test(t_id, 'XAUUSD', w_from, w_to, 100.0, m_id, tickets=2, base_lot=0.01, tier_step=50.0, sl=200, tp1=200, tp2=500, tp3=800)
        if res:
            p = res['profit']
            tot += p
            if p > 0: p_cnt += 1
            print(f'  {w_name}: Net=${p:+.2f} | Trades={res["trades"]} | WR={res["win_pct"]:.1f}% | PF={res["pf"]:.2f} | DD=${res["dd"]:.2f}', flush=True)
        else:
            print(f'  {w_name}: No rep', flush=True)
    print(f'  >> {m_label} CUMULATIVE: Net=${tot:+.2f} | PASS RATE: {p_cnt}/4', flush=True)
