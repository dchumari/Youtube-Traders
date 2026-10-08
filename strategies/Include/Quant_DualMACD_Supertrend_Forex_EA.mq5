//+------------------------------------------------------------------+
//|                      Quant_DualMACD_Supertrend_Forex_EA.mq5      |
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
input double   InpMinRR                = 2.2;    // Risk to Reward Ratio
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 7.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 3;      // Max Trades per Day

input group "=== Dual MACD & Supertrend Parameters ==="
input int      InpFastMACD_Fast        = 3;      // Fast MACD Fast EMA
input int      InpFastMACD_Slow        = 10;     // Fast MACD Slow EMA
input int      InpFastMACD_Signal      = 14;     // Fast MACD Signal SMA
input int      InpSlowMACD_Fast        = 12;     // Slow MACD Fast EMA
input int      InpSlowMACD_Slow        = 26;     // Slow MACD Slow EMA
input int      InpSlowMACD_Signal      = 9;      // Slow MACD Signal SMA
input int      InpSTATRPeriod          = 10;     // Supertrend ATR Period
input double   InpSTFactor             = 2.5;    // Supertrend ATR Multiplier
input int      InpSessionStartHour     = 7;      // Session Start Hour (07:00 UTC)
input int      InpSessionEndHour       = 19;     // Session End Hour (19:00 UTC)
input ulong    InpMagicNumber          = 202611; // Magic Number

CQuantTrade    quant;
int            fast_macd_h, slow_macd_h, atr_h;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   fast_macd_h = iMACD(_Symbol, _Period, InpFastMACD_Fast, InpFastMACD_Slow, InpFastMACD_Signal, PRICE_CLOSE);
   slow_macd_h = iMACD(_Symbol, _Period, InpSlowMACD_Fast, InpSlowMACD_Slow, InpSlowMACD_Signal, PRICE_CLOSE);
   atr_h       = iATR(_Symbol, _Period, InpSTATRPeriod);

   if(fast_macd_h == INVALID_HANDLE || slow_macd_h == INVALID_HANDLE || atr_h == INVALID_HANDLE)
      return INIT_FAILED;

   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(fast_macd_h);
   IndicatorRelease(slow_macd_h);
   IndicatorRelease(atr_h);
}

int GetSupertrendSignal()
{
   double atrBuf[2]; ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atr_h, 0, 1, 2, atrBuf) < 2) return 0;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return 0;

   double mid = (rates[1].high + rates[1].low) / 2.0;
   if(rates[0].close > mid + InpSTFactor * atrBuf[1]) return 1;
   if(rates[0].close < mid - InpSTFactor * atrBuf[1]) return -1;
   return 0;
}

int GetDualMACDSignal()
{
   double fMain[2], fSig[2], sMain[2], sSig[2];
   ArraySetAsSeries(fMain, true); ArraySetAsSeries(fSig, true);
   ArraySetAsSeries(sMain, true); ArraySetAsSeries(sSig, true);

   if(CopyBuffer(fast_macd_h, 0, 1, 2, fMain) < 2) return 0;
   if(CopyBuffer(fast_macd_h, 1, 1, 2, fSig) < 2) return 0;
   if(CopyBuffer(slow_macd_h, 0, 1, 2, sMain) < 2) return 0;
   if(CopyBuffer(slow_macd_h, 1, 1, 2, sSig) < 2) return 0;

   bool fastBull = (fMain[0] > 0 && fMain[0] > fMain[1]);
   bool fastBear = (fMain[0] < 0 && fMain[0] < fMain[1]);
   bool slowBull = (sMain[0] > sSig[0]);
   bool slowBear = (sMain[0] < sSig[0]);

   if(fastBull && slowBull) return 1;
   if(fastBear && slowBear) return -1;
   return 0;
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

   int stSig = GetSupertrendSignal();
   int mSig  = GetDualMACDSignal();

   if(stSig != 0 && stSig == mSig)
   {
      double sl_points = InpStopLossPips * pip_mult;
      double tp_points = InpStopLossPips * InpMinRR * pip_mult;

      if(stSig == 1)
      {
         if(quant.OpenBuy(sl_points, tp_points, InpRiskPercent, "DualMACD_ST_Buy"))
            daily_trades++;
         return;
      }
      else if(stSig == -1)
      {
         if(quant.OpenSell(sl_points, tp_points, InpRiskPercent, "DualMACD_ST_Sell"))
            daily_trades++;
         return;
      }
   }
}
