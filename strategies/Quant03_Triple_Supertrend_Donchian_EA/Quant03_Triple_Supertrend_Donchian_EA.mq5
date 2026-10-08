//+------------------------------------------------------------------+
//|                     Quant03_Triple_Supertrend_Donchian_EA.mq5    |
//|               Archetype: Multi-Timeframe Trend Continuation      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 24.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 7.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Trend & Donchian Breakout Parameters ==="
input int      InpH1EMAPeriod          = 100;    // Macro Regime Filter EMA
input int      InpDonchianPeriod       = 16;     // Donchian Breakout Period
input int      InpADXPeriod            = 14;     // ADX Trend Filter Period
input double   InpMinADX               = 22.0;   // Minimum ADX Threshold
input int      InpTradeStartHour       = 7;      // Trade Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 18;     // Trade End Hour (18:00 UTC)
input ulong    InpMagicNumber          = 202603; // Magic Number

CQuantTrade    quant;
int            ema_handle;
int            adx_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   ema_handle = iMA(_Symbol, PERIOD_H1, InpH1EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   adx_handle = iADX(_Symbol, _Period, InpADXPeriod);
   if(ema_handle == INVALID_HANDLE || adx_handle == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(ema_handle);
   IndicatorRelease(adx_handle);
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

   double adx_val[]; ArraySetAsSeries(adx_val, true);
   if(CopyBuffer(adx_handle, 0, 1, 2, adx_val) < 2) return;
   if(adx_val[0] < InpMinADX) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 1, InpDonchianPeriod + 2, rates);
   if(copied < InpDonchianPeriod + 2) return;

   double donchian_high = rates[1].high;
   double donchian_low  = rates[1].low;
   for(int i = 2; i <= InpDonchianPeriod; i++)
   {
      if(rates[i].high > donchian_high) donchian_high = rates[i].high;
      if(rates[i].low < donchian_low)   donchian_low  = rates[i].low;
   }

   // Bullish Breakout above Donchian High + Trend above H1 EMA
   if(rates[0].close > donchian_high && rates[0].close > ema_val[0])
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q03_Donchian_Buy"))
         daily_trades++;
      return;
   }

   // Bearish Breakdown below Donchian Low + Trend below H1 EMA
   if(rates[0].close < donchian_low && rates[0].close < ema_val[0])
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q03_Donchian_Sell"))
         daily_trades++;
      return;
   }
}
