//+------------------------------------------------------------------+
//|                     Quant08_RSI_Divergence_Envelope_EA.mq5       |
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
input double   InpTakeProfitPips       = 20.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 6.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Envelope & Divergence Parameters ==="
input int      InpEnvMAPeriod          = 20;     // Envelope Moving Average Period
input double   InpEnvDeviation         = 0.12;   // Envelope Percentage Deviation
input int      InpRSIPeriod            = 14;     // RSI Oscillator Period
input int      InpDivergenceLookback   = 10;     // Divergence Swing Lookback Bars
input int      InpH1TrendEMA           = 100;    // Trend Filter EMA
input int      InpTradeStartHour       = 7;      // Session Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 17;     // Session End Hour (17:00 UTC)
input ulong    InpMagicNumber          = 202608; // Magic Number

CQuantTrade    quant;
int            env_handle, rsi_handle, ema_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   env_handle = iEnvelopes(_Symbol, _Period, InpEnvMAPeriod, 0, MODE_SMA, PRICE_CLOSE, InpEnvDeviation);
   rsi_handle = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   ema_handle = iMA(_Symbol, PERIOD_H1, InpH1TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(env_handle == INVALID_HANDLE || rsi_handle == INVALID_HANDLE || ema_handle == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(env_handle);
   IndicatorRelease(rsi_handle);
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

   double env_up[], env_low[], ema_val[];
   ArraySetAsSeries(env_up, true); ArraySetAsSeries(env_low, true); ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(env_handle, 0, 1, 2, env_up) < 2) return;
   if(CopyBuffer(env_handle, 1, 1, 2, env_low) < 2) return;
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   double rsi_buf[]; ArraySetAsSeries(rsi_buf, true);
   if(CopyBuffer(rsi_handle, 0, 1, InpDivergenceLookback + 2, rsi_buf) < InpDivergenceLookback + 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, InpDivergenceLookback + 2, rates) < InpDivergenceLookback + 2) return;

   // Bullish Divergence at lower envelope in bullish trend
   if(rates[0].low <= env_low[0] && rates[0].close > ema_val[0])
   {
      for(int i = 3; i <= InpDivergenceLookback; i++)
      {
         if(rates[0].low < rates[i].low && rsi_buf[0] > rsi_buf[i] && rsi_buf[i] < 35.0)
         {
            if(rates[0].close > rates[0].open)
            {
               if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q08_RSI_Div_Buy"))
                  daily_trades++;
               return;
            }
         }
      }
   }

   // Bearish Divergence at upper envelope in bearish trend
   if(rates[0].high >= env_up[0] && rates[0].close < ema_val[0])
   {
      for(int i = 3; i <= InpDivergenceLookback; i++)
      {
         if(rates[0].high > rates[i].high && rsi_buf[0] < rsi_buf[i] && rsi_buf[i] > 65.0)
         {
            if(rates[0].close < rates[0].open)
            {
               if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q08_RSI_Div_Sell"))
                  daily_trades++;
               return;
            }
         }
      }
   }
}
