//+------------------------------------------------------------------+
//|                             Institutional_Liquidity_Sweep_EA.mq5 |
//|                           Archetype: Order Flow / Liquidity Sweep |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk & Sizing ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 24.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven
input double   InpBreakevenTriggerPips = 8.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 2.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 12.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 3.0;    // Trailing Step (Pips)

input group "=== Liquidity Sweep Engine ==="
input int      InpAsianStartHour       = 0;      // Asian Session Start Hour (Broker)
input int      InpAsianEndHour         = 7;      // Asian Session End Hour (Broker)
input int      InpTradeStartHour       = 7;      // Killzone Trade Start Hour
input int      InpTradeEndHour         = 13;     // Killzone Trade End Hour
input double   InpSweepMinPips         = 1.5;    // Minimum Sweep Distance (Pips)
input double   InpSweepMaxPips         = 25.0;   // Maximum Sweep Distance (Pips)
input ulong    InpMagicNumber          = 101001; // Magic Number

CQuantTrade    quant;
double         asian_high;
double         asian_low;
datetime       last_asian_calc_day;
bool           asian_range_valid;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol))
      return INIT_FAILED;
      
   asian_high = 0;
   asian_low = 999999;
   last_asian_calc_day = 0;
   asian_range_valid = false;
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Update Asian Session Range                                       |
//+------------------------------------------------------------------+
void UpdateAsianRange()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   // Reset at the beginning of each day
   datetime current_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(current_day != last_asian_calc_day)
   {
      last_asian_calc_day = current_day;
      asian_high = 0;
      asian_low = 999999;
      asian_range_valid = false;
   }
   
   // Accumulate high and low during Asian hours
   if(dt.hour >= InpAsianStartHour && dt.hour < InpAsianEndHour)
   {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      if(CopyRates(_Symbol, _Period, 0, 2, rates) >= 2)
      {
         if(rates[1].high > asian_high) asian_high = rates[1].high;
         if(rates[1].low < asian_low)  asian_low  = rates[1].low;
      }
   }
   else if(dt.hour >= InpAsianEndHour && asian_high > 0 && asian_low < 999999)
   {
      asian_range_valid = true;
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Continuous trade management (Breakeven & Trailing)
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
   
   // Check bar open
   if(!quant.IsNewBar(_Period))
      return;
      
   UpdateAsianRange();
   
   // Only trade during London/NY Killzone
   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour))
      return;
      
   if(!asian_range_valid || asian_high <= 0 || asian_low >= 999999)
      return;
      
   long pos_type;
   double open_price, pos_sl, pos_tp;
   ulong ticket;
   if(quant.HasOpenPosition(pos_type, open_price, pos_sl, pos_tp, ticket))
      return; // Max 1 active position
      
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3)
      return;
      
   // Bar 1 is the just-completed candle
   double candle_high = rates[0].high;
   double candle_low  = rates[0].low;
   double candle_open = rates[0].open;
   double candle_close= rates[0].close;
   double candle_range = candle_high - candle_low;
   if(candle_range <= 0) return;
   
   double sweep_min = InpSweepMinPips * pip;
   double sweep_max = InpSweepMaxPips * pip;
   
   // Bearish Liquidity Sweep (Swept Asian High & Closed Back Below)
   if(candle_high > asian_high + sweep_min && candle_high < asian_high + sweep_max)
   {
      if(candle_close < asian_high)
      {
         double upper_wick = candle_high - MathMax(candle_open, candle_close);
         if(upper_wick / candle_range >= 0.35) // Rejection wick
         {
            double sl_points = InpStopLossPips * pip_mult;
            double tp_points = InpTakeProfitPips * pip_mult;
            quant.OpenSell(sl_points, tp_points, InpRiskPercent, "Asian_High_Sweep_Sell");
            return;
         }
      }
   }
   
   // Bullish Liquidity Sweep (Swept Asian Low & Closed Back Above)
   if(candle_low < asian_low - sweep_min && candle_low > asian_low - sweep_max)
   {
      if(candle_close > asian_low)
      {
         double lower_wick = MathMin(candle_open, candle_close) - candle_low;
         if(lower_wick / candle_range >= 0.35) // Rejection wick
         {
            double sl_points = InpStopLossPips * pip_mult;
            double tp_points = InpTakeProfitPips * pip_mult;
            quant.OpenBuy(sl_points, tp_points, InpRiskPercent, "Asian_Low_Sweep_Buy");
            return;
         }
      }
   }
}
