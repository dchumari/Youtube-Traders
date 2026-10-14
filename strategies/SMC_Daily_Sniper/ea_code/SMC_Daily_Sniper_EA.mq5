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
   MODEL_ICT_OTE_SD_GOLDEN_ZONE     = 4, // 4: 24/5 ICT OTE 70.5% Golden Pocket nested in S&D Base
   MODEL_DANIAL_QUASIMODO           = 5, // 5: Ahmad Danial Quasimodo (QML) Left Shoulder Invalidation
   MODEL_TRADER_YUSH_VALUE_AREA     = 6, // 6: Trader Yush 70% Value Area & Delta Absorption
   MODEL_MATTEO_BANK_ORB            = 7, // 7: Matteo Conti Bank Opening Range Breakout (ORB 30m)
   MODEL_MASTER_ALL_CONFLUENCE      = 8, // 8: Master Institutional Confluence Suite (Autonomous Fusion)
   MODEL_HYBRID_QUASIMODO_ORB       = 9  // 9: Dual Champion Hybrid (Quasimodo Left Shoulder + Matteo Bank ORB)
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
input bool                       InpInvertExecution   = false;                        // Invert Direction (Fade: Buy->Sell, Sell->Buy)
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
input bool      InpEnableVolumeClimaxFade = false;   // Enable Volume Climax Absorption Fade (Default false to prevent false chop entries)

sinput string   sep5 = "================ SESSION & TIMING FILTERS ==============";
input bool      InpUseSessionFilter     = true;      // Enable London / NY Killzone Focus
input int       InpLondonStartHour      = 7;         // London Open Start (07:00 UTC)
input int       InpLondonEndHour        = 11;        // London Open End (11:00 UTC)
input int       InpNYStartHour          = 12;        // New York Open Start (12:00 UTC)
input int       InpNYEndHour            = 18;        // New York Open End (18:00 UTC)
input int       InpGMTOffset            = 3;         // Broker GMT Offset

sinput string   sep6 = "================ DAILY TRADE & FREQUENCY CONTROLS ======";
input int       InpMaxDailyTrades       = 2;         // Maximum Setups Allowed Per Day (1 to 2 Target)
input int       InpMinTradeCooldownMin  = 90;        // Minimum Minutes Between Consecutive Entries

sinput string   sep6b = "================ DAILY DOUBLING & TARGET LOCKOUT ======";
input bool      InpEnableDailyDoubleLockout = false; // Halt trading for the day once account doubles (+100%)
input double    InpDailyTargetPct       = 100.0;     // Daily Target Return % to lock in (+100% = doubling)
input double    InpMinATRPoints         = 0.0;       // Minimum ATR points to trade (filters out low-vol chop)

sinput string   sep6c = "================ WEEKLY CAPITAL RETENTION SHIELD ====";
input bool      InpEnableWeeklyTargetLockout  = false; // Halt trading for week once target is banked (Default false per user request)
input double    InpWeeklyTargetPct            = 100.0; // Weekly Profit Target % (+100.0%)
input bool      InpEnableWeeklyTrailingShield = true;  // Trailing Weekly Equity Shield (protects 70% of peak weekly gains)
input double    InpWeeklyMaxGivebackPct       = 35.0;  // Max giveback allowed from weekly peak profit (35%)

sinput string   sep6d = "================ SETUP EXPIRATION & INVALIDATION ====";
input int       InpMaxHoldingBars             = 8;     // Max M15 Bars to Hold Trade if TP1 Not Hit (Stale Setup Timeout)
input bool      InpEnableStructuralExit       = true;  // Close Position Early on Opposing Rejection Wick

sinput string   sep7 = "================ VISUAL TRADE SUITE & HUD ==============";
input bool      InpEnableVisuals        = true;      // Enable On-Chart Visual Roadmap & Boxes
input bool      InpApplyDraculaTheme    = true;      // Auto-Apply Dracula Dark Palette (#282A36)

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & STRUCTS                                         |
//+------------------------------------------------------------------+
CFlipperBehavioralEngine ExtEngine;
CTrade                   ExtTrade;
CPositionInfo            ExtPos;

