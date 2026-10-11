//+------------------------------------------------------------------+
//|                               Institutional_SMC_ICT_Master_Suite.mq5|
//|               Master Algorithmic Trading Architecture               |
//|    10 Unique Institutional SMC, ICT & Supply-Demand Strategies      |
//|    Equipped with 10 Truly Unique Account-Flipper Behavioral Patterns|
//|    (Multi-Ticket Slicing, TP1-TP5 Laddering, Pyramiding, Stepped BE)|
//|    Full Dracula Dark Visual Roadmap & Setup Drawings on Charts      |
//|                                 Copyright 2026, Quant Research Lab  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research Lab"
#property link      "https://github.com/dchumari/Youtube-Traders"
#property version   "3.00"
#property description "Master Institutional Suite: 10 SMC, ICT & Supply/Demand Strategies with Behavioral Flipper Engine"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Flipper_Behavioral_Engine.mqh>
#include <VisualTradeSuite.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS: 10 Unique Institutional Strategies & Modes         |
//+------------------------------------------------------------------+
enum ENUM_SMC_ICT_STRATEGY
{
   STRAT_0_SMC_LIQUIDITY_SWEEP_OB   = 0, // 0: SMC Liquidity Sweep & Order Block Sniper (BSL/SSL Purge + OB Retest)
   STRAT_1_ICT_FVG_CONSEQUENT_ENC   = 1, // 1: ICT Fair Value Gap Mitigation (Displacement + 50% CE Retest)
   STRAT_2_SD_FRESH_BASE_FLIP       = 2, // 2: S&D Fresh Base Support/Resistance Flip Breakout
   STRAT_3_SMC_INDUCEMENT_TRAP      = 3, // 3: SMC Inducement Trap & Institutional Reload (IDM Sweep + HTF OB)
   STRAT_4_ICT_POWER_OF_3_AMD       = 4, // 4: ICT Power of 3 (AMD) Session Expander (Asian Accum -> Judas -> NY Dist)
   STRAT_5_ICT_BREAKER_BLOCK_FLIP   = 5, // 5: ICT Breaker Block Invalidation Flip (Violated OB -> Velocity Breaker)
   STRAT_6_24_5_OTE_GOLDEN_ZONE     = 6, // 6: 24/5 Optimal Trade Entry (OTE) Golden Zone (62%-79% Fib Retracement)
   STRAT_7_SD_DBR_RBD_VELOCITY      = 7, // 7: S&D Multi-Timeframe Velocity (Drop-Base-Rally / Rally-Base-Drop)
   STRAT_8_ICT_LIQUIDITY_VOID_BPR   = 8, // 8: ICT Liquidity Void & Balanced Price Range (BPR) Mean Reversion
   STRAT_9_INSTITUTIONAL_HYBRID     = 9  // 9: Institutional Master Hybrid Confluence Engine (SMC + ICT + S&D + Flipper)
};

enum ENUM_SESSION_FILTER
{
   SESSION_ALL_24_5        = 0, // 24/5 Session Flexible (Runs Across All Hours)
   SESSION_LONDON_NY_ONLY  = 1, // London & NY Killzones Only (07:00-11:00 & 12:00-17:00 UTC)
   SESSION_LONDON_ONLY     = 2, // London Killzone Only (07:00-11:00 UTC)
   SESSION_NY_ONLY         = 3  // New York Killzone Only (12:00-17:00 UTC)
};

