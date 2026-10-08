//+------------------------------------------------------------------+
//|                               Quant01_Asian_Sweep_Sniper_EA.mq5  |
//|               Archetype: Institutional Order Flow / Liquidity    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 8.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 20.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 5.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 8.0;    // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Liquidity Sweep Parameters ==="
input int      InpAsianStartHour       = 0;      // Asian Start Hour (00:00 UTC)
input int      InpAsianEndHour         = 7;      // Asian End Hour (07:00 UTC)
input int      InpTradeStartHour       = 7;      // London Killzone Start (07:00 UTC)
input int      InpTradeEndHour         = 14;     // London Killzone End (14:00 UTC)
input double   InpSweepMinPips         = 1.0;    // Min Sweep Distance (Pips)
input double   InpSweepMaxPips         = 15.0;   // Max Sweep Distance (Pips)
input int      InpTrendEMAPeriod       = 50;     // H1 Regime Filter EMA
input ulong    InpMagicNumber          = 202601; // Magic Number

CQuantTrade    quant;
double         asian_high, asian_low;
datetime       last_asian_day, last_trade_day;
bool           asian_ready;
int            ema_handle;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   ema_handle = iMA(_Symbol, PERIOD_H1, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(ema_handle == INVALID_HANDLE) return INIT_FAILED;
   asian_high = 0; asian_low = 999999; last_asian_day = 0; last_trade_day = 0;
   asian_ready = false; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(ema_handle);
}

void UpdateAsianRange()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_asian_day)
   {
      last_asian_day = cur_day;
      asian_high = 0; asian_low = 999999; asian_ready = false;
   }
   if(dt.hour >= InpAsianStartHour && dt.hour < InpAsianEndHour)
   {
      MqlRates r[]; ArraySetAsSeries(r, true);
      if(CopyRates(_Symbol, _Period, 0, 2, r) >= 2)
      {
         if(r[1].high > asian_high) asian_high = r[1].high;
         if(r[1].low < asian_low)   asian_low  = r[1].low;
      }
   }
   else if(dt.hour >= InpAsianEndHour && asian_high > 0 && asian_low < 999999)
   {
      asian_ready = true;
   }
}

void OnTick()
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;
   double pip = point * pip_mult;

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

   UpdateAsianRange();

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;
   if(!asian_ready || asian_high <= 0 || asian_low >= 999999) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   double ema_val[]; ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   double c_high = rates[0].high, c_low = rates[0].low, c_open = rates[0].open, c_close = rates[0].close;
   double c_range = c_high - c_low;
   if(c_range <= 0) return;

   double sw_min = InpSweepMinPips * pip;
   double sw_max = InpSweepMaxPips * pip;

   // Bearish Sweep of Asian High in Downtrend / Reversal
   if(c_high >= asian_high + sw_min && c_high <= asian_high + sw_max)
   {
      if(c_close < asian_high && c_close < ema_val[0])
      {
         double wick = c_high - MathMax(c_open, c_close);
         if(wick / c_range >= 0.30)
         {
            if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q01_Asian_Sweep_Sell"))
               daily_trades++;
            return;
         }
      }
   }

   // Bullish Sweep of Asian Low in Uptrend / Reversal
   if(c_low <= asian_low - sw_min && c_low >= asian_low - sw_max)
   {
      if(c_close > asian_low && c_close > ema_val[0])
      {
         double wick = MathMin(c_open, c_close) - c_low;
         if(wick / c_range >= 0.30)
         {
            if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q01_Asian_Sweep_Buy"))
               daily_trades++;
            return;
         }
      }
   }
}
