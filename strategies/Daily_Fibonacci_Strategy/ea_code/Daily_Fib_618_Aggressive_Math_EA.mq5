//+------------------------------------------------------------------+
//|                      Daily_Fib_618_Aggressive_Math_EA.mq5         |
//|                  Copyright 2026, Quantitative Research Lab       |
//|    Aggressive Tiered Mathematical Flow & On-Chart Fib Engine     |
//+------------------------------------------------------------------+
#property copyright "Quantitative Research Lab"
#property link      "https://trading-automations.internal"
#property version   "4.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//--- Enums
enum ENUM_TIER_COMPOUNDING
{
   TIER_FIXED_MICRO       = 0, // Fixed 0.01 Lot per Leg
   TIER_MATHEMATICAL_FLOW = 1, // Aggressive Tiered Equity Flow ($0-$25, $25-$50, $50-$100, $100+)
   TIER_STEP_EQUITY       = 2  // Dynamic Step ($X Equity per 0.01 lot)
};

enum ENUM_TARGET_MODE
{
   TARGET_FIXED_RR       = 0, // Fixed RR (Leg1 = 1:1, Leg2 = InpLeg2_RR)
   TARGET_RANGE_RATIO    = 1  // Range-Adaptive (TP1 = 50% Day Range, TP2 = 100% Day Range)
};

//--- Input Parameters
input group "=== Aggressive Mathematical Compounding ==="
input ENUM_TIER_COMPOUNDING InpSizingMode        = TIER_MATHEMATICAL_FLOW; // Position Sizing Engine
input double                InpFixedLot         = 0.01;                   // Base Lot per Leg (if Fixed)
input double                InpStepEquitySize   = 50.0;                   // Equity per 0.01 Lot (if Step mode)
input double                InpMaxLotCap        = 3.00;                   // Maximum Allowed Lot per Leg

input group "=== Risk & Golden Pocket Settings ==="
input int                   InpSLPoints         = 400;                    // Structural Stop Loss (Points from Level)
input ENUM_TARGET_MODE      InpTargetMode       = TARGET_FIXED_RR;        // Take Profit Architecture
input double                InpLeg1_RR          = 1.0;                    // Leg 1 Target (1:1 Velocity Cash-Out)
input double                InpLeg2_RR          = 2.0;                    // Leg 2 Target (2:1 Runner Target)
input int                   InpBELockPoints     = 10;                     // Profit Locked on Breakeven (Points)
input int                   InpBaseMagic        = 618900;                 // Magic Base (Uses Base+1, Base+2)

input group "=== Volatility & Range Filtering ==="
input int                   InpMinDayRangePts   = 1000;                   // Min Prior Day Range Points (1000 pts = $10)
input int                   InpEntryTolerance   = 50;                     // Entry Tolerance Around 61.8% (Points)
input int                   InpMaxSpreadPoints  = 50;                     // Max Allowed Spread (Points)
input bool                    InpTradeImmediate   = true;                   // Trade Day+1 Immediate Retests
input bool                    InpTradeVirginLevels= true;                   // Trade Unmitigated Virgin Levels
input int                     InpMaxVirginAgeDays = 30;                     // Max Virgin Level Lookback (Days)
input int                     InpMaxDailyTrades   = 2;                      // Max Trades per Day

input group "=== Session Filtering ==="
input bool                    InpUseSessionFilter = true;                   // Enable Session Filter
input int                     InpSessionStartHour = 7;                      // Start Hour (Server Time)
input int                     InpSessionEndHour   = 18;                     // End Hour (Server Time)

input group "=== Visual Chart Drawing Engine ==="
input bool                    InpDrawChartObjects = true;                   // Draw Fibonacci & Virgin Rays on Chart
input color                 InpBuyColor         = clrDodgerBlue;          // Bullish 61.8% Level Color
input color                 InpSellColor        = clrCrimson;             // Bearish 61.8% Level Color
input color                 InpVirginColor      = clrGold;                // Virgin 61.8% Level Color
input color                 InpRangeColor       = clrDimGray;             // Prior Day Range Bounds Color
input bool                    InpShowDashboard    = true;                   // Show Real-Time Mathematical HUD

