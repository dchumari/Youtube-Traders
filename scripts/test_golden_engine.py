import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from tester_runner import run_tester, compile_ea, DATA_FOLDER, WINDOWS

code_golden = """//+------------------------------------------------------------------+
//|                                     Quant_Golden_Sniper.mq5      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 8.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 20.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 5.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 9.0;    // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Institutional Setup Parameters ==="
input int      InpFastEMA              = 13;     // Momentum Fast EMA
input int      InpSlowEMA              = 34;     // Trend Slow EMA
input int      InpMacroEMA             = 100;    // H1 Regime Filter EMA
input int      InpSessionStartHour     = 7;      // Killzone Start (07:00 UTC)
input int      InpSessionEndHour       = 17;     // Killzone End (17:00 UTC)
input ulong    InpMagicNumber          = 202655; // Magic Number

CQuantTrade    quant;
int            fast_h, slow_h, macro_h;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   fast_h  = iMA(_Symbol, _Period, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   slow_h  = iMA(_Symbol, _Period, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   macro_h = iMA(_Symbol, PERIOD_H1, InpMacroEMA, 0, MODE_EMA, PRICE_CLOSE);

   if(fast_h == INVALID_HANDLE || slow_h == INVALID_HANDLE || macro_h == INVALID_HANDLE)
      return INIT_FAILED;

   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(fast_h);
   IndicatorRelease(slow_h);
   IndicatorRelease(macro_h);
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven || InpUseTrailing)
   {
      quant.ManageBreakevenAndTrailing(
         InpUseBreakeven ? InpBreakevenTriggerPips * pip_mult : 0,
         InpUseBreakeven ? InpBreakevenLockPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingStepPips * pip_mult : 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   if(!CQuantTrade::IsInHourWindow(InpSessionStartHour, InpSessionEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double f_val[3], s_val[3], m_val[2];
   ArraySetAsSeries(f_val, true); ArraySetAsSeries(s_val, true); ArraySetAsSeries(m_val, true);

   if(CopyBuffer(fast_h, 0, 1, 3, f_val) < 3) return;
   if(CopyBuffer(slow_h, 0, 1, 3, s_val) < 3) return;
   if(CopyBuffer(macro_h, 0, 1, 2, m_val) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   // Bullish Expansion:
   // 1. H1 Macro Bullish: Close > H1 100 EMA
   // 2. M15 Fast EMA crosses above Slow EMA or expands upwards
   // 3. Rejection candle off the Slow EMA (Low <= Slow EMA, Close > Fast EMA)
   if(rates[0].close > m_val[0] && f_val[0] > s_val[0])
   {
      bool cross_up = (f_val[1] <= s_val[1] && f_val[0] > s_val[0]);
      bool bounce_up = (rates[0].low <= s_val[0] && rates[0].close > f_val[0]);
      if(cross_up || bounce_up)
      {
         if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Golden_Buy"))
            daily_trades++;
         return;
      }
   }

   // Bearish Expansion:
   if(rates[0].close < m_val[0] && f_val[0] < s_val[0])
   {
      bool cross_down = (f_val[1] >= s_val[1] && f_val[0] < s_val[0]);
      bool bounce_down = (rates[0].high >= s_val[0] && rates[0].close < f_val[0]);
      if(cross_down || bounce_down)
      {
         if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Golden_Sell"))
            daily_trades++;
         return;
      }
   }
}
"""

target = os.path.join(DATA_FOLDER, "MQL5", "Experts", "Quant10", "Quant_Golden_Sniper.mq5")
with open(target, "w", encoding="utf-8") as f:
    f.write(code_golden)

ok, log, ex5 = compile_ea("Quant10\\Quant_Golden_Sniper.mq5")
print(f"Compilation: {ok}")

tot_net = 0
wins = 0
for wid, w in WINDOWS.items():
    res = run_tester("Quant10\\Quant_Golden_Sniper", "EURUSD", "M15", w["from"], w["to"], deposit=100.0)
    net = res.get('net_profit', 0.0)
    pf = res.get('profit_factor', 0.0)
    dd = res.get('drawdown_pct', 0.0)
    tr = res.get('total_trades', 0)
    tot_net += net
    if net > 0: wins += 1
    print(f"[{wid}] {w['name'][:30]:<30} | Trades={tr:<3} | Net=${net:<6.2f} | PF={pf:<4.2f} | DD={dd:<4.2f}%")

print(f"\nSummary: Total Net=${tot_net:.2f} | Win Windows={wins}/16")
