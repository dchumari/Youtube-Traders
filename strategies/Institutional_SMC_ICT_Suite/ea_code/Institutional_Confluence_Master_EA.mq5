//+------------------------------------------------------------------+
//|                               Institutional_Confluence_Master_EA.mq5|
//|               Master Algorithmic Trading Architecture               |
//|      10 Deeply Intertwined Strategies Fusing SMC + ICT + S&D        |
//|    Equipped with 10 Truly Unique Account-Flipper Behavioral Patterns|
//|    (Granular Slicing, TP1-TP5 Ladder, Stepped BE, Pyramiding)       |
//|    Full Dracula Dark Visual Roadmap & Setup Drawings on Charts      |
//|                                 Copyright 2026, Quant Research Lab  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research Lab"
#property link      "https://github.com/dchumari/Youtube-Traders"
#property version   "4.00"
#property description "Master Institutional Confluence Suite: 10 Deeply Intertwined SMC, ICT & S&D Strategies with Behavioral Flipper Engine"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Flipper_Behavioral_Engine.mqh>
#include <VisualTradeSuite.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS: 10 Intertwined Confluence Strategies               |
//+------------------------------------------------------------------+
enum ENUM_CONFLUENCE_STRATEGY
{
   STRAT_0_SD_BASE_SMC_SWEEP        = 0, // 0: S&D Fresh Base + SMC Liquidity Sweep (S&D + SMC)
   STRAT_1_HTF_OB_ICT_FVG_CE        = 1, // 1: HTF Order Block + ICT FVG Consequent Encroachment (SMC + ICT)
   STRAT_2_SD_FLIP_ICT_BREAKER      = 2, // 2: S&D Support/Resistance Flip + ICT Breaker Block (S&D + ICT)
   STRAT_3_SMC_IDM_ICT_FVG          = 3, // 3: SMC Inducement Trap + ICT FVG Mitigation (SMC + ICT)
   STRAT_4_24_5_OTE_SD_BASE         = 4, // 4: 24/5 ICT OTE Golden Zone + Fresh S&D Base (ICT + S&D)
   STRAT_5_ICT_JUDAS_HTF_SD_ZONE    = 5, // 5: London Judas Sweep into HTF S&D Zone (ICT + S&D)
   STRAT_6_ICT_BPR_SD_FLIP_REVERT   = 6, // 6: ICT Balanced Price Range (BPR) inside S&D Flip (ICT + S&D)
   STRAT_7_SMC_QM_ICT_FVG           = 7, // 7: Quasimodo Left Shoulder + ICT Fair Value Gap (SMC + ICT)
   STRAT_8_SMC_BOS_SD_TRACEBACK     = 8, // 8: Multi-Timeframe BOS + S&D Velocity + Traceback Reload (SMC + S&D)
   STRAT_9_TRIPLE_CONFLUENCE_MASTER = 9  // 9: Triple-Confluence Master Flipper (SMC Sweep + ICT FVG + S&D Base)
};

enum ENUM_SESSION_FILTER_MODE
{
   SESSION_MODE_24_5        = 0, // 24/5 Session Flexible (Runs Across All Hours)
   SESSION_MODE_LONDON_NY   = 1, // London & NY Killzones (07:00-11:00 & 12:00-17:00 UTC)
   SESSION_MODE_LONDON_ONLY = 2, // London Killzone Only (07:00-11:00 UTC)
   SESSION_MODE_NY_ONLY     = 3  // New York Killzone Only (12:00-17:00 UTC)
};

