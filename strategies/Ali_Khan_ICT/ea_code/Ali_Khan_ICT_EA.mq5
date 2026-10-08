//+------------------------------------------------------------------+
//|  Ali_Khan_ICT_EA.mq5                                               |
//|  Strategy: ICT Live Trading Architecture — Ali_Khan_ICT             |
//|  Asset:    XAUUSD / NQ                                           |
//|  Version:  1.00                                                  |
//+------------------------------------------------------------------+
#property copyright "Master Quant Architecture"
#property link      "https://youtube-traders.pipeline"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

enum ENUM_EXEC_MODE
  {
   EXEC_SINGLE_RUNNER = 0, // Single Full Target (2.5R)
   EXEC_DUAL_PARTIAL  = 1  // Dual Partials (50% @ 1:1, 50% @ 1:2 + BE)
  };

enum ENUM_STRATEGY_MODEL
  {
   MODEL_1 = 1, // Dealing Range OTE
   MODEL_2 = 2, // Displacement Verify
   MODEL_3 = 3, // LRLR Run
   MODEL_ALL_CONFLUENCE = 4 // All Models in Confluence
  };

//--- Inputs
input group "=== Strategy Model Selector ==="
input ENUM_STRATEGY_MODEL  StrategyModel         = MODEL_1;          // Active Strategy Model
input ENUM_EXEC_MODE       ExecutionMode         = EXEC_SINGLE_RUNNER; // Execution Mode
input double               SingleTarget_RR       = 2.5;              // Target Reward-to-Risk (e.g. 2.5R)
input double               Part1_RR              = 1.0;              // Dual Partial 1 Target (1:1 R:R)
input double               Part2_RR              = 2.0;              // Dual Partial 2 Target (1:2 R:R)
input bool                 MoveBE_On_TP1         = true;             // Move SL to Breakeven at TP1
input double               BE_Offset_Pips        = 1.0;              // Breakeven Buffer Pips

input group "=== Risk & Sizing ==="
input double               RiskPercent           = 2.0;              // Risk % per Trade
input double               MaxLotCap             = 5.00;             // Max Allowed Lot Size
input bool                 UseFixedLot           = false;            // Force Fixed Lot
input double               FixedLotSize          = 0.01;             // Fixed Lot Size
input double               SL_Pips               = 15.0;             // Base Stop Loss (Pips)

input group "=== ICT Core Parameters ==="
input double               Min_FVG_Pips          = 2.0;              // Minimum FVG Size (Pips)
input double               Max_FVG_Pips          = 25.0;             // Maximum FVG Size (Pips)
input double               Sweep_Pips            = 2.5;              // Minimum Liquidity Sweep Buffer (Pips)
input int                  StructureLookback     = 10;               // Swing High/Low Lookback Bars
input bool                 UseVolumeFilter       = true;             // Volume Surge Filter
input double               VolMultiplier         = 1.15;             // Volume Surge Multiplier

input group "=== Session & Protection ==="
input int                  StartHourUTC          = 13;               // Session Start Hour (UTC)
input int                  EndHourUTC            = 19;               // Session End Hour (UTC)
input int                  MaxDailyTrades        = 4;                // Max Daily Trades
input int                  MaxDailyLosses        = 2;                // Max Daily Losses Circuit Breaker
input double               MaxSpreadPips         = 25.0;             // Maximum Spread Allowed (Points)
input ulong                MagicNumber           = 20264070;     // Magic Number Base

//--- Globals
CTrade trade;
CPositionInfo pos;
int dailyTrades = 0;
int dailyLosses = 0;
datetime lastTradeDay = 0;

// HTF Levels
double pdh = 0.0, pdl = 0.0;
datetime lastD1Date = 0;

// Asian Session Levels
double asianHigh = 0.0, asianLow = 999999.0;
datetime lastAsianDate = 0;

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   Print("Ali_Khan_ICT_EA Initialized on ", _Symbol);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//| Update PDH and PDL                                               |
//+------------------------------------------------------------------+
void UpdatePDH_PDL()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastD1Date == today) return;
   lastD1Date = today;

   double dH[], dL[];
   ArraySetAsSeries(dH, true); ArraySetAsSeries(dL, true);
   if(CopyHigh(_Symbol, PERIOD_D1, 1, 1, dH) >= 1 && CopyLow(_Symbol, PERIOD_D1, 1, 1, dL) >= 1)
     {
      pdh = dH[0];
      pdl = dL[0];
     }
  }

