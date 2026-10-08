//+------------------------------------------------------------------+
//|                         Quant04_EMA_Ribbon_Pullback_EA.mq5       |
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

input group "=== Ribbon & Oscillator Pullback Parameters ==="
input int      InpFastEMA              = 8;      // Fast Ribbon EMA
input int      InpMedEMA               = 21;     // Medium Ribbon EMA
input int      InpSlowEMA              = 55;     // Slow Ribbon EMA
input int      InpH1TrendEMA           = 100;    // H1 Trend Filter EMA
input int      InpTradeStartHour       = 6;      // Session Start Hour (06:00 UTC)
input int      InpTradeEndHour         = 18;     // Session End Hour (18:00 UTC)
input ulong    InpMagicNumber          = 202604; // Magic Number

CQuantTrade    quant;
int            fast_ema_h, med_ema_h, slow_ema_h, h1_ema_h;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   fast_ema_h = iMA(_Symbol, _Period, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   med_ema_h  = iMA(_Symbol, _Period, InpMedEMA,  0, MODE_EMA, PRICE_CLOSE);
   slow_ema_h = iMA(_Symbol, _Period, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   h1_ema_h   = iMA(_Symbol, PERIOD_H1, InpH1TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   
   if(fast_ema_h == INVALID_HANDLE || med_ema_h == INVALID_HANDLE || slow_ema_h == INVALID_HANDLE || h1_ema_h == INVALID_HANDLE)
      return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(fast_ema_h);
   IndicatorRelease(med_ema_h);
   IndicatorRelease(slow_ema_h);
   IndicatorRelease(h1_ema_h);
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

   double f_ema[], m_ema[], s_ema[], h1_ema[];
   ArraySetAsSeries(f_ema, true); ArraySetAsSeries(m_ema, true); ArraySetAsSeries(s_ema, true); ArraySetAsSeries(h1_ema, true);
   if(CopyBuffer(fast_ema_h, 0, 1, 2, f_ema) < 2) return;
   if(CopyBuffer(med_ema_h, 0, 1, 2, m_ema) < 2) return;
   if(CopyBuffer(slow_ema_h, 0, 1, 2, s_ema) < 2) return;
   if(CopyBuffer(h1_ema_h, 0, 1, 2, h1_ema) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   bool ribbon_bull = (f_ema[0] > m_ema[0] && m_ema[0] > s_ema[0] && rates[0].close > h1_ema[0]);
   bool ribbon_bear = (f_ema[0] < m_ema[0] && m_ema[0] < s_ema[0] && rates[0].close < h1_ema[0]);

   // Bullish Pullback: low touched med EMA, closed back above fast EMA
   if(ribbon_bull && rates[0].low <= m_ema[0] && rates[0].close > f_ema[0])
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q04_Ribbon_Buy"))
         daily_trades++;
      return;
   }

   // Bearish Pullback: high touched med EMA, closed back below fast EMA
   if(ribbon_bear && rates[0].high >= m_ema[0] && rates[0].close < f_ema[0])
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q04_Ribbon_Sell"))
         daily_trades++;
      return;
   }
}
