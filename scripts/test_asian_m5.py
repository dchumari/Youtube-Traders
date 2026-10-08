import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from tester_runner import run_tester, compile_ea, DATA_FOLDER, WINDOWS

code_m5_asian = """//+------------------------------------------------------------------+
//|                                   Quant_Asian_M5_Sniper.mq5      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 12.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 8.0;    // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 5.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input int      InpMaxDailyTrades       = 3;      // Max Trades per Day

input group "=== Asian Scalper Parameters ==="
input int      InpBBPeriod             = 20;     // Bollinger Bands Period
input double   InpBBDeviation          = 2.2;    // Bollinger Bands Deviation
input int      InpRSIPeriod            = 7;      // Fast RSI Period
input double   InpRSIOverbought        = 75.0;   // RSI Overbought Level
input double   InpRSIOversold          = 25.0;   // RSI Oversold Level
input int      InpAsianStartHour       = 22;     // Asian Session Start (22:00 UTC)
input int      InpAsianEndHour         = 5;      // Asian Session End (05:00 UTC)
input ulong    InpMagicNumber          = 202688; // Magic Number

CQuantTrade    quant;
int            bb_h, rsi_h;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   bb_h  = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   rsi_h = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   if(bb_h == INVALID_HANDLE || rsi_h == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(bb_h);
   IndicatorRelease(rsi_h);
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven)
   {
      quant.ManageBreakevenAndTrailing(
         InpBreakevenTriggerPips * pip_mult,
         InpBreakevenLockPips * pip_mult,
         0, 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   if(!CQuantTrade::IsInHourWindow(InpAsianStartHour, InpAsianEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double bb_up[2], bb_low[2], bb_mid[2], rsi[2];
   ArraySetAsSeries(bb_up, true); ArraySetAsSeries(bb_low, true); ArraySetAsSeries(bb_mid, true);
   ArraySetAsSeries(rsi, true);

   if(CopyBuffer(bb_h, 1, 1, 2, bb_up) < 2) return;
   if(CopyBuffer(bb_h, 2, 1, 2, bb_low) < 2) return;
   if(CopyBuffer(bb_h, 0, 1, 2, bb_mid) < 2) return;
   if(CopyBuffer(rsi_h, 0, 1, 2, rsi) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 2, rates) < 2) return;

   // Buy: Low pierced lower band & RSI oversold & close turned bullish
   if(rates[0].low <= bb_low[0] && rsi[0] <= InpRSIOversold && rates[0].close > rates[0].open)
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Asian_Buy"))
         daily_trades++;
      return;
   }

   // Sell: High pierced upper band & RSI overbought & close turned bearish
   if(rates[0].high >= bb_up[0] && rsi[0] >= InpRSIOverbought && rates[0].close < rates[0].open)
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Asian_Sell"))
         daily_trades++;
      return;
   }
}
"""

target = os.path.join(DATA_FOLDER, "MQL5", "Experts", "Quant10", "Quant_Asian_M5_Sniper.mq5")
with open(target, "w", encoding="utf-8") as f:
    f.write(code_m5_asian)

ok, log, ex5 = compile_ea("Quant10\\Quant_Asian_M5_Sniper.mq5")
print(f"Compilation: {ok}")

windows = ["W1", "W2", "W3", "W4", "M1", "M2", "M3", "M4", "Q1", "Q2", "Q3", "Q4", "Y2", "Y3"]
tot_net = 0
wins = 0
for wid in windows:
    w = WINDOWS[wid]
    res = run_tester("Quant10\\Quant_Asian_M5_Sniper", "EURUSD", "M5", w["from"], w["to"], deposit=100.0)
    net = res.get('net_profit', 0.0)
    pf = res.get('profit_factor', 0.0)
    dd = res.get('drawdown_pct', 0.0)
    tr = res.get('total_trades', 0)
    tot_net += net
    if net > 0: wins += 1
    print(f"[{wid}] Trades={tr:<3} | Net=${net:<6.2f} | PF={pf:<4.2f} | DD={dd:<4.2f}%")

print(f"\nSummary: Total Net=${tot_net:.2f} | Win Windows={wins}/{len(windows)}")