int      hEMA                 = INVALID_HANDLE;
int      hATR                 = INVALID_HANDLE;
datetime g_last_bar_time      = 0;
datetime g_last_trade_time    = 0;
int      g_last_day           = -1;
int      g_last_dow           = -1;
int      g_daily_trades_count = 0;
double   g_day_start_equity   = 0.0;
bool     g_day_locked_out     = false;
double   g_week_start_equity  = 0.0;
double   g_week_peak_equity   = 0.0;
bool     g_week_locked_out    = false;

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
   cfg.enableVolumeClimaxFade= InpEnableVolumeClimaxFade;
   cfg.volumeSpikeMultiplier = InpVolumeSurgeMult;
   cfg.enableFlipMilestone   = false;
   cfg.targetEquity          = 10000.0;
   cfg.enableVisuals         = InpEnableVisuals;
   cfg.applyDraculaTheme     = InpApplyDraculaTheme;
   cfg.maxHoldingBars        = InpMaxHoldingBars;
   cfg.enableStructuralExit  = InpEnableStructuralExit;

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
//| MODEL 4: 24/5 ICT Optimal Trade Entry (OTE 70.5% Golden Pocket)  |
//| Retraces 61.8% to 78.6% of session impulse into fresh S&D base   |
//+------------------------------------------------------------------+
bool CheckICTOptimalTradeEntry(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   if(total < 25) return false;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Find recent impulse leg (bars 2 to 20)
   double legHigh = 0.0, legLow = 999999.0;
   int hIdx = -1, lIdx = -1;
   for(int i = 2; i <= 20; i++)
   {
      if(rates[i].high > legHigh) { legHigh = rates[i].high; hIdx = i; }
      if(rates[i].low < legLow)   { legLow  = rates[i].low;  lIdx = i; }
   }

   if((legHigh - legLow) < 80 * point) return false;

   // Bullish OTE: Swing Low formed BEFORE Swing High (Impulse is Upward)
   if(lIdx > hIdx)
   {
      double fib618 = legHigh - (0.618 * (legHigh - legLow));
      double fib786 = legHigh - (0.786 * (legHigh - legLow));

      // Bar 1 enters the 61.8% - 78.6% golden pocket with a lower rejection wick
      if(rates[1].low <= fib618 && rates[1].close >= fib786)
      {
         double total_range = rates[1].high - rates[1].low;
         double lower_wick  = MathMin(rates[1].open, rates[1].close) - rates[1].low;
         if(total_range > 0 && (lower_wick / total_range) >= InpMinWickRejection)
         {
            if(rates[1].close > ema_val) // Aligned with macro EMA 50
            {
               signal_dir = 1; // BUY
               return true;
            }
         }
      }
   }
   // Bearish OTE: Swing High formed BEFORE Swing Low (Impulse is Downward)
   else if(hIdx > lIdx)
   {
      double fib618 = legLow + (0.618 * (legHigh - legLow));
      double fib786 = legLow + (0.786 * (legHigh - legLow));

      if(rates[1].high >= fib618 && rates[1].close <= fib786)
      {
         double total_range = rates[1].high - rates[1].low;
         double upper_wick  = rates[1].high - MathMax(rates[1].open, rates[1].close);
         if(total_range > 0 && (upper_wick / total_range) >= InpMinWickRejection)
         {
            if(rates[1].close < ema_val)
            {
               signal_dir = -1; // SELL
               return true;
            }
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 5: Ahmad Danial Quasimodo (QML) Left Shoulder Invalidation |
//+------------------------------------------------------------------+
bool CheckDanialQuasimodo(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   if(total < 35) return false;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int head_limit = 28;
   int ls_limit   = 34;

   // Bearish QM: Left Shoulder High -> Interim Low -> Head (Higher High) -> BOS (Lower Low)
   int idx_head = -1;
   double max_high = 0.0;
   for(int i = 4; i < head_limit; i++)
   {
      if(rates[i].high > max_high)
      {
         max_high = rates[i].high;
         idx_head = i;
      }
   }

   int idx_ls = -1;
   double ls_high = 0.0;
   for(int i = idx_head + 2; i < ls_limit; i++)
   {
      if(rates[i].high > ls_high && rates[i].high < max_high - (80 * point))
      {
         ls_high = rates[i].high;
         idx_ls = i;
      }
   }

   if(idx_head > 0 && idx_ls > idx_head)
   {
      // Pre-Trade Setup Invalidation Check:
      // If ANY bar between the Head (idx_head) and Bar 1 traded above max_high, the Head (SL) was violated!
      // This proves the setup was NEVER respected and is completely INVALID!
      for(int i = 1; i < idx_head; i++)
      {
         if(rates[i].high > max_high) return false;
      }

      double interim_low = 999999.0;
      for(int i = idx_head; i <= idx_ls; i++)
         if(rates[i].low < interim_low) interim_low = rates[i].low;

      double lowest_after_head = 999999.0;
      for(int i = 1; i < idx_head; i++)
         if(rates[i].low < lowest_after_head) lowest_after_head = rates[i].low;

      if(lowest_after_head < interim_low - (50 * point))
      {
         double diff = MathAbs(rates[1].close - ls_high) / point;
         if(diff <= 150 && rates[1].close <= max_high)
         {
            double tot_range = rates[1].high - rates[1].low;
            double upper_wick = rates[1].high - MathMax(rates[1].open, rates[1].close);
            if(tot_range > 0 && (upper_wick / tot_range) >= InpMinWickRejection)
            {
               signal_dir = -1;
               return true;
            }
         }
      }
   }

   // Bullish QM: Left Shoulder Low -> Interim High -> Head (Lower Low) -> BOS (Higher High)
   int idx_head_l = -1;
   double min_low = 999999.0;
   for(int i = 4; i < head_limit; i++)
   {
      if(rates[i].low < min_low)
      {
         min_low = rates[i].low;
         idx_head_l = i;
      }
   }

   int idx_ls_l = -1;
   double ls_low = 999999.0;
   for(int i = idx_head_l + 2; i < ls_limit; i++)
   {
      if(rates[i].low < ls_low && rates[i].low > min_low + (80 * point))
      {
         ls_low = rates[i].low;
         idx_ls_l = i;
      }
   }

   if(idx_head_l > 0 && idx_ls_l > idx_head_l)
   {
      // Pre-Trade Setup Invalidation Check:
      // If ANY bar between the Head (idx_head_l) and Bar 1 traded below min_low, the Head (SL) was violated!
      // This proves the setup was NEVER respected and is completely INVALID!
      for(int i = 1; i < idx_head_l; i++)
      {
         if(rates[i].low < min_low) return false;
      }

      double interim_high = 0.0;
      for(int i = idx_head_l; i <= idx_ls_l; i++)
         if(rates[i].high > interim_high) interim_high = rates[i].high;

      double highest_after_head = 0.0;
      for(int i = 1; i < idx_head_l; i++)
         if(rates[i].high > highest_after_head) highest_after_head = rates[i].high;

      if(highest_after_head > interim_high + (50 * point))
      {
         double diff = MathAbs(rates[1].close - ls_low) / point;
         if(diff <= 150 && rates[1].close >= min_low)
         {
            double tot_range = rates[1].high - rates[1].low;
            double lower_wick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
            if(tot_range > 0 && (lower_wick / tot_range) >= InpMinWickRejection)
            {
               signal_dir = 1;
               return true;
            }
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 6: Trader Yush 70% Value Area & Delta Absorption Scalper   |
//+------------------------------------------------------------------+
bool CheckTraderYushValueArea(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   if(total < 48) return false;

   double highest = rates[1].high;
   double lowest  = rates[1].low;
   for(int i = 2; i <= 48; i++)
   {
      if(rates[i].high > highest) highest = rates[i].high;
      if(rates[i].low < lowest)   lowest  = rates[i].low;
   }

   double range = highest - lowest;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(range < 60 * point) return false;

   double vah = lowest + (range * 0.85);
   double val = lowest + (range * 0.15);

   long cur_vol = rates[1].tick_volume;
   long sum_vol = 0;
   for(int i = 2; i <= 21; i++) sum_vol += rates[i].tick_volume;
   double avg_vol = (double)sum_vol / 20.0;
   bool vol_surge = (avg_vol > 0 && cur_vol >= (avg_vol * InpVolumeSurgeMult));

   double tot_range = rates[1].high - rates[1].low;
   if(tot_range <= 0) return false;

   if(rates[1].high >= vah && vol_surge)
   {
      double upper_wick = rates[1].high - MathMax(rates[1].open, rates[1].close);
      if((upper_wick / tot_range) >= InpMinWickRejection && rates[1].close < rates[1].open)
      {
         signal_dir = -1;
         return true;
      }
   }

   if(rates[1].low <= val && vol_surge)
   {
      double lower_wick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
      if((lower_wick / tot_range) >= InpMinWickRejection && rates[1].close > rates[1].open)
      {
         signal_dir = 1;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 7: Matteo Conti Bank Opening Range Breakout (ORB 30m)      |
//+------------------------------------------------------------------+
bool CheckMatteoBankORB(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.hour < InpLondonStartHour || dt.hour > 17) return false;

   datetime day_start = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   datetime orb_start = day_start + (InpLondonStartHour + InpGMTOffset) * 3600;
   datetime orb_end   = orb_start + 1800; // 30 mins

   double orb_high = 0.0, orb_low = 999999.0;
   int bars_orb = 0;
   for(int i = 0; i < total; i++)
   {
      if(rates[i].time >= orb_start && rates[i].time < orb_end)
      {
         if(rates[i].high > orb_high) orb_high = rates[i].high;
         if(rates[i].low < orb_low)   orb_low  = rates[i].low;
         bars_orb++;
      }
   }

   if(bars_orb < 2 || orb_high <= 0.0 || orb_low >= 999999.0) return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double orb_range = orb_high - orb_low;
   if(orb_range < 50 * point) return false;

   if(rates[1].close > orb_high && rates[2].close <= orb_high && rates[1].close > ema_val)
   {
      signal_dir = 1;
      return true;
   }

   if(rates[1].close < orb_low && rates[2].close >= orb_low && rates[1].close < ema_val)
   {
      signal_dir = -1;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 8: Master Confluence Daily Sniper (Multi-Signal Fusion)    |
//| Requires >= 3 weighted aligned signals for elite win rate & PF   |
//| Champion models (Quasimodo, Inducement) carry 3 votes;          |
//| Weak models carry 1 vote and can never trigger trades alone.     |
//+------------------------------------------------------------------+
bool CheckMasterAllConfluence(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   int buy_votes = 0;
   int sell_votes = 0;

   int d0 = 0, d1 = 0, d2 = 0, d3 = 0, d4 = 0, d5 = 0, d6 = 0, d7 = 0;

   // 1. Champion Model: Ahmad Danial Quasimodo (3 votes - High-conviction structural reversal)
   if(CheckDanialQuasimodo(rates, total, ema_val, d5))
   {
      if(d5 > 0) buy_votes += 3; else if(d5 < 0) sell_votes += 3;
   }
   // 2. Champion Model: SMC Inducement & Order Block (3 votes - Proven high PF in RW2 & RW3)
   if(CheckSMCInducementOrderBlock(rates, total, ema_val, d1))
   {
      if(d1 > 0) buy_votes += 3; else if(d1 < 0) sell_votes += 3;
   }
   // 3. Momentum Model: Matteo Bank ORB (2 votes - Dominates London open expansion)
   if(CheckMatteoBankORB(rates, total, ema_val, d7))
   {
      if(d7 > 0) buy_votes += 2; else if(d7 < 0) sell_votes += 2;
   }
   // 4. Volume Profile Model: Trader Yush Value Area (2 votes - High PF in RW1 & RW2)
   if(CheckTraderYushValueArea(rates, total, ema_val, d6))
   {
      if(d6 > 0) buy_votes += 2; else if(d6 < 0) sell_votes += 2;
   }
   // 5. Confluence Filters: Asian Sweep, S&D Base, Trendline, OTE (1 vote each - cannot fire alone)
   if(CheckAsianSweepContinuation(rates, total, ema_val, d3))
   {
      if(d3 > 0) buy_votes += 1; else if(d3 < 0) sell_votes += 1;
   }
   if(CheckFreshSDBaseFlip(rates, total, ema_val, d2))
   {
      if(d2 > 0) buy_votes += 1; else if(d2 < 0) sell_votes += 1;
   }
   if(CheckTrendlineLiquidityTrap(rates, total, ema_val, d0))
   {
      if(d0 > 0) buy_votes += 1; else if(d0 < 0) sell_votes += 1;
   }
   if(CheckICTOptimalTradeEntry(rates, total, ema_val, d4))
   {
      if(d4 > 0) buy_votes += 1; else if(d4 < 0) sell_votes += 1;
   }

   // Minimum 3 votes required (prevents toxic standalone signals)
   if(buy_votes >= 3 && buy_votes > sell_votes)
   {
      signal_dir = 1;
      return true;
   }
   if(sell_votes >= 3 && sell_votes > buy_votes)
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

      case MODEL_ICT_OTE_SD_GOLDEN_ZONE:
         return CheckICTOptimalTradeEntry(rates, total, ema_val, signal_dir);

      case MODEL_DANIAL_QUASIMODO:
         return CheckDanialQuasimodo(rates, total, ema_val, signal_dir);

      case MODEL_TRADER_YUSH_VALUE_AREA:
         return CheckTraderYushValueArea(rates, total, ema_val, signal_dir);

      case MODEL_MATTEO_BANK_ORB:
         return CheckMatteoBankORB(rates, total, ema_val, signal_dir);

      case MODEL_HYBRID_QUASIMODO_ORB:
         if(CheckDanialQuasimodo(rates, total, ema_val, signal_dir)) return true;
         if(CheckMatteoBankORB(rates, total, ema_val, signal_dir))   return true;
         return false;

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

   // 2. Weekly & Daily Capital Retention Shield (Checked on every tick!)
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(g_week_start_equity <= 0.0)
   {
      g_week_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_week_peak_equity  = g_week_start_equity;
   }
   if(g_day_start_equity <= 0.0)
   {
      g_day_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   }

   // Monday Weekly Reset
   if(dt.day_of_week == 1 && g_last_dow != 1)
   {
      g_week_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_week_peak_equity  = g_week_start_equity;
      g_week_locked_out   = false;
   }
   g_last_dow = dt.day_of_week;

   double cur_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(cur_equity > g_week_peak_equity) g_week_peak_equity = cur_equity;

   // 3a. Weekly Target Lockout (+50% or +100%)
   if(InpEnableWeeklyTargetLockout && !g_week_locked_out)
   {
      if(g_week_start_equity > 0 && cur_equity >= g_week_start_equity * (1.0 + (InpWeeklyTargetPct / 100.0)))
      {
         Print("🏆 WEEKLY PROFIT TARGET ACHIEVED (+", InpWeeklyTargetPct, "%)! Net Equity: $", cur_equity, ". Locking weekly win!");
         ExtEngine.CloseAllPositions();
         g_week_locked_out = true;
         return;
      }
   }

   // 3b. Weekly Trailing Equity Shield (protects 70% of peak weekly gains once up >= +35%)
   if(InpEnableWeeklyTrailingShield && !g_week_locked_out)
   {
      double max_profit = g_week_peak_equity - g_week_start_equity;
      if(max_profit >= (g_week_start_equity * 0.35))
      {
         double min_allowed_equity = g_week_start_equity + (max_profit * (1.0 - (InpWeeklyMaxGivebackPct / 100.0)));
         if(cur_equity <= min_allowed_equity)
         {
            Print("🛡️ WEEKLY TRAILING SHIELD TRIGGERED! Preserving locked profit at $", cur_equity, ". Halting for rest of week!");
            ExtEngine.CloseAllPositions();
            g_week_locked_out = true;
            return;
         }
      }
   }

   if(g_week_locked_out) return;

   // 3c. Daily Reset & Limit
   if(dt.day != g_last_day)
   {
      g_last_day = dt.day;
      g_daily_trades_count = 0;
      g_day_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_day_locked_out = false;
   }

   // 3d. Daily Doubling Milestone Check (+100% in 1 day / 1 trade)
   if(InpEnableDailyDoubleLockout && !g_day_locked_out)
   {
      if(g_day_start_equity > 0 && cur_equity >= g_day_start_equity * (1.0 + (InpDailyTargetPct / 100.0)))
      {
         Print("🎯 DAILY DOUBLING TARGET ACHIEVED (+", InpDailyTargetPct, "%)! Closing basket & locking profits for today!");
         ExtEngine.CloseAllPositions();
         g_day_locked_out = true;
         return;
      }
   }
   if(g_day_locked_out) return;

   // 4. Check for New Bar for new entry evaluation
   datetime cur_bar = iTime(_Symbol, _Period, 0);
   if(cur_bar == g_last_bar_time) return;
   g_last_bar_time = cur_bar;

   if(g_daily_trades_count >= InpMaxDailyTrades) return;

   // 5. Time between consecutive entries (cooldown in minutes)
   if(TimeCurrent() - g_last_trade_time < InpMinTradeCooldownMin * 60) return;

   // 5b. Low Volatility Chop Filter (Skip dead consolidation)
   if(InpMinATRPoints > 0)
   {
      double atr_buf[];
      ArraySetAsSeries(atr_buf, true);
      if(CopyBuffer(hATR, 0, 0, 2, atr_buf) >= 1)
      {
         double cur_atr_pts = atr_buf[1] / SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         if(cur_atr_pts < InpMinATRPoints) return;
      }
   }

   // 5. Session Filter Guard
   if(!IsInActiveSession()) return;

   // 6. Retrieve Market Rates & Indicators
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 0, 65, rates);
   if(copied < 45) return;

   double ema_buf[];
   ArraySetAsSeries(ema_buf, true);
   if(CopyBuffer(hEMA, 0, 0, 3, ema_buf) < 2) return;
   double ema_val = ema_buf[1];

   // 7. Check Opposing Dump & Flip
   if(InpEnableDumpAndFlip) ExtEngine.CheckOpposingDumpAndFlip(rates);

   // 8. Check Volume Climax Absorption (Guarded by Session, Daily Limits & Cooldown)
   if(InpEnableVolumeClimaxFade && IsInActiveSession() && g_daily_trades_count < InpMaxDailyTrades && (TimeCurrent() - g_last_trade_time >= InpMinTradeCooldownMin * 60))
   {
      int before_count = PositionsTotal();
      ExtEngine.CheckVolumeClimaxFade(rates, copied);
      if(PositionsTotal() > before_count)
      {
         g_last_trade_time = TimeCurrent();
         g_daily_trades_count++;
      }
   }

   // 9. If basket already open, let the behavioral manager run
   int primary_open = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(ExtPos.SelectByIndex(i))
      {
         if(ExtPos.Magic() == InpMagicNumber && ExtPos.Symbol() == _Symbol) primary_open++;
      }
   }
   if(primary_open > 0) return;

   // 10. Evaluate SMC Daily Setup
   int signal_dir = 0;
   if(EvaluateDailySignal(rates, copied, ema_val, signal_dir))
   {
      if(InpInvertExecution) signal_dir = -signal_dir;
      ENUM_ORDER_TYPE otype = (signal_dir > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double entryPrice = (otype == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

      Print("🎯 SMC DAILY SNIPER SIGNAL DETECTED", (InpInvertExecution ? " [INVERTED FADE]" : ""), ": ", (signal_dir > 0 ? "BUY" : "SELL"), " @ ", entryPrice, " [Daily Trade: ", g_daily_trades_count + 1, "/", InpMaxDailyTrades, "]");
      if(ExtEngine.ExecuteSpamBasket(otype, entryPrice, InpBaseStopLossPoints))
      {
         g_last_trade_time = TimeCurrent();
         g_daily_trades_count++;
      }
   }
}
//+------------------------------------------------------------------+
