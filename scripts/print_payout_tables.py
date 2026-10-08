import re
from datetime import datetime
from collections import defaultdict

html = open(r"d:\MT5_Tester\ytd_run_rep.htm", "r", encoding="utf-16", errors="ignore").read()
p = html.find("<b>Deals</b>")
deals_html = html[p:]

pattern = r"<tr[^>]*>\s*<td>(\d{4}\.\d{2}\.\d{2}\s+\d{2}:\d{2}:\d{2})</td><td>(\d+)</td><td>([^<]*)</td><td>([^<]*)</td><td>([^<]*)</td><td>([^<]*)</td><td>([^<]*)</td><td>([^<]*)</td><td>([^<]*)</td><td>([^<]*)</td><td>([^<]*)</td><td>([^<]*)</td><td>([^<]*)</td></tr>"

deals = []
for m in re.finditer(pattern, deals_html):
    dt_str = m.group(1).strip()
    deal_type = m.group(4).strip().lower()
    direction = m.group(5).strip().lower()
    profit_str = m.group(11).strip().replace(" ", "")
    bal_str = m.group(12).strip().replace(" ", "")
    try:
        profit = float(profit_str) if profit_str else 0.0
        bal = float(bal_str) if bal_str else 0.0
    except:
        continue
    
    if deal_type == "balance": continue
    dt = datetime.strptime(dt_str, "%Y.%m.%d %H:%M:%S")
    if direction == "out":
        deals.append({"dt": dt, "profit": profit, "balance": bal})

print(f"Total Closed Deals: {len(deals)}")

# 1. Monthly Aggregation
monthly_pnl = defaultdict(float)
monthly_trades = defaultdict(int)
for d in deals:
    m_key = d["dt"].strftime("%Y-%m")
    monthly_pnl[m_key] += d["profit"]
    monthly_trades[m_key] += 1

print("\n" + "="*70)
print("MONTHLY BREAKDOWN & MONTHLY PAYOUT SCHEDULE ($100 Starting Capital)")
print("="*70)
print(f"{'Month':<12} | {'Trades':<6} | {'Net PnL':<10} | {'Cum Profit':<12} | {'Payout ($)':<12} | {'Holding Capital':<15}")
print("-"*70)

# Monthly payout logic:
# At the end of each month, if monthly profit > 0, withdraw the profit (payout) to bank, keeping capital at $100.
# If monthly profit < 0, capital absorbs the loss, and payouts pause until recovered.
held_payouts_monthly = 0.0
active_capital_monthly = 100.0

for m in sorted(monthly_pnl.keys()):
    pnl = monthly_pnl[m]
    nt = monthly_trades[m]
    active_capital_monthly += pnl
    payout = 0.0
    if active_capital_monthly > 100.0:
        payout = active_capital_monthly - 100.0
        held_payouts_monthly += payout
        active_capital_monthly = 100.0
    
    print(f"{m:<12} | {nt:<6} | ${pnl:>+8.2f} | ${sum(monthly_pnl[k] for k in sorted(monthly_pnl.keys()) if k <= m):>+10.2f} | ${payout:>10.2f} | ${active_capital_monthly:>13.2f}")

print("-"*70)
print(f"Total Withdrawn to Pocket (Monthly Payouts): ${held_payouts_monthly:.2f}")
print(f"Active Trading Capital Remaining:          ${active_capital_monthly:.2f}")
print(f"Total Wealth (Withdrawn + Active):          ${held_payouts_monthly + active_capital_monthly:.2f}")

# 2. Weekly Aggregation
weekly_pnl = defaultdict(float)
weekly_trades = defaultdict(int)
for d in deals:
    iso_year, iso_week, _ = d["dt"].isocalendar()
    w_key = f"{iso_year}-W{iso_week:02d}"
    weekly_pnl[w_key] += d["profit"]
    weekly_trades[w_key] += 1

held_payouts_weekly = 0.0
active_capital_weekly = 100.0
profitable_weeks = 0
total_weeks = len(weekly_pnl)

for w in sorted(weekly_pnl.keys()):
    pnl = weekly_pnl[w]
    if pnl > 0: profitable_weeks += 1
    active_capital_weekly += pnl
    payout = 0.0
    if active_capital_weekly > 100.0:
        payout = active_capital_weekly - 100.0
        held_payouts_weekly += payout
        active_capital_weekly = 100.0

# 3. Bi-Weekly Aggregation
biweekly_pnl = defaultdict(float)
for d in deals:
    iso_year, iso_week, _ = d["dt"].isocalendar()
    bw_key = f"{iso_year}-BW{(iso_week+1)//2:02d}"
    biweekly_pnl[bw_key] += d["profit"]

held_payouts_bw = 0.0
active_capital_bw = 100.0
for bw in sorted(biweekly_pnl.keys()):
    pnl = biweekly_pnl[bw]
    active_capital_bw += pnl
    payout = 0.0
    if active_capital_bw > 100.0:
        payout = active_capital_bw - 100.0
        held_payouts_bw += payout
        active_capital_bw = 100.0

print("\n" + "="*70)
print("PAYOUT COMPARISON TABLE ($100 Starting Capital - Jan 1 to Oct 8)")
print("="*70)
print(f"{'Payout Frequency':<20} | {'Total Withdrawn (In Pocket)':<30} | {'Active Capital':<15} | {'Total Wealth':<12}")
print("-"*70)
print(f"{'Weekly Payouts':<20} | ${held_payouts_weekly:>28.2f} | ${active_capital_weekly:>13.2f} | ${held_payouts_weekly + active_capital_weekly:>10.2f}")
print(f"{'Bi-Weekly Payouts':<20} | ${held_payouts_bw:>28.2f} | ${active_capital_bw:>13.2f} | ${held_payouts_bw + active_capital_bw:>10.2f}")
print(f"{'Monthly Payouts':<20} | ${held_payouts_monthly:>28.2f} | ${active_capital_monthly:>13.2f} | ${held_payouts_monthly + active_capital_monthly:>10.2f}")
print(f"{'No Payout (Compounding)':<20} | ${0.0:>28.2f} | ${100.0 + sum(monthly_pnl.values()):>13.2f} | ${100.0 + sum(monthly_pnl.values()):>10.2f}")
print("="*70)
