//+------------------------------------------------------------------+
//|                                        Quant_Benchmark_Engine.mq5|
//|               Institutional Trend Pullback & Volatility Model    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 9.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 20.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 6.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)

input group "=== Trend & Pullback Core ==="
input int      InpH1FastEMA            = 20;     // H1 Fast Trend EMA
input int      InpH1SlowEMA            = 50;     // H1 Slow Trend EMA
input int      InpM15FastEMA           = 10;     // M15 Value EMA Fast
input int      InpM15SlowEMA           = 25;     // M15 Value EMA Slow
input int      InpRSIPeriod            = 9;      // RSI Momentum Period
input int      InpTradeStartHour       = 7;      // Killzone Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 17;     // Killzone End Hour (17:00 UTC)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day
input ulong    InpMagicNumber          = 202699; // Magic Number

CQuantTrade    quant;
int            h1_fast_h;
int            h1_slow_h;
int            m15_fast_h;
int            m15_slow_h;
int            rsi_h;
int            daily_trades;
datetime       last_day;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   h1_fast_h  = iMA(_Symbol, PERIOD_H1, InpH1FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   h1_slow_h  = iMA(_Symbol, PERIOD_H1, InpH1SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   m15_fast_h = iMA(_Symbol, _Period, InpM15FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   m15_slow_h = iMA(_Symbol, _Period, InpM15SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   rsi_h      = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);

   if(h1_fast_h == INVALID_HANDLE || h1_slow_h == INVALID_HANDLE ||
      m15_fast_h == INVALID_HANDLE || m15_slow_h == INVALID_HANDLE || rsi_h == INVALID_HANDLE)
      return INIT_FAILED;

   daily_trades = 0;
   last_day = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(h1_fast_h);
   IndicatorRelease(h1_slow_h);
   IndicatorRelease(m15_fast_h);
   IndicatorRelease(m15_slow_h);
   IndicatorRelease(rsi_h);
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
   if(cur_day != last_day)
   {
      last_day = cur_day;
      daily_trades = 0;
   }
   if(daily_trades >= InpMaxDailyTrades) return;

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double h1_f[], h1_s[];
   ArraySetAsSeries(h1_f, true); ArraySetAsSeries(h1_s, true);
   if(CopyBuffer(h1_fast_h, 0, 1, 2, h1_f) < 2) return;
   if(CopyBuffer(h1_slow_h, 0, 1, 2, h1_s) < 2) return;

   double m15_f[], m15_s[];
   ArraySetAsSeries(m15_f, true); ArraySetAsSeries(m15_s, true);
   if(CopyBuffer(m15_fast_h, 0, 1, 2, m15_f) < 2) return;
   if(CopyBuffer(m15_slow_h, 0, 1, 2, m15_s) < 2) return;

   double rsi_buf[]; ArraySetAsSeries(rsi_buf, true);
   if(CopyBuffer(rsi_h, 0, 1, 3, rsi_buf) < 3) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   bool h1_bull = (h1_f[0] > h1_s[0]);
   bool h1_bear = (h1_f[0] < h1_s[0]);

   // Bullish Setup:
   // 1. H1 Trend is Bullish
   // 2. Bar 1 dipped into value pocket (low <= m15_slow) and closed back above m15_fast
   // 3. RSI(9) crossed back above 50 or is > 50
   if(h1_bull && rates[0].low <= m15_s[0] && rates[0].close > m15_f[0] && rsi_buf[0] > 50.0 && rsi_buf[1] <= 52.0)
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Trend_Pullback_Buy"))
      {
         daily_trades++;
         return;
      }
   }

   // Bearish Setup:
   // 1. H1 Trend is Bearish
   // 2. Bar 1 rallied into value pocket (high >= m15_slow) and closed back below m15_fast
   // 3. RSI(9) crossed back below 50 or is < 50
   if(h1_bear && rates[0].high >= m15_s[0] && rates[0].close < m15_f[0] && rsi_buf[0] < 50.0 && rsi_buf[1] >= 48.0)
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Trend_Pullback_Sell"))
      {
         daily_trades++;
         return;
      }
   }
}