//+------------------------------------------------------------------+
//| Update Asian Session Range (00:00 - 07:00 UTC)                   |
//+------------------------------------------------------------------+
void UpdateAsianRange()
  {
   MqlDateTime dt; TimeToStruct(TimeGMT(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today == lastAsianDate && dt.hour >= 7) return;

   datetime startT = today;
   datetime endT   = today + 7 * 3600;

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
      if(dt.hour >= 7) lastAsianDate = today;
     }
  }

//+------------------------------------------------------------------+
//| Position Checker                                                 |
//+------------------------------------------------------------------+
bool HasOpenPosition()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol)
        {
         ulong m = pos.Magic();
         if(m >= MagicNumber && m <= MagicNumber + 3) return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Daily Loss Check                                                 |
//+------------------------------------------------------------------+
void UpdateDailyLosses(datetime today)
  {
   dailyLosses = 0;
   HistorySelect(today, TimeCurrent());
   int total = HistoryDealsTotal();
   int consec = 0;
   for(int i = 0; i < total; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
           {
            ulong m = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            if(m >= MagicNumber && m <= MagicNumber + 3)
              {
               double p = HistoryDealGetDouble(ticket, DEAL_PROFIT);
               if(p < 0) consec++;
               else if(p > 0) consec = 0;
              }
           }
        }
     }
   dailyLosses = consec;
  }

//+------------------------------------------------------------------+
//| Lot Calculation                                                  |
//+------------------------------------------------------------------+
double CalculateLots(double slDistancePips)
  {
   if(UseFixedLot) return NormalizeDouble(FixedLotSize, 2);

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double capital = MathMin(balance, equity);

   double riskMoney = capital * (RiskPercent / 100.0);
   double pip       = _Point * 10;
   double tv        = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts        = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pv        = (pip / ts) * tv;

   if(slDistancePips <= 0 || pv <= 0) return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   double lots = riskMoney / (slDistancePips * pv);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / step) * step;

   return NormalizeDouble(MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), MathMin(MaxLotCap, lots)), 2);
  }

//+------------------------------------------------------------------+
//| Order Placement                                                  |
//+------------------------------------------------------------------+
void ExecuteTrade(int dir, double lots, double entry, double sl, string comment)
  {
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   if(ExecutionMode == EXEC_SINGLE_RUNNER)
     {
      double tp = (dir > 0) ? (entry + SingleTarget_RR * (entry - sl))
                            : (entry - SingleTarget_RR * (sl - entry));
      tp = NormalizeDouble(tp, _Digits);
      trade.SetExpertMagicNumber(MagicNumber);
      if(dir > 0) trade.Buy(lots, _Symbol, entry, sl, tp, comment);
      else        trade.Sell(lots, _Symbol, entry, sl, tp, comment);
      dailyTrades++;
     }
   else if(ExecutionMode == EXEC_DUAL_PARTIAL)
     {
      double lot1 = MathMax(minLot, MathFloor((lots * 0.50) / step) * step);
      double lot2 = MathMax(minLot, NormalizeDouble(lots - lot1, 2));

      double tp1 = (dir > 0) ? NormalizeDouble(entry + Part1_RR * (entry - sl), _Digits)
                             : NormalizeDouble(entry - Part1_RR * (sl - entry), _Digits);
      double tp2 = (dir > 0) ? NormalizeDouble(entry + Part2_RR * (entry - sl), _Digits)
                             : NormalizeDouble(entry - Part2_RR * (sl - entry), _Digits);

      trade.SetExpertMagicNumber(MagicNumber + 1);
      if(dir > 0) trade.Buy(lot1, _Symbol, entry, sl, tp1, comment + "-P1");
      else        trade.Sell(lot1, _Symbol, entry, sl, tp1, comment + "-P1");

      trade.SetExpertMagicNumber(MagicNumber + 2);
      if(dir > 0) trade.Buy(lot2, _Symbol, entry, sl, tp2, comment + "-P2");
      else        trade.Sell(lot2, _Symbol, entry, sl, tp2, comment + "-P2");

      dailyTrades++;
     }
  }

