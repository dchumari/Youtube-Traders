//+------------------------------------------------------------------+
//|                                     SMC_Inverted_Momentum_EA.mq5 |
//|           Institutional Inverted SMC Momentum & Trap Fade Suite  |
//|    Fades Failed Retail SMC Reversals into Trend Breakout Expansion|
//|    Features: 3-Stage TP Ladder, Dynamic Tiered Compounding,      |
//|    Displacement Confirmation & Stepped Breakeven Shield          |
//|                               Copyright 2026, Quant Research Lab |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research Lab"
#property link      "https://github.com/dchumari/Youtube-Traders"
#property version   "1.00"
#property description "SMC Inverted Momentum EA: Fades failed retail SMC reversal setups into aggressive trend expansion runners with 3-stage partial laddering and dynamic equity compounding."
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Flipper_Behavioral_Engine.mqh>
#include <VisualTradeSuite.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                     |
//+------------------------------------------------------------------+
enum ENUM_INVERTED_SMC_MODEL
{
   INV_MODEL_TRENDLINE_BREAKOUT     = 0, // 0: Trendline Trap Fade (Breakdown/Breakout Liquidation Run)
   INV_MODEL_INDUCEMENT_EXPANSION   = 1, // 1: SMC Inducement (IDM) Breach (Extreme OB Invalidation)
   INV_MODEL_FRESH_SD_FLIP_RUN      = 2, // 2: S&D Flip Momentum Continuation
   INV_MODEL_ASIAN_BREAKOUT         = 3, // 3: Daily Asian Range Direct Expansion Run
   INV_MODEL_ICT_OTE_VIOLATION      = 4, // 4: 24/5 ICT OTE 70.5% Golden Corridor Violation
   INV_MODEL_QUASIMODO_SQUEEZE      = 5, // 5: Ahmad Danial QML Invalidation Squeeze (Reversal Trap)
   INV_MODEL_VALUE_AREA_EXPANSION   = 6, // 6: Trader Yush 70% Value Area Range Rejection Fade
   INV_MODEL_MATTEO_BANK_ORB        = 7, // 7: Matteo Conti Bank Opening Range Breakout (ORB 30m)
   INV_MODEL_MASTER_ALL_CONFLUENCE  = 8, // 8: Master Institutional Trap Confluence
   INV_MODEL_HYBRID_QUASIMODO_ORB   = 9  // 9: Dual Champion Inverted Hybrid (QML Squeeze + Bank ORB)
};