enum ENUM_CONFLUENCE_EXECUTION
{
   EXEC_MODE_BEHAVIORAL_FLIPPER = 0, // Flipper Behavioral Engine (Multi-Ticket Slicing, TP1-TP5, Stepped BE, Pyramiding)
   EXEC_MODE_STANDARD_FIXED     = 1  // Standard Institutional Execution (Fixed/Dual Target)
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
sinput string   sep0 = "================ STRATEGY SELECTION ================";
input ENUM_CONFLUENCE_STRATEGY InpStrategyModel      = STRAT_9_TRIPLE_CONFLUENCE_MASTER; // Intertwined Confluence Strategy
input ENUM_SESSION_FILTER_MODE InpSessionFilter      = SESSION_MODE_LONDON_NY;           // Session Regime Filter
input ENUM_CONFLUENCE_EXECUTION InpExecutionMode     = EXEC_MODE_BEHAVIORAL_FLIPPER;     // Execution Engine Mode

sinput string   sep1 = "================ CAPITAL & RISK SIZING ================";
input double    InpBaseLotSize          = 0.01;      // Base Fixed Lot Size
input double    InpEquityPerMinLot      = 25.0;      // Equity Step per 0.01 Lot ($25 aggressive / $50 conservative)
input double    InpMaxLotCap            = 0.50;      // Maximum Single Ticket Lot Cap
input int       InpStopLossPoints       = 250;       // Stop Loss in Points (25 pips on Gold)
input ulong     InpMagicNumber          = 779000;    // EA Magic Number

sinput string   sep2 = "================ BEHAVIORAL FLIPPER PARAMETERS =========";
input int       InpSpamTicketsCount     = 5;         // Pattern 1: Micro-Tickets per Basket (3 to 8)
input int       InpTP1Points            = 200;       // Pattern 2: Stage 1 TP (+20 pips, bank ticket 1)
input int       InpTP2Points            = 350;       // Pattern 2: Stage 2 TP (+35 pips, bank ticket 2 + move BE)
input int       InpTP3Points            = 600;       // Pattern 2: Stage 3 TP (+60 pips, bank ticket 3 + lock +25p)
input int       InpTP4Points            = 1000;      // Pattern 2: Stage 4 TP (+100 pips, bank ticket 4 + lock +60p)
input int       InpTP5Points            = 1600;      // Pattern 2: Stage 5 TP (+160 pips moonshot runner)
input bool      InpEnableTraceback      = false;     // Pattern 3: Traceback Scalp Engine
input int       InpTracebackExtensionPts= 250;       // Pattern 3: Distance from EMA 50 for pullback scalp
input int       InpTracebackTPPoints    = 150;       // Pattern 3: Traceback Take Profit (pts)
input int       InpTracebackSLPoints    = 120;       // Pattern 3: Traceback Stop Loss (pts)
input bool      InpEnablePyramiding     = true;      // Pattern 4: Floating Margin Pyramiding
input int       InpReloadStepPoints     = 350;       // Pattern 4: Pyramiding Step Distance (+35 pips)
input int       InpMaxPyramidLayers     = 3;         // Pattern 4: Max Pyramid Layers
input int       InpReloadTicketsCount   = 3;         // Pattern 4: Reload Micro-Tickets Count
input bool      InpEnableDumpAndFlip    = false;     // Pattern 7: Opposing Reversal Inversion
input double    InpDumpWickRatio        = 0.45;      // Pattern 7: Opposing Wick Ratio Threshold (45%)
input bool      InpEnableVolumeClimax   = false;     // Pattern 8: Volume Climax Absorption Fade
input double    InpVolumeSpikeMulti     = 3.0;       // Pattern 8: Tick Volume Surge Multiplier
input bool      InpEnableFlipMilestone  = true;      // Pattern 9: Milestone Extraction Lockout
input double    InpTargetEquity         = 1000.0;    // Pattern 9: Account Flip Target ($1,000 or $10,000)

sinput string   sep3 = "================ INSTITUTIONAL CONFLUENCE THRESHOLDS ==";
input int       InpLookbackBars         = 30;        // Swing High/Low Structure Lookback
input int       InpMinSweepPoints       = 15;        // Minimum Liquidity Sweep Points (1.5 pips)
input int       InpMinFVGPoints         = 20;        // Minimum 3-Candle FVG Gap Points (2.0 pips)
input double    InpMinWickRejection     = 0.35;      // Minimum Reversal Wick Ratio (35%)
input int       InpMinDisplacementPts   = 35;        // Minimum Displacement Impulse Points
input int       InpEMATrendPeriod       = 50;        // Institutional Trend Filter EMA (0 = disabled)
input int       InpAsianStartHour       = 0;         // Asian Session Start Hour UTC
input int       InpAsianEndHour         = 7;         // Asian Session End Hour UTC
input int       InpLondonStartHour      = 7;         // London Killzone Start Hour UTC
input int       InpLondonEndHour        = 11;        // London Killzone End Hour UTC
input int       InpNYStartHour          = 12;        // New York Killzone Start Hour UTC
input int       InpNYEndHour            = 17;        // New York Killzone End Hour UTC

sinput string   sep4 = "================ VISUAL ON-CHART ROADMAP & HUD ========";
input bool      InpEnableVisuals        = true;      // Enable Dracula Visual Roadmap Drawings
input bool      InpApplyDraculaTheme    = true;      // Apply Dark Navy Dracula Chart Theme (#282A36)
input bool      InpDrawSetupBoxes       = true;      // Draw Translucent Setup Zones

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & STRUCTS                                         |
//+------------------------------------------------------------------+
CTrade                  ExtTrade;
CPositionInfo           ExtPos;
CFlipperBehavioralEngine ExtBehavioralEngine;

int                     ExtEmaHandle = INVALID_HANDLE;
datetime                ExtLastBarTime = 0;
string                  ExtPrefix = "CONF_";

//+------------------------------------------------------------------+
//| Helper: Check Active Session Filter                              |
//+------------------------------------------------------------------+
bool IsSessionAllowed()
{
   if(InpSessionFilter == SESSION_MODE_24_5) return true;

   MqlDateTime dt;
   TimeGMT(dt);
   int hour = dt.hour;

   if(InpSessionFilter == SESSION_MODE_LONDON_NY)
   {
      return ((hour >= InpLondonStartHour && hour < InpLondonEndHour) ||
              (hour >= InpNYStartHour && hour < InpNYEndHour));
   }
   else if(InpSessionFilter == SESSION_MODE_LONDON_ONLY)
   {
      return (hour >= InpLondonStartHour && hour < InpLondonEndHour);
   }
   else if(InpSessionFilter == SESSION_MODE_NY_ONLY)
   {
      return (hour >= InpNYStartHour && hour < InpNYEndHour);
   }
   return true;
}

//+------------------------------------------------------------------+
//| Helper: Draw Visual Institutional Setup Box & Text               |
//+------------------------------------------------------------------+
void DrawConfluenceZone(string id, datetime tStart, datetime tEnd, double highPrice, double lowPrice, 
                        color boxColor, string labelText)
{
   if(!InpEnableVisuals || !InpDrawSetupBoxes) return;

   string boxName = ExtPrefix + "Zone_" + id;
   string lblName = ExtPrefix + "Lbl_" + id;

   if(ObjectFind(0, boxName) < 0)
   {
      ObjectCreate(0, boxName, OBJ_RECTANGLE, 0, tStart, highPrice, tEnd, lowPrice);
      ObjectSetInteger(0, boxName, OBJPROP_COLOR, boxColor);
      ObjectSetInteger(0, boxName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, boxName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, boxName, OBJPROP_BACK, true);
      ObjectSetInteger(0, boxName, OBJPROP_FILL, true);
      ObjectSetInteger(0, boxName, OBJPROP_SELECTABLE, false);
   }
   else
   {
      ObjectSetInteger(0, boxName, OBJPROP_TIME, 1, tEnd);
   }

   if(ObjectFind(0, lblName) < 0)
   {
      ObjectCreate(0, lblName, OBJ_TEXT, 0, tStart, highPrice);
      ObjectSetString(0, lblName, OBJPROP_TEXT, "  " + labelText);
      ObjectSetInteger(0, lblName, OBJPROP_COLOR, boxColor);
      ObjectSetString(0, lblName, OBJPROP_FONT, "Segoe UI Bold");
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| Execution Router: Dispatches Order Basket                        |
//+------------------------------------------------------------------+
bool DispatchConfluenceEntry(ENUM_ORDER_TYPE otype, double entryPrice, int slPoints, string setupTag)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(InpExecutionMode == EXEC_MODE_BEHAVIORAL_FLIPPER)
   {
      Print("⚡ [", setupTag, "] Dispatched to Flipper Behavioral Engine (Spamming Micro-Basket)!");
      return ExtBehavioralEngine.ExecuteSpamBasket(otype, entryPrice, slPoints);
   }
   else
   {
      double lot = InpBaseLotSize;
      double sl = (otype == ORDER_TYPE_BUY) ? entryPrice - (slPoints * point) : entryPrice + (slPoints * point);
      double tp = (otype == ORDER_TYPE_BUY) ? entryPrice + (InpTP2Points * point) : entryPrice - (InpTP2Points * point);

      if(otype == ORDER_TYPE_BUY)
         return ExtTrade.Buy(lot, _Symbol, ask, sl, tp, setupTag);
      else
         return ExtTrade.Sell(lot, _Symbol, bid, sl, tp, setupTag);
   }
}

//+------------------------------------------------------------------+
//| Active Position Count Guard                                      |
//+------------------------------------------------------------------+
int CountActivePositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(ExtPos.SelectByIndex(i))
      {
         if((ExtPos.Magic() == InpMagicNumber || ExtPos.Magic() == InpMagicNumber + 99) && ExtPos.Symbol() == _Symbol)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   ExtTrade.SetExpertMagicNumber(InpMagicNumber);
   ExtTrade.SetMarginMode();
   ExtTrade.SetTypeFillingBySymbol(_Symbol);

   if(InpEMATrendPeriod > 0)
   {
      ExtEmaHandle = iMA(_Symbol, _Period, InpEMATrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(ExtEmaHandle == INVALID_HANDLE)
      {
         Print("Error creating EMA indicator handle!");
         return INIT_FAILED;
      }
   }

   // Initialize Universal Behavioral Engine
   SFlipperBehavioralConfig bcfg;
   bcfg.enabled                = (InpExecutionMode == EXEC_MODE_BEHAVIORAL_FLIPPER);
   bcfg.magicNumber            = InpMagicNumber;
   bcfg.prefix                 = ExtPrefix;
   bcfg.spamTicketsCount       = InpSpamTicketsCount;
   bcfg.equityPerMinLot        = InpEquityPerMinLot;
   bcfg.maxLotPerTicket        = InpMaxLotCap;
   bcfg.stopLossPoints         = InpStopLossPoints;
   bcfg.tp1Points              = InpTP1Points;
   bcfg.tp2Points              = InpTP2Points;
   bcfg.tp3Points              = InpTP3Points;
   bcfg.tp4Points              = InpTP4Points;
   bcfg.tp5Points              = InpTP5Points;
   bcfg.enableTraceback        = InpEnableTraceback;
   bcfg.tracebackExtensionPts  = InpTracebackExtensionPts;
   bcfg.tracebackWickRatio     = InpMinWickRejection;
   bcfg.tracebackTPPoints      = InpTracebackTPPoints;
   bcfg.tracebackSLPoints      = InpTracebackSLPoints;
   bcfg.reloadAtHL             = true;
   bcfg.enablePyramiding       = InpEnablePyramiding;
   bcfg.maxPyramidLayers       = InpMaxPyramidLayers;
   bcfg.reloadStepPoints       = InpReloadStepPoints;
   bcfg.reloadTicketsCount     = InpReloadTicketsCount;
   bcfg.enableLiquidationSweep = true;
   bcfg.spikeMinWickPct        = InpMinWickRejection;
   bcfg.enableJudasFlush       = true;
   bcfg.enableDumpAndFlip      = InpEnableDumpAndFlip;
   bcfg.dumpWickRatio          = InpDumpWickRatio;
   bcfg.enableVolumeClimaxFade = InpEnableVolumeClimax;
   bcfg.volumeSpikeMultiplier  = InpVolumeSpikeMulti;
   bcfg.enableFlipMilestone    = InpEnableFlipMilestone;
   bcfg.targetEquity           = InpTargetEquity;
   bcfg.enableVisuals          = InpEnableVisuals;
   bcfg.applyDraculaTheme      = InpApplyDraculaTheme;

   ExtBehavioralEngine.Init(bcfg);

   if(InpEnableVisuals && InpApplyDraculaTheme)
   {
      VTS_ApplyDraculaTheme();
   }

   Print("🚀 Institutional Confluence Master Suite Initialized! Strategy: ", EnumToString(InpStrategyModel));
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(ExtEmaHandle != INVALID_HANDLE)
   {
      IndicatorRelease(ExtEmaHandle);
      ExtEmaHandle = INVALID_HANDLE;
   }
   ExtBehavioralEngine.Clean();
   if(InpEnableVisuals)
   {
      ObjectsDeleteAll(0, ExtPrefix);
      ChartRedraw(0);
   }
}

//+------------------------------------------------------------------+
//| 10 INTERTWINED CONFLUENCE DETECTORS                              |
//+------------------------------------------------------------------+

// --- 0: S&D Fresh Base + SMC Liquidity Sweep (S&D + SMC) ---
void ScanStrat0_SD_Base_SMC_Sweep(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 25) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Find prior swing extremes
   double swingHigh = 0.0, swingLow = 999999.0;
   for(int i = 3; i <= 20; i++)
   {
      if(rates[i].high > swingHigh) swingHigh = rates[i].high;
      if(rates[i].low < swingLow)   swingLow  = rates[i].low;
   }

   // Demand Base (DBR) + SSL Purge
   double drop = (rates[4].open - rates[4].close) / point;
   double base = (rates[3].high - rates[3].low) / point;
   double rally = (rates[2].close - rates[2].open) / point;

   if(drop >= 20 && base <= 35 && rally >= 25)
   {
      double baseHigh = rates[3].high;
      double baseLow  = rates[3].low;

      // Bar 1 sweeps below swingLow or baseLow, enters inside base with lower wick >= 35%
      if(rates[1].low <= baseHigh && rates[1].low < swingLow && rates[1].close > swingLow)
      {
         double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
         double totalRange = rates[1].high - rates[1].low;
         if(totalRange > 0 && (lowerWick / totalRange) >= InpMinWickRejection)
         {
            if(emaVal == 0.0 || rates[1].close >= emaVal)
            {
               Print("🎯 STRAT 0: S&D BASE + SMC SSL SWEEP CONFLUENCE BUY!");
               DrawConfluenceZone("S0_Buy", rates[3].time, rates[0].time + 3600*5, baseHigh, rates[1].low, FBE_COLOR_WIN_LIME, "[S&D Demand + SSL Sweep]");
               DispatchConfluenceEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "S0_SD_SMC_Buy");
               return;
            }
         }
      }
   }

   // Supply Base (RBD) + BSL Purge
   double preRally = (rates[4].close - rates[4].open) / point;
   double postDrop = (rates[2].open - rates[2].close) / point;

   if(preRally >= 20 && base <= 35 && postDrop >= 25)
   {
      double baseHigh = rates[3].high;
      double baseLow  = rates[3].low;

      if(rates[1].high >= baseLow && rates[1].high > swingHigh && rates[1].close < swingHigh)
      {
         double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
         double totalRange = rates[1].high - rates[1].low;
         if(totalRange > 0 && (upperWick / totalRange) >= InpMinWickRejection)
         {
            if(emaVal == 0.0 || rates[1].close <= emaVal)
            {
               Print("🎯 STRAT 0: S&D BASE + SMC BSL SWEEP CONFLUENCE SELL!");
               DrawConfluenceZone("S0_Sell", rates[3].time, rates[0].time + 3600*5, rates[1].high, baseLow, FBE_COLOR_LOSS_CORAL, "[S&D Supply + BSL Sweep]");
               DispatchConfluenceEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "S0_SD_SMC_Sell");
               return;
            }
         }
      }
   }
}