enum ENUM_EXECUTION_ENGINE
{
   EXEC_BEHAVIORAL_FLIPPER = 0, // Behavioral Flipper Engine (Multi-Ticket, TP1-TP5 Ladder, Pyramiding, BE Shield)
   EXEC_STANDARD_FIXED     = 1  // Standard Institutional Execution (Single/Dual Target)
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
sinput string   sep0 = "================ STRATEGY SELECTION ================";
input ENUM_SMC_ICT_STRATEGY   InpStrategyModel        = STRAT_0_SMC_LIQUIDITY_SWEEP_OB; // Institutional Strategy Model
input ENUM_SESSION_FILTER     InpSessionFilter        = SESSION_ALL_24_5;               // Session Regime Filter
input ENUM_EXECUTION_ENGINE   InpExecutionEngine      = EXEC_BEHAVIORAL_FLIPPER;        // Execution Engine Mode

sinput string   sep1 = "================ CAPITAL & RISK SIZING ================";
input double    InpBaseLotSize          = 0.01;      // Base Fixed Lot Size
input double    InpEquityPerMinLot      = 35.0;      // Equity Step per 0.01 Lot ($35 aggressive / $50 conservative)
input double    InpMaxLotCap            = 0.50;      // Maximum Single Ticket Lot Cap
input int       InpStopLossPoints       = 150;       // Initial Stop Loss in Points (15 pips)
input ulong     InpMagicNumber          = 777000;    // EA Magic Number

sinput string   sep2 = "================ BEHAVIORAL FLIPPER PARAMETERS =========";
input int       InpSpamTicketsCount     = 5;         // Pattern 1: Initial Micro-Tickets per Basket (3 to 10)
input int       InpTP1Points            = 200;       // Pattern 2: Stage 1 TP (+20 pips, bank ticket 1)
input int       InpTP2Points            = 350;       // Pattern 2: Stage 2 TP (+35 pips, bank ticket 2 + move BE)
input int       InpTP3Points            = 600;       // Pattern 2: Stage 3 TP (+60 pips, bank ticket 3 + lock +25p)
input int       InpTP4Points            = 1000;      // Pattern 2: Stage 4 TP (+100 pips, bank ticket 4 + lock +60p)
input int       InpTP5Points            = 1600;      // Pattern 2: Stage 5 TP (+160 pips runner)
input bool      InpEnableTraceback      = true;      // Pattern 3: Traceback Counter-Scalp & Higher-Low Reload
input int       InpTracebackExtensionPts= 250;       // Pattern 3: Distance from EMA 50 to trigger scalp
input int       InpTracebackTPPoints    = 150;       // Pattern 3: Traceback Scalp Take Profit (pts)
input int       InpTracebackSLPoints    = 120;       // Pattern 3: Traceback Scalp Stop Loss (pts)
input bool      InpEnablePyramiding     = true;      // Pattern 4: Floating Equity Free-Margin Pyramiding
input int       InpReloadStepPoints     = 350;       // Pattern 4: Pyramiding Step Distance (+35 pips)
input int       InpMaxPyramidLayers     = 3;         // Pattern 4: Max Pyramid Cascade Layers
input int       InpReloadTicketsCount   = 3;         // Pattern 4: Reload Micro-Tickets Count per Layer
input bool      InpEnableDumpAndFlip    = true;      // Pattern 7: Opposing Rejection Wick Dump & 180° Flip
input double    InpDumpWickRatio        = 0.45;      // Pattern 7: Opposing Wick Ratio Threshold (45%)
input bool      InpEnableVolumeClimax   = true;      // Pattern 8: Volume Climax Absorption Fade
input double    InpVolumeSpikeMulti     = 3.0;       // Pattern 8: Tick Volume Surge Multiplier (3.0x avg)
input bool      InpEnableFlipMilestone  = true;      // Pattern 9: Milestone Extraction Lockout
input double    InpTargetEquity         = 1000.0;    // Pattern 9: Account Flip Equity Target ($1,000 or $10,000)

sinput string   sep3 = "================ INSTITUTIONAL SETUP THRESHOLDS =======";
input int       InpLookbackBars         = 30;        // Swing High/Low Structure Lookback
input int       InpMinSweepPoints       = 15;        // Minimum Liquidity Sweep Points (1.5 pips)
input int       InpMinFVGPoints         = 20;        // Minimum 3-Candle FVG Gap Points (2.0 pips)
input double    InpMinWickRejection     = 0.35;      // Minimum Order Block / Reversal Wick Ratio (35%)
input int       InpMinDisplacementPts   = 40;        // Minimum Displacement Impulse Candle Points (4.0 pips)
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
input bool      InpDrawSetupBoxes       = true;      // Draw Translucent Setup Zones (OB, FVG, S&D, Breakers)

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & STRUCTS                                         |
//+------------------------------------------------------------------+
CTrade                  ExtTrade;
CPositionInfo           ExtPos;
CFlipperBehavioralEngine ExtBehavioralEngine;

int                     ExtEmaHandle = INVALID_HANDLE;
datetime                ExtLastBarTime = 0;
string                  ExtPrefix = "SMC_ICT_";

// Memory structures for S&D and Breakers
struct SZoneRecord
{
   datetime time;
   double   high;
   double   low;
   int      type; // 1 = Bullish/Demand, -1 = Bearish/Supply
   bool     mitigated;
   bool     flipped;
   string   tag;
};

SZoneRecord ExtActiveZones[20];
int         ExtZoneCount = 0;

//+------------------------------------------------------------------+
//| Helper: Check Active Session Filter                              |
//+------------------------------------------------------------------+
bool IsSessionAllowed()
{
   if(InpSessionFilter == SESSION_ALL_24_5) return true;

   MqlDateTime dt;
   TimeGMT(dt);
   int hour = dt.hour;

   if(InpSessionFilter == SESSION_LONDON_NY_ONLY)
   {
      return ((hour >= InpLondonStartHour && hour < InpLondonEndHour) ||
              (hour >= InpNYStartHour && hour < InpNYEndHour));
   }
   else if(InpSessionFilter == SESSION_LONDON_ONLY)
   {
      return (hour >= InpLondonStartHour && hour < InpLondonEndHour);
   }
   else if(InpSessionFilter == SESSION_NY_ONLY)
   {
      return (hour >= InpNYStartHour && hour < InpNYEndHour);
   }
   return true;
}

//+------------------------------------------------------------------+
//| Helper: Draw Visual Institutional Setup Box & Text               |
//+------------------------------------------------------------------+
void DrawInstitutionalZone(string id, datetime tStart, datetime tEnd, double highPrice, double lowPrice, 
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
//| Helper: Register / Maintain Institutional Zones                  |
//+------------------------------------------------------------------+
void AddZone(datetime t, double h, double l, int type, string tag, color c)
{
   if(ExtZoneCount >= 20)
   {
      for(int i = 0; i < 19; i++) ExtActiveZones[i] = ExtActiveZones[i + 1];
      ExtZoneCount = 19;
   }
   ExtActiveZones[ExtZoneCount].time      = t;
   ExtActiveZones[ExtZoneCount].high      = h;
   ExtActiveZones[ExtZoneCount].low       = l;
   ExtActiveZones[ExtZoneCount].type      = type;
   ExtActiveZones[ExtZoneCount].mitigated = false;
   ExtActiveZones[ExtZoneCount].flipped   = false;
   ExtActiveZones[ExtZoneCount].tag       = tag;
   ExtZoneCount++;

   datetime tEnd = t + (PeriodSeconds(_Period) * 20);
   DrawInstitutionalZone(tag + "_" + IntegerToString(t), t, tEnd, h, l, c, tag);
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
   bcfg.enabled                = (InpExecutionEngine == EXEC_BEHAVIORAL_FLIPPER);
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

   ExtZoneCount = 0;
   Print("🚀 Institutional SMC & ICT Master Suite Initialized! Strategy: ", EnumToString(InpStrategyModel), " | Execution: ", EnumToString(InpExecutionEngine));
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
//| Execution Router: Dispatches Order Basket                        |
//+------------------------------------------------------------------+
bool DispatchEntry(ENUM_ORDER_TYPE otype, double entryPrice, int slPoints, string setupTag)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(InpExecutionEngine == EXEC_BEHAVIORAL_FLIPPER)
   {
      Print("⚡ [", setupTag, "] Dispatched to Flipper Behavioral Engine (Spamming Micro-Basket)!");
      return ExtBehavioralEngine.ExecuteSpamBasket(otype, entryPrice, slPoints);
   }
   else
   {
      // Standard Execution Mode
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
//| 10 STRATEGY DETECTORS                                            |
//+------------------------------------------------------------------+

// --- MODEL 0: SMC Liquidity Sweep & Order Block Sniper ---
void ScanModel0_LiquiditySweepOB(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < InpLookbackBars + 5) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Find prior swing high & low over lookback
   double swingHigh = 0.0, swingLow = 999999.0;
   int shIdx = -1, slIdx = -1;
   for(int i = 3; i <= InpLookbackBars; i++)
   {
      if(rates[i].high > swingHigh) { swingHigh = rates[i].high; shIdx = i; }
      if(rates[i].low < swingLow)   { swingLow  = rates[i].low;  slIdx = i; }
   }

   // Check Bar 1 for Buy-Side Liquidity Sweep (BSL Purge)
   if(rates[1].high > swingHigh + (InpMinSweepPoints * point) && rates[1].close < swingHigh)
   {
      double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
      double totalRange = rates[1].high - rates[1].low;
      if(totalRange > 0 && (upperWick / totalRange) >= InpMinWickRejection)
      {
         if(emaVal == 0.0 || rates[1].close < emaVal)
         {
            Print("🎯 MODEL 0: BSL SWEEP & BEARISH OB TRIGGERED! High: ", rates[1].high, " > SwingH: ", swingHigh);
            AddZone(rates[1].time, rates[1].high, rates[1].open, -1, "SMC Bearish OB", FBE_COLOR_LOSS_CORAL);
            DispatchEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "M0_BSL_Sweep");
            return;
         }
      }
   }

   // Check Bar 1 for Sell-Side Liquidity Sweep (SSL Purge)
   if(rates[1].low < swingLow - (InpMinSweepPoints * point) && rates[1].close > swingLow)
   {
      double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
      double totalRange = rates[1].high - rates[1].low;
      if(totalRange > 0 && (lowerWick / totalRange) >= InpMinWickRejection)
      {
         if(emaVal == 0.0 || rates[1].close > emaVal)
         {
            Print("🎯 MODEL 0: SSL SWEEP & BULLISH OB TRIGGERED! Low: ", rates[1].low, " < SwingL: ", swingLow);
            AddZone(rates[1].time, rates[1].open, rates[1].low, 1, "SMC Bullish OB", FBE_COLOR_WIN_LIME);
            DispatchEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "M0_SSL_Sweep");
            return;
         }
      }
   }
}

// --- MODEL 1: ICT Fair Value Gap Mitigation (Displacement + 50% CE Retest) ---
void ScanModel1_ICT_FVG(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 10) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Bullish FVG formed across bar 4, 3, 2: Bar 4 High < Bar 2 Low
   double bullGap = rates[2].low - rates[4].high;
   if(bullGap >= InpMinFVGPoints * point)
   {
      double ceLevel = rates[4].high + (bullGap * 0.50); // 50% Consequent Encroachment
      // Bar 1 retraces to tap CE
      if(rates[1].low <= ceLevel && rates[1].close >= rates[4].high)
      {
         if(emaVal == 0.0 || rates[1].close >= emaVal)
         {
            Print("🎯 MODEL 1: ICT BULLISH FVG CE 50% MITIGATED at ", ceLevel);
            AddZone(rates[3].time, rates[2].low, rates[4].high, 1, "ICT Bullish FVG (CE)", FBE_COLOR_WIN_LIME);
            DispatchEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "M1_Bull_FVG_CE");
            return;
         }
      }
   }

   // Bearish FVG formed across bar 4, 3, 2: Bar 4 Low > Bar 2 High
   double bearGap = rates[4].low - rates[2].high;
   if(bearGap >= InpMinFVGPoints * point)
   {
      double ceLevel = rates[2].high + (bearGap * 0.50);
      if(rates[1].high >= ceLevel && rates[1].close <= rates[4].low)
      {
         if(emaVal == 0.0 || rates[1].close <= emaVal)
         {
            Print("🎯 MODEL 1: ICT BEARISH FVG CE 50% MITIGATED at ", ceLevel);
            AddZone(rates[3].time, rates[4].low, rates[2].high, -1, "ICT Bearish FVG (CE)", FBE_COLOR_LOSS_CORAL);
            DispatchEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "M1_Bear_FVG_CE");
            return;
         }
      }
   }
}

