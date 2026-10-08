//+------------------------------------------------------------------+
//| Gold_London_Judas_TurtleSoup_EA.mq5                              |
//| Strategy 3: London Open Judas Turtle Soup with H1 50-EMA Filter  |
//| Asset: XAUUSD M1 | Target: Rapid Micro Account Doubling (1:400)  |
//+------------------------------------------------------------------+
#property copyright "Master Quant Architecture"
#property link      "https://youtube-traders.pipeline"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Capital Sizing & Doubling Engine (1,000 KES / $8.00) ==="
input double   CapitalPerMicroLot    = 6.0;              // Capital per 0.01 lot ($6 = 0.01, $12 = 0.02)
input double   MaxLotCap             = 0.05;             // Max Lot Cap
input double   FixedLotSize          = 0.01;             // Fixed Lot Size fallback
input double   SL_Pips               = 11.0;             // Base Stop Loss (Pips)
input double   Target_RR             = 3.0;              // Target Reward:Risk (3.0R)
input bool     UseBreakeven          = true;             // Move SL to Breakeven
input double   BE_Trigger_R          = 1.0;              // BE Trigger R (at +1.0R)
input double   BE_Offset_Pips        = 1.0;              // BE Profit Lock Buffer (Pips)

input group "=== London Judas & Turtle Soup Engine ==="
input bool     Enable_HTF_Filter     = true;             // Enforce H1 50-EMA Trend Confluence
input int      HTF_EMA_Period        = 50;               // H1 EMA Period
input int      AsianStartHour        = 0;                // Asian Start Hour UTC (00:00)
input int      AsianEndHour          = 7;                // Asian End Hour UTC (07:00)
input double   SweepMinPips          = 2.0;              // Min Sweep Penetration (Pips)
input double   SweepMaxPips          = 10.0;             // Max Sweep Penetration (Avoid Runaways)
input int      JudasStartHour        = 7;                // London Judas Start Hour UTC (07:00)
input int      JudasEndHour          = 11;               // London Judas End Hour UTC (11:00)
input bool     Enable_Vol_Filter     = true;             // Require Tick Volume Surge on Reversal
input int      VolMAPeriod           = 20;               // Volume MA Period
input double   VolSpikeRatio         = 1.15;             // Volume Spike Ratio (1.15x)

input group "=== Risk Circuit Breakers ==="
input int      MaxDailyTrades        = 3;                // Max Trades per Day
input int      MaxDailyLosses        = 1;                // Circuit Breaker: Halt after 1 loss per day
input double   MaxSpreadPips         = 25.0;             // Max Spread Allowed (Points)
input ulong    MagicNumber           = 20265003;         // Magic Number

CTrade trade;
CPositionInfo pos;

int dailyTrades = 0;
int dailyLosses = 0;
datetime lastTradeDay = 0;

double asianHigh = 0.0, asianLow = 999999.0;
datetime lastAsianDate = 0;
int htfEmaHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   if(Enable_HTF_Filter)
     {
      htfEmaHandle = iMA(_Symbol, PERIOD_H1, HTF_EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
      if(htfEmaHandle == INVALID_HANDLE)
        {
         Print("Failed to create H1 EMA handle!");
         return(INIT_FAILED);
        }
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(htfEmaHandle != INVALID_HANDLE)
      IndicatorRelease(htfEmaHandle);
  }

//+------------------------------------------------------------------+
//| Calculate Asian Session Range (00:00 - 07:00 UTC)                |
//+------------------------------------------------------------------+
void UpdateAsianRange()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today == lastAsianDate && dt.hour >= AsianEndHour) return;

   datetime startT = today + AsianStartHour * 3600;
   datetime endT   = today + AsianEndHour * 3600;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_M5, startT, endT, rates);
   if(copied > 0)
     {
      double h = -1.0, l = 999999.0;
      for(int i = 0; i < copied; i++)
        {
         if(rates[i].high > h) h = rates[i].high;
         if(rates[i].low < l)  l = rates[i].low;
        }
      asianHigh = h;
      asianLow  = l;
      if(dt.hour >= AsianEndHour) lastAsianDate = today;
     }
  }

//+------------------------------------------------------------------+
//| Dynamic Micro Lot Sizing Ladder                                  |
//+------------------------------------------------------------------+
double CalculateLots(double slPips)
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double capital = MathMin(balance, equity);
   double step    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   double microLots = MathMax(minLot, MathFloor(capital / CapitalPerMicroLot) * 0.01);
   microLots = MathFloor(microLots / step) * step;
   return NormalizeDouble(MathMin(MaxLotCap, microLots), 2);
  }

//+------------------------------------------------------------------+
//| Check H1 EMA Trend Bias                                          |
//+------------------------------------------------------------------+
int GetHTFBias()
  {
   if(!Enable_HTF_Filter || htfEmaHandle == INVALID_HANDLE) return 0; // Neutral/No filter

   double emaVal[2];
   if(CopyBuffer(htfEmaHandle, 0, 0, 2, emaVal) < 2) return 0;

   MqlRates h1Rates[2];
   ArraySetAsSeries(h1Rates, true);
   if(CopyRates(_Symbol, PERIOD_H1, 0, 2, h1Rates) < 2) return 0;

   if(h1Rates[1].close > emaVal[1]) return 1;  // Bullish Bias
   if(h1Rates[1].close < emaVal[1]) return -1; // Bearish Bias

   return 0;
  }

