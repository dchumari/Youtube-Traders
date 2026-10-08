//+------------------------------------------------------------------+
//|  Gold_Master_Super_EA.mq5                                        |
//|  Strategy: Master Super Gold Strategy (3-Month Doubling Target)   |
//|  Core:     Institutional CPR + SMC Sweep + Multi-Target Partials |
//|  Asset:    XAUUSD (Gold) M1                                      |
//|  Version:  3.10 | Master Production Super Strategy               |
//+------------------------------------------------------------------+
#property copyright "Master Quant Architecture"
#property link      "https://youtube-traders.pipeline"
#property version   "3.10"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <TradingView_Visualizer.mqh>

enum ENUM_EXECUTION_MODE
  {
   EXEC_SINGLE_RUNNER  = 0,  // Single Full Target (2.5R or 3.0R)
   EXEC_DUAL_PARTIAL   = 1,  // Dual Partials (50% @ 1:1, 50% @ 1:2)
   EXEC_TRIPLE_PARTIAL = 2   // Triple Partials (33% @ 1:1, 33% @ 1:2, 34% @ 1:3)
  };

enum ENUM_COMPOUND_MODE
  {
   COMP_BALANCE_FRACTIONAL = 0, // Fractional Balance Compounding
   COMP_MILESTONE_STEPUP   = 1, // Milestone Step-Up (Aggressive 3-Month Doubling)
   COMP_STREAK_SCALING     = 2  // Anti-Martingale Win Streak Scaling
  };

input group "=== Compounding & Risk Engine (3-Month 2x Target) ==="
input double               RiskPercent           = 3.0;              // Base Risk Per Trade (%) [2.0% - 6.0%]
input ENUM_COMPOUND_MODE   CompoundMode          = COMP_MILESTONE_STEPUP; // Compounding Mode
input double               MilestoneStepUSD      = 2000.0;           // Milestone Step Threshold ($)
input double               MilestoneRiskBoost    = 0.40;             // Risk Boost Per Milestone ($)
input double               MaxRiskCapPercent     = 7.00;             // Maximum Risk Cap (%)
input double               ConfluenceBoost       = 1.25;             // Lot Boost when SMC/Volume Confirms
input bool                 UseFixedLot           = false;            // Use Fixed Lot
input double               FixedLot              = 0.01;             // Fixed Lot Size

input group "=== Partial Profit Scale-Outs (1:1, 1:2, 1:3) ==="
input ENUM_EXECUTION_MODE  ExecutionMode         = EXEC_SINGLE_RUNNER; // Execution Mode
input double               Part1_RR              = 1.0;              // Target 1 (1:1 R:R)
input double               Part2_RR              = 2.0;              // Target 2 (1:2 R:R)
input double               Part3_RR              = 3.0;              // Target 3 (1:3 R:R)
input double               SingleTarget_RR       = 2.5;              // Single Target R:R (Default 2.5)
input double               Part1_Ratio           = 0.33;             // Part 1 Volume Allocation
input double               Part2_Ratio           = 0.33;             // Part 2 Volume Allocation
input double               Part3_Ratio           = 0.34;             // Part 3 Volume Allocation
input bool                 MoveBE_On_TP1         = true;             // Move SL to Breakeven when TP1 Hits
input double               BE_Offset_Pips        = 1.0;              // Breakeven Buffer (Pips)
input bool                 LockProfit_On_TP2     = true;             // Lock +1.0R when TP2 Hits

input group "=== System B: Central Pivot Range (CPR Core) ==="
input double               CPR_NarrowMax         = 18.0;             // Narrow CPR Threshold (Pips)
input double               CPR_WideMin           = 30.0;             // Wide CPR Threshold (Pips)
input double               SL_Pips_B             = 15.0;             // Stop Loss Distance (Pips)

input group "=== Confluence Enhancers (SMC & Volume) ==="
input bool                 Enable_SMC_Confluence = true;             // SMC Asian Sweep Confluence
input int                  AsianStartHour        = 0;                // Asian Session Start UTC
input int                  AsianEndHour          = 7;                // Asian Session End UTC
input double               AsianSweepPips        = 3.0;              // Asian Sweep Buffer (Pips)
input bool                 Enable_Vol_Confluence = true;             // Volume Spike Confluence
input int                  VolMAPeriod           = 20;               // Volume MA Period
input double               VolSpikeRatio         = 1.30;             // Volume Spike Ratio

