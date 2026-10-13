import os
import sys
sys.path.append(os.path.dirname(__file__))
from benchmark_smc_daily_sniper import run_single_test, parse_preset, PRESET_DIR

p_100_sprint = os.path.join(PRESET_DIR, 'SMCD_Daily_Sprint_Doubler_100USD.set')
base_inputs = parse_preset(p_100_sprint)

models = {
    0: 'Model 0 (Trendline Liquidity Trap)',
    1: 'Model 1 (SMC Inducement IDM OB)',
    2: 'Model 2 (Fresh S&D Base Flip)',
    3: 'Model 3 (Asian Sweep Continuation)',
    4: 'Model 4 (Master All Confluence)'
}

for m_id, m_name in models.items():
    inp = dict(base_inputs)
    inp['InpCoreModel'] = str(m_id)
    res = run_single_test(f'test_m{m_id}', '2024.03.04', '2024.03.11', 100.0, 400, inp, timeout_sec=40)
    print(f"{m_name}: Net=${res['net_profit']:+.2f} ({res['roi_pct']:+.1f}%) | WR: {res['win_rate']}% | PF: {res['profit_factor']} | DD: {res['max_dd_pct']}% | Trades: {res['trades']}")