//--- Level Structure
struct SFibLevel
{
   datetime day_date;
   double   price_level;
   double   day_high;
   double   day_low;
   double   day_range;
   bool     is_bullish;
   bool     is_virgin;
   bool     is_mitigated;
   bool     trade_taken;
};

//--- Global Objects
CTrade         m_trade;
CSymbolInfo    m_symbol;
CPositionInfo  m_position;
CAccountInfo   m_account;

SFibLevel      g_active_levels[];
int            g_daily_trade_count = 0;
datetime       g_last_day = 0;
int            g_total_wins = 0;
int            g_total_losses = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!m_symbol.Name(_Symbol)) return(INIT_FAILED);
   m_symbol.RefreshRates();

   m_trade.SetExpertMagicNumber(InpBaseMagic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(_Symbol);

   UpdateDailyLevels();
   if(InpDrawChartObjects) RedrawChartObjects();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(InpDrawChartObjects)
   {
      ObjectsDeleteAll(0, "FIB618_");
   }
   Comment("");
}

//+------------------------------------------------------------------+
//| Aggressive Mathematical Tier Lot Allocation                      |
//+------------------------------------------------------------------+
double CalculateAggressiveLotSize()
{
   double min_lot  = m_symbol.LotsMin();
   double max_lot  = m_symbol.LotsMax();
   double lot_step = m_symbol.LotsStep();
   double equity   = m_account.Equity();

   double leg_lot = min_lot;

   if(InpSizingMode == TIER_FIXED_MICRO)
   {
      leg_lot = InpFixedLot;
   }
   else if(InpSizingMode == TIER_MATHEMATICAL_FLOW)
   {
      // Mathematical Equity Tiered Flow
      // $0 - $25:   0.01 lot per leg (Survival Tier)
      // $25 - $50:  0.02 lot per leg (Boost Tier)
      // $50 - $100: 0.03 lot per leg (Expansion Tier)
      // $100 - $200: 0.05 lot per leg (Institutional Tier 1)
      // $200 - $350: 0.08 lot per leg (Institutional Tier 2)
      // $350 - $500: 0.12 lot per leg (Institutional Tier 3)
      // $500+:      Floor(Equity / 40.0) * 0.01 lot per leg
      if(equity < 25.0)
         leg_lot = 0.01;
      else if(equity < 50.0)
         leg_lot = 0.02;
      else if(equity < 100.0)
         leg_lot = 0.03;
      else if(equity < 200.0)
         leg_lot = 0.05;
      else if(equity < 350.0)
         leg_lot = 0.08;
      else if(equity < 500.0)
         leg_lot = 0.12;
      else
         leg_lot = MathFloor(equity / 40.0) * 0.01;
   }
   else if(InpSizingMode == TIER_STEP_EQUITY)
   {
      double calculated = MathFloor(equity / InpStepEquitySize) * 0.01;
      leg_lot = MathMax(min_lot, calculated);
   }

   leg_lot = MathFloor(leg_lot / lot_step) * lot_step;
   leg_lot = MathMax(min_lot, MathMin(InpMaxLotCap, leg_lot));
   return NormalizeDouble(leg_lot, 2);
}