//+------------------------------------------------------------------+
//| Volume Filter Check                                              |
//+------------------------------------------------------------------+
bool IsVolumeConfirmed(const MqlRates &rates[])
  {
   if(!Enable_Vol_Filter) return true;
   long sumVol = 0;
   for(int i = 1; i <= VolMAPeriod; i++)
      sumVol += rates[i].tick_volume;
   double avgVol = (double)sumVol / VolMAPeriod;
   return (rates[1].tick_volume >= avgVol * VolSpikeRatio);
  }

//+------------------------------------------------------------------+
//| Breakeven Manager                                                |
//+------------------------------------------------------------------+
void ManageBreakeven()
  {
   if(!UseBreakeven) return;
   double pip = _Point * 10;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MagicNumber)
        {
         ulong ticket = pos.Ticket();
         double openP = pos.PriceOpen();
         double sl = pos.StopLoss();
         double curP = (pos.PositionType() == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double riskPips = MathAbs(openP - sl) / pip;
         if(riskPips <= 0) continue;

         if(pos.PositionType() == POSITION_TYPE_BUY)
           {
            if(curP >= openP + BE_Trigger_R * riskPips * pip && sl < openP)
               trade.PositionModify(ticket, openP + BE_Offset_Pips * pip, pos.TakeProfit());
           }
         else
           {
            if(curP <= openP - BE_Trigger_R * riskPips * pip && (sl > openP || sl == 0))
               trade.PositionModify(ticket, openP - BE_Offset_Pips * pip, pos.TakeProfit());
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Reset Daily Counters                                             |
//+------------------------------------------------------------------+
void CheckDailyReset()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today != lastTradeDay)
     {
      dailyTrades = 0;
      dailyLosses = 0;
      lastTradeDay = today;
     }
  }

//+------------------------------------------------------------------+
//| Track Deal Losses for Circuit Breaker                            |
//+------------------------------------------------------------------+
void CheckClosedDeals()
  {
   HistorySelect(lastTradeDay, TimeCurrent());
   int totalDeals = HistoryDealsTotal();
   int losses = 0;
   for(int i = totalDeals - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0)
        {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol &&
            HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber &&
            HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
           {
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if(profit < -0.01) losses++;
           }
        }
     }
   dailyLosses = losses;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   CheckDailyReset();
   CheckClosedDeals();
   ManageBreakeven();

   // Spread & Open position check
   double spreadPips = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / (_Point * 10);
   if(spreadPips > MaxSpreadPips) return;

   // Circuit breaker checks
   if(dailyLosses >= MaxDailyLosses) return;
   if(dailyTrades >= MaxDailyTrades) return;

   // Check if we already have an open position
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MagicNumber)
         return; // Only 1 active trade at a time
     }

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   UpdateAsianRange();

   // Only trade inside London Judas window
   if(dt.hour < JudasStartHour || dt.hour >= JudasEndHour) return;
   if(asianHigh <= 0.0 || asianLow >= 900000.0) return;

   // Read recent M1 rates
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M1, 0, VolMAPeriod + 5, rates) < VolMAPeriod + 5) return;

   double pip = _Point * 10;
   int htfBias = GetHTFBias();

   // ---------------------------------------------------------------
   // BULLISH TURTLE SOUP SETUP:
   // 1. HTF Trend is Bullish (Bias >= 0)
   // 2. Previous candle or sweep wick dipped below Asian Low by at least SweepMinPips
   // 3. But not exceeded SweepMaxPips (avoid catching runaway knives)
   // 4. Bar[1] closed back ABOVE Asian Low (Turtle Soup Re-entry)
   // ---------------------------------------------------------------
   if(htfBias >= 0)
     {
      double sweepDepth = (asianLow - rates[1].low) / pip;
      if(sweepDepth >= SweepMinPips && sweepDepth <= SweepMaxPips && rates[1].close > asianLow)
        {
         if(IsVolumeConfirmed(rates))
           {
            double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double slDistance = MathMax(SL_Pips * pip, (entry - rates[1].low) + 1.0 * pip);
            slDistance = MathMin(slDistance, SL_Pips * pip); // Cap at max SL
            double sl = entry - slDistance;
            double tp = entry + (slDistance * Target_RR);
            double lots = CalculateLots(slDistance / pip);

            if(trade.Buy(lots, _Symbol, entry, sl, tp, "London Judas Turtle Soup Buy"))
              {
               dailyTrades++;
               return;
              }
           }
        }
     }

   // ---------------------------------------------------------------
   // BEARISH TURTLE SOUP SETUP:
   // 1. HTF Trend is Bearish (Bias <= 0)
   // 2. Previous candle swept above Asian High by at least SweepMinPips
   // 3. But not exceeded SweepMaxPips
   // 4. Bar[1] closed back BELOW Asian High (Turtle Soup Re-entry)
   // ---------------------------------------------------------------
   if(htfBias <= 0)
     {
      double sweepHeight = (rates[1].high - asianHigh) / pip;
      if(sweepHeight >= SweepMinPips && sweepHeight <= SweepMaxPips && rates[1].close < asianHigh)
        {
         if(IsVolumeConfirmed(rates))
           {
            double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double slDistance = MathMax(SL_Pips * pip, (rates[1].high - entry) + 1.0 * pip);
            slDistance = MathMin(slDistance, SL_Pips * pip);
            double sl = entry + slDistance;
            double tp = entry - (slDistance * Target_RR);
            double lots = CalculateLots(slDistance / pip);

            if(trade.Sell(lots, _Symbol, entry, sl, tp, "London Judas Turtle Soup Sell"))
              {
               dailyTrades++;
               return;
              }
           }
        }
     }
  }