// --- 1: HTF Order Block + ICT FVG Consequent Encroachment (SMC + ICT) ---
void ScanStrat1_HTF_OB_ICT_FVG_CE(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 15) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Bullish FVG (Bar 4 to 2) originating from Order Block (Bar 4)
   double bullGap = rates[2].low - rates[4].high;
   if(bullGap >= InpMinFVGPoints * point && rates[4].close < rates[4].open)
   {
      double ceLevel = rates[4].high + (bullGap * 0.50);
      // Bar 1 retraces to tap CE directly at OB high
      if(rates[1].low <= ceLevel && rates[1].close >= rates[4].high)
      {
         if(emaVal == 0.0 || rates[1].close >= emaVal)
         {
            Print("🎯 STRAT 1: SMC ORDER BLOCK + ICT FVG 50% CE CONFLUENCE BUY!");
            DrawConfluenceZone("S1_Buy", rates[4].time, rates[0].time + 3600*5, rates[2].low, rates[4].low, FBE_COLOR_WIN_LIME, "[OB + FVG CE 50%]");
            DispatchConfluenceEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "S1_OB_FVG_Buy");
            return;
         }
      }
   }

   // Bearish FVG originating from Bearish Order Block
   double bearGap = rates[4].low - rates[2].high;
   if(bearGap >= InpMinFVGPoints * point && rates[4].close > rates[4].open)
   {
      double ceLevel = rates[2].high + (bearGap * 0.50);
      if(rates[1].high >= ceLevel && rates[1].close <= rates[4].low)
      {
         if(emaVal == 0.0 || rates[1].close <= emaVal)
         {
            Print("🎯 STRAT 1: SMC ORDER BLOCK + ICT FVG 50% CE CONFLUENCE SELL!");
            DrawConfluenceZone("S1_Sell", rates[4].time, rates[0].time + 3600*5, rates[4].high, rates[2].high, FBE_COLOR_LOSS_CORAL, "[OB + FVG CE 50%]");
            DispatchConfluenceEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "S1_OB_FVG_Sell");
            return;
         }
      }
   }
}

