//+------------------------------------------------------------------+
//|                                     DanialFX_Aggressive_Suite.mq5 |
//|                             Ahmad Danial (@Danialfx) Strategy EA |
//|            Quasimodo (QM) + AO Momentum + BBMA REM + Layering    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Institutional Algo Lab"
#property link      "https://www.youtube.com/@Danialfx"
#property version   "1.10"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Enums
enum ENUM_DANIAL_STRATEGY
{
   STRAT_QM_SNIPER           = 0, // Model 0: Quasimodo (QM) Left Shoulder Retest
   STRAT_QM_AO_CONFLUENCE    = 1, // Model 1: QM + Awesome Oscillator (AO) Momentum
   STRAT_BBMA_REM            = 2, // Model 2: BBMA REM Setup (Trend Re-entry & Rejection)
   STRAT_HYBRID_CHAMPION     = 3  // Model 3: Danial FX Master Hybrid Confluence
};

enum ENUM_RISK_MODE
{
   RISK_DYNAMIC_TIER = 0, // Dynamic Compounding (Equity Step Tiering)
   RISK_FIXED_LOT     = 1  // Fixed Lot Size
};

//--- Input Parameters
input group "=== Strategy Mode & Identification ==="
input ENUM_DANIAL_STRATEGY InpStrategyMode        = STRAT_HYBRID_CHAMPION; // Strategy Model
input ulong                InpMagicNumber         = 991100;                // EA Magic Number
input string               InpTradeComment        = "DanialFX";            // Trade Comment

input group "=== Dynamic Capital & Lot Sizing ==="
input ENUM_RISK_MODE       InpRiskMode            = RISK_DYNAMIC_TIER;     // Sizing Mode
input double               InpFixedLot            = 0.01;                  // Fixed Lot Size (if RISK_FIXED_LOT)
input double               InpEquityStepPerMinLot = 25.0;                  // Equity ($) per 0.01 lot
input double               InpMinLot              = 0.01;                  // Minimum Lot
input double               InpMaxLot              = 5.00;                  // Maximum Lot Cap

input group "=== Aggressive Layering / Pyramiding ==="
input bool                 InpEnableLayering      = true;                  // Enable Layering / Adding to Winners
input int                  InpMaxLayers           = 3;                     // Max Layer Positions in Same Direction
input int                  InpLayerStepPoints     = 350;                   // Profit Distance (Points) to Trigger Next Layer (35 pips)
input bool                 InpLockBreakevenOnLayer= true;                  // Move Previous Positions to BE when Layering
input int                  InpBreakevenBufferPts  = 10;                    // Breakeven Buffer Points (+1.0 pip)
input bool                 InpEnableTrailing      = true;                  // Enable Basket Trailing Stop
input int                  InpTrailingStartPoints = 450;                   // Trailing Start (Points)
input int                  InpTrailingStepPoints  = 150;                   // Trailing Step (Points)

input group "=== Quasimodo (QM) Structural Engine ==="
input int                  InpSwingLookback       = 30;                    // Lookback Bars for Swing High/Low
input int                  InpMinBOSPoints        = 120;                   // Minimum Break of Structure (Points)
input int                  InpQMLTolerancePoints  = 100;                   // QML Entry Tolerance (Points)
input int                  InpSLHeadBufferPoints  = 50;                    // SL Head Buffer (Points)
input int                  InpStopLossPoints      = 250;                   // Default Max Stop Loss (Points)
input int                  InpTakeProfitPoints    = 750;                   // Take Profit Target (Points)

input group "=== Awesome Oscillator (AO) Settings ==="
input int                  InpAOFastPeriod        = 5;                     // AO Fast Median SMA
input int                  InpAOSlowPeriod        = 34;                    // AO Slow Median SMA

input group "=== BBMA & Trend Backbone Settings ==="
input int                  InpBBPeriod            = 20;                    // Bollinger Bands Period
input double               InpBBDev               = 2.0;                   // Bollinger Bands Deviation
input int                  InpEMA50Period         = 50;                    // EMA Trend Backbone Period
input bool                 InpUseEMATrendFilter   = true;                  // Enforce EMA 50 Trend Alignment (Never Fade Trend)
input double               InpMinRejectionWickPct = 0.30;                  // Minimum Rejection Wick % (30%)

