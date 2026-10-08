//+------------------------------------------------------------------+
//|                            Daily_Fib_618_Institutional_EA.mq5    |
//|                  Copyright 2026, Quantitative Research Lab       |
//|    Gold Daily 61.8% Fibonacci with 1:1 Partial Engine & Trend    |
//+------------------------------------------------------------------+
#property copyright "Quantitative Research Lab"
#property link      "https://trading-automations.internal"
#property version   "3.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//--- Enums
enum ENUM_CAPITAL_ALLOCATION
{
   CAPITAL_FIXED_LOT   = 0, // Fixed Lot per Leg
   CAPITAL_STEP_EQUITY = 1  // Dynamic Compounding (0.01 per Step Equity)
};

enum ENUM_TREND_FILTER
{
   TREND_FILTER_NONE      = 0, // None (Trade Both Directions)
   TREND_FILTER_DAILY_EMA = 1, // Daily EMA Filter (Above EMA = Buy, Below = Sell)
   TREND_FILTER_WEEKLY    = 2  // Prior Week Candle Bias (Green = Buy, Red = Sell)
};

//--- Input Parameters
input group "=== Capital Allocation & Compounding ==="
input ENUM_CAPITAL_ALLOCATION InpCapitalMode       = CAPITAL_FIXED_LOT; // Sizing Mode
input double                  InpFixedLot          = 0.01;              // Fixed Lot per Leg
input double                  InpEquityStep        = 100.0;             // Equity per 0.01 Lot Step
input double                  InpMaxLotCap         = 2.0;               // Maximum Allowed Lot per Leg

input group "=== Target & Risk Parameters ==="
input int                     InpSLPoints          = 400;               // Stop Loss (Points from Level)
input double                  InpLeg1_RR           = 1.0;               // Leg 1 Target R:R (1:1 Cash-out)
input double                  InpLeg2_RR           = 2.0;               // Leg 2 Target R:R (Runner)
input int                     InpBELockPoints      = 10;                // Profit Locked at BE (Points)
input int                     InpBaseMagic         = 618800;            // Base Magic Number (Uses Base+1, Base+2)

input group "=== Macro Trend Alignment ==="
input ENUM_TREND_FILTER       InpTrendFilterMode   = TREND_FILTER_NONE; // Macro Trend Filter
input int                     InpDailyEMAPeriod    = 100;               // Daily EMA Period (If EMA mode selected)

input group "=== Level & Filter Settings ==="
input int                     InpEntryTolerance    = 50;                // Entry Tolerance (Points)
input int                     InpMaxSpreadPoints   = 50;                // Max Allowed Spread (Points)
input int                     InpMinDayRangePoints = 0;                 // Min Prior Day Range (Points, 0=Disabled)
input bool                    InpTradeImmediate    = true;              // Trade Day+1 Immediate Retests
input bool                    InpTradeVirginLevels = true;              // Trade Unmitigated Virgin Levels
input int                     InpMaxVirginAgeDays  = 30;                // Max Virgin Level Lookback (Days)
input int                     InpMaxDailyTrades    = 2;                 // Max Entries Per Day

input group "=== Session Filtering ==="
input bool                    InpUseSessionFilter  = true;              // Enable Session Filter
input int                     InpSessionStartHour  = 7;                 // Start Hour (Server Time)
input int                     InpSessionEndHour    = 18;                // End Hour (Server Time)

//--- Level Structure
struct SFibLevel
{
   datetime day_date;
   double   price_level;
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
int            g_h_daily_ema = INVALID_HANDLE;

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

   if(InpTrendFilterMode == TREND_FILTER_DAILY_EMA)
   {
      g_h_daily_ema = iMA(_Symbol, PERIOD_D1, InpDailyEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   }

   UpdateDailyLevels();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_h_daily_ema != INVALID_HANDLE)
      IndicatorRelease(g_h_daily_ema);
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

      // Filter tiny range candles if specified
      if(InpMinDayRangePoints > 0 && d_range < InpMinDayRangePoints * m_symbol.Point())
         continue;

      bool is_bullish = (d_close >= d_open);
      double fib_618 = 0.0;

