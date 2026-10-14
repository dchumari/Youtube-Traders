import test_inverted_models_screening as tims

print('=== TESTING INVERTED MODEL 5 ON $20 ACCOUNT (2,000 USC CENT TIER) ===', flush=True)

# On Cent account ($20 deposit = 2000.0 USC)
# 1 USC = $0.01 USD.
# If base lot is 0.01, lot per ticket is 0.01 (3 x 0.01 = 0.03 total lot).
# Tier step = 20.0 USD = 2000.0 USC.
for dep, is_cent, tier_s in [(2000.0, True, 2000.0), (20.0, False, 20.0)]:
    label = "$20 Cent Account (2,000 USC)" if is_cent else "$20 Standard Account ($20 USD)"
    print(f"\n==================== {label} ====================", flush=True)
    tot = 0.0
    p_cnt = 0
    for w_name, (w_from, w_to) in tims.windows.items():
        clean_date = w_from.replace('.', '')
        t_id = f'test_20_{"cent" if is_cent else "usd"}_{clean_date}'
        tickets_cnt = 3 if is_cent else 1
        res = tims.run_test(t_id, 'XAUUSD', w_from, w_to, dep, 5, tickets=tickets_cnt, base_lot=0.01, tier_step=tier_s, sl=150, tp1=150, tp2=350, tp3=700)
        if res:
            p = res['profit']
            # Convert cent profit back to USD for fair comparison
            usd_profit = p / 100.0 if is_cent else p
            tot += usd_profit
            if p > 0: p_cnt += 1
            status = "WIN" if p > 0 else "LOSS"
            print(f'  {w_name}: Net=${usd_profit:+.2f} ({p:+.2f} {"USC" if is_cent else "USD"}) | Trades={res["trades"]} | WR={res["win_pct"]:.1f}% | PF={res["pf"]:.2f} | DD=${res["dd"] / (100.0 if is_cent else 1.0):.2f} | {status}', flush=True)
        else:
            print(f'  {w_name}: No rep', flush=True)
    print(f'  >> {label} CUMULATIVE: Net=${tot:+.2f} | PASS RATE: {p_cnt}/4', flush=True)