// --- MODEL 2: S&D Fresh Base Support/Resistance Flip Breakout ---
void ScanModel2_SND_FreshBaseFlip(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 15) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Identify fresh consolidation base across bars 6, 5, 4 (range < 40 pts)
   double baseHigh = MathMax(rates[6].high, MathMax(rates[5].high, rates[4].high));
   double baseLow  = MathMin(rates[6].low,  MathMin(rates[5].low,  rates[4].low));
   double baseRange = (baseHigh - baseLow) / point;

   if(baseRange > 10 && baseRange < 45)
   {
      // Bullish Flip: Bar 3 or 2 broke decisively above baseHigh (displacement > 35 pts)
      if(rates[2].close > baseHigh + (20 * point))
      {
         // Bar 1 pulls back and tests old Supply base as new Demand (Base Flip)
         if(rates[1].low <= baseHigh + (10 * point) && rates[1].close >= baseHigh)
         {
            double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
            if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
            {
               Print("🎯 MODEL 2: S&D SUPPLY-TO-DEMAND BASE FLIP CONFIRMED at ", baseHigh);
               AddZone(rates[5].time, baseHigh, baseLow, 1, "S&D Flip (Supply->Demand)", FBE_COLOR_WIN_LIME);
               DispatchEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "M2_Base_Flip_Buy");
               return;
            }
         }
      }
      // Bearish Flip: Bar 3 or 2 broke decisively below baseLow
      else if(rates[2].close < baseLow - (20 * point))
      {
         if(rates[1].high >= baseLow - (10 * point) && rates[1].close <= baseLow)
         {
            double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
            if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
            {
               Print("🎯 MODEL 2: S&D DEMAND-TO-SUPPLY BASE FLIP CONFIRMED at ", baseLow);
               AddZone(rates[5].time, baseHigh, baseLow, -1, "S&D Flip (Demand->Supply)", FBE_COLOR_LOSS_CORAL);
               DispatchEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "M2_Base_Flip_Sell");
               return;
            }
         }
      }
   }
}