      // Mathematical logic:
      // Bearish Day: 100% at High, 0% at Low -> Level = Low + 0.618 * Range (SELL)
      // Bullish Day: 100% at Low, 0% at High -> Level = High - 0.618 * Range (BUY)
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

      if(i == 1) // Yesterday's candle
      {
         if(!InpTradeImmediate) continue;
      }
      else // Older candles: Virgin check
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
      g_active_levels[sz].is_bullish   = is_bullish;
      g_active_levels[sz].is_virgin    = (i > 1);
      g_active_levels[sz].is_mitigated = false;
      g_active_levels[sz].trade_taken  = false;
   }
}

//+------------------------------------------------------------------+
//| Calculate Lot Size per Leg                                       |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   double min_lot  = m_symbol.LotsMin();
   double max_lot  = m_symbol.LotsMax();
   double lot_step = m_symbol.LotsStep();
   double equity   = m_account.Equity();

   double leg_lot = min_lot;

   if(InpCapitalMode == CAPITAL_FIXED_LOT)
   {
      leg_lot = InpFixedLot;
   }
   else if(InpCapitalMode == CAPITAL_STEP_EQUITY)
   {
      double calculated = MathFloor(equity / InpEquityStep) * 0.01;
      leg_lot = MathMax(min_lot, calculated);
   }

   leg_lot = MathFloor(leg_lot / lot_step) * lot_step;
   leg_lot = MathMax(min_lot, MathMin(InpMaxLotCap, leg_lot));
   return NormalizeDouble(leg_lot, 2);
}

//+------------------------------------------------------------------+
//| Check if open positions exist for this strategy                  |
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
   }

   // Manage Leg 2 Runner (Breakeven Lock)
   ManageOpenPositions();

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

   // Calculate Macro Trend Bias
   bool can_buy = true;
   bool can_sell = true;

   if(InpTrendFilterMode == TREND_FILTER_DAILY_EMA && g_h_daily_ema != INVALID_HANDLE)
   {
      double ema_val[1];
      if(CopyBuffer(g_h_daily_ema, 0, 1, 1, ema_val) > 0)
      {
         double d_close = iClose(_Symbol, PERIOD_D1, 1);
         can_buy  = (d_close >= ema_val[0]);
         can_sell = (d_close <= ema_val[0]);
      }
   }
   else if(InpTrendFilterMode == TREND_FILTER_WEEKLY)
   {
      double w_open  = iOpen(_Symbol, PERIOD_W1, 1);
      double w_close = iClose(_Symbol, PERIOD_W1, 1);
      can_buy  = (w_close >= w_open);
      can_sell = (w_close <= w_open);
   }

   double ask = m_symbol.Ask();
   double bid = m_symbol.Bid();
   double point = m_symbol.Point();

   // Check active levels for entry touch
   for(int i = 0; i < ArraySize(g_active_levels); i++)
   {
      if(g_active_levels[i].trade_taken) continue;

      double lvl = g_active_levels[i].price_level;
      bool is_buy = g_active_levels[i].is_bullish;

      if(is_buy && can_buy) // BUY SUPPORT LEVEL
      {
         if(ask <= lvl + InpEntryTolerance * point && ask >= lvl - InpEntryTolerance * point)
         {
            double sl  = NormalizeDouble(ask - InpSLPoints * point, _Digits);
            double tp1 = NormalizeDouble(ask + (InpSLPoints * InpLeg1_RR) * point, _Digits);
            double tp2 = NormalizeDouble(ask + (InpSLPoints * InpLeg2_RR) * point, _Digits);
            double lots = CalculateLotSize();

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
      else if(!is_buy && can_sell) // SELL RESISTANCE LEVEL
      {
         if(bid >= lvl - InpEntryTolerance * point && bid <= lvl + InpEntryTolerance * point)
         {
            double sl  = NormalizeDouble(bid + InpSLPoints * point, _Digits);
            double tp1 = NormalizeDouble(bid - (InpSLPoints * InpLeg1_RR) * point, _Digits);
            double tp2 = NormalizeDouble(bid - (InpSLPoints * InpLeg2_RR) * point, _Digits);
            double lots = CalculateLotSize();

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
