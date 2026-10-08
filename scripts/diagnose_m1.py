import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from tester_runner import run_tester
from run_matrix_validation import STRATEGIES_TO_EVALUATE

print("Running M1 Diagnostic across all 10 strategies...")
for s in STRATEGIES_TO_EVALUATE:
    ea = f"Quant10\\{s['name']}"
    res = run_tester(ea, s['symbol'], s['period'], '2024.01.01', '2024.01.31', deposit=100.0)
    print(f"{s['id']} | {s['name'][:30]:<30} | Sym={s['symbol']} | Trades={res.get('total_trades', 0):<3} | Net=${res.get('net_profit', 0.0):<6.2f} | PF={res.get('profit_factor', 0.0):<4.2f} | DD={res.get('drawdown_pct', 0.0):<4.2f}%")
