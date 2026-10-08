//+------------------------------------------------------------------+
//| Gold_Wyckoff_CVD_Absorption_EA.mq5                               |
//| Strategy 4: Wyckoff Effort-vs-Result Volume Absorption Scalper   |
//| Asset: XAUUSD M1 | Target: Sub-10 Pip SL Ultra-Asymmetric Scalp  |
//+------------------------------------------------------------------+
#property copyright "Master Quant Architecture"
#property link      "https://youtube-traders.pipeline"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Capital Sizing & Doubling Engine (1,000 KES / $8.00) ==="
input double   CapitalPerMicroLot    = 6.0;              // Capital per 0.01 lot ($6 = 0.01, $12 = 0.02)
input double   MaxLotCap             = 0.05;             // Max Lot Cap
input double   FixedLotSize          = 0.01;             // Fixed Lot Size fallback
input double   SL_Pips               = 9.0;              // Ultra-Tight Max Stop Loss (Pips)
input double   Target_RR             = 3.5;              // Target Reward:Risk (3.5R Asymmetry)
input bool     UseBreakeven          = true;             // Move SL to Breakeven
input double   BE_Trigger_R          = 1.2;              // BE Trigger R (at +1.2R)
input double   BE_Offset_Pips        = 1.0;              // BE Profit Lock Buffer (Pips)

input group "=== Wyckoff Absorption Parameters ==="
input int      VolMAPeriod           = 20;               // Volume MA Lookback
input double   VolMultiplier         = 1.60;             // Volume Spike Multiplier (Effort)
input double   MaxBodyPips           = 3.5;              // Max Body Allowed for Absorption (Result)
input double   MinWickPercent        = 50.0;             // Minimum Wick % of Total Range
input double   MinTotalRangePips     = 6.0;              // Minimum Total Candle Span (Pips)
input int      SessionStartHour      = 7;                // London Open UTC (07:00)
input int      SessionEndHour        = 20;               // NY Close UTC (20:00)

input group "=== Risk Circuit Breakers ==="
input int      MaxDailyTrades        = 4;                // Max Trades per Day
input int      MaxDailyLosses        = 1;                // Circuit Breaker: Halt after 1 loss per day
input double   MaxSpreadPips         = 25.0;             // Max Spread Allowed (Points)
input ulong    MagicNumber           = 20265004;         // Magic Number

CTrade trade;
CPositionInfo pos;

int dailyTrades = 0;
int dailyLosses = 0;
datetime lastTradeDay = 0;
datetime lastSignalBar = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {}

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

   // Spread check
   double spreadPips = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / (_Point * 10);
   if(spreadPips > MaxSpreadPips) return;

   // Circuit breaker checks
   if(dailyLosses >= MaxDailyLosses) return;
   if(dailyTrades >= MaxDailyTrades) return;

   // Only 1 open position
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MagicNumber)
         return;
     }

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.hour < SessionStartHour || dt.hour >= SessionEndHour) return;

   // Read M1 rates
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M1, 0, VolMAPeriod + 5, rates) < VolMAPeriod + 5) return;

   if(rates[0].time == lastSignalBar) return;

   // Calculate 20-period Average Volume on bars 2 to 21
   long sumVol = 0;
   for(int i = 2; i <= VolMAPeriod + 1; i++)
      sumVol += rates[i].tick_volume;
   double avgVol = (double)sumVol / VolMAPeriod;

   double pip = _Point * 10;
   double body1 = MathAbs(rates[1].close - rates[1].open) / pip;
   double range1 = (rates[1].high - rates[1].low) / pip;
   if(range1 < MinTotalRangePips) return;

   // Check if Bar 1 has Volume Climax (Effort)
   bool isHighVolume = (rates[1].tick_volume >= avgVol * VolMultiplier);
   if(!isHighVolume) return;

   // Check if Bar 1 had minimal price progress (Result failed)
   bool isCompressedBody = (body1 <= MaxBodyPips);
   if(!isCompressedBody) return;

   double lowerWick1 = (MathMin(rates[1].open, rates[1].close) - rates[1].low) / pip;
   double upperWick1 = (rates[1].high - MathMax(rates[1].open, rates[1].close)) / pip;

   double lowerWickPct = (lowerWick1 / range1) * 100.0;
   double upperWickPct = (upperWick1 / range1) * 100.0;

   // ---------------------------------------------------------------
   // BULLISH ABSORPTION SETUP:
   // 1. Bar 1 has lower wick >= 50% of range (Smart money absorbed sellers)
   // 2. Current Bar 0 breaks above Bar 1 High or Close (Confirmation Engulfing)
   // ---------------------------------------------------------------
   if(lowerWickPct >= MinWickPercent && rates[0].close > rates[1].close)
     {
      double entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double slDist = (entry - rates[1].low) + 1.0 * pip;
      slDist = MathMax(6.0 * pip, MathMin(SL_Pips * pip, slDist));
      double sl = entry - slDist;
      double tp = entry + (slDist * Target_RR);
      double lots = CalculateLots(slDist / pip);

      if(trade.Buy(lots, _Symbol, entry, sl, tp, "Wyckoff CVD Absorption Buy"))
        {
         dailyTrades++;
         lastSignalBar = rates[0].time;
         return;
        }
     }

   // ---------------------------------------------------------------
   // BEARISH ABSORPTION SETUP:
   // 1. Bar 1 has upper wick >= 50% of range (Smart money absorbed buyers)
   // 2. Current Bar 0 breaks below Bar 1 Low or Close
   // ---------------------------------------------------------------
   if(upperWickPct >= MinWickPercent && rates[0].close < rates[1].close)
     {
      double entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double slDist = (rates[1].high - entry) + 1.0 * pip;
      slDist = MathMax(6.0 * pip, MathMin(SL_Pips * pip, slDist));
      double sl = entry + slDist;
      double tp = entry - (slDist * Target_RR);
      double lots = CalculateLots(slDist / pip);

      if(trade.Sell(lots, _Symbol, entry, sl, tp, "Wyckoff CVD Absorption Sell"))
        {
         dailyTrades++;
         lastSignalBar = rates[0].time;
         return;
        }
     }
  }
