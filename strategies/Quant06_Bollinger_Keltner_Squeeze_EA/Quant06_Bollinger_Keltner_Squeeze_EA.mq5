//+------------------------------------------------------------------+
//|                     Quant06_Bollinger_Keltner_Squeeze_EA.mq5     |
//|               Archetype: Mean Reversion & Volatility Compression |
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

input group "=== Squeeze Compression Parameters ==="
input int      InpBBPeriod             = 20;     // Bollinger Bands Period
input double   InpBBDeviation          = 2.0;    // Bollinger Bands Deviation
input int      InpKeltnerATRPeriod     = 20;     // Keltner Channel ATR Period
input double   InpKeltnerMult          = 1.5;    // Keltner Channel ATR Multiplier
input int      InpTrendEMAPeriod       = 50;     // Trend Filter EMA
input int      InpTradeStartHour       = 7;      // Session Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 18;     // Session End Hour (18:00 UTC)
input ulong    InpMagicNumber          = 202606; // Magic Number

CQuantTrade    quant;
int            bb_handle, atr_handle, ema_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   bb_handle  = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   atr_handle = iATR(_Symbol, _Period, InpKeltnerATRPeriod);
   ema_handle = iMA(_Symbol, PERIOD_H1, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(bb_handle == INVALID_HANDLE || atr_handle == INVALID_HANDLE || ema_handle == INVALID_HANDLE)
      return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(bb_handle);
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

   double bb_up[], bb_low[], bb_mid[];
   ArraySetAsSeries(bb_up, true); ArraySetAsSeries(bb_low, true); ArraySetAsSeries(bb_mid, true);
   if(CopyBuffer(bb_handle, 1, 1, 3, bb_up) < 3) return;
   if(CopyBuffer(bb_handle, 2, 1, 3, bb_low) < 3) return;
   if(CopyBuffer(bb_handle, 0, 1, 3, bb_mid) < 3) return;

   double atr_val[], ema_val[];
   ArraySetAsSeries(atr_val, true); ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(atr_handle, 0, 1, 3, atr_val) < 3) return;
   if(CopyBuffer(ema_handle, 0, 1, 3, ema_val) < 3) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   double keltner_up_prev  = bb_mid[1] + InpKeltnerMult * atr_val[1];
   double keltner_low_prev = bb_mid[1] - InpKeltnerMult * atr_val[1];
   double keltner_up_curr  = bb_mid[0] + InpKeltnerMult * atr_val[0];
   double keltner_low_curr = bb_mid[0] - InpKeltnerMult * atr_val[0];

   bool was_in_squeeze = (bb_up[1] < keltner_up_prev && bb_low[1] > keltner_low_prev);
   bool is_squeeze_fired = (bb_up[0] > keltner_up_curr || bb_low[0] < keltner_low_curr);

   if(was_in_squeeze && is_squeeze_fired)
   {
      // Bullish Squeeze Fired + Above H1 EMA
      if(rates[0].close > bb_mid[0] && rates[0].close > ema_val[0])
      {
         if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q06_Squeeze_Buy"))
            daily_trades++;
         return;
      }
      // Bearish Squeeze Fired + Below H1 EMA
      if(rates[0].close < bb_mid[0] && rates[0].close < ema_val[0])
      {
         if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q06_Squeeze_Sell"))
            daily_trades++;
         return;
      }
   }
}