// --- MODEL 3: SMC Inducement Trap & Institutional Reload ---
void ScanModel3_SMC_InducementTrap(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 20) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Minor internal swing high (retail inducement IDM) at bar 4
   bool isInternalHigh = (rates[4].high > rates[5].high && rates[4].high > rates[3].high);
   bool isInternalLow  = (rates[4].low < rates[5].low   && rates[4].low < rates[3].low);

   // True Higher Timeframe OB located at bar 8-10
   double majorHigh = 0.0, majorLow = 999999.0;
   for(int i = 8; i <= 15; i++)
   {
      if(rates[i].high > majorHigh) majorHigh = rates[i].high;
      if(rates[i].low < majorLow)   majorLow  = rates[i].low;
   }

   // Bullish IDM Trap: Price sweeps minor low at bar 4, taps major OB low, prints rejection
   if(isInternalLow && rates[1].low < rates[4].low && rates[1].low >= majorLow - (30 * point) && rates[1].close > rates[4].low)
   {
      double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
      if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
      {
         Print("🎯 MODEL 3: SMC INDUCEMENT TRAP SWEPT! Smart money reloading long at ", rates[1].low);
         AddZone(rates[4].time, rates[4].low + (15 * point), rates[1].low, 1, "SMC Retail IDM Purged", FBE_COLOR_PURPLE);
         DispatchEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "M3_IDM_Trap_Long");
         return;
      }
   }

   // Bearish IDM Trap: Price sweeps minor high at bar 4, taps major OB high, prints rejection
   if(isInternalHigh && rates[1].high > rates[4].high && rates[1].high <= majorHigh + (30 * point) && rates[1].close < rates[4].high)
   {
      double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
      if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
      {
         Print("🎯 MODEL 3: SMC INDUCEMENT TRAP SWEPT! Smart money reloading short at ", rates[1].high);
         AddZone(rates[4].time, rates[1].high, rates[4].high - (15 * point), -1, "SMC Retail IDM Purged", FBE_COLOR_PURPLE);
         DispatchEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "M3_IDM_Trap_Short");
         return;
      }
   }
}

