//+------------------------------------------------------------------+
//|                               Quant02_FVG_Mitigation_Flow_EA.mq5 |
//|               Archetype: Institutional Order Flow / Imbalance    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 9.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 22.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 6.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Fair Value Gap & Displacement Parameters ==="
input int      InpATRPeriod            = 14;     // ATR Volatility Period
input double   InpDisplacementATRMult  = 1.2;    // Displacement Body ATR Multiplier
input int      InpTrendEMAPeriod       = 50;     // H1 Regime Filter EMA
input int      InpTradeStartHour       = 8;      // Active Killzone Start (08:00 UTC)
input int      InpTradeEndHour         = 17;     // Active Killzone End (17:00 UTC)
input ulong    InpMagicNumber          = 202602; // Magic Number

CQuantTrade    quant;
int            atr_handle;
int            ema_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   atr_handle = iATR(_Symbol, _Period, InpATRPeriod);
   ema_handle = iMA(_Symbol, PERIOD_H1, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(atr_handle == INVALID_HANDLE || ema_handle == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(atr_handle);
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

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 4, rates) < 4) return;

   double atr_val[]; ArraySetAsSeries(atr_val, true);
   if(CopyBuffer(atr_handle, 0, 1, 2, atr_val) < 2) return;

   double ema_val[]; ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   double bar2_body = MathAbs(rates[1].close - rates[1].open);
   if(bar2_body < InpDisplacementATRMult * atr_val[0]) return;

   // Bullish FVG: Bar 2 was strong bullish, Low of Bar 1 > High of Bar 3, trend above H1 EMA
   if(rates[1].close > rates[1].open && rates[0].low > rates[2].high && rates[0].close > ema_val[0])
   {
      double fvg_ce = (rates[0].low + rates[2].high) / 2.0;
      if(rates[0].close > fvg_ce)
      {
         if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q02_FVG_Flow_Buy"))
            daily_trades++;
         return;
      }
   }

   // Bearish FVG: Bar 2 was strong bearish, High of Bar 1 < Low of Bar 3, trend below H1 EMA
   if(rates[1].close < rates[1].open && rates[0].high < rates[2].low && rates[0].close < ema_val[0])
   {
      double fvg_ce = (rates[0].high + rates[2].low) / 2.0;
      if(rates[0].close < fvg_ce)
      {
         if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q02_FVG_Flow_Sell"))
            daily_trades++;
         return;
      }
   }
}