enum ENUM_INVERTED_HORIZON
{
   INV_HORIZON_DAILY_SPRINT_DOUBLER = 0, // Daily/Weekly Sprint (>= 100% ROI, Aggressive Compounding)
   INV_HORIZON_MONTHLY_CONSISTENCY  = 1, // Monthly Consistency (>= 100% ROI, Balanced Compounding)
   INV_HORIZON_SWING_ENDURANCE      = 2  // Multi-Month Endurance (Conservative Risk Guard)
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
sinput string   sep0 = "================ STRATEGY & HORIZON MODE ================";
input ENUM_INVERTED_SMC_MODEL    InpCoreModel         = INV_MODEL_HYBRID_QUASIMODO_ORB; // Core Execution Model
input ENUM_INVERTED_HORIZON      InpHorizonMode       = INV_HORIZON_DAILY_SPRINT_DOUBLER; // Target Horizon Tier
input ulong                      InpMagicNumber       = 889300;                       // EA Magic Number

sinput string   sep1 = "================ CAPITAL & TIERED COMPOUNDING ==========";
input bool      InpEnableDynamicTiering = true;       // Enable Dynamic Equity Compounding (Doubling Lot by Tier)
input double    InpBaseLotSize          = 0.01;      // Base Lot Size per Micro-Ticket
input double    InpEquityTierStep       = 20.0;      // Equity Step to Double/Scale Lot ($20 for $20 Tier, $50 for $100 Tier)
input double    InpMaxLotCap            = 0.20;      // Maximum Lot Cap per Micro-Ticket
input int       InpBaseStopLossPoints   = 200;       // Base Stop Loss in Points (20 pips on Gold - old TP distance)

sinput string   sep2 = "================ 3-STAGE TAKE-PROFIT LADDER =============";
input int       InpSpamTicketsCount     = 3;         // Micro-Tickets per Entry Basket (3-Stage Harvesting)
input int       InpTP1Points            = 200;       // TP1 (+20 pips: Harvest Ticket 1 at Old Retail SL Level)
input int       InpTP2Points            = 400;       // TP2 (+40 pips: Harvest Ticket 2 + Lock Breakeven Shield)
input int       InpTP3Points            = 700;       // TP3 (+70 pips: Moonshot Runner Harvest)
input int       InpTP4Points            = 1200;      // TP4 (+120 pips: Extended Trend Runner)
input int       InpTP5Points            = 1800;      // TP5 (+180 pips: Super Trend Runner)

sinput string   sep3 = "================ MARGIN PYRAMIDING & CONTROLS ==========";
input bool      InpEnablePyramiding     = false;     // Enable Floating Equity Pyramiding
input int       InpMaxPyramidLayers     = 1;         // Maximum Pyramid Layers
input int       InpReloadStepPoints     = 300;       // Distance to Fire Next Layer (+30 pips)
input bool      InpEnableDumpAndFlip    = false;     // Opposing Exhaustion Dump & Flip
input double    InpDumpWickRatio        = 0.45;      // Opposing Rejection Wick Ratio to Wipe Basket

sinput string   sep4 = "================ MOMENTUM CONFIRMATION & FILTERS ========";
input bool      InpRequireDisplacement  = true;      // Require Momentum Displacement Candle (Filters Out Chop)
input double    InpMinDisplacementPct   = 0.40;      // Minimum Candle Body Ratio (40% of range)
input int       InpSwingLookback        = 24;        // Swing High/Low Lookback Window
input int       InpTrendlinePoints      = 3;         // Touches to Validate Trendline
input int       InpMinSweepPoints       = 100;       // Minimum Liquidity Sweep (10 pips)
input double    InpMinWickRejection     = 0.35;      // Minimum Rejection Wick Ratio (35%)
input int       InpEMATrendPeriod       = 50;        // Baseline Structural EMA Period
input double    InpVolumeSurgeMult      = 1.5;       // Volume Surge Multiplier
input double    InpMinATRPoints         = 100.0;     // Minimum ATR Points (Filters Out Dead Consolidation)

sinput string   sep5 = "================ SESSION & TIMING FILTERS ==============";
input bool      InpUseSessionFilter     = true;      // Enable London / NY Killzone Focus
input int       InpLondonStartHour      = 7;         // London Open Start (07:00 UTC)
input int       InpLondonEndHour        = 11;        // London Open End (11:00 UTC)
input int       InpNYStartHour          = 12;        // New York Open Start (12:00 UTC)
input int       InpNYEndHour            = 18;        // New York Open End (18:00 UTC)
input int       InpGMTOffset            = 3;         // Broker GMT Offset

sinput string   sep6 = "================ DAILY & WEEKLY TARGET CONTROLS ========";
input int       InpMaxDailyTrades       = 2;         // Maximum Setups Allowed Per Day (1 to 2 Target)
input int       InpMinTradeCooldownMin  = 90;        // Minimum Minutes Between Consecutive Entries
input bool      InpEnableDailyDoubleLockout = true;  // Halt trading for day once daily doubling target is banked
input double    InpDailyTargetPct       = 100.0;     // Daily Target Return % to lock in (+100% = doubling)
input bool      InpEnableWeeklyTargetLockout  = false;// Halt trading for week once target is banked (Uncapped)
input double    InpWeeklyTargetPct            = 100.0;// Weekly Profit Target %
input bool      InpEnableWeeklyTrailingShield = true; // Trailing Weekly Equity Shield (protects 65% of peak weekly gains)
input double    InpWeeklyMaxGivebackPct       = 35.0; // Max giveback allowed from weekly peak profit (35%)
input int       InpMaxHoldingBars             = 8;    // Max M15 Bars to Hold Trade if TP1 Not Hit (Stale Setup Timeout)
input bool      InpEnableStructuralExit       = true; // Close Position Early on Opposing Rejection Wick

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

struct SMarketSwing
{
   double   price;
   datetime time;
   int      bar_idx;
   bool     is_high;
};

//+------------------------------------------------------------------+
//| Dynamic Tiered Lot Sizing Calculator                             |
//+------------------------------------------------------------------+
double GetDynamicLotPerTicket()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double lot = InpBaseLotSize;

