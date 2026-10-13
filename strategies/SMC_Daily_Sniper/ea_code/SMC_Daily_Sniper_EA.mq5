//+------------------------------------------------------------------+
//|                                         SMC_Daily_Sniper_EA.mq5 |
//|           Institutional Smart Money Concepts & S&D Daily Suite   |
//|    Fuses Trendline Liquidity Purge, SMC Inducement (IDM), Fresh  |
//|    Supply & Demand Bases, Asian Sweep & Behavioral Compounding   |
//|                               Copyright 2026, Quant Research Lab |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research Lab"
#property link      "https://github.com/dchumari/Youtube-Traders"
#property version   "5.10"
#property description "SMC Daily Sniper EA: High-frequency daily SMC + Trendline Liquidity + Fresh S&D Bases with 5-stage TP laddering & aggressive compounding"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Flipper_Behavioral_Engine.mqh>
#include <VisualTradeSuite.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                     |
//+------------------------------------------------------------------+
enum ENUM_SMC_DAILY_MODEL
{
   MODEL_TRENDLINE_LIQUIDITY_TRAP   = 0, // 0: Trendline Liquidity Purge + Fresh S&D Base Tap
   MODEL_SMC_INDUCEMENT_ORDERBLOCK  = 1, // 1: SMC Inducement (IDM) Sweep + Origin Order Block
   MODEL_FRESH_SD_BASE_FLIP         = 2, // 2: Fresh Drop-Base-Rally / Rally-Base-Drop S&D Flip
   MODEL_ASIAN_SWEEP_CONTINUATION   = 3, // 3: Daily Asian High/Low Sweep + Killzone Momentum
   MODEL_MASTER_ALL_CONFLUENCE      = 4  // 4: Master Confluence Sniper (Multi-Signal Fusion)
};