//+------------------------------------------------------------------+
//| Check for new day and refresh levels                             |
//+------------------------------------------------------------------+
void UpdateDailyLevels()
{
   MqlRates daily_rates[];
   ArraySetAsSeries(daily_rates, true);
   int copied = CopyRates(_Symbol, PERIOD_D1, 0, InpMaxVirginAgeDays + 5, daily_rates);
   if(copied < 2) return;

   ArrayResize(g_active_levels, 0);

   for(int i = 1; i < copied; i++)
   {
      double d_open  = daily_rates[i].open;
      double d_high  = daily_rates[i].high;
      double d_low   = daily_rates[i].low;
      double d_close = daily_rates[i].close;
      double d_range = d_high - d_low;

      if(d_range <= 0) continue;

      // Volatility filter: skip narrow days
      if(InpMinDayRangePts > 0 && d_range < InpMinDayRangePts * m_symbol.Point())
         continue;

      bool is_bullish = (d_close >= d_open);
      double fib_618 = 0.0;

      // Bearish Day: High = 100%, Low = 0% -> Level = Low + 0.618 * Range (SELL)
      // Bullish Day: Low = 100%, High = 0% -> Level = High - 0.618 * Range (BUY)
      if(!is_bullish)
         fib_618 = d_low + 0.618 * d_range;
      else
         fib_618 = d_high - 0.618 * d_range;

      bool is_mitigated = false;
      bool touched_next_day = false;

      if(!is_bullish)
      {
         if(daily_rates[i-1].high >= fib_618) touched_next_day = true;
      }
      else
      {
         if(daily_rates[i-1].low <= fib_618) touched_next_day = true;
      }

      if(i == 1) // Prior day candle
      {
         if(!InpTradeImmediate) continue;
      }
      else // Virgin check
      {
         if(!InpTradeVirginLevels) continue;
         if(touched_next_day) continue;

         for(int k = i - 2; k >= 0; k--)
         {
            if(!is_bullish && daily_rates[k].high >= fib_618) { is_mitigated = true; break; }
            if(is_bullish && daily_rates[k].low <= fib_618)   { is_mitigated = true; break; }
         }

         if(is_mitigated) continue;
      }

      int sz = ArraySize(g_active_levels);
      ArrayResize(g_active_levels, sz + 1);
      g_active_levels[sz].day_date     = daily_rates[i].time;
      g_active_levels[sz].price_level  = NormalizeDouble(fib_618, _Digits);
      g_active_levels[sz].day_high     = d_high;
      g_active_levels[sz].day_low      = d_low;
      g_active_levels[sz].day_range    = d_range;
      g_active_levels[sz].is_bullish   = is_bullish;
      g_active_levels[sz].is_virgin    = (i > 1);
      g_active_levels[sz].is_mitigated = false;
      g_active_levels[sz].trade_taken  = false;
   }
}

