//+------------------------------------------------------------------+
//|                                       Grand_Master_Hybrid_EA.mq5 |
//|               Master Algorithmic Trading Architecture            |
//|    The Ultimate Multi-Strategy Synthesis: SMC + ICT + S&D +     |
//|    Danial FX + Chart Fanatics + Universal Behavioral Compounding|
//|                               Copyright 2026, Quant Research Lab |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research Lab"
#property link      "https://github.com/dchumari/Youtube-Traders"
#property version   "5.00"
#property description "Grand Master Hybrid Suite: Fuses Bank ORB, ICT OTE 70.5%, S&D Bases, Danial Quasimodo, Verma Parabolic Short & Multi-Horizon Compounding"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Flipper_Behavioral_Engine.mqh>
#include <VisualTradeSuite.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                     |
//+------------------------------------------------------------------+
enum ENUM_HYBRID_CORE_MODEL
{
   MODEL_0_MATTEO_BANK_ORB          = 0, // 0: Matteo Conti Bank ORB + Session VWAP Breakout
   MODEL_1_ICT_OTE_SD_BASE          = 1, // 1: 24/5 ICT OTE 70.5% Golden Zone + S&D Fresh Base Tap
   MODEL_2_DANIAL_QUASIMODO         = 2, // 2: Ahmad Danial Quasimodo (QML) Left Shoulder Reversal
   MODEL_3_VERMA_PARABOLIC_SHORT    = 3, // 3: Kris Verma Parabolic Exhaustion Gap Fade
   MODEL_4_GRAND_MASTER_FUSION      = 4  // 4: Grand Master Multi-Regime Fusion (Autonomous All-Confluence)
};

enum ENUM_HORIZON_TARGET_TIER
{
   HORIZON_WEEKLY_FLIPPER           = 0, // 1-Week Flipper Sprint (>= 100% ROI Target, Aggressive Tiered Compounding)
   HORIZON_MONTHLY_EXPANSION        = 1, // 1-Month Expansion (>= 100% ROI Target, Balanced 3-Stage Compounding)
   HORIZON_ANNUAL_COMPOUND          = 2  // 1-Year Endurance (>= 1000% Multi-Month Target, Conservative Drawdown Guard)
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
sinput string   sep0 = "================ STRATEGY & HORIZON MODE ================";
input ENUM_HYBRID_CORE_MODEL     InpCoreModel         = MODEL_4_GRAND_MASTER_FUSION; // Core Institutional Model
input ENUM_HORIZON_TARGET_TIER   InpHorizonTier       = HORIZON_WEEKLY_FLIPPER;      // Target Horizon Tier
input ulong                      InpMagicNumber       = 889000;                      // EA Magic Number

sinput string   sep1 = "================ CAPITAL & COMPOUNDING SIZING ==========";
input double    InpBaseLotSize          = 0.01;      // Base Lot Size (Minimum Ticket)
input double    InpEquityStepSprint     = 20.0;      // Sprint Equity Step per 0.01 Lot ($20.0 for Weekly 100%)
input double    InpEquityStepMonthly    = 35.0;      // Monthly Equity Step per 0.01 Lot ($35.0 for 1-Month 100%)
input double    InpEquityStepAnnual     = 50.0;      // Annual Equity Step per 0.01 Lot ($50.0 for 1-Year 1000%)
input double    InpMaxLotCap            = 1.00;      // Maximum Lot Cap per Ticket
input int       InpBaseStopLossPoints   = 220;       // Stop Loss in Points (22 pips on Gold)

sinput string   sep2 = "================ BEHAVIORAL FLIPPER PARAMETERS =========";
input int       InpSpamTicketsCount     = 5;         // Micro-Tickets per Entry Basket
input int       InpTP1Points            = 200;       // TP1 (+20 pips, bank partial)
input int       InpTP2Points            = 350;       // TP2 (+35 pips, bank partial + move BE)
input int       InpTP3Points            = 600;       // TP3 (+60 pips, bank partial + lock +25p)
input int       InpTP4Points            = 1000;      // TP4 (+100 pips, bank partial + lock +60p)
input int       InpTP5Points            = 1600;      // TP5 (+160 pips moonshot runner)
input bool      InpEnablePyramiding     = true;      // Floating Margin Pyramiding
input int       InpReloadStepPoints     = 350;       // Pyramiding Step Distance (+35 pips)
input int       InpMaxPyramidLayers     = 3;         // Max Pyramid Layers
input bool      InpEnableDumpAndFlip    = true;      // Opposing Reversal Handbrake Dump
input double    InpDumpWickRatio        = 0.45;      // Opposing Wick Ratio Threshold (45%)
input bool      InpEnableFlipMilestone  = true;      // Milestone Extraction Lockout
input double    InpTargetEquityWeekly   = 1000.0;    // Target Equity Flip Cap ($1,000)

sinput string   sep3 = "================ SESSION & CONFLUENCE FILTERS ===========";
input bool      InpUseSessionFilter     = true;      // Use London/NY Session Filter
input int       InpLondonStartHour      = 7;         // London Start UTC
input int       InpLondonEndHour        = 11;        // London End UTC
input int       InpNYStartHour          = 12;        // NY Start UTC
input int       InpNYEndHour            = 18;        // NY End UTC
input int       InpEMATrendPeriod       = 50;        // EMA Trend Backbone (50 M15)
input double    InpMinWickRejection     = 0.35;      // Minimum Rejection Wick (35%)
input int       InpSwingLookback        = 24;        // Swing High/Low Structure Lookback
input double    InpVolumeSurgeMult      = 1.8;       // Tick Volume Surge Multiplier

sinput string   sep4 = "================ VISUAL ROADMAP & HUD ==================";
input bool      InpEnableVisuals        = true;      // Dracula Visual Roadmap Drawings
input bool      InpApplyDraculaTheme    = true;      // Apply Dracula Navy Dark Palette (#282A36)

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & STATE                                           |
//+------------------------------------------------------------------+
CTrade                  ExtTrade;
CPositionInfo           ExtPos;
CFlipperBehavioralEngine ExtEngine;

int                     ExtEmaHandle = INVALID_HANDLE;
datetime                ExtLastTradeTime = 0;
datetime                ExtLastBarTime = 0;
double                  ExtLastORBHigh = 0.0;
double                  ExtLastORBLow = 0.0;
datetime                ExtLastORBDate = 0;
string                  ExtPrefix = "GMH_";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   ExtTrade.SetExpertMagicNumber(InpMagicNumber);
   ExtTrade.SetMarginMode();
   ExtTrade.SetTypeFillingBySymbol(_Symbol);