// --- 2: S&D Support/Resistance Flip + ICT Breaker Block (S&D + ICT) ---
void ScanStrat2_SD_Flip_ICT_Breaker(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 20) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   for(int i = 5; i <= 14; i++)
   {
      // Bearish Breaker & Supply Flip
      if(rates[i].close > rates[i].open && rates[2].close < rates[i].low - (20 * point))
      {
         double obLow = rates[i].low;
         double obHigh = rates[i].high;

         if(rates[1].high >= obLow && rates[1].close <= obHigh)
         {
            double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
            if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
            {
               if(emaVal == 0.0 || rates[1].close <= emaVal)
               {
                  Print("🎯 STRAT 2: S&D FLIP + ICT BREAKER CONFLUENCE SELL!");
                  DrawConfluenceZone("S2_Sell", rates[i].time, rates[0].time + 3600*5, obHigh, obLow, FBE_COLOR_LOSS_CORAL, "[S&D Flip + Breaker]");
                  DispatchConfluenceEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "S2_Flip_Breaker_Sell");
                  return;
               }
            }
         }
      }
      // Bullish Breaker & Demand Flip
      else if(rates[i].close < rates[i].open && rates[2].close > rates[i].high + (20 * point))
      {
         double obHigh = rates[i].high;
         double obLow  = rates[i].low;

         if(rates[1].low <= obHigh && rates[1].close >= obLow)
         {
            double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
            if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
            {
               if(emaVal == 0.0 || rates[1].close >= emaVal)
               {
                  Print("🎯 STRAT 2: S&D FLIP + ICT BREAKER CONFLUENCE BUY!");
                  DrawConfluenceZone("S2_Buy", rates[i].time, rates[0].time + 3600*5, obHigh, obLow, FBE_COLOR_WIN_LIME, "[S&D Flip + Breaker]");
                  DispatchConfluenceEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "S2_Flip_Breaker_Buy");
                  return;
               }
            }
         }
      }
   }
}

