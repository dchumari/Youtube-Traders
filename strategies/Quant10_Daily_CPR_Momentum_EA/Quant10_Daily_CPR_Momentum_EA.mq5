//+------------------------------------------------------------------+
//|                        Quant10_Daily_CPR_Momentum_EA.mq5         |
//|               Archetype: Session Momentum & Killzone Dynamics    |
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

input group "=== Daily CPR Compression Parameters ==="
input double   InpMaxCPRPips           = 18.0;   // Max CPR Width (TC-BC in Pips)
input int      InpMACDFast             = 12;     // MACD Fast Period
input int      InpMACDSlow             = 26;     // MACD Slow Period
input int      InpMACDSignal           = 9;      // MACD Signal Period
input int      InpH1TrendEMA           = 100;    // Trend Baseline Filter
input int      InpTradeStartHour       = 7;      // Session Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 16;     // Session End Hour (16:00 UTC)
input ulong    InpMagicNumber          = 202610; // Magic Number

CQuantTrade    quant;
int            macd_handle, ema_handle;
double         cpr_pivot, cpr_bc, cpr_tc, cpr_width_pips;
datetime       last_cpr_day, last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   macd_handle = iMACD(_Symbol, _Period, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   ema_handle  = iMA(_Symbol, PERIOD_H1, InpH1TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(macd_handle == INVALID_HANDLE || ema_handle == INVALID_HANDLE) return INIT_FAILED;
   last_cpr_day = 0; last_trade_day = 0; daily_trades = 0;
   cpr_pivot = 0; cpr_bc = 0; cpr_tc = 0; cpr_width_pips = 999;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(macd_handle);
   IndicatorRelease(ema_handle);
}

void UpdateCPR()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day == last_cpr_day) return;
   last_cpr_day = cur_day;

   MqlRates d_rates[]; ArraySetAsSeries(d_rates, true);
   if(CopyRates(_Symbol, PERIOD_D1, 1, 1, d_rates) < 1) return;

   double high = d_rates[0].high, low = d_rates[0].low, close = d_rates[0].close;
   cpr_pivot = (high + low + close) / 3.0;
   cpr_bc    = (high + low) / 2.0;
   cpr_tc    = (cpr_pivot - cpr_bc) + cpr_pivot;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;
   cpr_width_pips = MathAbs(cpr_tc - cpr_bc) / (point * pip_mult);
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

   UpdateCPR();

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;
   if(cpr_width_pips > InpMaxCPRPips || cpr_pivot <= 0) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double macd_main[], macd_sig[], ema_val[];
   ArraySetAsSeries(macd_main, true); ArraySetAsSeries(macd_sig, true); ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(macd_handle, 0, 1, 2, macd_main) < 2) return;
   if(CopyBuffer(macd_handle, 1, 1, 2, macd_sig) < 2) return;
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 2, rates) < 2) return;

   double upper_cpr = MathMax(cpr_tc, cpr_bc);
   double lower_cpr = MathMin(cpr_tc, cpr_bc);

   // Bullish Expansion
   if(rates[0].close > upper_cpr && macd_main[0] > macd_sig[0] && rates[0].close > ema_val[0])
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q10_CPR_Expansion_Buy"))
         daily_trades++;
      return;
   }

   // Bearish Expansion
   if(rates[0].close < lower_cpr && macd_main[0] < macd_sig[0] && rates[0].close < ema_val[0])
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q10_CPR_Expansion_Sell"))
         daily_trades++;
      return;
   }
}
