import json

d = json.load(open('d:/Projects/AUTOMATIONS/TRADING/Youtube-Traders/GROUPED_WINDOW_STATISTICS.json', 'r', encoding='utf-8'))

for gname, gdata in d.items():
    print("=" * 115)
    print(f" {gname.upper()} ")
    print(f" Description: {gdata['desc']}")
    print("=" * 115)
    
    for skey, sdata in gdata['strategies'].items():
        print(f"\n>> {sdata['name']}")
        print(f"   {'Window':8s} | {'$100 Net':9s} {'PF':5s} {'DD%':6s} {'Win%':5s} {'Tr':4s} | {'$20 Net':9s} {'Return%':8s} {'PF':5s} {'DD%':6s} {'Win%':5s} {'Tr':4s}")
        print("   " + "-" * 88)
        
        for w, wdata in sdata['windows'].items():
            r100 = wdata['account_100']
            r20 = wdata['account_20']
            print(f"   {w:8s} | ${r100['net_profit']:+7.2f} {r100['profit_factor']:5.2f} {r100['drawdown_pct']:5.1f}% {r100['win_rate_pct']:4.0f}% {r100['trades']:3d}  | ${r20['net_profit']:+7.2f} {r20['return_pct']:+7.1f}% {r20['profit_factor']:5.2f} {r20['drawdown_pct']:5.1f}% {r20['win_rate_pct']:4.0f}% {r20['trades']:3d}")
            
        a100 = sdata['aggregate_100']
        a20 = sdata['aggregate_20']
        print("   " + "-" * 88)
        print(f"   TOTAL    | ${a100['net_profit']:+7.2f} {a100['combined_pf']:5.2f} {a100['max_drawdown_pct']:5.1f}% {a100['overall_win_rate']:4.0f}% {a100['total_trades']:3d}  | ${a20['net_profit']:+7.2f} {a20['total_return_pct']:+7.1f}% {a20['combined_pf']:5.2f} {a20['max_drawdown_pct']:5.1f}% {a20['overall_win_rate']:4.0f}% {a20['total_trades']:3d}")
        print(f"   Windows Profitable: $100 -> {a100['profitable_windows']}/4 | $20 -> {a20['profitable_windows']}/4")
    print("\n")