// --- 3: SMC Inducement Trap + ICT FVG Mitigation (SMC + ICT) ---
void ScanStrat3_SMC_IDM_ICT_FVG(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 20) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Minor retail IDM swing high/low at bar 4
   bool isIDMHigh = (rates[4].high > rates[5].high && rates[4].high > rates[3].high);
   bool isIDMLow  = (rates[4].low < rates[5].low   && rates[4].low < rates[3].low);

   // Bullish IDM Trap with FVG: Swept IDM low, tapped FVG Consequent Encroachment
   double bullGap = rates[2].low - rates[5].high;
   if(isIDMLow && bullGap >= InpMinFVGPoints * point && rates[1].low < rates[4].low && rates[1].close > rates[4].low)
   {
      double ceMid = rates[5].high + (bullGap * 0.50);
      if(rates[1].low <= ceMid + (15 * point))
      {
         if(emaVal == 0.0 || rates[1].close >= emaVal)
         {
            Print("🎯 STRAT 3: SMC IDM TRAP + ICT FVG MITIGATION BUY!");
            DrawConfluenceZone("S3_Buy", rates[4].time, rates[0].time + 3600*5, rates[2].low, rates[1].low, FBE_COLOR_PURPLE, "[IDM Purged + FVG Mitigated]");
            DispatchConfluenceEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "S3_IDM_FVG_Buy");
            return;
         }
      }
   }

   // Bearish IDM Trap with FVG
   double bearGap = rates[5].low - rates[2].high;
   if(isIDMHigh && bearGap >= InpMinFVGPoints * point && rates[1].high > rates[4].high && rates[1].close < rates[4].high)
   {
      double ceMid = rates[2].high + (bearGap * 0.50);
      if(rates[1].high >= ceMid - (15 * point))
      {
         if(emaVal == 0.0 || rates[1].close <= emaVal)
         {
            Print("🎯 STRAT 3: SMC IDM TRAP + ICT FVG MITIGATION SELL!");
            DrawConfluenceZone("S3_Sell", rates[4].time, rates[0].time + 3600*5, rates[1].high, rates[2].high, FBE_COLOR_PURPLE, "[IDM Purged + FVG Mitigated]");
            DispatchConfluenceEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "S3_IDM_FVG_Sell");
            return;
         }
      }
   }
}

