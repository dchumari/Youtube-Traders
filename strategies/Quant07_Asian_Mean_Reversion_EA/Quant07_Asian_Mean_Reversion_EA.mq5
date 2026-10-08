//+------------------------------------------------------------------+
//|                         Quant07_Asian_Mean_Reversion_EA.mq5      |
//|               Archetype: Mean Reversion & Volatility Compression |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.10"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 8.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 14.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 4.5;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input int      InpMaxDailyTrades       = 3;      // Max Trades per Day

input group "=== Asian Mean Reversion Parameters ==="
input int      InpBBPeriod             = 20;     // Bollinger Bands Period
input double   InpBBDeviation          = 2.0;    // Bollinger Bands Deviation
input int      InpRSIPeriod            = 10;     // RSI Period
input double   InpRSIOverbought        = 68.0;   // RSI Overbought Level
input double   InpRSIOversold          = 32.0;   // RSI Oversold Level
input int      InpAsianStartHour       = 21;     // Asian Session Start (21:00 UTC)
input int      InpAsianEndHour         = 5;      // Asian Session End (05:00 UTC)
input ulong    InpMagicNumber          = 202607; // Magic Number

CQuantTrade    quant;
int            bb_handle, rsi_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   bb_handle  = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   rsi_handle = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   if(bb_handle == INVALID_HANDLE || rsi_handle == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(bb_handle);
   IndicatorRelease(rsi_handle);
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

   double bb_up[], bb_low[], bb_mid[];
   ArraySetAsSeries(bb_up, true); ArraySetAsSeries(bb_low, true); ArraySetAsSeries(bb_mid, true);
   if(CopyBuffer(bb_handle, 1, 1, 2, bb_up) < 2) return;
   if(CopyBuffer(bb_handle, 2, 1, 2, bb_low) < 2) return;
   if(CopyBuffer(bb_handle, 0, 1, 2, bb_mid) < 2) return;

   double rsi_val[]; ArraySetAsSeries(rsi_val, true);
   if(CopyBuffer(rsi_handle, 0, 1, 2, rsi_val) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 2, rates) < 2) return;

   // Mean Reversion Long: Pierced lower band + Oversold RSI + Bullish candle
   if(rates[0].low <= bb_low[0] && rsi_val[0] <= InpRSIOversold && rates[0].close > rates[0].open)
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q07_Asian_Buy"))
         daily_trades++;
      return;
   }

   // Mean Reversion Short: Pierced upper band + Overbought RSI + Bearish candle
   if(rates[0].high >= bb_up[0] && rsi_val[0] >= InpRSIOverbought && rates[0].close < rates[0].open)
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q07_Asian_Sell"))
         daily_trades++;
      return;
   }
}