//+------------------------------------------------------------------+
//| Manage Dual Partials (Breakeven on TP1 Hit)                      |
//+------------------------------------------------------------------+
void ManagePartials()
  {
   if(ExecutionMode != EXEC_DUAL_PARTIAL || !MoveBE_On_TP1) return;
   double pip = _Point * 10;
   bool tp1_hit = false;

   HistorySelect(TimeCurrent() - 4 * 3600, TimeCurrent());
   int total = HistoryDealsTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber + 1)
            tp1_hit = true;
        }
     }

   if(tp1_hit)
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MagicNumber + 2)
           {
            ulong ticket = pos.Ticket();
            double openP = pos.PriceOpen();
            double curSL = pos.StopLoss();
            double curTP = pos.TakeProfit();
            if(pos.PositionType() == POSITION_TYPE_BUY)
              {
               double newSL = NormalizeDouble(openP + BE_Offset_Pips * pip, _Digits);
               if(curSL < newSL) trade.PositionModify(ticket, newSL, curTP);
              }
            else if(pos.PositionType() == POSITION_TYPE_SELL)
              {
               double newSL = NormalizeDouble(openP - BE_Offset_Pips * pip, _Digits);
               if(curSL == 0 || curSL > newSL) trade.PositionModify(ticket, newSL, curTP);
              }
           }
        }
     }
  }


void EvaluateSignals()
  {
   double pip = _Point * 10;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 5, rates) < 5) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   int signal = 0; string comment = "";

   // Model 1: Dealing Range OTE (62% - 79% Fibonacci)
   if(StrategyModel == MODEL_1 || StrategyModel == MODEL_ALL_CONFLUENCE)
     {
      double rangeH = MathMax(rates[1].high, rates[2].high);
      double rangeL = MathMin(rates[1].low, rates[2].low);
      double rangeD = rangeH - rangeL;
      if(rangeD >= 10.0 * pip)
        {
         double ote62Buy = rangeL + 0.382 * rangeD; // Pullback level
         double ote79Buy = rangeL + 0.210 * rangeD;
         if(rates[0].low <= ote62Buy && rates[0].low >= ote79Buy && rates[0].close > rates[0].open)
           { signal = 1; comment = "AliKhan-OTE-Buy"; }

         double ote62Sell = rangeH - 0.382 * rangeD;
         double ote79Sell = rangeH - 0.210 * rangeD;
         if(rates[0].high >= ote62Sell && rates[0].high <= ote79Sell && rates[0].close < rates[0].open)
           { signal = -1; comment = "AliKhan-OTE-Sell"; }
        }
     }

   // Model 2: Full Body Displacement Verification
   if((StrategyModel == MODEL_2 || StrategyModel == MODEL_ALL_CONFLUENCE) && signal == 0)
     {
      double body1 = MathAbs(rates[1].close - rates[1].open);
      double range1 = rates[1].high - rates[1].low;
      if(range1 > 0 && (body1 / range1) >= 0.70) // 70%+ full body displacement
        {
         if(rates[1].close > rates[1].open && rates[0].close > rates[1].high)
           { signal = 1; comment = "AliKhan-Displacement-Buy"; }
         else if(rates[1].close < rates[1].open && rates[0].close < rates[1].low)
           { signal = -1; comment = "AliKhan-Displacement-Sell"; }
        }
     }

   // Model 3: Low Resistance Liquidity Run (LRLR)
   if((StrategyModel == MODEL_3 || StrategyModel == MODEL_ALL_CONFLUENCE) && signal == 0)
     {
      if(rates[0].close > rates[1].high && rates[1].close > rates[2].high)
        { signal = 1; comment = "AliKhan-LRLR-Buy"; }
      else if(rates[0].close < rates[1].low && rates[1].close < rates[2].low)
        { signal = -1; comment = "AliKhan-LRLR-Sell"; }
     }

   if(signal != 0)
     {
      double sl = (signal > 0) ? NormalizeDouble(ask - SL_Pips * pip, _Digits)
                               : NormalizeDouble(bid + SL_Pips * pip, _Digits);
      double lots = CalculateLots(SL_Pips);
      if(lots > 0) ExecuteTrade(signal, lots, (signal > 0 ? ask : bid), sl, comment);
     }
  }


//+------------------------------------------------------------------+
//| OnTick Handling                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   ManagePartials();

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastTradeDay != today) { dailyTrades = 0; lastTradeDay = today; }
   if(dailyTrades >= MaxDailyTrades) return;

   UpdateDailyLosses(today);
   if(dailyLosses >= MaxDailyLosses) return;

   MqlDateTime gmt; TimeToStruct(TimeGMT(), gmt);
   if(gmt.day_of_week == 0 || gmt.day_of_week == 6) return;
   if(gmt.hour < StartHourUTC || gmt.hour >= EndHourUTC) return;
   if((double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpreadPips) return;

   UpdatePDH_PDL();
   UpdateAsianRange();

   static datetime lastBar = 0;
   datetime curBar = iTime(_Symbol, _Period, 0);
   if(lastBar == curBar) return;
   lastBar = curBar;

   if(HasOpenPosition()) return;

   EvaluateSignals();
  }
//+------------------------------------------------------------------+
