//+------------------------------------------------------------------+
//|                          Quant05_Turtle_ATR_Breakout_EA.mq5      |
//|               Archetype: Multi-Timeframe Trend Continuation      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 12.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 28.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 8.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 2.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 12.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 3.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Turtle Breakout & ATR Regime Parameters ==="
input int      InpChannelPeriod        = 20;     // Donchian Breakout Channel Length
input int      InpH1EMAPeriod          = 100;    // Trend Baseline Filter
input int      InpTradeStartHour       = 6;      // Session Start Hour (06:00 UTC)
input int      InpTradeEndHour         = 19;     // Session End Hour (19:00 UTC)
input ulong    InpMagicNumber          = 202605; // Magic Number

CQuantTrade    quant;
int            ema_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   ema_handle = iMA(_Symbol, _Period, InpH1EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(ema_handle == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(ema_handle);
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

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double ema_val[]; ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   int rates_copied = CopyRates(_Symbol, _Period, 1, InpChannelPeriod + 2, rates);
   if(rates_copied < InpChannelPeriod + 2) return;

   double ch_high = rates[1].high;
   double ch_low  = rates[1].low;
   for(int i = 2; i <= InpChannelPeriod; i++)
   {
      if(rates[i].high > ch_high) ch_high = rates[i].high;
      if(rates[i].low < ch_low)   ch_low  = rates[i].low;
   }

   // Turtle Long Breakout above channel high and above EMA
   if(rates[0].close > ch_high && rates[0].close > ema_val[0])
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q05_Turtle_Buy"))
         daily_trades++;
      return;
   }

   // Turtle Short Breakdown below channel low and below EMA
   if(rates[0].close < ch_low && rates[0].close < ema_val[0])
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q05_Turtle_Sell"))
         daily_trades++;
      return;
   }
}