   if(InpEnableDynamicTiering && InpEquityTierStep > 0.0)
   {
      int tier = (int)MathFloor(equity / InpEquityTierStep);
      if(tier < 1) tier = 1;
      lot = tier * InpBaseLotSize;
   }

   double step_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot  = MathMin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), InpMaxLotCap);

   if(step_lot > 0)
      lot = MathFloor(lot / step_lot) * step_lot;

   if(lot < min_lot) lot = min_lot;
   if(lot > max_lot) lot = max_lot;

   return NormalizeDouble(lot, 2);
}

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
   cfg.prefix                = "INV_";
   cfg.spamTicketsCount      = InpSpamTicketsCount;
   cfg.tp1Points             = InpTP1Points;
   cfg.tp2Points             = InpTP2Points;
   cfg.tp3Points             = InpTP3Points;
   cfg.tp4Points             = InpTP4Points;
   cfg.tp5Points             = InpTP5Points;
   cfg.stopLossPoints        = InpBaseStopLossPoints;

   cfg.equityPerMinLot       = InpEquityTierStep;
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
   cfg.enableVolumeClimaxFade= false;
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

   Print("✅ SMC Inverted Momentum EA initialized successfully. Model: ", EnumToString(InpCoreModel));
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
//| Helper: Confirm Momentum Displacement (Filters Out Range Chop)    |
//+------------------------------------------------------------------+
bool ConfirmMomentumDisplacement(const MqlRates &rates[], int signal_dir, double ema_val)
{
   if(!InpRequireDisplacement) return true;

   double tot_range = rates[1].high - rates[1].low;
   if(tot_range <= 0) return false;

   double body = MathAbs(rates[1].close - rates[1].open);
   double body_ratio = body / tot_range;

   if(signal_dir > 0) // Inverted BUY: must have bullish momentum AND be above EMA
   {
      bool is_bullish = (rates[1].close > rates[1].open);
      bool good_body  = (body_ratio >= InpMinDisplacementPct);
      bool over_ema   = (rates[1].close > ema_val);
      return (is_bullish && good_body && over_ema);
   }
   else if(signal_dir < 0) // Inverted SELL: must have bearish momentum AND be below EMA
   {
      bool is_bearish = (rates[1].close < rates[1].open);
      bool good_body  = (body_ratio >= InpMinDisplacementPct);
      bool under_ema  = (rates[1].close < ema_val);
      return (is_bearish && good_body && under_ema);
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 0: Trendline Trap Fade                                     |
//+------------------------------------------------------------------+
bool CheckTrendlineTrapFade(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   if(total < 30) return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   SMarketSwing swings[];
   int count = 0;
   if(!GetSwingPoints(rates, total, swings, count)) return false;

   // 1. Ascending Trendline Breakdown: Retail buyers trapped -> We SELL!
   int low_swings[2];
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
      double p1 = swings[low_swings[1]].price;
      double p2 = swings[low_swings[0]].price;
      int b1    = swings[low_swings[1]].bar_idx;
      int b2    = swings[low_swings[0]].bar_idx;

      if(b1 > b2 && p2 >= p1 && (b1 - b2) > 0)
      {
         double projected_tl = p2 + ((p2 - p1) / (double)(b2 - b1)) * (1.0 - (double)b2);
         // Decisive breakdown below trendline: Bar 1 closes BELOW trendline!
         if(rates[1].close < projected_tl && rates[1].open >= projected_tl)
         {
            signal_dir = -1; // Inverted SELL
            return true;
         }
      }
   }

   // 2. Descending Trendline Breakout: Retail sellers trapped -> We BUY!
   int high_swings[2];
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
      double p1 = swings[high_swings[1]].price;
      double p2 = swings[high_swings[0]].price;
      int b1    = swings[high_swings[1]].bar_idx;
      int b2    = swings[high_swings[0]].bar_idx;

      if(b1 > b2 && p2 <= p1 && (b1 - b2) > 0)
      {
         double projected_tl = p2 + ((p2 - p1) / (double)(b2 - b1)) * (1.0 - (double)b2);
         // Decisive breakout above trendline: Bar 1 closes ABOVE trendline!
         if(rates[1].close > projected_tl && rates[1].open <= projected_tl)
         {
            signal_dir = 1; // Inverted BUY
            return true;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 1: SMC Inducement Violation & Extreme OB Breach            |
//+------------------------------------------------------------------+
bool CheckSMCInducementViolation(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   if(total < 35) return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   SMarketSwing swings[];
   int count = 0;
   if(!GetSwingPoints(rates, total, swings, count)) return false;

   for(int i = 0; i < count - 1; i++)
   {
      // Bearish OB Violation: Price blows above the high -> SELLERS TRAPPED, We BUY!
      if(swings[i].is_high)
      {
         double ob_high = swings[i].price;
         int ob_bar     = swings[i].bar_idx;

         if(ob_bar >= 4 && ob_bar <= 25)
         {
            if(rates[1].close > ob_high && rates[2].close <= ob_high)
            {
               signal_dir = 1; // Inverted BUY
               return true;
            }
         }
      }
      // Bullish OB Violation: Price blows below the low -> BUYERS TRAPPED, We SELL!
      else if(!swings[i].is_high)
      {
         double ob_low = swings[i].price;
         int ob_bar    = swings[i].bar_idx;

         if(ob_bar >= 4 && ob_bar <= 25)
         {
            if(rates[1].close < ob_low && rates[2].close >= ob_low)
            {
               signal_dir = -1; // Inverted SELL
               return true;
            }
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| MODEL 5: Ahmad Danial Quasimodo Invalidation Squeeze             |
//+------------------------------------------------------------------+
bool CheckDanialQuasimodoSqueeze(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;
   if(total < 40) return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int head_limit = (InpSwingLookback > 28) ? InpSwingLookback : 36;
   int ls_limit   = head_limit + 16;

   // 1. Bearish QM Invalidation (Failed Top Reversal -> SQUEEZE BUY)
   int head_idx = 0;
   double head_high = 0;
   for(int i = 3; i < head_limit; i++)
   {
      if(rates[i].high > head_high)
      {
         head_high = rates[i].high;
         head_idx = i;
      }
   }

   if(head_idx >= 5 && head_idx < head_limit)
   {
      int ls_idx = 0;
      double ls_high = 0;
      for(int i = head_idx + 2; i < ls_limit; i++)
      {
         if(rates[i].high > ls_high)
         {
            ls_high = rates[i].high;
            ls_idx = i;
         }
      }

      if(ls_idx > head_idx && head_high > ls_high + (100 * point))
      {
         // When price blows ABOVE the Head with momentum -> Short Squeeze BUY!
         if(rates[1].close > head_high && rates[2].close <= head_high && rates[1].close > ema_val)
         {
            signal_dir = 1; // Squeeze BUY
            return true;
         }
      }
   }

   // 2. Bullish QM Invalidation (Failed Bottom Reversal -> SQUEEZE SELL)
   head_idx = 0;
   double head_low = 999999.0;
   for(int i = 3; i < head_limit; i++)
   {
      if(rates[i].low < head_low)
      {
         head_low = rates[i].low;
         head_idx = i;
      }
   }

   if(head_idx >= 5 && head_idx < head_limit)
   {
      int ls_idx = 0;
      double ls_low = 999999.0;
      for(int i = head_idx + 2; i < ls_limit; i++)
      {
         if(rates[i].low < ls_low)
         {
            ls_low = rates[i].low;
            ls_idx = i;
         }
      }

      if(ls_idx > head_idx && head_low < ls_low - (100 * point))
      {
         // When price blows BELOW the Head with momentum -> Long Liquidation SELL!
         if(rates[1].close < head_low && rates[2].close >= head_low && rates[1].close < ema_val)
         {
            signal_dir = -1; // Squeeze SELL
            return true;
         }
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
   if(total < 15) return false;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int london_open_hour = InpLondonStartHour + InpGMTOffset;
   int london_end_hour  = InpLondonEndHour + InpGMTOffset;

   // Allow breakout entries throughout the London session after the opening range has formed (10:30 to 14:00 server time)
   if(dt.hour < london_open_hour || (dt.hour == london_open_hour && dt.min < 30) || dt.hour >= london_end_hour) return false;

   double orb_high = -1.0;
   double orb_low  = 999999.0;
   int collected   = 0;

   for(int i = 1; i < total; i++)
   {
      MqlDateTime bdt;
      TimeToStruct(rates[i].time, bdt);
      if(bdt.day == dt.day && bdt.hour == london_open_hour && bdt.min < 30)
      {
         if(rates[i].high > orb_high) orb_high = rates[i].high;
         if(rates[i].low  < orb_low)  orb_low  = rates[i].low;
         collected++;
         if(collected >= 2) break;
      }
   }

   if(collected < 2 || orb_high <= 0 || orb_low >= 999999.0) return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double orb_range = (orb_high - orb_low) / point;
   if(orb_range < 50.0 || orb_range > 450.0) return false;

   // Bullish Breakout above London Opening Range
   if(rates[1].close > orb_high && (rates[2].close <= orb_high || rates[1].open <= orb_high) && rates[1].close > ema_val)
   {
      signal_dir = 1;
      return true;
   }
   // Bearish Breakdown below London Opening Range
   else if(rates[1].close < orb_low && (rates[2].close >= orb_low || rates[1].open >= orb_low) && rates[1].close < ema_val)
   {
      signal_dir = -1;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Core Signal Dispatcher                                           |
//+------------------------------------------------------------------+
bool EvaluateInvertedSignal(const MqlRates &rates[], int total, double ema_val, int &signal_dir)
{
   signal_dir = 0;

   switch(InpCoreModel)
   {
      case INV_MODEL_TRENDLINE_BREAKOUT:
         return CheckTrendlineTrapFade(rates, total, ema_val, signal_dir);

      case INV_MODEL_INDUCEMENT_EXPANSION:
         return CheckSMCInducementViolation(rates, total, ema_val, signal_dir);

      case INV_MODEL_QUASIMODO_SQUEEZE:
         return CheckDanialQuasimodoSqueeze(rates, total, ema_val, signal_dir);

      case INV_MODEL_MATTEO_BANK_ORB:
         return CheckMatteoBankORB(rates, total, ema_val, signal_dir);

      case INV_MODEL_HYBRID_QUASIMODO_ORB:
         if(CheckDanialQuasimodoSqueeze(rates, total, ema_val, signal_dir)) return true;
         if(CheckMatteoBankORB(rates, total, ema_val, signal_dir))         return true;
         return false;

      case INV_MODEL_MASTER_ALL_CONFLUENCE:
      default:
         if(CheckDanialQuasimodoSqueeze(rates, total, ema_val, signal_dir)) return true;
         if(CheckMatteoBankORB(rates, total, ema_val, signal_dir))         return true;
         if(CheckTrendlineTrapFade(rates, total, ema_val, signal_dir))     return true;
         if(CheckSMCInducementViolation(rates, total, ema_val, signal_dir)) return true;
         return false;
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Behavioral Engine: Manage 3-Stage Ladder, Partials, BE Shield
   ExtEngine.ManageLadderAndBreakeven();
   ExtEngine.CheckPyramiding();
   ExtEngine.UpdateHUD();

   // 2. Weekly & Daily Capital Retention Shield
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // 2a. Weekly Reset & Retention
   if(dt.day_of_week == 1 && g_last_dow != 1)
   {
      g_last_dow = 1;
      g_week_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_week_peak_equity  = g_week_start_equity;
      g_week_locked_out   = false;
   }
   else if(dt.day_of_week != 1)
   {
      g_last_dow = dt.day_of_week;
   }

   double cur_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(cur_equity > g_week_peak_equity) g_week_peak_equity = cur_equity;

   // Weekly Trailing Shield
   if(InpEnableWeeklyTrailingShield && !g_week_locked_out && g_week_start_equity > 0)
   {
      double peak_gain_pct = ((g_week_peak_equity - g_week_start_equity) / g_week_start_equity) * 100.0;
      if(peak_gain_pct >= 35.0)
      {
         double max_allowed_giveback = (g_week_peak_equity - g_week_start_equity) * (InpWeeklyMaxGivebackPct / 100.0);
         double floor_equity = g_week_peak_equity - max_allowed_giveback;
         if(cur_equity <= floor_equity)
         {
            Print("🛡️ WEEKLY TRAILING SHIELD HIT! Banked profits protected. Closing basket!");
            ExtEngine.CloseAllPositions();
            g_week_locked_out = true;
            return;
         }
      }
   }

   if(InpEnableWeeklyTargetLockout && !g_week_locked_out && g_week_start_equity > 0)
   {
      if(cur_equity >= g_week_start_equity * (1.0 + (InpWeeklyTargetPct / 100.0)))
      {
         Print("🎯 WEEKLY TARGET ACHIEVED (+", InpWeeklyTargetPct, "%)! Closing basket & locking for week!");
         ExtEngine.CloseAllPositions();
         g_week_locked_out = true;
         return;
      }
   }

   if(g_week_locked_out) return;

   // 2b. Daily Reset & Limit
   if(dt.day != g_last_day)
   {
      g_last_day = dt.day;
      g_daily_trades_count = 0;
      g_day_start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      g_day_locked_out = false;
   }

   // 2c. Daily Doubling Milestone Check (+100% in 1 day / 1 trade)
   if(InpEnableDailyDoubleLockout && !g_day_locked_out)
   {
      if(g_day_start_equity > 0 && cur_equity >= g_day_start_equity * (1.0 + (InpDailyTargetPct / 100.0)))
      {
         Print("🎯 DAILY DOUBLING TARGET ACHIEVED (+", InpDailyTargetPct, "%)! Closing basket & locking for today!");
         ExtEngine.CloseAllPositions();
         g_day_locked_out = true;
         return;
      }
   }
   if(g_day_locked_out) return;

   // 3. New Bar Check
   datetime cur_bar = iTime(_Symbol, _Period, 0);
   if(cur_bar == g_last_bar_time) return;
   g_last_bar_time = cur_bar;

   if(g_daily_trades_count >= InpMaxDailyTrades) return;

   // 4. Cooldown Guard
   if(TimeCurrent() - g_last_trade_time < InpMinTradeCooldownMin * 60) return;

   // 5. Volatility / ATR Filter
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

   // 6. Session Filter Guard
   if(!IsInActiveSession()) return;

   // 7. Retrieve Rates
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 0, 100, rates);
   if(copied < 55) return;

   double ema_buf[];
   ArraySetAsSeries(ema_buf, true);
   if(CopyBuffer(hEMA, 0, 0, 3, ema_buf) < 2) return;
   double ema_val = ema_buf[1];

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

   // 9. Evaluate Inverted SMC Setup
   int signal_dir = 0;
   if(EvaluateInvertedSignal(rates, copied, ema_val, signal_dir))
   {
      // Confirm Momentum Displacement
      if(!ConfirmMomentumDisplacement(rates, signal_dir, ema_val)) return;

      ENUM_ORDER_TYPE otype = (signal_dir > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double entryPrice = (otype == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ticket_lot = GetDynamicLotPerTicket();

      Print("⚡ INVERTED MOMENTUM BREAKOUT DETECTED: ", (signal_dir > 0 ? "BUY" : "SELL"), " @ ", entryPrice,
            " [Ticket Lot: ", ticket_lot, " | Daily Trade: ", g_daily_trades_count + 1, "/", InpMaxDailyTrades, "]");

      if(ExtEngine.ExecuteSpamBasket(otype, entryPrice, InpBaseStopLossPoints, ticket_lot))
      {
         g_last_trade_time = TimeCurrent();
         g_daily_trades_count++;
      }
   }
}
//+------------------------------------------------------------------+