input group "=== Trade Controls & Sessions ==="
input int                  MaxDailyTrades        = 2;                // Max Daily Trades
input int                  SessionStartHour      = 13;               // NY Start Hour UTC
input int                  SessionEndHour        = 19;               // NY End Hour UTC
input double               MaxSpread             = 20.0;             // Max Spread (Pips)
input ulong                MasterMagic           = 20262000;         // Master Magic Number

input group "=== Visuals: TradingView Chart Overlay ==="
input bool                 InpShowTradeBoxes     = true;             // Enable TradingView Profit/Loss Boxes
input bool                 InpShowEntryArrows    = true;             // Enable Directional Entry Arrows
input bool                 InpShowBadges         = true;             // Enable PnL & Level Badges
input bool                 InpShowConnLines      = true;             // Enable Entry-to-Exit Connecting Line
input string               InpVisualPrefix       = "TV_GMS_";        // Visual Objects Unique Prefix
input bool                 InpCleanOnDeinit      = false;            // Clean Visuals on Unload

//--- Global Objects
CTrade trade;
CPositionInfo pos;
int dailyTrades = 0;
datetime lastTradeDay = 0;

// CPR variables
double cpr_TC = 0.0, cpr_BC = 0.0, cpr_Pivot = 0.0, cpr_Width = 0.0;
datetime lastCPRDate = 0;

// Asian Session variables
double asianHigh = 0.0, asianLow = 999999.0;
datetime lastAsianDate = 0;

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MasterMagic);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   TV_Visualizer_Init(MasterMagic, InpShowTradeBoxes, InpVisualPrefix,
                      InpShowEntryArrows, InpShowBadges, InpShowTradeBoxes,
                      InpShowConnLines, InpCleanOnDeinit);
   TV_Visualizer_PlotHistory();

   Print("Gold Master Super Strategy EA v3.10 Initialized.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   TV_Visualizer_Deinit();
  }

//+------------------------------------------------------------------+
//| Update CPR (Exact Verified Formulation)                          |
//+------------------------------------------------------------------+
void UpdateCPR()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastCPRDate == today) return;
   lastCPRDate = today;

   double dH[], dL[], dC[];
   ArraySetAsSeries(dH, true); ArraySetAsSeries(dL, true); ArraySetAsSeries(dC, true);
   if(CopyHigh(_Symbol, PERIOD_D1, 1, 1, dH) < 1) return;
   if(CopyLow(_Symbol, PERIOD_D1, 1, 1, dL) < 1)  return;
   if(CopyClose(_Symbol, PERIOD_D1, 1, 1, dC) < 1) return;

   cpr_Pivot = (dH[0] + dL[0] + dC[0]) / 3.0;
   cpr_BC    = (dH[0] + dL[0]) / 2.0;
   cpr_TC    = (cpr_Pivot - cpr_BC) + cpr_Pivot;
   cpr_Width = (cpr_TC - cpr_BC) / (_Point * 10);
  }

//+------------------------------------------------------------------+
//| Update Asian Session High/Low                                    |
//+------------------------------------------------------------------+
void UpdateAsianRange()
  {
   MqlDateTime dt; TimeToStruct(TimeGMT(), dt);
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
//| Check Open Positions                                             |
//+------------------------------------------------------------------+
bool HasOpenPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol)
        {
         ulong m = pos.Magic();
         if(m >= MasterMagic && m <= MasterMagic + 5) return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Session Filter                                                   |
//+------------------------------------------------------------------+
bool IsSessionAllowed(const MqlDateTime &gmt)
  {
   if(gmt.day_of_week == 0 || gmt.day_of_week == 6) return false;
   return (gmt.hour >= SessionStartHour && gmt.hour < SessionEndHour);
  }

//+------------------------------------------------------------------+
//| Dynamic Compounding Calculator                                   |
//+------------------------------------------------------------------+
double CalculateMasterLots(double slPips, bool hasConfluence)
  {
   if(UseFixedLot) return NormalizeDouble(FixedLot, 2);

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double capital = MathMax(balance, equity);

   double effRisk = RiskPercent;

   // Milestone Step-Up Compounding: As account grows, scale risk to hit 2x Doubling
   if(CompoundMode == COMP_MILESTONE_STEPUP)
     {
      if(capital > 10000.0)
        {
         double profit = capital - 10000.0;
         int milestones = (int)MathFloor(profit / MilestoneStepUSD);
         effRisk += (milestones * MilestoneRiskBoost);
        }
     }

   if(hasConfluence)
     {
      effRisk *= ConfluenceBoost;
     }

   effRisk = MathMin(effRisk, MaxRiskCapPercent);

   double riskMoney = capital * effRisk / 100.0;
   double pip       = _Point * 10;
   double tv        = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts        = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pv        = (pip / ts) * tv;
   double lots      = riskMoney / (slPips * pv);
   double step      = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / step) * step;

   return NormalizeDouble(MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), MathMin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), lots)), 2);
  }