input group "=== Session Timing & Spread Filter ==="
input bool                 InpUseSessionFilter    = true;                  // Enable Session Filter
input int                  InpStartHour           = 7;                     // Start Hour (London Open)
input int                  InpEndHour             = 19;                    // End Hour (NY Close)
input int                  InpMaxSpreadPoints     = 45;                    // Max Spread (Points)

//--- Global Variables
CTrade         m_trade;
CPositionInfo  m_position;

int            h_bb;
int            h_ema50;
int            h_ao;

datetime       last_bar_time = 0;
double         last_layer_price_buy = 0.0;
double         last_layer_price_sell = 0.0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(_Symbol);

   // Initialize Indicators
   h_bb = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDev, PRICE_CLOSE);
   if (h_bb == INVALID_HANDLE)
   {
      Print("Failed to create Bollinger Bands handle");
      return INIT_FAILED;
   }

   h_ema50 = iMA(_Symbol, _Period, InpEMA50Period, 0, MODE_EMA, PRICE_CLOSE);
   if (h_ema50 == INVALID_HANDLE)
   {
      Print("Failed to create EMA 50 handle");
      return INIT_FAILED;
   }

   h_ao = iAO(_Symbol, _Period);
   if (h_ao == INVALID_HANDLE)
   {
      Print("Failed to create AO handle");
      return INIT_FAILED;
   }

   last_layer_price_buy = 0.0;
   last_layer_price_sell = 0.0;

   PrintFormat("DanialFX Aggressive Suite v1.10 initialized. Symbol: %s, Strategy: %d", _Symbol, InpStrategyMode);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(h_bb);
   IndicatorRelease(h_ema50);
   IndicatorRelease(h_ao);
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Lot Size Based on Danial FX Tiering            |
//+------------------------------------------------------------------+
double CalculateDanialLot()
{
   if (InpRiskMode == RISK_FIXED_LOT)
      return InpFixedLot;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if (InpEquityStepPerMinLot <= 0.0)
      return InpMinLot;

   int tiers = (int)MathFloor(equity / InpEquityStepPerMinLot);
   if (tiers < 1) tiers = 1;

   double lot = tiers * 0.01;

   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if (lot < min_lot) lot = min_lot;
   if (lot > InpMaxLot) lot = InpMaxLot;
   if (lot > max_lot) lot = max_lot;

   lot = MathFloor(lot / lot_step) * lot_step;
   return lot;
}