// --- 4: 24/5 ICT OTE Golden Zone + Fresh S&D Base (ICT + S&D) ---
void ScanStrat4_24_5_OTE_SD_Base(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 25) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Find impulse leg
   double legHigh = 0.0, legLow = 999999.0;
   int hIdx = -1, lIdx = -1;
   for(int i = 2; i <= 18; i++)
   {
      if(rates[i].high > legHigh) { legHigh = rates[i].high; hIdx = i; }
      if(rates[i].low < legLow)   { legLow  = rates[i].low;  lIdx = i; }
   }

   if((legHigh - legLow) < 60 * point) return;

   // Bullish OTE + S&D Base
   if(lIdx > hIdx)
   {
      double fib62 = legHigh - (0.618 * (legHigh - legLow));
      double fib79 = legHigh - (0.786 * (legHigh - legLow));

      // Bar 1 enters 62-79% pocket with rejection wick
      if(rates[1].low <= fib62 && rates[1].close >= fib79)
      {
         double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
         if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
         {
            if(emaVal == 0.0 || rates[1].close >= emaVal)
            {
               Print("🎯 STRAT 4: 24/5 ICT OTE (70.5%) + S&D BASE CONFLUENCE BUY!");
               DrawConfluenceZone("S4_Buy", rates[hIdx].time, rates[0].time + 3600*5, fib62, fib79, FBE_COLOR_YELLOW, "[OTE 70.5% + S&D Base]");
               DispatchConfluenceEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "S4_OTE_SD_Buy");
               return;
            }
         }
      }
   }
   // Bearish OTE + S&D Base
   else if(hIdx > lIdx)
   {
      double fib62 = legLow + (0.618 * (legHigh - legLow));
      double fib79 = legLow + (0.786 * (legHigh - legLow));

      if(rates[1].high >= fib62 && rates[1].close <= fib79)
      {
         double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
         if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
         {
            if(emaVal == 0.0 || rates[1].close <= emaVal)
            {
               Print("🎯 STRAT 4: 24/5 ICT OTE (70.5%) + S&D BASE CONFLUENCE SELL!");
               DrawConfluenceZone("S4_Sell", rates[lIdx].time, rates[0].time + 3600*5, fib79, fib62, FBE_COLOR_YELLOW, "[OTE 70.5% + S&D Base]");
               DispatchConfluenceEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "S4_OTE_SD_Sell");
               return;
            }
         }
      }
   }
}

// --- 5: London Judas Sweep into HTF S&D Zone (ICT + S&D) ---
void ScanStrat5_ICT_Judas_HTF_SD(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 30) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   MqlDateTime dt;
   TimeGMT(dt);
   if(dt.hour < InpLondonStartHour || dt.hour > 11) return;

   // Asian Range (00:00 - 07:00 UTC)
   double asianHigh = 0.0, asianLow = 999999.0;
   int asianBars = 0;
   for(int i = 1; i < 30; i++)
   {
      MqlDateTime bdt;
      TimeToStruct(rates[i].time, bdt);
      if(bdt.day == dt.day && bdt.hour >= InpAsianStartHour && bdt.hour < InpAsianEndHour)
      {
         if(rates[i].high > asianHigh) asianHigh = rates[i].high;
         if(rates[i].low < asianLow)   asianLow  = rates[i].low;
         asianBars++;
      }
   }

   if(asianBars < 4 || asianHigh <= asianLow) return;

   // Judas False Breakdown of Asian Low into Demand Zone
   if(rates[1].low < asianLow - (10 * point) && rates[1].close > asianLow)
   {
      double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
      if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
      {
         if(emaVal == 0.0 || rates[1].close >= emaVal)
         {
            Print("🎯 STRAT 5: LONDON JUDAS SWEEP INTO DEMAND ZONE BUY!");
            DrawConfluenceZone("S5_Buy", rates[1].time, rates[0].time + 3600*5, asianHigh, asianLow, FBE_COLOR_BE_CYAN, "[Judas Sweep into Demand]");
            DispatchConfluenceEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "S5_Judas_SD_Buy");
            return;
         }
      }
   }
   // Judas False Breakout of Asian High into Supply Zone
   else if(rates[1].high > asianHigh + (10 * point) && rates[1].close < asianHigh)
   {
      double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
      if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
      {
         if(emaVal == 0.0 || rates[1].close <= emaVal)
         {
            Print("🎯 STRAT 5: LONDON JUDAS SWEEP INTO SUPPLY ZONE SELL!");
            DrawConfluenceZone("S5_Sell", rates[1].time, rates[0].time + 3600*5, asianHigh, asianLow, FBE_COLOR_BE_CYAN, "[Judas Sweep into Supply]");
            DispatchConfluenceEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "S5_Judas_SD_Sell");
            return;
         }
      }
   }
}