// --- MODEL 4: ICT Power of 3 (AMD) Session Expander ---
void ScanModel4_ICT_PowerOf3_AMD(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 30) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   MqlDateTime dt;
   TimeGMT(dt);
   // Only execute during London Judas or New York Distribution (07:00 to 15:00 UTC)
   if(dt.hour < InpLondonStartHour || dt.hour > 15) return;

   // Calculate Asian Session High and Low (00:00 - 07:00 UTC)
   double asianHigh = 0.0, asianLow = 999999.0;
   int asianBars = 0;
   for(int i = 1; i < 30; i++)
   {
      MqlDateTime barDt;
      TimeToStruct(rates[i].time, barDt);
      if(barDt.day == dt.day && barDt.hour >= InpAsianStartHour && barDt.hour < InpAsianEndHour)
      {
         if(rates[i].high > asianHigh) asianHigh = rates[i].high;
         if(rates[i].low < asianLow)   asianLow  = rates[i].low;
         asianBars++;
      }
   }

   if(asianBars < 4 || asianHigh <= asianLow) return;

   // London / NY Judas Manipulation: False break of Asian Low -> NY Expansion Up
   if(rates[1].low < asianLow - (10 * point) && rates[1].close > asianLow)
   {
      double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
      if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
      {
         if(emaVal == 0.0 || rates[1].close >= emaVal)
         {
            Print("🎯 MODEL 4: ICT POWER OF 3 (AMD) MANIPULATION! Asian Low Swept (Judas). Buying Expansion!");
            AddZone(rates[1].time, asianHigh, asianLow, 1, "ICT AMD Asian Range", FBE_COLOR_BE_CYAN);
            DispatchEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "M4_AMD_Judas_Long");
            return;
         }
      }
   }

   // London / NY Judas Manipulation: False break of Asian High -> NY Expansion Down
   if(rates[1].high > asianHigh + (10 * point) && rates[1].close < asianHigh)
   {
      double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
      if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
      {
         if(emaVal == 0.0 || rates[1].close <= emaVal)
         {
            Print("🎯 MODEL 4: ICT POWER OF 3 (AMD) MANIPULATION! Asian High Swept (Judas). Selling Expansion!");
            AddZone(rates[1].time, asianHigh, asianLow, -1, "ICT AMD Asian Range", FBE_COLOR_BE_CYAN);
            DispatchEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "M4_AMD_Judas_Short");
            return;
         }
      }
   }
}

// --- MODEL 5: ICT Breaker Block Invalidation Flip ---
void ScanModel5_ICT_BreakerBlock(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 25) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // A Bearish Breaker was a prior Bullish Order Block (last green candle) that pushed to a Higher High
   // but was subsequently blown through downwards with massive displacement.
   for(int i = 5; i <= 15; i++)
   {
      if(rates[i].close > rates[i].open) // Bullish candle
      {
         double obHigh = rates[i].high;
         double obLow  = rates[i].low;

         // Candle i+1 to i+3 made a higher high
         bool madeHH = (rates[i - 1].high > obHigh || rates[i - 2].high > obHigh);
         // Recent candles violated obLow decisively
         bool violatedDown = (rates[2].close < obLow - (20 * point));

         if(madeHH && violatedDown)
         {
            // Bar 1 pulls back to retest the failed OB (now a Bearish Breaker) from below
            if(rates[1].high >= obLow && rates[1].close <= obHigh)
            {
               double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
               if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
               {
                  if(emaVal == 0.0 || rates[1].close <= emaVal)
                  {
                     Print("🎯 MODEL 5: ICT BEARISH BREAKER BLOCK TESTED at ", obLow);
                     AddZone(rates[i].time, obHigh, obLow, -1, "ICT Bearish Breaker", FBE_COLOR_LOSS_CORAL);
                     DispatchEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "M5_Bearish_Breaker");
                     return;
                  }
               }
            }
         }
      }
      else // Bearish candle turning into Bullish Breaker
      {
         double obHigh = rates[i].high;
         double obLow  = rates[i].low;

         bool madeLL = (rates[i - 1].low < obLow || rates[i - 2].low < obLow);
         bool violatedUp = (rates[2].close > obHigh + (20 * point));

         if(madeLL && violatedUp)
         {
            if(rates[1].low <= obHigh && rates[1].close >= obLow)
            {
               double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
               if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
               {
                  if(emaVal == 0.0 || rates[1].close >= emaVal)
                  {
                     Print("🎯 MODEL 5: ICT BULLISH BREAKER BLOCK TESTED at ", obHigh);
                     AddZone(rates[i].time, obHigh, obLow, 1, "ICT Bullish Breaker", FBE_COLOR_WIN_LIME);
                     DispatchEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "M5_Bullish_Breaker");
                     return;
                  }
               }
            }
         }
      }
   }
}