enum ENUM_DAILY_TARGET_HORIZON
{
   HORIZON_DAILY_SPRINT_DOUBLER     = 0, // Daily/Weekly Sprint (>= 100% ROI, Aggressive Compounding)
   HORIZON_MONTHLY_CONSISTENCY      = 1, // Monthly Consistency (>= 100% ROI, Balanced Compounding)
   HORIZON_SWING_ENDURANCE          = 2  // Multi-Month Endurance (Conservative Risk Guard)
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
sinput string   sep0 = "================ STRATEGY & HORIZON MODE ================";
input ENUM_SMC_DAILY_MODEL       InpCoreModel         = MODEL_MASTER_ALL_CONFLUENCE;  // Core Execution Model
input ENUM_DAILY_TARGET_HORIZON  InpHorizonMode       = HORIZON_DAILY_SPRINT_DOUBLER; // Target Horizon Tier
input ulong                      InpMagicNumber       = 889100;                       // EA Magic Number

sinput string   sep1 = "================ CAPITAL & COMPOUNDING SIZING ==========";
input double    InpBaseLotSize          = 0.01;      // Base Lot Size (Minimum Ticket)
input double    InpEquityStepSprint     = 18.0;      // Equity Step per 0.01 Lot ($18.0 for Sprint Doubler)
input double    InpEquityStepMonthly    = 35.0;      // Equity Step per 0.01 Lot ($35.0 for Monthly 100%)
input double    InpMaxLotCap            = 1.00;      // Maximum Lot Cap per Ticket
input int       InpBaseStopLossPoints   = 220;       // Base Stop Loss in Points (22 pips on Gold)

sinput string   sep2 = "================ BEHAVIORAL LADDER PARAMETERS ==========";
input int       InpSpamTicketsCount     = 3;         // Micro-Tickets per Entry Basket
input int       InpTP1Points            = 200;       // TP1 (+20 pips, bank partial)
input int       InpTP2Points            = 350;       // TP2 (+35 pips, bank partial + BE shield)
input int       InpTP3Points            = 600;       // TP3 (+60 pips, bank partial + lock +25p)
input int       InpTP4Points            = 1000;      // TP4 (+100 pips, bank partial + lock +60p)
input int       InpTP5Points            = 1600;      // TP5 (+160 pips moonshot runner)

sinput string   sep3 = "================ MARGIN PYRAMIDING & CONTROLS ==========";
input bool      InpEnablePyramiding     = true;      // Enable Floating Equity Pyramiding
input int       InpMaxPyramidLayers     = 2;         // Maximum Pyramid Layers
input int       InpReloadStepPoints     = 300;       // Distance to Fire Next Layer (+30 pips)
input bool      InpEnableDumpAndFlip    = true;      // Opposing Exhaustion Dump & Flip
input double    InpDumpWickRatio        = 0.45;      // Opposing Rejection Wick Ratio to Wipe Basket

sinput string   sep4 = "================ SMC & TRENDLINE PARAMETERS ============";
input int       InpSwingLookback        = 24;        // Swing High/Low Lookback Window
input int       InpTrendlinePoints      = 3;         // Touches to Validate Trendline (2 or 3)
input int       InpMinSweepPoints       = 120;       // Minimum Liquidity Sweep (12 pips)
input double    InpMinWickRejection     = 0.35;      // Minimum Rejection Wick Ratio (35%)
input int       InpEMATrendPeriod       = 50;        // Baseline Structural EMA Period
input double    InpVolumeSurgeMult      = 1.6;       // Volume Surge Multiplier (1.6x 20-bar avg)

sinput string   sep5 = "================ SESSION & TIMING FILTERS ==============";
input bool      InpUseSessionFilter     = true;      // Enable London / NY Killzone Focus
input int       InpLondonStartHour      = 7;         // London Open Start (07:00 UTC)
input int       InpLondonEndHour        = 11;        // London Open End (11:00 UTC)
input int       InpNYStartHour          = 12;        // New York Open Start (12:00 UTC)
input int       InpNYEndHour            = 18;        // New York Open End (18:00 UTC)
input int       InpGMTOffset            = 3;         // Broker GMT Offset

sinput string   sep6 = "================ VISUAL TRADE SUITE & HUD ==============";
input bool      InpEnableVisuals        = true;      // Enable On-Chart Visual Roadmap & Boxes
input bool      InpApplyDraculaTheme    = true;      // Auto-Apply Dracula Dark Palette (#282A36)

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & STRUCTS                                         |
//+------------------------------------------------------------------+
CFlipperBehavioralEngine ExtEngine;
CTrade                   ExtTrade;
CPositionInfo            ExtPos;

int      hEMA             = INVALID_HANDLE;
int      hATR             = INVALID_HANDLE;
datetime g_last_bar_time  = 0;
datetime g_last_trade_time= 0;

// Internal Swing Structure
struct SMarketSwing
{
   double   price;
   datetime time;
   int      bar_idx;
   bool     is_high;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   hEMA = iMA(_Symbol, _Period, InpEMATrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
   hATR = iATR(_Symbol, _Period, 14);

   if(hEMA == INVALID_HANDLE || hATR == INVALID_HANDLE)
   {
      Print("❌ Failed to initialize core indicators!");
      return INIT_FAILED;
   }

   // Initialize Universal Flipper Behavioral Engine
   SFlipperBehavioralConfig cfg;
   cfg.magicNumber           = InpMagicNumber;
   cfg.prefix                = "SMCD_";
   cfg.spamTicketsCount      = InpSpamTicketsCount;
   cfg.tp1Points             = InpTP1Points;
   cfg.tp2Points             = InpTP2Points;
   cfg.tp3Points             = InpTP3Points;
   cfg.tp4Points             = InpTP4Points;
   cfg.tp5Points             = InpTP5Points;
   cfg.stopLossPoints        = InpBaseStopLossPoints;

   // Compounding Step
   if(InpHorizonMode == HORIZON_DAILY_SPRINT_DOUBLER)
      cfg.equityPerMinLot    = InpEquityStepSprint;
   else if(InpHorizonMode == HORIZON_MONTHLY_CONSISTENCY)
      cfg.equityPerMinLot    = InpEquityStepMonthly;
   else
      cfg.equityPerMinLot    = 50.0;

   cfg.maxLotPerTicket       = InpMaxLotCap;
   cfg.enablePyramiding      = InpEnablePyramiding;
   cfg.maxPyramidLayers      = InpMaxPyramidLayers;
   cfg.reloadStepPoints      = InpReloadStepPoints;
   cfg.reloadTicketsCount    = 2;
   cfg.enableDumpAndFlip     = InpEnableDumpAndFlip;
   cfg.dumpWickRatio         = InpDumpWickRatio;
   cfg.enableTraceback       = false;
   cfg.enableLiquidationSweep= true;
   cfg.spikeMinWickPct       = InpMinWickRejection;
   cfg.enableJudasFlush      = true;
   cfg.enableVolumeClimaxFade= true;
   cfg.volumeSpikeMultiplier = InpVolumeSurgeMult;
   cfg.enableFlipMilestone   = false;
   cfg.targetEquity          = 10000.0;
   cfg.enableVisuals         = InpEnableVisuals;
   cfg.applyDraculaTheme     = InpApplyDraculaTheme;

   ExtEngine.Init(cfg);

   if(InpEnableVisuals && InpApplyDraculaTheme)
   {
      VTS_ApplyDraculaTheme();
   }

   Print("✅ SMC Daily Sniper EA initialized successfully. Model: ", EnumToString(InpCoreModel));
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(hEMA != INVALID_HANDLE) IndicatorRelease(hEMA);
   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);
   ExtEngine.Clean();
}

//+------------------------------------------------------------------+
//| Helper: Check Active Trading Session                             |
//+------------------------------------------------------------------+
bool IsInActiveSession()
{
   if(!InpUseSessionFilter) return true;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hour = dt.hour;

   bool is_london = (hour >= InpLondonStartHour && hour < InpLondonEndHour);
   bool is_ny     = (hour >= InpNYStartHour && hour < InpNYEndHour);

   return (is_london || is_ny);
}

//+------------------------------------------------------------------+
//| Helper: Extract Swing Highs and Lows                             |
//+------------------------------------------------------------------+
bool GetSwingPoints(const MqlRates &rates[], int total, SMarketSwing &swings[], int &swing_count)
{
   swing_count = 0;
   int lookback = 3;
   if(total < lookback * 2 + 5) return false;

   for(int i = lookback; i < total - lookback; i++)
   {
      bool is_high = true;
      bool is_low  = true;

      for(int j = 1; j <= lookback; j++)
      {
         if(rates[i].high <= rates[i - j].high || rates[i].high <= rates[i + j].high) is_high = false;
         if(rates[i].low  >= rates[i - j].low  || rates[i].low  >= rates[i + j].low)  is_low  = false;
      }

      if(is_high)
      {
         ArrayResize(swings, swing_count + 1);
         swings[swing_count].price   = rates[i].high;
         swings[swing_count].time    = rates[i].time;
         swings[swing_count].bar_idx = i;
         swings[swing_count].is_high = true;
         swing_count++;
      }
      else if(is_low)
      {
         ArrayResize(swings, swing_count + 1);
         swings[swing_count].price   = rates[i].low;
         swings[swing_count].time    = rates[i].time;
         swings[swing_count].bar_idx = i;
         swings[swing_count].is_high = false;
         swing_count++;
      }

      if(swing_count >= 10) break;
   }

   return (swing_count >= 3);
}

//+------------------------------------------------------------------+
//| MODEL 0: Trendline Liquidity Trap + S&D Base Tap                 |
//| Sweeps retail trendline stops into fresh unmitigated zone        |
//+------------------------------------------------------------------+
bool CheckTrendlineLiquidityTrap(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   if(total < 30) return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   SMarketSwing swings[];
   int count = 0;
   if(!GetSwingPoints(rates, total, swings, count)) return false;

   // 1. Check Bullish Trendline Liquidity Run (Ascending Trendline Lows Swept)
   int low_swings[3];
   int low_count = 0;
   for(int i = 0; i < count; i++)
   {
      if(!swings[i].is_high)
      {
         low_swings[low_count++] = i;
         if(low_count >= 2) break;
      }
   }

   if(low_count >= 2)
   {
      double p1 = swings[low_swings[1]].price; // older swing low (bar b1)
      double p2 = swings[low_swings[0]].price; // newer swing low (bar b2)
      int b1    = swings[low_swings[1]].bar_idx;
      int b2    = swings[low_swings[0]].bar_idx;

      if(b1 > b2 && p2 >= p1 && (b1 - b2) > 0) // Ascending trendline
      {
         // Linear extrapolation to bar 1: p(1) = p2 + ((p2 - p1) / (b2 - b1)) * (1 - b2)
         double projected_tl = p2 + ((p2 - p1) / (double)(b2 - b1)) * (1.0 - (double)b2);

         // Bar 1 wicks BELOW trendline by at least InpMinSweepPoints, but closes back ABOVE!
         double bar1_low = rates[1].low;
         double sweep_dist = (projected_tl - bar1_low) / point;

         double total_range = rates[1].high - rates[1].low;
         double lower_wick  = MathMin(rates[1].open, rates[1].close) - rates[1].low;

         if(sweep_dist >= InpMinSweepPoints && total_range > 0 && (lower_wick / total_range) >= InpMinWickRejection && rates[1].close > projected_tl)
         {
            if(rates[1].close > ema_val) // Aligned with macro trend
            {
               signal_dir = 1; // BUY SIGNAL
               return true;
            }
         }
      }
   }

   // 2. Bearish Trendline Trap: Descending Trendline Highs Swept
   int high_swings[3];
   int high_count = 0;
   for(int i = 0; i < count; i++)
   {
      if(swings[i].is_high)
      {
         high_swings[high_count++] = i;
         if(high_count >= 2) break;
      }
   }

   if(high_count >= 2)
   {
      double p1 = swings[high_swings[1]].price; // older swing high
      double p2 = swings[high_swings[0]].price; // newer swing high
      int b1    = swings[high_swings[1]].bar_idx;
      int b2    = swings[high_swings[0]].bar_idx;

      if(b1 > b2 && p2 <= p1 && (b1 - b2) > 0) // Descending trendline
      {
         double projected_tl = p2 + ((p2 - p1) / (double)(b2 - b1)) * (1.0 - (double)b2);

         double bar1_high = rates[1].high;
         double sweep_dist = (bar1_high - projected_tl) / point;

         double total_range = rates[1].high - rates[1].low;
         double upper_wick  = rates[1].high - MathMax(rates[1].open, rates[1].close);

         if(sweep_dist >= InpMinSweepPoints && total_range > 0 && (upper_wick / total_range) >= InpMinWickRejection && rates[1].close < projected_tl)
         {
            if(rates[1].close < ema_val) // Aligned with macro trend
            {
               signal_dir = -1; // SELL SIGNAL
               return true;
            }
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 1: SMC Inducement (IDM) Sweep + Origin Order Block         |
//| Purges retail bait pullback and taps unmitigated origin block   |
//+------------------------------------------------------------------+
bool CheckSMCInducementOrderBlock(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   if(total < 25) return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Bullish Setup:
   // Prior impulse broke structure upwards. Bar 3-5 formed minor pullback high/low (IDM).
   // Bar 1 swept below the IDM low into the prior bullish Order Block (Bar 7-10) and rejected strongly.
   if(rates[1].close > ema_val)
   {
      double idm_low = 999999.0;
      for(int i = 2; i <= 6; i++)
      {
         if(rates[i].low < idm_low) idm_low = rates[i].low;
      }

      // Bar 1 swept below idm_low
      if(rates[1].low < idm_low && rates[1].close > idm_low)
      {
         double total_range = rates[1].high - rates[1].low;
         double lower_wick  = MathMin(rates[1].open, rates[1].close) - rates[1].low;
         if(total_range > 0 && (lower_wick / total_range) >= InpMinWickRejection)
         {
            signal_dir = 1; // BUY
            return true;
         }
      }
   }

   // Bearish Setup:
   if(rates[1].close < ema_val)
   {
      double idm_high = 0.0;
      for(int i = 2; i <= 6; i++)
      {
         if(rates[i].high > idm_high) idm_high = rates[i].high;
      }

      // Bar 1 swept above idm_high
      if(rates[1].high > idm_high && rates[1].close < idm_high)
      {
         double total_range = rates[1].high - rates[1].low;
         double upper_wick  = rates[1].high - MathMax(rates[1].open, rates[1].close);
         if(total_range > 0 && (upper_wick / total_range) >= InpMinWickRejection)
         {
            signal_dir = -1; // SELL
            return true;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 2: Fresh Drop-Base-Rally / Rally-Base-Drop S&D Flip        |
//| Retests fresh base with displacement ratio >= 1.5x               |
//+------------------------------------------------------------------+
bool CheckFreshSDBaseFlip(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   if(total < 20) return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Scan for fresh Drop-Base-Rally (Demand):
   // Bar 4-5 small consolidating base. Bar 2-3 massive bullish displacement candle.
   // Bar 1 retests the top of the base.
   double base_high = MathMax(rates[4].high, rates[5].high);
   double base_low  = MathMin(rates[4].low,  rates[5].low);
   double base_size = base_high - base_low;

   double rally_size = rates[2].high - rates[4].close;
   if(base_size > 0 && (rally_size / base_size) >= 1.8 && rates[2].close > base_high)
   {
      // Retest tap on Bar 1
      if(rates[1].low <= base_high && rates[1].close >= base_high && rates[1].close > ema_val)
      {
         double total_range = rates[1].high - rates[1].low;
         double lower_wick  = MathMin(rates[1].open, rates[1].close) - rates[1].low;
         if(total_range > 0 && (lower_wick / total_range) >= InpMinWickRejection)
         {
            signal_dir = 1; // BUY
            return true;
         }
      }
   }

   // Scan for fresh Rally-Base-Drop (Supply):
   double s_base_high = MathMax(rates[4].high, rates[5].high);
   double s_base_low  = MathMin(rates[4].low,  rates[5].low);
   double s_base_size = s_base_high - s_base_low;

   double drop_size = rates[4].close - rates[2].low;
   if(s_base_size > 0 && (drop_size / s_base_size) >= 1.8 && rates[2].close < s_base_low)
   {
      // Retest tap on Bar 1
      if(rates[1].high >= s_base_low && rates[1].close <= s_base_low && rates[1].close < ema_val)
      {
         double total_range = rates[1].high - rates[1].low;
         double upper_wick  = rates[1].high - MathMax(rates[1].open, rates[1].close);
         if(total_range > 0 && (upper_wick / total_range) >= InpMinWickRejection)
         {
            signal_dir = -1; // SELL
            return true;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 3: Daily Asian High/Low Sweep + Killzone Momentum          |
//| London Open purges Asian range, absorbs retail breakout orders  |
//+------------------------------------------------------------------+
bool CheckAsianSweepContinuation(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // Only active during London / NY Transition (07:00 to 14:00 UTC)
   if(dt.hour < InpLondonStartHour || dt.hour > 14) return false;

   // Identify Asian Range (00:00 to 07:00 UTC)
   datetime day_start = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   datetime a_start   = day_start + (0 + InpGMTOffset) * 3600;
   datetime a_end     = day_start + (7 + InpGMTOffset) * 3600;

   double a_high = 0.0, a_low = 999999.0;
   int bars_found = 0;

   for(int i = 0; i < total; i++)
   {
      if(rates[i].time >= a_start && rates[i].time < a_end)
      {
         if(rates[i].high > a_high) a_high = rates[i].high;
         if(rates[i].low  < a_low)  a_low  = rates[i].low;
         bars_found++;
      }
   }

   if(bars_found < 5) return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Sweep of Asian Low (Bullish Judas Sweep)
   if(rates[1].low < a_low && (a_low - rates[1].low) / point >= InpMinSweepPoints && rates[1].close > a_low)
   {
      double total_range = rates[1].high - rates[1].low;
      double lower_wick  = MathMin(rates[1].open, rates[1].close) - rates[1].low;
      if(total_range > 0 && (lower_wick / total_range) >= InpMinWickRejection)
      {
         signal_dir = 1; // BUY
         return true;
      }
   }

   // Sweep of Asian High (Bearish Judas Sweep)
   if(rates[1].high > a_high && (rates[1].high - a_high) / point >= InpMinSweepPoints && rates[1].close < a_high)
   {
      double total_range = rates[1].high - rates[1].low;
      double upper_wick  = rates[1].high - MathMax(rates[1].open, rates[1].close);
      if(total_range > 0 && (upper_wick / total_range) >= InpMinWickRejection)
      {
         signal_dir = -1; // SELL
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 4: Master Confluence Daily Sniper (Multi-Signal Fusion)    |
//| Requires >= 2 aligned signals for maximum win rate & PF          |
//+------------------------------------------------------------------+
bool CheckMasterAllConfluence(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   int buy_votes = 0;
   int sell_votes = 0;

   int d0 = 0, d1 = 0, d2 = 0, d3 = 0;

   if(CheckTrendlineLiquidityTrap(rates, total, ema_val, d0))
   {
      if(d0 > 0) buy_votes += 2; else if(d0 < 0) sell_votes += 2;
   }
   if(CheckSMCInducementOrderBlock(rates, total, ema_val, d1))
   {
      if(d1 > 0) buy_votes++; else if(d1 < 0) sell_votes++;
   }
   if(CheckFreshSDBaseFlip(rates, total, ema_val, d2))
   {
      if(d2 > 0) buy_votes++; else if(d2 < 0) sell_votes++;
   }
   if(CheckAsianSweepContinuation(rates, total, ema_val, d3))
   {
      if(d3 > 0) buy_votes++; else if(d3 < 0) sell_votes++;
   }

   if(buy_votes >= 2 && buy_votes > sell_votes)
   {
      signal_dir = 1;
      return true;
   }
   if(sell_votes >= 2 && sell_votes > buy_votes)
   {
      signal_dir = -1;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Core Signal Dispatcher                                           |
//+------------------------------------------------------------------+
bool EvaluateDailySignal(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;

   switch(InpCoreModel)
   {
      case MODEL_TRENDLINE_LIQUIDITY_TRAP:
         return CheckTrendlineLiquidityTrap(rates, total, ema_val, signal_dir);

      case MODEL_SMC_INDUCEMENT_ORDERBLOCK:
         return CheckSMCInducementOrderBlock(rates, total, ema_val, signal_dir);

      case MODEL_FRESH_SD_BASE_FLIP:
         return CheckFreshSDBaseFlip(rates, total, ema_val, signal_dir);

      case MODEL_ASIAN_SWEEP_CONTINUATION:
         return CheckAsianSweepContinuation(rates, total, ema_val, signal_dir);

      case MODEL_MASTER_ALL_CONFLUENCE:
      default:
         return CheckMasterAllConfluence(rates, total, ema_val, signal_dir);
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Behavioral Engine: Manage Ladder, Partials, BE Shield & Cashouts
   ExtEngine.ManageLadderAndBreakeven();
   ExtEngine.CheckPyramiding();
   ExtEngine.UpdateHUD();

   // 2. Check for New Bar
   datetime cur_bar = iTime(_Symbol, _Period, 0);
   if(cur_bar == g_last_bar_time) return;
   g_last_bar_time = cur_bar;

   // 3. Time between consecutive entries (cooldown)
   if(TimeCurrent() - g_last_trade_time < PeriodSeconds(_Period) * 2) return;

   // 4. Session Filter Guard
   if(!IsInActiveSession()) return;

   // 5. Retrieve Market Rates & Indicators
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 0, 50, rates);
   if(copied < 40) return;

   double ema_buf[];
   ArraySetAsSeries(ema_buf, true);
   if(CopyBuffer(hEMA, 0, 0, 3, ema_buf) < 2) return;
   double ema_val = ema_buf[1];

   // 6. Check Opposing Dump & Flip
   ExtEngine.CheckOpposingDumpAndFlip(rates);

   // 7. Check Volume Climax Absorption
   ExtEngine.CheckVolumeClimaxFade(rates, copied);

   // 8. If basket already open, let the behavioral manager run
   int primary_open = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(ExtPos.SelectByIndex(i))
      {
         if(ExtPos.Magic() == InpMagicNumber && ExtPos.Symbol() == _Symbol) primary_open++;
      }
   }
   if(primary_open > 0) return;

   // 9. Evaluate SMC Daily Setup
   int signal_dir = 0;
   if(EvaluateDailySignal(rates, copied, ema_val, signal_dir))
   {
      ENUM_ORDER_TYPE otype = (signal_dir > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double entryPrice = (otype == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

      Print("🎯 SMC DAILY SNIPER SIGNAL DETECTED: ", (signal_dir > 0 ? "BUY" : "SELL"), " @ ", entryPrice);
      if(ExtEngine.ExecuteSpamBasket(otype, entryPrice, InpBaseStopLossPoints))
      {
         g_last_trade_time = TimeCurrent();
      }
   }
}
//+------------------------------------------------------------------+