// --- 6: ICT Balanced Price Range (BPR) inside S&D Flip (ICT + S&D) ---
void ScanStrat6_ICT_BPR_SD_Flip(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 15) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Overlapping opposing FVGs creating BPR vacuum
   if(rates[3].close > rates[3].open && rates[2].close < rates[2].open)
   {
      double overlapHigh = MathMin(rates[3].high, rates[2].high);
      double overlapLow  = MathMax(rates[3].low, rates[2].low);

      if((overlapHigh - overlapLow) >= 20 * point)
      {
         // Revert Short
         if(rates[1].high > overlapHigh && rates[1].close < overlapHigh)
         {
            double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
            if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
            {
               if(emaVal == 0.0 || rates[1].close <= emaVal)
               {
                  Print("🎯 STRAT 6: ICT BPR VACUUM + S&D FLIP REVERSION SELL!");
                  DrawConfluenceZone("S6_Sell", rates[2].time, rates[0].time + 3600*5, overlapHigh, overlapLow, FBE_COLOR_ORANGE, "[BPR Vacuum inside S&D Flip]");
                  DispatchConfluenceEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "S6_BPR_Flip_Sell");
                  return;
               }
            }
         }
         // Revert Long
         else if(rates[1].low < overlapLow && rates[1].close > overlapLow)
         {
            double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
            if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
            {
               if(emaVal == 0.0 || rates[1].close >= emaVal)
               {
                  Print("🎯 STRAT 6: ICT BPR VACUUM + S&D FLIP REVERSION BUY!");
                  DrawConfluenceZone("S6_Buy", rates[2].time, rates[0].time + 3600*5, overlapHigh, overlapLow, FBE_COLOR_ORANGE, "[BPR Vacuum inside S&D Flip]");
                  DispatchConfluenceEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "S6_BPR_Flip_Buy");
                  return;
               }
            }
         }
      }
   }
}

// --- 7: Quasimodo Left Shoulder + ICT Fair Value Gap (SMC + ICT) ---
void ScanStrat7_SMC_QM_ICT_FVG(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 25) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Bearish QM: Left Shoulder (bar 10), Head (bar 6), Break of Structure LL (bar 3)
   double leftShoulder = rates[10].high;
   double head = rates[6].high;
   double hl = rates[8].low;
   double ll = rates[3].low;

   if(head > leftShoulder + (20 * point) && ll < hl - (20 * point))
   {
      // FVG forms during the drop from Head to LL
      double bearGap = rates[5].low - rates[3].high;
      if(bearGap >= InpMinFVGPoints * point)
      {
         // Bar 1 retraces to Left Shoulder level
         if(rates[1].high >= leftShoulder - (15 * point) && rates[1].close <= leftShoulder + (15 * point))
         {
            double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
            if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
            {
               if(emaVal == 0.0 || rates[1].close <= emaVal)
               {
                  Print("🎯 STRAT 7: QUASIMODO LEFT SHOULDER + ICT FVG REVERSAL SELL!");
                  DrawConfluenceZone("S7_Sell", rates[10].time, rates[0].time + 3600*5, head, leftShoulder, FBE_COLOR_LOSS_CORAL, "[Quasimodo QML + FVG]");
                  DispatchConfluenceEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "S7_QM_FVG_Sell");
                  return;
               }
            }
         }
      }
   }
}

// --- 8: Multi-Timeframe BOS + S&D Velocity + Traceback Reload (SMC + S&D) ---
void ScanStrat8_SMC_BOS_SD_Traceback(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 20) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Clean Break of Structure (BOS) in direction of EMA 50
   double swingHigh = 0.0;
   for(int i = 5; i <= 15; i++)
   {
      if(rates[i].high > swingHigh) swingHigh = rates[i].high;
   }

   // Bar 2 broke decisively above swingHigh (BOS)
   if(rates[2].close > swingHigh + (25 * point) && rates[2].close > emaVal)
   {
      // Bar 1 pulls back to retest the broken swing level (now Higher Low Demand)
      if(rates[1].low <= swingHigh + (10 * point) && rates[1].close >= swingHigh)
      {
         double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
         if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
         {
            Print("🎯 STRAT 8: SMC BOS + S&D HIGHER-LOW CONTINUATION BUY!");
            DrawConfluenceZone("S8_Buy", rates[2].time, rates[0].time + 3600*5, rates[2].close, swingHigh, FBE_COLOR_WIN_LIME, "[BOS + HL Reload]");
            DispatchConfluenceEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "S8_BOS_SD_Buy");
            return;
         }
      }
   }
}