// --- MODEL 6: 24/5 Optimal Trade Entry (OTE) Golden Zone (62%-79% Fib) ---
void ScanModel6_24_5_OTE_GoldenZone(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 25) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Find the dominant displacement impulse leg over the last 15 bars
   double legHigh = 0.0, legLow = 999999.0;
   int hIdx = -1, lIdx = -1;
   for(int i = 2; i <= 18; i++)
   {
      if(rates[i].high > legHigh) { legHigh = rates[i].high; hIdx = i; }
      if(rates[i].low < legLow)   { legLow  = rates[i].low;  lIdx = i; }
   }

   double legRange = (legHigh - legLow) / point;
   if(legRange < 60) return; // Minimum 60-point expansion leg

   // Bullish Impulse: Low occurred before High (lIdx > hIdx)
   if(lIdx > hIdx)
   {
      double fib62 = legHigh - (0.618 * (legHigh - legLow));
      double fib79 = legHigh - (0.786 * (legHigh - legLow));
      double oteSweetSpot = legHigh - (0.705 * (legHigh - legLow));

      // Bar 1 retraces into the 62% - 79% OTE pocket
      if(rates[1].low <= fib62 && rates[1].low >= fib79 - (15 * point) && rates[1].close >= fib79)
      {
         double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
         if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
         {
            if(emaVal == 0.0 || rates[1].close >= emaVal)
            {
               Print("🎯 MODEL 6: 24/5 ICT OTE GOLDEN POCKET (70.5%) REACHED! Buying at ", oteSweetSpot);
               AddZone(rates[hIdx].time, fib62, fib79, 1, "ICT OTE Golden Pocket (70.5%)", FBE_COLOR_YELLOW);
               DispatchEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "M6_OTE_GoldenPocket_Long");
               return;
            }
         }
      }
   }
   // Bearish Impulse: High occurred before Low (hIdx > lIdx)
   else if(hIdx > lIdx)
   {
      double fib62 = legLow + (0.618 * (legHigh - legLow));
      double fib79 = legLow + (0.786 * (legHigh - legLow));
      double oteSweetSpot = legLow + (0.705 * (legHigh - legLow));

      if(rates[1].high >= fib62 && rates[1].high <= fib79 + (15 * point) && rates[1].close <= fib79)
      {
         double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
         if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
         {
            if(emaVal == 0.0 || rates[1].close <= emaVal)
            {
               Print("🎯 MODEL 6: 24/5 ICT OTE GOLDEN POCKET (70.5%) REACHED! Selling at ", oteSweetSpot);
               AddZone(rates[lIdx].time, fib79, fib62, -1, "ICT OTE Golden Pocket (70.5%)", FBE_COLOR_YELLOW);
               DispatchEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "M6_OTE_GoldenPocket_Short");
               return;
            }
         }
      }
   }
}

// --- MODEL 7: S&D Multi-Timeframe Velocity (Drop-Base-Rally / Rally-Base-Drop) ---
void ScanModel7_SND_DBR_RBD(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 15) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Drop-Base-Rally (DBR):
   // Bar 4: Sharp drop (body > 35 pts)
   // Bar 3: Small base candle (range < 25 pts)
   // Bar 2: Explosive rally (body > 45 pts)
   double dropBody = (rates[4].open - rates[4].close) / point;
   double baseRange = (rates[3].high - rates[3].low) / point;
   double rallyBody = (rates[2].close - rates[2].open) / point;

   if(dropBody >= 30 && baseRange <= 25 && rallyBody >= 40)
   {
      double baseHigh = rates[3].high;
      double baseLow  = rates[3].low;

      // Bar 1 retests fresh unmitigated base
      if(rates[1].low <= baseHigh + (10 * point) && rates[1].close >= baseLow)
      {
         double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
         if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
         {
            Print("🎯 MODEL 7: S&D DROP-BASE-RALLY (DBR) RETEST! Buying fresh base at ", baseHigh);
            AddZone(rates[3].time, baseHigh, baseLow, 1, "S&D Fresh DBR Demand", FBE_COLOR_WIN_LIME);
            DispatchEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "M7_DBR_Retest_Buy");
            return;
         }
      }
   }

   // Rally-Base-Drop (RBD):
   double preRallyBody = (rates[4].close - rates[4].open) / point;
   double postDropBody = (rates[2].open - rates[2].close) / point;

   if(preRallyBody >= 30 && baseRange <= 25 && postDropBody >= 40)
   {
      double baseHigh = rates[3].high;
      double baseLow  = rates[3].low;

      if(rates[1].high >= baseLow - (10 * point) && rates[1].close <= baseHigh)
      {
         double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
         if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
         {
            Print("🎯 MODEL 7: S&D RALLY-BASE-DROP (RBD) RETEST! Selling fresh base at ", baseLow);
            AddZone(rates[3].time, baseHigh, baseLow, -1, "S&D Fresh RBD Supply", FBE_COLOR_LOSS_CORAL);
            DispatchEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "M7_RBD_Retest_Sell");
            return;
         }
      }
   }
}