//+------------------------------------------------------------------+
//| Manage Partials (Breakeven on TP1, Lock Profit on TP2)           |
//+------------------------------------------------------------------+
void ManagePartials(double slPips)
  {
   if(ExecutionMode == EXEC_SINGLE_RUNNER) return;
   double pip = _Point * 10;
   bool tp1_hit = false;
   bool tp2_hit = false;

   HistorySelect(TimeCurrent() - 4 * 3600, TimeCurrent());
   int totalDeals = HistoryDealsTotal();
   for(int i = totalDeals - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
           {
            ulong m = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            if(m == MasterMagic + 1) tp1_hit = true;
            if(m == MasterMagic + 2) tp2_hit = true;
           }
        }
     }

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol)
        {
         ulong m = pos.Magic();
         if(m < MasterMagic + 1 || m > MasterMagic + 3) continue;

         ulong ticket     = pos.Ticket();
         double openPrice = pos.PriceOpen();
         double curSL     = pos.StopLoss();
         double curTP     = pos.TakeProfit();
         ENUM_POSITION_TYPE type = pos.PositionType();

         // Move to BE on TP1 hit
         if(tp1_hit && MoveBE_On_TP1)
           {
            if(type == POSITION_TYPE_BUY)
              {
               double newSL = NormalizeDouble(openPrice + BE_Offset_Pips * pip, _Digits);
               if(curSL < newSL) { trade.PositionModify(ticket, newSL, curTP); curSL = newSL; }
              }
            else if(type == POSITION_TYPE_SELL)
              {
               double newSL = NormalizeDouble(openPrice - BE_Offset_Pips * pip, _Digits);
               if(curSL == 0 || curSL > newSL) { trade.PositionModify(ticket, newSL, curTP); curSL = newSL; }
              }
           }

         // Lock +1.0R on TP2 hit for Part 3
         if(tp2_hit && m == MasterMagic + 3 && LockProfit_On_TP2)
           {
            if(type == POSITION_TYPE_BUY)
              {
               double lockSL = NormalizeDouble(openPrice + Part1_RR * slPips * pip, _Digits);
               if(curSL < lockSL) { trade.PositionModify(ticket, lockSL, curTP); }
              }
            else if(type == POSITION_TYPE_SELL)
              {
               double lockSL = NormalizeDouble(openPrice - Part1_RR * slPips * pip, _Digits);
               if(curSL == 0 || curSL > lockSL) { trade.PositionModify(ticket, lockSL, curTP); }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Execute Order Placement                                          |
//+------------------------------------------------------------------+
void PlaceMasterTrade(int dir, double totalLots, double entryPrice, double slPrice, double slPips)
  {
   double pip = _Point * 10;
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   // Mode 0: Single Target (2.5R or 3.0R)
   if(ExecutionMode == EXEC_SINGLE_RUNNER)
     {
      double tp = (dir > 0) ? (entryPrice + SingleTarget_RR * (entryPrice - slPrice))
                            : (entryPrice - SingleTarget_RR * (slPrice - entryPrice));
      tp = NormalizeDouble(tp, _Digits);
      trade.SetExpertMagicNumber(MasterMagic);
      if(dir > 0) trade.Buy(totalLots, _Symbol, entryPrice, slPrice, tp, "Super-SingleBuy");
      else        trade.Sell(totalLots, _Symbol, entryPrice, slPrice, tp, "Super-SingleSell");
      dailyTrades++;
      return;
     }

   // Mode 1: Dual Partials (50% @ 1:1, 50% @ 1:2)
   if(ExecutionMode == EXEC_DUAL_PARTIAL)
     {
      double lot1 = MathMax(minLot, MathFloor((totalLots * 0.50) / step) * step);
      double lot2 = MathMax(minLot, totalLots - lot1);

      double tp1 = (dir > 0) ? NormalizeDouble(entryPrice + Part1_RR * (entryPrice - slPrice), _Digits)
                             : NormalizeDouble(entryPrice - Part1_RR * (slPrice - entryPrice), _Digits);
      double tp2 = (dir > 0) ? NormalizeDouble(entryPrice + Part2_RR * (entryPrice - slPrice), _Digits)
                             : NormalizeDouble(entryPrice - Part2_RR * (slPrice - entryPrice), _Digits);

      trade.SetExpertMagicNumber(MasterMagic + 1);
      if(dir > 0) trade.Buy(lot1, _Symbol, entryPrice, slPrice, tp1, "Super-Dual-TP1");
      else        trade.Sell(lot1, _Symbol, entryPrice, slPrice, tp1, "Super-Dual-TP1");

      trade.SetExpertMagicNumber(MasterMagic + 2);
      if(dir > 0) trade.Buy(lot2, _Symbol, entryPrice, slPrice, tp2, "Super-Dual-TP2");
      else        trade.Sell(lot2, _Symbol, entryPrice, slPrice, tp2, "Super-Dual-TP2");

      dailyTrades++;
      return;
     }

   // Mode 2: Triple Partials (33% @ 1:1, 33% @ 1:2, 34% @ 1:3)
   if(ExecutionMode == EXEC_TRIPLE_PARTIAL)
     {
      double lot1 = MathMax(minLot, MathFloor((totalLots * Part1_Ratio) / step) * step);
      double lot2 = MathMax(minLot, MathFloor((totalLots * Part2_Ratio) / step) * step);
      double lot3 = MathMax(minLot, NormalizeDouble(totalLots - lot1 - lot2, 2));

      double tp1 = (dir > 0) ? NormalizeDouble(entryPrice + Part1_RR * (entryPrice - slPrice), _Digits)
                             : NormalizeDouble(entryPrice - Part1_RR * (slPrice - entryPrice), _Digits);
      double tp2 = (dir > 0) ? NormalizeDouble(entryPrice + Part2_RR * (entryPrice - slPrice), _Digits)
                             : NormalizeDouble(entryPrice - Part2_RR * (slPrice - entryPrice), _Digits);
      double tp3 = (dir > 0) ? NormalizeDouble(entryPrice + Part3_RR * (entryPrice - slPrice), _Digits)
                             : NormalizeDouble(entryPrice - Part3_RR * (slPrice - entryPrice), _Digits);

      trade.SetExpertMagicNumber(MasterMagic + 1);
      if(dir > 0) trade.Buy(lot1, _Symbol, entryPrice, slPrice, tp1, "Super-Triple-TP1");
      else        trade.Sell(lot1, _Symbol, entryPrice, slPrice, tp1, "Super-Triple-TP1");

      trade.SetExpertMagicNumber(MasterMagic + 2);
      if(dir > 0) trade.Buy(lot2, _Symbol, entryPrice, slPrice, tp2, "Super-Triple-TP2");
      else        trade.Sell(lot2, _Symbol, entryPrice, slPrice, tp2, "Super-Triple-TP2");

      trade.SetExpertMagicNumber(MasterMagic + 3);
      if(dir > 0) trade.Buy(lot3, _Symbol, entryPrice, slPrice, tp3, "Super-Triple-TP3");
      else        trade.Sell(lot3, _Symbol, entryPrice, slPrice, tp3, "Super-Triple-TP3");

      dailyTrades++;
      return;
     }
  }

//+------------------------------------------------------------------+
//| OnTick Handling                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   ManagePartials(SL_Pips_B);

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastTradeDay != today) { dailyTrades = 0; lastTradeDay = today; }
   if(dailyTrades >= MaxDailyTrades) return;

   MqlDateTime gmt; TimeToStruct(TimeGMT(), gmt);
   if(!IsSessionAllowed(gmt)) return;
   if((double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpread) return;

   UpdateCPR();
   UpdateAsianRange();

   static datetime lastBar = 0;
   datetime curBar = iTime(_Symbol, PERIOD_M1, 0);
   if(lastBar == curBar) return;
   lastBar = curBar;

   if(HasOpenPositions()) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pip = _Point * 10;

   // Check Confluence Signals
   bool smcBullSweep = false;
   bool smcBearSweep = false;
   if(Enable_SMC_Confluence && asianHigh > 0 && asianLow < 999999.0)
     {
      MqlRates m1Rates[];
      ArraySetAsSeries(m1Rates, true);
      if(CopyRates(_Symbol, PERIOD_M1, 1, 3, m1Rates) >= 3)
        {
         if(m1Rates[1].low <= asianLow - AsianSweepPips * pip && m1Rates[0].close > asianLow) smcBullSweep = true;
         if(m1Rates[1].high >= asianHigh + AsianSweepPips * pip && m1Rates[0].close < asianHigh) smcBearSweep = true;
        }
     }

   bool volSpike = false;
   if(Enable_Vol_Confluence)
     {
      long vol[];
      ArraySetAsSeries(vol, true);
      if(CopyTickVolume(_Symbol, PERIOD_M1, 1, VolMAPeriod + 1, vol) >= VolMAPeriod + 1)
        {
         double sumVol = 0;
         for(int i = 1; i <= VolMAPeriod; i++) sumVol += (double)vol[i];
         double avgVol = sumVol / VolMAPeriod;
         if((double)vol[0] >= avgVol * VolSpikeRatio) volSpike = true;
        }
     }

   // CPR Core Breakout & Reversal
   if(cpr_TC > 0 && cpr_BC > 0)
     {
      bool narrow = (cpr_Width <= CPR_NarrowMax);
      bool wide   = (cpr_Width >= CPR_WideMin);

      if(narrow)
        {
         // Bullish Narrow Breakout
         if(bid > cpr_TC && ask - cpr_TC < SL_Pips_B * pip * 2)
           {
            double sl = cpr_BC - SL_Pips_B * pip;
            double slPips = (bid - sl) / pip;
            bool confluence = (smcBullSweep || volSpike);
            double lots = CalculateMasterLots(slPips, confluence);
            if(lots > 0) PlaceMasterTrade(1, lots, ask, sl, slPips);
           }
         // Bearish Narrow Breakout
         else if(bid < cpr_BC && cpr_BC - ask < SL_Pips_B * pip * 2)
           {
            double sl = cpr_TC + SL_Pips_B * pip;
            double slPips = (sl - bid) / pip;
            bool confluence = (smcBearSweep || volSpike);
            double lots = CalculateMasterLots(slPips, confluence);
            if(lots > 0) PlaceMasterTrade(-1, lots, bid, sl, slPips);
           }
        }
      else if(wide)
        {
         // Wide CPR Mean Reversion Sell
         if(MathAbs(bid - cpr_TC) < SL_Pips_B * pip)
           {
            double sl = cpr_TC + SL_Pips_B * 2 * pip;
            if(cpr_TC - cpr_BC >= SingleTarget_RR * (sl - cpr_TC))
              {
               double slPips = SL_Pips_B * 2;
               bool confluence = (smcBearSweep || volSpike);
               double lots = CalculateMasterLots(slPips, confluence);
               if(lots > 0) PlaceMasterTrade(-1, lots, bid, sl, slPips);
              }
           }
         // Wide CPR Mean Reversion Buy
         else if(MathAbs(ask - cpr_BC) < SL_Pips_B * pip)
           {
            double sl = cpr_BC - SL_Pips_B * 2 * pip;
            if(cpr_TC - cpr_BC >= SingleTarget_RR * (cpr_BC - sl))
              {
               double slPips = SL_Pips_B * 2;
               bool confluence = (smcBullSweep || volSpike);
               double lots = CalculateMasterLots(slPips, confluence);
               if(lots > 0) PlaceMasterTrade(1, lots, ask, sl, slPips);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Trade transaction handler for visual box updates                 |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   TV_Visualizer_OnTradeTransaction(trans, request, result);
}
//+------------------------------------------------------------------+