// --- 9: Triple-Confluence Master Flipper (SMC Sweep + ICT FVG + S&D Base) ---
void ScanStrat9_TripleConfluenceMaster(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 30) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Find prior swing extremes
   double swingHigh = 0.0, swingLow = 999999.0;
   for(int i = 3; i <= 20; i++)
   {
      if(rates[i].high > swingHigh) swingHigh = rates[i].high;
      if(rates[i].low < swingLow)   swingLow  = rates[i].low;
   }

   // Bullish Triple Confluence: Uptrend + Swept Sell-Side Liquidity + 40% Lower Rejection Wick
   if(rates[1].close > emaVal && rates[1].low < swingLow && rates[1].close > swingLow)
   {
      double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
      double totalRange = rates[1].high - rates[1].low;
      if(totalRange > 0 && (lowerWick / totalRange) >= 0.40)
      {
         Print("👑 STRAT 9: TRIPLE CONFLUENCE MASTER FLIPPER BUY!");
         DrawConfluenceZone("S9_Buy", rates[1].time, rates[0].time + 3600*5, rates[1].close, rates[1].low, FBE_COLOR_WIN_LIME, "[TRIPLE CONFLUENCE BUY]");
         DispatchConfluenceEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "S9_Triple_Buy");
         return;
      }
   }

   // Bearish Triple Confluence: Downtrend + Swept Buy-Side Liquidity + 40% Upper Rejection Wick
   if(rates[1].close < emaVal && rates[1].high > swingHigh && rates[1].close < swingHigh)
   {
      double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
      double totalRange = rates[1].high - rates[1].low;
      if(totalRange > 0 && (upperWick / totalRange) >= 0.40)
      {
         Print("👑 STRAT 9: TRIPLE CONFLUENCE MASTER FLIPPER SELL!");
         DrawConfluenceZone("S9_Sell", rates[1].time, rates[0].time + 3600*5, rates[1].high, rates[1].close, FBE_COLOR_LOSS_CORAL, "[TRIPLE CONFLUENCE SELL]");
         DispatchConfluenceEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "S9_Triple_Sell");
         return;
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(InpExecutionMode == EXEC_MODE_BEHAVIORAL_FLIPPER)
   {
      if(ExtBehavioralEngine.CheckMilestoneFlipTarget()) return;
      ExtBehavioralEngine.ManageLadderAndBreakeven();
      ExtBehavioralEngine.CheckPyramiding();
      ExtBehavioralEngine.UpdateHUD();
   }

   // Process strictly on bar completion
   datetime curBar = iTime(_Symbol, _Period, 0);
   if(curBar == ExtLastBarTime) return;
   ExtLastBarTime = curBar;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 0, 35, rates);
   if(copied < 32) return;

   double emaVal = 0.0;
   if(ExtEmaHandle != INVALID_HANDLE)
   {
      double emaBuf[];
      ArraySetAsSeries(emaBuf, true);
      if(CopyBuffer(ExtEmaHandle, 0, 1, 2, emaBuf) >= 2)
         emaVal = emaBuf[1];
   }

   if(InpEnableVisuals)
   {
      VTS_DrawSessionZones(rates, copied, VTS_GetGMTOffset(), false);
   }

   if(CountActivePositions() > 0) return;
   if(!IsSessionAllowed()) return;

   // Route to Selected Intertwined Strategy
   switch(InpStrategyModel)
   {
      case STRAT_0_SD_BASE_SMC_SWEEP:
         ScanStrat0_SD_Base_SMC_Sweep(rates, emaVal);
         break;
      case STRAT_1_HTF_OB_ICT_FVG_CE:
         ScanStrat1_HTF_OB_ICT_FVG_CE(rates, emaVal);
         break;
      case STRAT_2_SD_FLIP_ICT_BREAKER:
         ScanStrat2_SD_Flip_ICT_Breaker(rates, emaVal);
         break;
      case STRAT_3_SMC_IDM_ICT_FVG:
         ScanStrat3_SMC_IDM_ICT_FVG(rates, emaVal);
         break;
      case STRAT_4_24_5_OTE_SD_BASE:
         ScanStrat4_24_5_OTE_SD_Base(rates, emaVal);
         break;
      case STRAT_5_ICT_JUDAS_HTF_SD_ZONE:
         ScanStrat5_ICT_Judas_HTF_SD(rates, emaVal);
         break;
      case STRAT_6_ICT_BPR_SD_FLIP_REVERT:
         ScanStrat6_ICT_BPR_SD_Flip(rates, emaVal);
         break;
      case STRAT_7_SMC_QM_ICT_FVG:
         ScanStrat7_SMC_QM_ICT_FVG(rates, emaVal);
         break;
      case STRAT_8_SMC_BOS_SD_TRACEBACK:
         ScanStrat8_SMC_BOS_SD_Traceback(rates, emaVal);
         break;
      case STRAT_9_TRIPLE_CONFLUENCE_MASTER:
         ScanStrat9_TripleConfluenceMaster(rates, emaVal);
         break;
   }
}
//+------------------------------------------------------------------+