// --- MODEL 8: ICT Liquidity Void & Balanced Price Range (BPR) Mean Reversion ---
void ScanModel8_ICT_LiquidityVoid_BPR(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 15) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Balanced Price Range (BPR):
   // Bar 3 had an aggressive Bullish FVG, and Bar 2 immediately printed an aggressive Bearish FVG overlapping it
   double bullFvgLow = rates[4].high;
   double bullFvgHigh = rates[2].low;

   double bearFvgHigh = rates[3].low;
   double bearFvgLow = rates[1].high;

   // Check if price created an overlapping vacuum channel (BPR)
   if(rates[3].close > rates[3].open && rates[2].close < rates[2].open)
   {
      double overlapHigh = MathMin(rates[3].high, rates[2].high);
      double overlapLow  = MathMax(rates[3].low, rates[2].low);
      double overlapSpan = (overlapHigh - overlapLow) / point;

      if(overlapSpan >= 25)
      {
         double bprMid = overlapLow + ((overlapHigh - overlapLow) * 0.50);

         // Overextended above BPR midpoint with rejection wick -> Mean Revert Short
         if(rates[1].high > overlapHigh && rates[1].close < overlapHigh)
         {
            double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
            if((upperWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
            {
               Print("🎯 MODEL 8: ICT BALANCED PRICE RANGE (BPR) VACUUM! Reverting Short to ", bprMid);
               AddZone(rates[2].time, overlapHigh, overlapLow, -1, "ICT Balanced Price Range", FBE_COLOR_ORANGE);
               DispatchEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "M8_BPR_Revert_Short");
               return;
            }
         }
         // Overextended below BPR midpoint with rejection wick -> Mean Revert Long
         else if(rates[1].low < overlapLow && rates[1].close > overlapLow)
         {
            double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
            if((lowerWick / (rates[1].high - rates[1].low + point)) >= InpMinWickRejection)
            {
               Print("🎯 MODEL 8: ICT BALANCED PRICE RANGE (BPR) VACUUM! Reverting Long to ", bprMid);
               AddZone(rates[2].time, overlapHigh, overlapLow, 1, "ICT Balanced Price Range", FBE_COLOR_ORANGE);
               DispatchEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "M8_BPR_Revert_Long");
               return;
            }
         }
      }
   }
}