   ExtEmaHandle = iMA(_Symbol, _Period, InpEMATrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(ExtEmaHandle == INVALID_HANDLE)
   {
      Print("[GMH ERROR] Failed to create EMA handle!");
      return INIT_FAILED;
   }

   // Initialize Flipper Behavioral Engine
   SFlipperBehavioralConfig cfg;
   cfg.enabled                 = true;
   cfg.magicNumber             = InpMagicNumber;
   cfg.prefix                  = ExtPrefix;
   cfg.spamTicketsCount        = InpSpamTicketsCount;
   
   // Calibrate equity step based on selected Horizon Tier
   if(InpHorizonTier == HORIZON_WEEKLY_FLIPPER)
      cfg.equityPerMinLot      = InpEquityStepSprint;
   else if(InpHorizonTier == HORIZON_MONTHLY_EXPANSION)
      cfg.equityPerMinLot      = InpEquityStepMonthly;
   else
      cfg.equityPerMinLot      = InpEquityStepAnnual;

   cfg.maxLotPerTicket         = InpMaxLotCap;
   cfg.stopLossPoints          = InpBaseStopLossPoints;
   cfg.tp1Points               = InpTP1Points;
   cfg.tp2Points               = InpTP2Points;
   cfg.tp3Points               = InpTP3Points;
   cfg.tp4Points               = InpTP4Points;
   cfg.tp5Points               = InpTP5Points;
   cfg.enableTraceback         = false;
   cfg.tracebackExtensionPts   = 250;
   cfg.tracebackWickRatio      = 0.35;
   cfg.tracebackTPPoints       = 150;
   cfg.tracebackSLPoints       = 120;
   cfg.reloadAtHL              = false;
   cfg.enablePyramiding        = (InpHorizonTier != HORIZON_ANNUAL_COMPOUND) ? InpEnablePyramiding : false;
   cfg.maxPyramidLayers        = (InpHorizonTier == HORIZON_WEEKLY_FLIPPER) ? InpMaxPyramidLayers : 2;
   cfg.reloadStepPoints        = InpReloadStepPoints;
   cfg.reloadTicketsCount      = 2;
   cfg.enableLiquidationSweep  = true;
   cfg.spikeMinWickPct         = 0.40;
   cfg.enableJudasFlush        = false;
   cfg.enableDumpAndFlip       = InpEnableDumpAndFlip;
   cfg.dumpWickRatio           = InpDumpWickRatio;
   cfg.enableVolumeClimaxFade  = true;
   cfg.volumeSpikeMultiplier   = InpVolumeSurgeMult;
   cfg.enableFlipMilestone     = (InpHorizonTier == HORIZON_WEEKLY_FLIPPER) ? InpEnableFlipMilestone : false;
   cfg.targetEquity            = InpTargetEquityWeekly;
   cfg.enableVisuals           = InpEnableVisuals;
   cfg.applyDraculaTheme       = InpApplyDraculaTheme;

   ExtEngine.Init(cfg);

   if(InpEnableVisuals && InpApplyDraculaTheme)
   {
      VTS_ApplyDraculaTheme();
   }

   Print("====================================================================");
   Print("  GRAND MASTER HYBRID SUITE INITIALIZED SUCCESSFULLY                ");
   Print("  Core Model: ", EnumToString(InpCoreModel));
   Print("  Horizon Tier: ", EnumToString(InpHorizonTier));
   Print("  Equity Compounding Step: $", cfg.equityPerMinLot, " / 0.01 lot");
   Print("====================================================================");

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
   ExtEngine.Clean();
}

//+------------------------------------------------------------------+
//| Helper: Check Session Filter                                     |
//+------------------------------------------------------------------+
bool IsInSession(datetime time)
{
   if(!InpUseSessionFilter) return true;
   MqlDateTime dt;
   TimeToStruct(time, dt);
   
   bool isLondon = (dt.hour >= InpLondonStartHour && dt.hour < InpLondonEndHour);
   bool isNY     = (dt.hour >= InpNYStartHour && dt.hour < InpNYEndHour);
   return (isLondon || isNY);
}

//+------------------------------------------------------------------+
//| Helper: Get Moving Average Value                                 |
//+------------------------------------------------------------------+
double GetEMA(int shift)
{
   double buf[1];
   if(CopyBuffer(ExtEmaHandle, 0, shift, 1, buf) > 0)
      return buf[0];
   return 0.0;
}

//+------------------------------------------------------------------+
//| Helper: Calculate Rejection Wick Ratios                          |
//+------------------------------------------------------------------+
void GetWickRatios(const MqlRates &bar, double &upperWickRatio, double &lowerWickRatio)
{
   double range = bar.high - bar.low;
   if(range <= 0.0) { upperWickRatio = 0.0; lowerWickRatio = 0.0; return; }
   double bodyHigh = MathMax(bar.open, bar.close);
   double bodyLow  = MathMin(bar.open, bar.close);
   upperWickRatio = (bar.high - bodyHigh) / range;
   lowerWickRatio = (bodyLow - bar.low) / range;
}

//+------------------------------------------------------------------+
//| Helper: Get Tick Volume Surge                                    |
//+------------------------------------------------------------------+
bool IsVolumeSurge(const MqlRates &rates[], int index)
{
   long currentVol = rates[index].tick_volume;
   long sumVol = 0;
   int count = 20;
   for(int i = 1; i <= count; i++)
   {
      if(index + i < ArraySize(rates))
         sumVol += rates[index + i].tick_volume;
   }
   double avgVol = (count > 0) ? (double)sumVol / count : 1.0;
   return (currentVol >= avgVol * InpVolumeSurgeMult);
}

//+------------------------------------------------------------------+
//| MODEL 0: Matteo Conti Bank Opening Range Breakout (ORB)          |
//+------------------------------------------------------------------+
void CheckMatteoBankORB(const MqlRates &rates[], int &sig)
{
   MqlDateTime dt;
   TimeToStruct(rates[1].time, dt);
   
   // Establish 15m Initial Balance at London Open (07:00 UTC)
   if(dt.hour == InpLondonStartHour && dt.min == 0)
   {
      ExtLastORBHigh = rates[1].high;
      ExtLastORBLow  = rates[1].low;
      ExtLastORBDate = rates[1].time;
   }
   
   if(ExtLastORBDate == 0 || (rates[1].time - ExtLastORBDate) > 4 * 3600) return;
   
   double ema = GetEMA(1);
   double close = rates[1].close;
   
   // Bullish Breakout above ORB High with EMA alignment
   if(rates[1].close > ExtLastORBHigh && rates[2].close <= ExtLastORBHigh && close > ema)
   {
      if(IsVolumeSurge(rates, 1))
         sig = 1;
   }
   // Bearish Breakout below ORB Low with EMA alignment
   else if(rates[1].close < ExtLastORBLow && rates[2].close >= ExtLastORBLow && close < ema)
   {
      if(IsVolumeSurge(rates, 1))
         sig = -1;
   }
}

//+------------------------------------------------------------------+
//| MODEL 1: ICT Optimal Trade Entry (OTE 70.5%) inside S&D Base     |
//+------------------------------------------------------------------+
void CheckICT_OTE_SDBase(const MqlRates &rates[], int &sig)
{
   int lookback = InpSwingLookback;
   double swingHigh = -1.0, swingLow = 999999.0;
   int highIdx = -1, lowIdx = -1;
   
   for(int i = 2; i <= lookback; i++)
   {
      if(rates[i].high > swingHigh) { swingHigh = rates[i].high; highIdx = i; }
      if(rates[i].low < swingLow)   { swingLow = rates[i].low;   lowIdx = i; }
   }
   
   double range = swingHigh - swingLow;
   if(range <= 50 * _Point) return;
   
   double ema = GetEMA(1);
   double upperWick, lowerWick;
   GetWickRatios(rates[1], upperWick, lowerWick);
   
   // Bullish OTE: Upward displacement (Low was before High), retracing into 61.8% - 78.6%
   if(lowIdx > highIdx && rates[1].close > ema)
   {
      double fib618 = swingHigh - 0.618 * range;
      double fib786 = swingHigh - 0.786 * range;
      if(rates[1].low <= fib618 && rates[1].low >= fib786 && lowerWick >= InpMinWickRejection)
      {
         sig = 1;
      }
   }
   // Bearish OTE: Downward displacement (High was before Low), retracing into 61.8% - 78.6%
   else if(highIdx > lowIdx && rates[1].close < ema)
   {
      double fib618 = swingLow + 0.618 * range;
      double fib786 = swingLow + 0.786 * range;
      if(rates[1].high >= fib618 && rates[1].high <= fib786 && upperWick >= InpMinWickRejection)
      {
         sig = -1;
      }
   }
}

//+------------------------------------------------------------------+
//| MODEL 2: Ahmad Danial Quasimodo (QML) Left Shoulder Reversal    |
//+------------------------------------------------------------------+
void CheckDanialQuasimodo(const MqlRates &rates[], int &sig)
{
   int lookback = 28;
   double ema = GetEMA(1);
   double upperWick, lowerWick;
   GetWickRatios(rates[1], upperWick, lowerWick);
   
   // Bearish QM: Left Shoulder (High), Head (Higher High), Lower Low (Break of structure), Retest QML
   double leftShoulderHigh = -1.0;
   int lsIdx = -1;
   for(int i = 12; i <= lookback; i++)
   {
      if(rates[i].high > leftShoulderHigh) { leftShoulderHigh = rates[i].high; lsIdx = i; }
   }
   
   double headHigh = -1.0;
   int headIdx = -1;
   for(int i = 6; i < lsIdx; i++)
   {
      if(rates[i].high > headHigh) { headHigh = rates[i].high; headIdx = i; }
   }
   
   if(headHigh > leftShoulderHigh && headIdx > 0)
   {
      double minLowAfterHead = 999999.0;
      for(int i = 2; i < headIdx; i++)
      {
         if(rates[i].low < minLowAfterHead) minLowAfterHead = rates[i].low;
      }
      
      if(minLowAfterHead < rates[headIdx].low && MathAbs(rates[1].high - leftShoulderHigh) <= 25 * _Point)
      {
         if(upperWick >= 0.40 && rates[1].close < ema)
            sig = -1;
      }
   }
   
   // Bullish QM: Left Shoulder (Low), Head (Lower Low), Higher High (BOS), Retest QML
   double leftShoulderLow = 999999.0;
   int lsLowIdx = -1;
   for(int i = 12; i <= lookback; i++)
   {
      if(rates[i].low < leftShoulderLow) { leftShoulderLow = rates[i].low; lsLowIdx = i; }
   }
   
   double headLow = 999999.0;
   int headLowIdx = -1;
   for(int i = 6; i < lsLowIdx; i++)
   {
      if(rates[i].low < headLow) { headLow = rates[i].low; headLowIdx = i; }
   }
   
   if(headLow < leftShoulderLow && headLowIdx > 0)
   {
      double maxHighAfterHead = -1.0;
      for(int i = 2; i < headLowIdx; i++)
      {
         if(rates[i].high > maxHighAfterHead) maxHighAfterHead = rates[i].high;
      }
      
      if(maxHighAfterHead > rates[headLowIdx].high && MathAbs(rates[1].low - leftShoulderLow) <= 25 * _Point)
      {
         if(lowerWick >= 0.40 && rates[1].close > ema)
            sig = 1;
      }
   }
}

//+------------------------------------------------------------------+
//| MODEL 3: Kris Verma Parabolic Exhaustion Gap Fade                |
//+------------------------------------------------------------------+
void CheckVermaParabolicFade(const MqlRates &rates[], int &sig)
{
   double ema = GetEMA(1);
   double distanceToEma = (rates[1].close - ema) / _Point;
   double upperWick, lowerWick;
   GetWickRatios(rates[1], upperWick, lowerWick);
   
   // Parabolic Bullish Extension Exhaustion Short
   if(distanceToEma >= 250.0 && upperWick >= 0.45)
   {
      if(IsVolumeSurge(rates, 1))
         sig = -1;
   }
   // Parabolic Bearish Extension Exhaustion Buy
   else if(distanceToEma <= -250.0 && lowerWick >= 0.45)
   {
      if(IsVolumeSurge(rates, 1))
         sig = 1;
   }
}

//+------------------------------------------------------------------+
//| MODEL 4: Grand Master Multi-Regime Fusion Engine                 |
//+------------------------------------------------------------------+
void CheckGrandMasterFusion(const MqlRates &rates[], int &sig)
{
   // Priority 1: Check Parabolic Volatility Exhaustion (High Alpha Fade)
   CheckVermaParabolicFade(rates, sig);
   if(sig != 0) return;
   
   // Priority 2: Check Session Opening Range Breakout (London/NY Institutional Push)
   CheckMatteoBankORB(rates, sig);
   if(sig != 0) return;
   
   // Priority 3: Check Quasimodo Left Shoulder Structural Invalidation
   CheckDanialQuasimodo(rates, sig);
   if(sig != 0) return;
   
   // Priority 4: Check ICT OTE 70.5% Golden Zone inside S&D Base
   CheckICT_OTE_SDBase(rates, sig);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Manage Open Baskets & Trailing via Behavioral Engine
   if(ExtEngine.CheckMilestoneFlipTarget()) return;
   ExtEngine.ManageLadderAndBreakeven();
   ExtEngine.CheckPyramiding();
   ExtEngine.UpdateHUD();

   // Only evaluate new signals on bar open
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == ExtLastBarTime) return;
   ExtLastBarTime = currentBarTime;