//+------------------------------------------------------------------+
//| On-Chart Visual Engine: Draw Fibonacci Rays & Range Bounds       |
//+------------------------------------------------------------------+
void RedrawChartObjects()
{
   if(!InpDrawChartObjects) return;
   ObjectsDeleteAll(0, "FIB618_");

   datetime now_t = TimeCurrent();
   datetime end_t = now_t + 86400 * 3; // Extend 3 days ahead

   for(int i = 0; i < ArraySize(g_active_levels); i++)
   {
      string pfx = "FIB618_" + IntegerToString(i) + "_";
      datetime t_start = g_active_levels[i].day_date;
      double lvl       = g_active_levels[i].price_level;
      bool is_buy      = g_active_levels[i].is_bullish;
      bool is_virgin   = g_active_levels[i].is_virgin;

      color line_col = is_virgin ? InpVirginColor : (is_buy ? InpBuyColor : InpSellColor);
      ENUM_LINE_STYLE style = is_virgin ? STYLE_DASH : STYLE_SOLID;
      int width = is_virgin ? 2 : 2;

      // Draw Main 61.8% Level Ray
      string name_line = pfx + "LINE";
      if(ObjectCreate(0, name_line, OBJ_TREND, 0, t_start, lvl, end_t, lvl))
      {
         ObjectSetInteger(0, name_line, OBJPROP_COLOR, line_col);
         ObjectSetInteger(0, name_line, OBJPROP_STYLE, style);
         ObjectSetInteger(0, name_line, OBJPROP_WIDTH, width);
         ObjectSetInteger(0, name_line, OBJPROP_RAY_RIGHT, true);
         ObjectSetInteger(0, name_line, OBJPROP_SELECTABLE, false);
      }

      // Draw Label
      string name_txt = pfx + "LABEL";
      string desc = (is_virgin ? "[VIRGIN 61.8%] " : "[DAILY 61.8%] ") + 
                    (is_buy ? "BUY SUPPORT: " : "SELL RESIST: ") + DoubleToString(lvl, _Digits);
      if(ObjectCreate(0, name_txt, OBJ_TEXT, 0, t_start, lvl))
      {
         ObjectSetString(0, name_txt, OBJPROP_TEXT, desc);
         ObjectSetInteger(0, name_txt, OBJPROP_COLOR, line_col);
         ObjectSetInteger(0, name_txt, OBJPROP_FONTSIZE, 9);
         ObjectSetString(0, name_txt, OBJPROP_FONT, "Trebuchet MS");
         ObjectSetInteger(0, name_txt, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      }
   }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Check if open positions exist                                    |
//+------------------------------------------------------------------+
bool HasOpenPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == _Symbol)
         {
            ulong m = m_position.Magic();
            if(m == InpBaseMagic + 1 || m == InpBaseMagic + 2)
               return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Manage Breakeven on Leg 2 Runner                                 |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   double point = m_symbol.Point();
   double risk_dist = InpSLPoints * point;
   if(risk_dist <= 0) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol) continue;

      ulong m = m_position.Magic();
      if(m != InpBaseMagic + 2) continue; // Only manage Leg 2 runner

      double open_price = m_position.PriceOpen();
      double current_sl = m_position.StopLoss();
      ENUM_POSITION_TYPE type = m_position.PositionType();

      // Trigger BE once price reaches Leg 1 R:R distance (+1.0R)
      if(type == POSITION_TYPE_BUY)
      {
         double current_bid = m_symbol.Bid();
         double profit_dist = current_bid - open_price;
         if(profit_dist >= risk_dist * InpLeg1_RR)
         {
            double be_sl = NormalizeDouble(open_price + InpBELockPoints * point, _Digits);
            if(current_sl < be_sl)
            {
               m_trade.PositionModify(m_position.Ticket(), be_sl, m_position.TakeProfit());
            }
         }
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double current_ask = m_symbol.Ask();
         double profit_dist = open_price - current_ask;
         if(profit_dist >= risk_dist * InpLeg1_RR)
         {
            double be_sl = NormalizeDouble(open_price - InpBELockPoints * point, _Digits);
            if(current_sl > be_sl || current_sl == 0)
            {
               m_trade.PositionModify(m_position.Ticket(), be_sl, m_position.TakeProfit());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update Real-Time On-Chart HUD Comment                            |
//+------------------------------------------------------------------+
void UpdateHUD()
{
   if(!InpShowDashboard) return;

   double eq = m_account.Equity();
   double bal = m_account.Balance();
   double lots = CalculateAggressiveLotSize();
   string tier_name = "";

   if(eq < 25.0) tier_name = "Survival Micro Tier ($0 - $25)";
   else if(eq < 50.0) tier_name = "Boost Tier ($25 - $50)";
   else if(eq < 100.0) tier_name = "Expansion Tier ($50 - $100)";
   else if(eq < 200.0) tier_name = "Institutional Growth Tier 1 ($100 - $200)";
   else if(eq < 350.0) tier_name = "Institutional Growth Tier 2 ($200 - $350)";
   else tier_name = "Institutional Multiplier ($350+)";

   string hud = "=======================================================\n" +
                "  GOLD DAILY 61.8% AGGRESSIVE MATHEMATICAL FLOW ENGINE \n" +
                "=======================================================\n" +
                "  Account Equity:       $" + DoubleToString(eq, 2) + " (Bal: $" + DoubleToString(bal, 2) + ")\n" +
                "  Active Sizing Tier:   " + tier_name + "\n" +
                "  Volume Per Leg:       " + DoubleToString(lots, 2) + " Lots (Total Position: " + DoubleToString(lots*2, 2) + ")\n" +
                "  Structural Stop Loss: " + IntegerToString(InpSLPoints) + " Points (" + DoubleToString(InpSLPoints*0.1, 1) + " Pips)\n" +
                "  Leg 1 Cash-Out:       1.0 R:R (+$" + DoubleToString(lots * InpSLPoints * 0.1, 2) + ")\n" +
                "  Leg 2 Runner Target:  " + DoubleToString(InpLeg2_RR, 1) + " R:R (+$" + DoubleToString(lots * InpSLPoints * InpLeg2_RR * 0.1, 2) + ")\n" +
                "  Active Monitored Fibs:" + IntegerToString(ArraySize(g_active_levels)) + " Levels\n" +
                "  Daily Trades Taken:   " + IntegerToString(g_daily_trade_count) + " / " + IntegerToString(InpMaxDailyTrades) + "\n" +
                "=======================================================";
   Comment(hud);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!m_symbol.RefreshRates()) return;

   // Handle new day
   datetime today = iTime(_Symbol, PERIOD_D1, 0);
   if(today != g_last_day)
   {
      g_last_day = today;
      g_daily_trade_count = 0;
      UpdateDailyLevels();
      if(InpDrawChartObjects) RedrawChartObjects();
   }

   // Manage Leg 2 Runner (Breakeven Lock)
   ManageOpenPositions();

   // Update HUD
   UpdateHUD();

   // Spread check
   if(m_symbol.Spread() > InpMaxSpreadPoints) return;

   // Session filter check
   if(InpUseSessionFilter)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      if(dt.hour < InpSessionStartHour || dt.hour >= InpSessionEndHour) return;
   }

   // Max daily trades check
   if(g_daily_trade_count >= InpMaxDailyTrades) return;

   // If already in a position, wait until it resolves
   if(HasOpenPositions()) return;

   double ask = m_symbol.Ask();
   double bid = m_symbol.Bid();
   double point = m_symbol.Point();

   // Check active levels for entry touch
   for(int i = 0; i < ArraySize(g_active_levels); i++)
   {
      if(g_active_levels[i].trade_taken) continue;

      double lvl = g_active_levels[i].price_level;
      bool is_buy = g_active_levels[i].is_bullish;

      if(is_buy) // BUY SUPPORT LEVEL
      {
         if(ask <= lvl + InpEntryTolerance * point && ask >= lvl - InpEntryTolerance * point)
         {
            double sl  = NormalizeDouble(ask - InpSLPoints * point, _Digits);
            double tp1 = 0.0;
            double tp2 = 0.0;

            if(InpTargetMode == TARGET_FIXED_RR)
            {
               tp1 = NormalizeDouble(ask + (InpSLPoints * InpLeg1_RR) * point, _Digits);
               tp2 = NormalizeDouble(ask + (InpSLPoints * InpLeg2_RR) * point, _Digits);
            }
            else // Range-Adaptive
            {
               double d_range = g_active_levels[i].day_range;
               tp1 = NormalizeDouble(ask + (d_range * 0.50), _Digits);
               tp2 = NormalizeDouble(g_active_levels[i].day_high, _Digits); // Prior Day High Sweep
            }

            double lots = CalculateAggressiveLotSize();

            // Open Leg 1 (1:1 Cash-Out)
            m_trade.SetExpertMagicNumber(InpBaseMagic + 1);
            if(m_trade.Buy(lots, _Symbol, ask, sl, tp1, "Fib618-Leg1-1R"))
            {
               // Open Leg 2 (Runner)
               m_trade.SetExpertMagicNumber(InpBaseMagic + 2);
               m_trade.Buy(lots, _Symbol, ask, sl, tp2, "Fib618-Leg2-Runner");

               g_active_levels[i].trade_taken = true;
               g_daily_trade_count++;
               break;
            }
         }
      }
      else // SELL RESISTANCE LEVEL
      {
         if(bid >= lvl - InpEntryTolerance * point && bid <= lvl + InpEntryTolerance * point)
         {
            double sl  = NormalizeDouble(bid + InpSLPoints * point, _Digits);
            double tp1 = 0.0;
            double tp2 = 0.0;

            if(InpTargetMode == TARGET_FIXED_RR)
            {
               tp1 = NormalizeDouble(bid - (InpSLPoints * InpLeg1_RR) * point, _Digits);
               tp2 = NormalizeDouble(bid - (InpSLPoints * InpLeg2_RR) * point, _Digits);
            }
            else // Range-Adaptive
            {
               double d_range = g_active_levels[i].day_range;
               tp1 = NormalizeDouble(bid - (d_range * 0.50), _Digits);
               tp2 = NormalizeDouble(g_active_levels[i].day_low, _Digits); // Prior Day Low Sweep
            }

            double lots = CalculateAggressiveLotSize();

            // Open Leg 1 (1:1 Cash-Out)
            m_trade.SetExpertMagicNumber(InpBaseMagic + 1);
            if(m_trade.Sell(lots, _Symbol, bid, sl, tp1, "Fib618-Leg1-1R"))
            {
               // Open Leg 2 (Runner)
               m_trade.SetExpertMagicNumber(InpBaseMagic + 2);
               m_trade.Sell(lots, _Symbol, bid, sl, tp2, "Fib618-Leg2-Runner");

               g_active_levels[i].trade_taken = true;
               g_daily_trade_count++;
               break;
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
