import test_inverted_models_screening as tims

print('=== TESTING TP1=15p, TP2=35p, TP3=70p WITH 3 TICKETS (0.01 BASE LOT) ===', flush=True)

models = {
    "Model 5 (Quasimodo Head Breakout Squeeze)": 5,
    "Model 9 (Hybrid QM + Bank ORB)": 9
}

# Test different TP1 values: 150 pts (15p) vs 200 pts (20p)
for tp1_val in [150, 200]:
    tp2_val = 350 if tp1_val == 150 else 400
    tp3_val = 700
    sl_val = tp1_val
    print(f"\n================ CONFIG: SL={sl_val/10}p, TP1={tp1_val/10}p, TP2={tp2_val/10}p, TP3={tp3_val/10}p ================", flush=True)
    
    for m_label, m_id in models.items():
        print(f"\n--- {m_label} ($100 Deposit, 3 Tickets) ---", flush=True)
        tot = 0.0
        p_cnt = 0
        for w_name, (w_from, w_to) in tims.windows.items():
            clean_date = w_from.replace('.', '')
            t_id = f'test_tp{tp1_val}_m{m_id}_{clean_date}'
            res = tims.run_test(t_id, 'XAUUSD', w_from, w_to, 100.0, m_id, tickets=3, base_lot=0.01, tier_step=50.0, sl=sl_val, tp1=tp1_val, tp2=tp2_val, tp3=tp3_val)
            if res:
                p = res['profit']
                tot += p
                if p > 0: p_cnt += 1
                status = "WIN" if p > 0 else "LOSS"
                print(f'  {w_name}: Net=${p:+.2f} | Trades={res["trades"]} | WR={res["win_pct"]:.1f}% | PF={res["pf"]:.2f} | DD=${res["dd"]:.2f} | {status}', flush=True)
            else:
                print(f'  {w_name}: No rep', flush=True)
        print(f'  >> {m_label} (TP1={tp1_val/10}p) CUMULATIVE: Net=${tot:+.2f} | PASS RATE: {p_cnt}/4', flush=True)