   // Enforce session regime
   if(!IsInSession(currentBarTime)) return;

   // 2-Bar Signal Throttle
   if(ExtLastTradeTime > 0 && (currentBarTime - ExtLastTradeTime) < 2 * PeriodSeconds(_Period))
      return;

   // Check if active basket already exists
   int openCount = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(ExtPos.SelectByIndex(i) && (ExtPos.Magic() == InpMagicNumber || ExtPos.Magic() == InpMagicNumber + 99) && ExtPos.Symbol() == _Symbol)
         openCount++;
   }
   if(openCount > 0) return;

   // Copy rates
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 40, rates) < 35) return;

   int signal = 0; // 1 = Buy, -1 = Sell

   switch(InpCoreModel)
   {
      case MODEL_0_MATTEO_BANK_ORB:       CheckMatteoBankORB(rates, signal);       break;
      case MODEL_1_ICT_OTE_SD_BASE:       CheckICT_OTE_SDBase(rates, signal);      break;
      case MODEL_2_DANIAL_QUASIMODO:      CheckDanialQuasimodo(rates, signal);     break;
      case MODEL_3_VERMA_PARABOLIC_SHORT: CheckVermaParabolicFade(rates, signal);  break;
      case MODEL_4_GRAND_MASTER_FUSION:   CheckGrandMasterFusion(rates, signal);   break;
   }

   if(signal != 0)
   {
      ENUM_ORDER_TYPE otype = (signal > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double entryPrice = (signal > 0) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

      // Execute via Behavioral Engine
      ExtEngine.ExecuteSpamBasket(otype, entryPrice, InpBaseStopLossPoints);
      ExtLastTradeTime = currentBarTime;

      Print("[GMH TRADE] Executed ", EnumToString(otype), " Basket! Model: ", EnumToString(InpCoreModel),
            " | Horizon: ", EnumToString(InpHorizonTier), " | Price: ", entryPrice);
   }
}
//+------------------------------------------------------------------+