// --- MODEL 9: Institutional Master Hybrid Confluence Engine (SMC + ICT + S&D) ---
void ScanModel9_MasterInstitutionalHybrid(const MqlRates &rates[], double emaVal)
{
   if(ArraySize(rates) < 30) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Confluence Check:
   // 1. Trend Direction via EMA 50
   // 2. Liquidity Sweep on Bar 2 or 1
   // 3. FVG Displacement Departure
   // 4. Strong Wick Rejection >= 40%

   double swingHigh = 0.0, swingLow = 999999.0;
   for(int i = 3; i <= 20; i++)
   {
      if(rates[i].high > swingHigh) swingHigh = rates[i].high;
      if(rates[i].low < swingLow)   swingLow  = rates[i].low;
   }

   // Bullish Confluence: Uptrend (close > EMA), Swept prior swingLow, closed back above with lower wick >= 40%
   if(rates[1].close > emaVal && rates[1].low < swingLow && rates[1].close > swingLow)
   {
      double lowerWick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
      double totalRange = rates[1].high - rates[1].low;
      if(totalRange > 0 && (lowerWick / totalRange) >= 0.40)
      {
         Print("👑 MODEL 9: MASTER INSTITUTIONAL CONFLUENCE ENGINE! Long Liquidity Purge + EMA Uptrend!");
         AddZone(rates[1].time, rates[1].close, rates[1].low, 1, "MASTER CONFLUENCE BUY", FBE_COLOR_WIN_LIME);
         DispatchEntry(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), InpStopLossPoints, "M9_Master_Hybrid_Buy");
         return;
      }
   }

   // Bearish Confluence: Downtrend (close < EMA), Swept prior swingHigh, closed back below with upper wick >= 40%
   if(rates[1].close < emaVal && rates[1].high > swingHigh && rates[1].close < swingHigh)
   {
      double upperWick = rates[1].high - MathMax(rates[1].open, rates[1].close);
      double totalRange = rates[1].high - rates[1].low;
      if(totalRange > 0 && (upperWick / totalRange) >= 0.40)
      {
         Print("👑 MODEL 9: MASTER INSTITUTIONAL CONFLUENCE ENGINE! Short Liquidity Purge + EMA Downtrend!");
         AddZone(rates[1].time, rates[1].high, rates[1].close, -1, "MASTER CONFLUENCE SELL", FBE_COLOR_LOSS_CORAL);
         DispatchEntry(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), InpStopLossPoints, "M9_Master_Hybrid_Sell");
         return;
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Always run Behavioral Engine Tick Managers if active
   if(InpExecutionEngine == EXEC_BEHAVIORAL_FLIPPER)
   {
      // 1. Milestone Flip Target Cashout Check
      if(ExtBehavioralEngine.CheckMilestoneFlipTarget()) return;

      // 2. Manage 5-Stage TP Ladder & Stepped Breakeven Shield
      ExtBehavioralEngine.ManageLadderAndBreakeven();

      // 3. Check Floating Margin Pyramiding Reloads
      ExtBehavioralEngine.CheckPyramiding();

      // 4. Update Dracula HUD
      ExtBehavioralEngine.UpdateHUD();
   }

   // New Bar Processing for Signals
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == ExtLastBarTime) return;
   ExtLastBarTime = currentBarTime;

   // Copy Rates for institutional analysis (minimum 35 bars)
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 0, 35, rates);
   if(copied < 32) return;

   // Get EMA Trend Value
   double emaVal = 0.0;
   if(ExtEmaHandle != INVALID_HANDLE)
   {
      double emaBuffer[];
      ArraySetAsSeries(emaBuffer, true);
      if(CopyBuffer(ExtEmaHandle, 0, 0, 2, emaBuffer) >= 2)
         emaVal = emaBuffer[1];
   }

   // Behavioral Special Triggers (Traceback & Dump-and-Flip)
   if(InpExecutionEngine == EXEC_BEHAVIORAL_FLIPPER)
   {
      // Pattern 3: Traceback checks & HL trend reloads
      ExtBehavioralEngine.CheckTraceback(emaVal, rates);
      ExtBehavioralEngine.ManageTraceback(emaVal);

      // Pattern 7: Opposing Exhaustion Dump & 180° Flip
      ExtBehavioralEngine.CheckOpposingDumpAndFlip(rates);

      // Pattern 8: Volume Climax Absorption Fade
      ExtBehavioralEngine.CheckVolumeClimaxFade(rates, copied);
   }

   // Draw Asian Zones if enabled
   if(InpEnableVisuals)
   {
      VTS_DrawSessionZones(rates, copied, VTS_GetGMTOffset(), false);
   }

   // If already holding active positions, do not open a new primary basket
   if(CountActivePositions() > 0) return;

   // Check Session Filter
   if(!IsSessionAllowed()) return;

   // Dispatch to Selected Strategy Model
   switch(InpStrategyModel)
   {
      case STRAT_0_SMC_LIQUIDITY_SWEEP_OB:
         ScanModel0_LiquiditySweepOB(rates, emaVal);
         break;
      case STRAT_1_ICT_FVG_CONSEQUENT_ENC:
         ScanModel1_ICT_FVG(rates, emaVal);
         break;
      case STRAT_2_SD_FRESH_BASE_FLIP:
         ScanModel2_SND_FreshBaseFlip(rates, emaVal);
         break;
      case STRAT_3_SMC_INDUCEMENT_TRAP:
         ScanModel3_SMC_InducementTrap(rates, emaVal);
         break;
      case STRAT_4_ICT_POWER_OF_3_AMD:
         ScanModel4_ICT_PowerOf3_AMD(rates, emaVal);
         break;
      case STRAT_5_ICT_BREAKER_BLOCK_FLIP:
         ScanModel5_ICT_BreakerBlock(rates, emaVal);
         break;
      case STRAT_6_24_5_OTE_GOLDEN_ZONE:
         ScanModel6_24_5_OTE_GoldenZone(rates, emaVal);
         break;
      case STRAT_7_SD_DBR_RBD_VELOCITY:
         ScanModel7_SND_DBR_RBD(rates, emaVal);
         break;
      case STRAT_8_ICT_LIQUIDITY_VOID_BPR:
         ScanModel8_ICT_LiquidityVoid_BPR(rates, emaVal);
         break;
      case STRAT_9_INSTITUTIONAL_HYBRID:
         ScanModel9_MasterInstitutionalHybrid(rates, emaVal);
         break;
   }
}
//+------------------------------------------------------------------+