//+------------------------------------------------------------------+
//| Check Trading Session & Spread Filter                            |
//+------------------------------------------------------------------+
bool IsFilterPassed()
{
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if (spread > InpMaxSpreadPoints)
      return false;

   if (InpUseSessionFilter)
   {
      MqlDateTime dt;
      TimeCurrent(dt);
      if (dt.hour < InpStartHour || dt.hour >= InpEndHour)
         return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Count Open Positions and Get Basket Profit Data                  |
//+------------------------------------------------------------------+
int GetOpenPositions(ENUM_POSITION_TYPE pos_type, double &oldest_open_price, double &newest_open_price, double &profit_pts)
{
   int count = 0;
   oldest_open_price = 0.0;
   newest_open_price = 0.0;
   profit_pts = 0.0;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   datetime oldest_time = D'2099.12.31';
   datetime newest_time = 0;

   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (m_position.SelectByIndex(i))
      {
         if (m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
         {
            if (m_position.PositionType() == pos_type)
            {
               count++;
               datetime pos_time = (datetime)m_position.Time();
               if (pos_time < oldest_time)
               {
                  oldest_time = pos_time;
                  oldest_open_price = m_position.PriceOpen();
               }
               if (pos_time > newest_time)
               {
                  newest_time = pos_time;
                  newest_open_price = m_position.PriceOpen();
               }
            }
         }
      }
   }

   if (count > 0 && oldest_open_price > 0.0)
   {
      if (pos_type == POSITION_TYPE_BUY)
         profit_pts = (bid - oldest_open_price) / _Point;
      else
         profit_pts = (oldest_open_price - ask) / _Point;
   }

   return count;
}

//+------------------------------------------------------------------+
//| Manage Breakeven and Basket Trailing                             |
//+------------------------------------------------------------------+
void ManageBreakevenAndTrailing()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (m_position.SelectByIndex(i))
      {
         if (m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
         {
            double open_price = m_position.PriceOpen();
            double sl = m_position.StopLoss();
            double tp = m_position.TakeProfit();
            ENUM_POSITION_TYPE p_type = m_position.PositionType();

            if (p_type == POSITION_TYPE_BUY)
            {
               double profit_pts = (bid - open_price) / _Point;

               // Move to Breakeven once in +InpLayerStepPoints profit
               if (InpLockBreakevenOnLayer && profit_pts >= InpLayerStepPoints)
               {
                  double new_sl = open_price + (InpBreakevenBufferPts * _Point);
                  if (sl < open_price)
                  {
                     m_trade.PositionModify(m_position.Ticket(), new_sl, tp);
                  }
               }

               // Basket Trailing Stop
               if (InpEnableTrailing && profit_pts >= InpTrailingStartPoints)
               {
                  double trail_sl = bid - (InpTrailingStepPoints * _Point);
                  if (trail_sl > sl && trail_sl > open_price)
                  {
                     m_trade.PositionModify(m_position.Ticket(), trail_sl, tp);
                  }
               }
            }
            else if (p_type == POSITION_TYPE_SELL)
            {
               double profit_pts = (open_price - ask) / _Point;

               // Move to Breakeven once in +InpLayerStepPoints profit
               if (InpLockBreakevenOnLayer && profit_pts >= InpLayerStepPoints)
               {
                  double new_sl = open_price - (InpBreakevenBufferPts * _Point);
                  if (sl > open_price || sl == 0.0)
                  {
                     m_trade.PositionModify(m_position.Ticket(), new_sl, tp);
                  }
               }

               // Basket Trailing Stop
               if (InpEnableTrailing && profit_pts >= InpTrailingStartPoints)
               {
                  double trail_sl = ask + (InpTrailingStepPoints * _Point);
                  if ((sl == 0.0 || trail_sl < sl) && trail_sl < open_price)
                  {
                     m_trade.PositionModify(m_position.Ticket(), trail_sl, tp);
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Quasimodo (QM) Pattern Scanner                                  |
//+------------------------------------------------------------------+
bool ScanQuasimodoSetup(bool &qm_buy, bool &qm_sell, double &qml_price, double &head_price)
{
   qm_buy = false;
   qm_sell = false;
   qml_price = 0.0;
   head_price = 0.0;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 0, InpSwingLookback, rates);
   if (copied < InpSwingLookback) return false;

   // Bearish QM: Left Shoulder High -> Interim Low -> Head (Higher High) -> BOS (Lower Low)
   int idx_head_high = 0;
   double max_high = 0.0;
   for (int i = 4; i < InpSwingLookback - 4; i++)
   {
      if (rates[i].high > max_high)
      {
         max_high = rates[i].high;
         idx_head_high = i;
      }
   }

   int idx_ls_high = 0;
   double ls_high = 0.0;
   for (int i = idx_head_high + 2; i < InpSwingLookback - 1; i++)
   {
      if (rates[i].high > ls_high && rates[i].high < max_high - (InpMinBOSPoints * _Point))
      {
         ls_high = rates[i].high;
         idx_ls_high = i;
      }
   }

   double interim_low = 999999.0;
   for (int i = idx_head_high; i <= idx_ls_high; i++)
   {
      if (rates[i].low < interim_low) interim_low = rates[i].low;
   }

   double lowest_after_head = 999999.0;
   for (int i = 1; i < idx_head_high; i++)
   {
      if (rates[i].low < lowest_after_head) lowest_after_head = rates[i].low;
   }

   if (idx_ls_high > 0 && max_high > ls_high && lowest_after_head < interim_low - (InpMinBOSPoints * _Point))
   {
      double current_close = rates[1].close;
      double qml_diff = MathAbs(current_close - ls_high) / _Point;
      if (qml_diff <= InpQMLTolerancePoints && current_close <= max_high)
      {
         // Upper rejection wick check
         double candle_rng = rates[1].high - rates[1].low;
         double upper_wick = rates[1].high - MathMax(rates[1].open, rates[1].close);
         if (candle_rng > 0.0 && (upper_wick / candle_rng) >= InpMinRejectionWickPct)
         {
            qm_sell = true;
            qml_price = ls_high;
            head_price = max_high;
            return true;
         }
      }
   }

   // Bullish QM: Left Shoulder Low -> Interim High -> Head (Lower Low) -> BOS (Higher High)
   int idx_head_low = 0;
   double min_low = 999999.0;
   for (int i = 4; i < InpSwingLookback - 4; i++)
   {
      if (rates[i].low < min_low)
      {
         min_low = rates[i].low;
         idx_head_low = i;
      }
   }

   int idx_ls_low = 0;
   double ls_low = 999999.0;
   for (int i = idx_head_low + 2; i < InpSwingLookback - 1; i++)
   {
      if (rates[i].low < ls_low && rates[i].low > min_low + (InpMinBOSPoints * _Point))
      {
         ls_low = rates[i].low;
         idx_ls_low = i;
      }
   }

   double interim_high = 0.0;
   for (int i = idx_head_low; i <= idx_ls_low; i++)
   {
      if (rates[i].high > interim_high) interim_high = rates[i].high;
   }

   double highest_after_head = 0.0;
   for (int i = 1; i < idx_head_low; i++)
   {
      if (rates[i].high > highest_after_head) highest_after_head = rates[i].high;
   }

   if (idx_ls_low > 0 && min_low < ls_low && highest_after_head > interim_high + (InpMinBOSPoints * _Point))
   {
      double current_close = rates[1].close;
      double qml_diff = MathAbs(current_close - ls_low) / _Point;
      if (qml_diff <= InpQMLTolerancePoints && current_close >= min_low)
      {
         // Lower rejection wick check
         double candle_rng = rates[1].high - rates[1].low;
         double lower_wick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
         if (candle_rng > 0.0 && (lower_wick / candle_rng) >= InpMinRejectionWickPct)
         {
            qm_buy = true;
            qml_price = ls_low;
            head_price = min_low;
            return true;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Awesome Oscillator Momentum Filter                               |
//+------------------------------------------------------------------+
bool CheckAOMomentum(bool is_buy)
{
   double ao_buffer[];
   ArraySetAsSeries(ao_buffer, true);
   if (CopyBuffer(h_ao, 0, 0, 3, ao_buffer) < 3) return false;

   if (is_buy)
      return (ao_buffer[1] > ao_buffer[2] || ao_buffer[1] > 0.0);
   else
      return (ao_buffer[1] < ao_buffer[2] || ao_buffer[1] < 0.0);
}

//+------------------------------------------------------------------+
//| BBMA REM Trend Continuation Scanner                              |
//+------------------------------------------------------------------+
bool CheckBBMAREM(bool &bbma_buy, bool &bbma_sell, double ema50_val)
{
   bbma_buy = false;
   bbma_sell = false;

   double bb_upper[], bb_lower[], bb_mid[];
   ArraySetAsSeries(bb_upper, true);
   ArraySetAsSeries(bb_lower, true);
   ArraySetAsSeries(bb_mid, true);

   if (CopyBuffer(h_bb, 1, 0, 3, bb_upper) < 3) return false;
   if (CopyBuffer(h_bb, 2, 0, 3, bb_lower) < 3) return false;
   if (CopyBuffer(h_bb, 0, 0, 3, bb_mid) < 3) return false;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if (CopyRates(_Symbol, _Period, 0, 3, rates) < 3) return false;

   double candle_rng = rates[1].high - rates[1].low;
   if (candle_rng <= 0.0) return false;

   // 1. BBMA Re-entry Buy in Uptrend (Price > EMA 50)
   // Pullback into Mid BB or Lower BB area with strong lower rejection wick
   if (rates[1].close > ema50_val)
   {
      double lower_wick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
      bool touched_support = (rates[1].low <= bb_mid[1] || rates[1].low <= bb_lower[1]);
      bool closed_above = (rates[1].close >= bb_mid[1] || rates[1].close > rates[1].open);

      if (touched_support && closed_above && (lower_wick / candle_rng) >= InpMinRejectionWickPct)
      {
         bbma_buy = true;
      }
   }
   // 2. BBMA Re-entry Sell in Downtrend (Price < EMA 50)
   // Pullback into Mid BB or Upper BB area with strong upper rejection wick
   else if (rates[1].close < ema50_val)
   {
      double upper_wick = rates[1].high - MathMax(rates[1].open, rates[1].close);
      bool touched_resistance = (rates[1].high >= bb_mid[1] || rates[1].high >= bb_upper[1]);
      bool closed_below = (rates[1].close <= bb_mid[1] || rates[1].close < rates[1].open);

      if (touched_resistance && closed_below && (upper_wick / candle_rng) >= InpMinRejectionWickPct)
      {
         bbma_sell = true;
      }
   }

   return (bbma_buy || bbma_sell);
}

//+------------------------------------------------------------------+
//| Check Stacking / Layering Opportunity                            |
//+------------------------------------------------------------------+
void CheckLayeringExecution()
{
   if (!InpEnableLayering) return;

   double oldest_price = 0.0, newest_price = 0.0, profit_pts = 0.0;

   // Check Buy Layering
   int buy_count = GetOpenPositions(POSITION_TYPE_BUY, oldest_price, newest_price, profit_pts);
   if (buy_count > 0 && buy_count < InpMaxLayers)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      // Require profit from newest layer to be at least InpLayerStepPoints
      double dist_from_last = (ask - newest_price) / _Point;

      if (dist_from_last >= InpLayerStepPoints && profit_pts >= (buy_count * InpLayerStepPoints))
      {
         double lot = CalculateDanialLot();
         double sl = oldest_price + (InpBreakevenBufferPts * _Point);
         double tp = ask + (InpTakeProfitPoints * _Point);

         string comment = StringFormat("%s_Layer%d", InpTradeComment, buy_count + 1);
         if (m_trade.Buy(lot, _Symbol, ask, sl, tp, comment))
         {
            PrintFormat("AGGRESSIVE LAYER %d BUY EXECUTED! Lot: %.2f, Profit Pts: %.1f", buy_count + 1, lot, profit_pts);
         }
      }
   }

   // Check Sell Layering
   int sell_count = GetOpenPositions(POSITION_TYPE_SELL, oldest_price, newest_price, profit_pts);
   if (sell_count > 0 && sell_count < InpMaxLayers)
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double dist_from_last = (newest_price - bid) / _Point;

      if (dist_from_last >= InpLayerStepPoints && profit_pts >= (sell_count * InpLayerStepPoints))
      {
         double lot = CalculateDanialLot();
         double sl = oldest_price - (InpBreakevenBufferPts * _Point);
         double tp = bid - (InpTakeProfitPoints * _Point);

         string comment = StringFormat("%s_Layer%d", InpTradeComment, sell_count + 1);
         if (m_trade.Sell(lot, _Symbol, bid, sl, tp, comment))
         {
            PrintFormat("AGGRESSIVE LAYER %d SELL EXECUTED! Lot: %.2f, Profit Pts: %.1f", sell_count + 1, lot, profit_pts);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Manage breakeven locks and trailing stops
   ManageBreakevenAndTrailing();

   // 2. Check aggressive layering on live price movements
   CheckLayeringExecution();

   // 3. New Bar Check for Primary Entries
   datetime current_bar_time = iTime(_Symbol, _Period, 0);
   if (current_bar_time == last_bar_time)
      return;
   last_bar_time = current_bar_time;

   if (!IsFilterPassed())
      return;

   // Check if we already have open positions
   double oldest_p = 0.0, newest_p = 0.0, prof_p = 0.0;
   int open_buys = GetOpenPositions(POSITION_TYPE_BUY, oldest_p, newest_p, prof_p);
   int open_sells = GetOpenPositions(POSITION_TYPE_SELL, oldest_p, newest_p, prof_p);

   if (open_buys > 0 || open_sells > 0)
      return; // Primary position already running; layering engine manages extensions

   // Fetch EMA 50 trend backbone
   double ema50_buf[];
   ArraySetAsSeries(ema50_buf, true);
   if (CopyBuffer(h_ema50, 0, 0, 2, ema50_buf) < 2) return;
   double ema50_val = ema50_buf[1];

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if (CopyRates(_Symbol, _Period, 0, 2, rates) < 2) return;
   double prev_close = rates[1].close;

   bool signal_buy = false;
   bool signal_sell = false;
   double qml_lvl = 0.0, head_lvl = 0.0;

   // Quasimodo Scan
   bool qm_buy = false, qm_sell = false;
   ScanQuasimodoSetup(qm_buy, qm_sell, qml_lvl, head_lvl);

   // BBMA Re-entry Scan
   bool bbma_buy = false, bbma_sell = false;
   CheckBBMAREM(bbma_buy, bbma_sell, ema50_val);

   // Enforce EMA 50 Trend Backbone:
   // If price > EMA 50 -> Bullish regime. Sells are STRICTLY FORBIDDEN.
   // If price < EMA 50 -> Bearish regime. Buys are STRICTLY FORBIDDEN.
   if (InpUseEMATrendFilter)
   {
      if (prev_close > ema50_val)
      {
         qm_sell = false;
         bbma_sell = false;
      }
      else if (prev_close < ema50_val)
      {
         qm_buy = false;
         bbma_buy = false;
      }
   }

   // Evaluate Selected Strategy
   switch (InpStrategyMode)
   {
      case STRAT_QM_SNIPER:
         if (qm_buy) signal_buy = true;
         if (qm_sell) signal_sell = true;
         break;

      case STRAT_QM_AO_CONFLUENCE:
         if (qm_buy && CheckAOMomentum(true)) signal_buy = true;
         if (qm_sell && CheckAOMomentum(false)) signal_sell = true;
         break;

      case STRAT_BBMA_REM:
         if (bbma_buy) signal_buy = true;
         if (bbma_sell) signal_sell = true;
         break;

      case STRAT_HYBRID_CHAMPION:
         // Champion confluence: (QM OR BBMA Re-entry) + AO momentum alignment
         if ((qm_buy || bbma_buy) && CheckAOMomentum(true)) signal_buy = true;
         if ((qm_sell || bbma_sell) && CheckAOMomentum(false)) signal_sell = true;
         break;
   }

   double lot = CalculateDanialLot();
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if (signal_buy)
   {
      double sl = ask - (InpStopLossPoints * _Point);
      if (head_lvl > 0.0 && head_lvl < ask && (ask - head_lvl) / _Point <= (InpStopLossPoints * 1.5))
      {
         sl = head_lvl - (InpSLHeadBufferPoints * _Point);
      }

      double tp = ask + (InpTakeProfitPoints * _Point);

      if (m_trade.Buy(lot, _Symbol, ask, sl, tp, StringFormat("%s_Primary", InpTradeComment)))
      {
         PrintFormat("PRIMARY BUY OPENED! Model: %d, Lot: %.2f, SL: %.2f, TP: %.2f", InpStrategyMode, lot, sl, tp);
      }
   }
   else if (signal_sell)
   {
      double sl = bid + (InpStopLossPoints * _Point);
      if (head_lvl > 0.0 && head_lvl > bid && (head_lvl - bid) / _Point <= (InpStopLossPoints * 1.5))
      {
         sl = head_lvl + (InpSLHeadBufferPoints * _Point);
      }

      double tp = bid - (InpTakeProfitPoints * _Point);

      if (m_trade.Sell(lot, _Symbol, bid, sl, tp, StringFormat("%s_Primary", InpTradeComment)))
      {
         PrintFormat("PRIMARY SELL OPENED! Model: %d, Lot: %.2f, SL: %.2f, TP: %.2f", InpStrategyMode, lot, sl, tp);
      }
   }
}
//+------------------------------------------------------------------+
