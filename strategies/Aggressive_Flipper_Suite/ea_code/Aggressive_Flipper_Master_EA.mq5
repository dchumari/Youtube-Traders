//+------------------------------------------------------------------+
//|                                  Aggressive_Flipper_Master_EA.mq5|
//|               Quantitative Account-Flipper Master Strategy Suite |
//|   Incorporating the 10 Real-World Flipper Behavioral Patterns:   |
//|   1. Micro-Ticket Burst Spamming (Multi-Order Entry Basket)      |
//|   2. 5-Stage Multi-TP Laddering (TP1 - TP5 Staggered Harvest)    |
//|   3. Floating Margin Re-Spamming (Velocity Layer Pyramiding)     |
//|   4. The "Traceback" Engine (Pullback Micro-Scalp + HL Reload)   |
//|   5. Stepped Breakeven Shield (Cascading Zero-Risk Math)         |
//|   6. London & New York Killzone Velocity Synchronization         |
//|   7. Liquidity Sweep & Rejection Wick Invalidation Sniping       |
//|   8. Opposing Momentum Exhaustion Dump (Atomic Basket Wipe)      |
//|   9. Asymmetric Account Flip Milestones ($100 -> $1K -> $10K)   |
//|  10. Interactive On-Chart Visual Roadmap & HUD Dashboard         |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/dchumari/Youtube-Traders"
#property version   "2.00"
#property description "Aggressive Account-Flipper Master Suite with On-Chart Visual Roadmap"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_LOT_MODE
{
   LOT_FIXED_PER_TICKET,    // Fixed Lot Size per Micro-Ticket
   LOT_DYNAMIC_TIER_STEP    // Dynamic Tiered Compounding ($25/0.01 lot)
};

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== Strategy Identification & Architecture ==="
input ulong                InpMagicNumber            = 882200;       // EA Magic Number
input string               InpTradeComment           = "FlipperMaster"; // Base Trade Comment

input group "=== Pattern 1: Micro-Ticket Cluster Spamming ==="
input ENUM_LOT_MODE        InpLotMode                = LOT_DYNAMIC_TIER_STEP; // Sizing Mode
input double               InpFixedLotPerTicket      = 0.01;         // Fixed Lot per Micro-Ticket
input double               InpEquityPerMinLot        = 25.0;         // Account Equity ($) per 0.01 Lot
input int                  InpSpamTicketsCount       = 6;            // Initial Spam Tickets Count (e.g. 6x micro-orders)
input double               InpMaxLotPerTicket        = 0.50;         // Maximum Lot Cap per Ticket

input group "=== Pattern 2: 5-Stage Multi-TP Laddering (Points) ==="
input int                  InpStopLossPoints         = 200;          // Sniper Stop Loss (20 pips)
input int                  InpTP1_Points             = 200;          // TP1: Harvest 20% of tickets (+20 pips)
input int                  InpTP2_Points             = 350;          // TP2: Harvest 25% + Move SL to Breakeven (+35 pips)
input int                  InpTP3_Points             = 600;          // TP3: Harvest 25% + Lock +25 pips (+60 pips)
input int                  InpTP4_Points             = 1000;         // TP4: Harvest 20% (+100 pips)
input int                  InpTP5_Points             = 1600;         // TP5: 10% Runner Expansion Target (+160 pips)

input group "=== Pattern 3 & 5: Reload Pyramiding & Breakeven Shield ==="
input bool                 InpEnableReloadPyramid    = true;         // Enable Floating Margin Re-Spamming
input int                  InpMaxPyramidLayers       = 4;            // Max Pyramiding Layers
input int                  InpReloadStepPoints       = 300;          // Profit Distance (Pts) to Trigger Reload (30 pips)
input int                  InpReloadTicketsCount     = 3;            // Micro-Tickets per Reload Layer
input int                  InpBreakevenBufferPts     = 10;           // Breakeven Buffer Points (+1.0 pip)
input bool                 InpSteppedTrailLock       = true;         // Cascade Trailing Stop into Locked Profits

input group "=== Pattern 4: The 'Traceback' Engine (Pullback Scalp) ==="
input bool                 InpEnableTraceback        = true;         // Enable Pullback Counter-Scalp & Trend Reload
input int                  InpTracebackExtensionPts  = 350;          // Min Extension from EMA 50 to look for Traceback
input double               InpTracebackWickRatio     = 0.38;         // Rejection Wick % to trigger Traceback Scalp
input int                  InpTracebackTP_Points     = 180;          // Traceback Quick TP (18 pips to Higher Low)
input int                  InpTracebackSL_Points     = 150;          // Traceback Tight SL (15 pips)
input bool                 InpReloadHeavyAtHL        = true;         // Slam Continuation Buys on Traceback Close

input group "=== Pattern 6 & 7: Market Invalidation & Killzones ==="
input int                  InpSwingLookback          = 25;           // Swing High / Low Lookback Bars
input double               InpMinRejectionWickPct    = 0.35;         // Minimum Primary Entry Wick Rejection %
input int                  InpEMA50Period            = 50;           // Trend Backbone EMA Period
input bool                 InpUseKillzones           = true;         // Restrict Entries to High-Velocity Killzones
input int                  InpLondonStartHour        = 7;            // London Killzone Start (07:00 UTC)
input int                  InpLondonEndHour          = 11;           // London Killzone End (11:00 UTC)
input int                  InpNYStartHour            = 12;           // New York Overlap Start (12:30 UTC -> 12)
input int                  InpNYEndHour              = 17;           // New York Overlap End (17:00 UTC)
input int                  InpMaxSpreadPoints        = 45;           // Max Allowable Spread Points
input bool                 InpDumpOnExhaustion       = true;         // Pattern 8: Dump Basket on Opposing Exhaustion

input group "=== Pattern 9: Account Flip Milestones ($100 -> $10,000) ==="
input bool                 InpAccountFlipMode        = true;         // Enable Milestone Account Flip Mode
input double               InpTargetEquity           = 1000.0;       // Target Equity Cashout ($1,000 / $10,000)
input bool                 InpLockMilestoneProfits   = true;         // Auto-liquidate basket when milestone reached

input group "=== Pattern 10: Interactive On-Chart Visual Roadmap & HUD ==="
input bool                 InpEnableVisualRoadmap    = true;         // Enable On-Chart Graphical Visualizer
input bool                 InpApplyDraculaTheme      = true;         // Apply Clean Dracula Dark Palette (#282A36)
input bool                 InpDrawPositionBoxes      = true;         // Draw TradingView-Style Position Zones
input bool                 InpDrawTPLines            = true;         // Draw TP1-TP5 & Breakeven Ladder Lines
input bool                 InpDrawSwingLabels        = true;         // Draw [HH] Higher High & [HL] Higher Low Labels
input bool                 InpShowHUDDashboard       = true;         // Show Interactive Top-Left Status HUD

//+------------------------------------------------------------------+
//| Global Variables & Objects                                       |
//+------------------------------------------------------------------+
CTrade         m_trade;
CPositionInfo  m_position;

int            h_ema50;
datetime       last_bar_time = 0;
int            current_pyramid_layer = 1;
double         last_layer_entry_price = 0.0;
bool           be_locked_active = false;
int            traceback_ticket = 0;

#define VIZ_PREFIX "AFM_"
#define COLOR_DRACULA_BG     (color)C'40,42,54'     // #282A36
#define COLOR_LIME_WIN       (color)C'80,250,123'   // #50FA7B Dracula Lime
#define COLOR_CORAL_LOSS     (color)C'255,85,85'    // #FF5555 Dracula Red
#define COLOR_CYAN_BE        (color)C'139,233,253'  // #8BE9FD Dracula Cyan
#define COLOR_PURPLE_ACCENT  (color)C'189,147,249'  // #BD93F9 Dracula Purple
#define COLOR_ORANGE_RUNNER  (color)C'255,184,108'  // #FFB86C Dracula Orange
#define COLOR_YELLOW_TP      (color)C'241,250,140'  // #F1FA8C Dracula Yellow
#define COLOR_WHITE_TEXT     (color)C'248,248,242'  // #F8F8F2 Off-white

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(_Symbol);

   h_ema50 = iMA(_Symbol, _Period, InpEMA50Period, 0, MODE_EMA, PRICE_CLOSE);
   if(h_ema50 == INVALID_HANDLE)
   {
      Print("Failed to create EMA 50 handle");
      return INIT_FAILED;
   }

   if(InpEnableVisualRoadmap && InpApplyDraculaTheme)
   {
      ApplyDraculaTheme();
   }

   Print("Aggressive Flipper Master EA initialized successfully on ", _Symbol);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(h_ema50);
   if(InpEnableVisualRoadmap)
   {
      ObjectsDeleteAll(0, VIZ_PREFIX);
      ChartRedraw(0);
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check Milestone Flip Target Cashout
   if(InpAccountFlipMode && AccountInfoDouble(ACCOUNT_EQUITY) >= InpTargetEquity)
   {
      Print("🎯 ACCOUNT FLIP TARGET HIT ($", InpTargetEquity, ")! Liquidating all positions atomically!");
      CloseAllPositions();
      UpdateHUD("TARGET CASHED OUT! FLIP ACHIEVED!");
      return;
   }

   // Manage Active Multi-TP Laddering & Stepped Breakeven Shield
   ManageMultiTPLaddering();

   // Check Floating Margin Reload Pyramiding
   if(InpEnableReloadPyramid)
   {
      CheckReloadPyramiding();
   }

   // Manage Traceback Scalp Exits
   ManageTracebackPosition();

   // Bar-by-bar Setup Checks
   datetime current_bar = iTime(_Symbol, _Period, 0);
   if(current_bar != last_bar_time)
   {
      last_bar_time = current_bar;
      
      // Update Chart Structure Visuals
      if(InpEnableVisualRoadmap && InpDrawSwingLabels)
      {
         DetectAndDrawStructurePoints();
      }

      // Check Primary Setup Triggers
      CheckPrimaryEntrySignals();

      // Check Opposing Exhaustion Dump
      if(InpDumpOnExhaustion)
      {
         CheckOpposingExhaustionDump();
      }
   }

   // Update HUD Dashboard
   if(InpEnableVisualRoadmap && InpShowHUDDashboard)
   {
      UpdateHUDDashboard();
   }
}

//+------------------------------------------------------------------+
//| Sizing Calculator: Micro-Ticket Lot Calculation                  |
//+------------------------------------------------------------------+
double CalculateMicroTicketLot()
{
   if(InpLotMode == LOT_FIXED_PER_TICKET)
      return InpFixedLotPerTicket;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   int steps = (int)MathFloor(equity / InpEquityPerMinLot);
   if(steps < 1) steps = 1;

   double base_total_lot = steps * 0.01;
   double lot_per_ticket = base_total_lot / InpSpamTicketsCount;

   // Normalize
   double step_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot  = MathMin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), InpMaxLotPerTicket);

   if(step_lot > 0)
      lot_per_ticket = MathFloor(lot_per_ticket / step_lot) * step_lot;

   if(lot_per_ticket < min_lot) lot_per_ticket = min_lot;
   if(lot_per_ticket > max_lot) lot_per_ticket = max_lot;

   return NormalizeDouble(lot_per_ticket, 2);
}

//+------------------------------------------------------------------+
//| Pattern 6: Killzone Filter Check                                 |
//+------------------------------------------------------------------+
bool IsInKillzone()
{
   if(!InpUseKillzones) return true;

   MqlDateTime dt;
   TimeCurrent(dt);
   int h = dt.hour;

   // London Killzone (07:00 - 11:00 UTC)
   if(h >= InpLondonStartHour && h < InpLondonEndHour) return true;

   // New York Overlap Killzone (12:00 - 17:00 UTC)
   if(h >= InpNYStartHour && h < InpNYEndHour) return true;

   return false;
}

//+------------------------------------------------------------------+
//| Pattern 1 & 7: Check Primary Entry Signals                       |
//+------------------------------------------------------------------+
void CheckPrimaryEntrySignals()
{
   // Only open primary baskets if no active primary trades exist
   if(GetPrimaryPositionsCount() > 0) return;

   // Check Spread
   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpreadPoints) return;

   // Check Killzone
   if(!IsInKillzone()) return;

   // Fetch Candle & EMA Data
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, InpSwingLookback + 5, rates) < InpSwingLookback + 5) return;

   double ema_val[];
   ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(h_ema50, 0, 0, 5, ema_val) < 5) return;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double high1  = rates[1].high;
   double low1   = rates[1].low;
   double open1  = rates[1].open;
   double close1 = rates[1].close;
   double total_range = high1 - low1;
   if(total_range < 50 * point) return;

   // Calculate Swing High and Low
   double swing_high = -1.0;
   double swing_low  = 9999999.0;
   for(int i = 2; i <= InpSwingLookback; i++)
   {
      if(rates[i].high > swing_high) swing_high = rates[i].high;
      if(rates[i].low < swing_low)   swing_low  = rates[i].low;
   }

   // --- BULLISH SETUP: Swept Swing Low + Lower Rejection Wick >= 35% + Price > EMA 50 ---
   double lower_wick = MathMin(open1, close1) - low1;
   double lower_wick_ratio = lower_wick / total_range;

   if(low1 < swing_low && close1 > swing_low && lower_wick_ratio >= InpMinRejectionWickPct && close1 > ema_val[1])
   {
      Print("🔥 BULLISH SNIPER TRIGGER: Swept Swing Low (", swing_low, ") with ", DoubleToString(lower_wick_ratio*100, 1), "% Rejection Wick!");
      ExecuteSpamBasket(ORDER_TYPE_BUY, InpSpamTicketsCount, CalculateMicroTicketLot(), InpStopLossPoints);
      return;
   }

   // --- BEARISH SETUP: Swept Swing High + Upper Rejection Wick >= 35% + Price < EMA 50 ---
   double upper_wick = high1 - MathMax(open1, close1);
   double upper_wick_ratio = upper_wick / total_range;

   if(high1 > swing_high && close1 < swing_high && upper_wick_ratio >= InpMinRejectionWickPct && close1 < ema_val[1])
   {
      Print("🔥 BEARISH SNIPER TRIGGER: Swept Swing High (", swing_high, ") with ", DoubleToString(upper_wick_ratio*100, 1), "% Rejection Wick!");
      ExecuteSpamBasket(ORDER_TYPE_SELL, InpSpamTicketsCount, CalculateMicroTicketLot(), InpStopLossPoints);
      return;
   }

   // --- PATTERN 4: THE TRACEBACK ENGINE ---
   if(InpEnableTraceback && traceback_ticket == 0)
   {
      CheckTracebackPullbackTrigger(rates, ema_val, point, total_range, upper_wick_ratio, lower_wick_ratio);
   }
}

//+------------------------------------------------------------------+
//| Pattern 4: Traceback Trigger (Counter-Trend Exhaustion Scalp)    |
//+------------------------------------------------------------------+
void CheckTracebackPullbackTrigger(const MqlRates &rates[], const double &ema_val[], double point, double total_range, double upper_wick_ratio, double lower_wick_ratio)
{
   double close1 = rates[1].close;
   double dist_from_ema = MathAbs(close1 - ema_val[1]) / point;

   // Overextended in Uptrend (Close > EMA 50 by Extension Points) + Upper Rejection Wick >= 38%
   if(close1 > ema_val[1] && dist_from_ema >= InpTracebackExtensionPts && upper_wick_ratio >= InpTracebackWickRatio)
   {
      Print("⚡ TRACEBACK SELL SCALP: Uptrend extended by ", (int)dist_from_ema, " pts! Taking quick counter-scalp to Higher Low.");
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl  = bid + (InpTracebackSL_Points * point);
      double tp  = bid - (InpTracebackTP_Points * point);

      m_trade.SetExpertMagicNumber(InpMagicNumber + 99); // Magic 99 for Traceback
      if(m_trade.Sell(0.02, _Symbol, bid, sl, tp, "Traceback_Scalp"))
      {
         traceback_ticket = (int)m_trade.ResultOrder();
         if(InpEnableVisualRoadmap)
         {
            DrawTracebackRoadmap(bid, tp, sl, ORDER_TYPE_SELL);
         }
      }
      m_trade.SetExpertMagicNumber(InpMagicNumber);
   }
   // Overextended in Downtrend (Close < EMA 50 by Extension Points) + Lower Rejection Wick >= 38%
   else if(close1 < ema_val[1] && dist_from_ema >= InpTracebackExtensionPts && lower_wick_ratio >= InpTracebackWickRatio)
   {
      Print("⚡ TRACEBACK BUY SCALP: Downtrend extended by ", (int)dist_from_ema, " pts! Taking quick counter-scalp to Lower High.");
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl  = ask - (InpTracebackSL_Points * point);
      double tp  = ask + (InpTracebackTP_Points * point);

      m_trade.SetExpertMagicNumber(InpMagicNumber + 99);
      if(m_trade.Buy(0.02, _Symbol, ask, sl, tp, "Traceback_Scalp"))
      {
         traceback_ticket = (int)m_trade.ResultOrder();
         if(InpEnableVisualRoadmap)
         {
            DrawTracebackRoadmap(ask, tp, sl, ORDER_TYPE_BUY);
         }
      }
      m_trade.SetExpertMagicNumber(InpMagicNumber);
   }
}

//+------------------------------------------------------------------+
//| Manage Traceback Position & Trigger Continuation Reload at HL/LH |
//+------------------------------------------------------------------+
void ManageTracebackPosition()
{
   if(traceback_ticket == 0) return;

   bool is_open = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Magic() == InpMagicNumber + 99)
         {
            is_open = true;
            break;
         }
      }
   }

   // If traceback closed (hit TP at Higher Low support), SLAM CONTINUATION BUYS!
   if(!is_open)
   {
      Print("🎯 TRACEBACK SCALP CLOSED (Higher Low Support reached)! Triggering HEAVY CONTINUATION RELOAD!");
      traceback_ticket = 0;

      if(InpReloadHeavyAtHL && GetPrimaryPositionsCount() == 0 && IsInKillzone())
      {
         // Verify EMA 50 trend alignment
         double ema_val[];
         ArraySetAsSeries(ema_val, true);
         CopyBuffer(h_ema50, 0, 0, 2, ema_val);
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

         if(bid > ema_val[0])
         {
            Print("🚀 SLAMMING TREND CONTINUATION BUYS AT CONFIRMED HIGHER LOW!");
            ExecuteSpamBasket(ORDER_TYPE_BUY, InpSpamTicketsCount, CalculateMicroTicketLot(), InpStopLossPoints);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Pattern 1: Execute Micro-Ticket Spam Basket                      |
//+------------------------------------------------------------------+
void ExecuteSpamBasket(ENUM_ORDER_TYPE order_type, int ticket_count, double lot_per_ticket, int sl_points)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entry_price = (order_type == ORDER_TYPE_BUY) ? ask : bid;
   double sl_price = (order_type == ORDER_TYPE_BUY) ? entry_price - (sl_points * point) : entry_price + (sl_points * point);

   current_pyramid_layer = 1;
   last_layer_entry_price = entry_price;
   be_locked_active = false;

   Print("⚡ SPAMMING ", ticket_count, " MICRO-ORDERS at ", entry_price, " (Lot: ", lot_per_ticket, " per ticket)!");

   for(int i = 1; i <= ticket_count; i++)
   {
      string comment = StringFormat("Flp_L1_T%d", i);
      if(order_type == ORDER_TYPE_BUY)
      {
         m_trade.Buy(lot_per_ticket, _Symbol, ask, sl_price, 0.0, comment);
      }
      else
      {
         m_trade.Sell(lot_per_ticket, _Symbol, bid, sl_price, 0.0, comment);
      }
   }

   // Pattern 10: Draw Initial Visual Roadmap on Chart
   if(InpEnableVisualRoadmap)
   {
      DrawBasketVisualRoadmap(entry_price, order_type, sl_price);
   }
}

//+------------------------------------------------------------------+
//| Pattern 2 & 5: Manage Multi-TP Laddering & Stepped Breakeven     |
//+------------------------------------------------------------------+
void ManageMultiTPLaddering()
{
   int total_primary = 0;
   double total_pnl = 0.0;
   ENUM_POSITION_TYPE pos_type = POSITION_TYPE_BUY;
   double entry_price = 0.0;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double current_price = 0.0;

   // Tally active positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Magic() == InpMagicNumber && m_position.Symbol() == _Symbol)
         {
            total_primary++;
            total_pnl += m_position.Profit() + m_position.Swap();
            pos_type = m_position.PositionType();
            entry_price = m_position.PriceOpen();
         }
      }
   }

   if(total_primary == 0) return;

   current_price = (pos_type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double profit_points = (pos_type == POSITION_TYPE_BUY) ? (current_price - entry_price) / point : (entry_price - current_price) / point;

   // --- STEP 1: TP1 Hit (+20 pips) -> Harvest Ticket 1 & 2 (20-30%) ---
   if(profit_points >= InpTP1_Points)
   {
      CloseSpecificTickets(1, 1); // Close Ticket 1
   }

   // --- STEP 2: TP2 Hit (+35 pips) -> Harvest Ticket 3 & Move ALL SL to Breakeven (+10 pts) ---
   if(profit_points >= InpTP2_Points)
   {
      CloseSpecificTickets(2, 2); // Close Ticket 2
      if(!be_locked_active)
      {
         MoveBasketStopLoss(entry_price, pos_type, InpBreakevenBufferPts);
         be_locked_active = true;
         Print("🛡️ STEPPED SHIELD: TP2 Hit (+35 pips)! Moved all remaining basket positions to Breakeven (+1.0 pip)!");
         if(InpEnableVisualRoadmap)
         {
            UpdateBELineVisual(entry_price, pos_type, InpBreakevenBufferPts);
         }
      }
   }

   // --- STEP 3: TP3 Hit (+60 pips) -> Harvest Ticket 4 & Lock +25 pips Profit ---
   if(profit_points >= InpTP3_Points)
   {
      CloseSpecificTickets(3, 3);
      if(InpSteppedTrailLock)
      {
         MoveBasketStopLoss(entry_price, pos_type, 250); // Lock +250 points profit
      }
   }

   // --- STEP 4: TP4 Hit (+100 pips) -> Harvest Ticket 5 & Lock +60 pips Profit ---
   if(profit_points >= InpTP4_Points)
   {
      CloseSpecificTickets(4, 4);
      if(InpSteppedTrailLock)
      {
         MoveBasketStopLoss(entry_price, pos_type, 600); // Lock +600 points profit
      }
   }

   // --- STEP 5: TP5 Hit (+160 pips) -> Final Runner Target Harvest ---
   if(profit_points >= InpTP5_Points)
   {
      Print("🏆 MOONSHOT TP5 HIT (+160 pips)! Banking final runner positions!");
      CloseAllPositions();
   }
}

//+------------------------------------------------------------------+
//| Close Specific Tickets in Basket                                 |
//+------------------------------------------------------------------+
void CloseSpecificTickets(int min_t_index, int max_t_index)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Magic() == InpMagicNumber && m_position.Symbol() == _Symbol)
         {
            string comment = m_position.Comment();
            for(int t = min_t_index; t <= max_t_index; t++)
            {
               string target_str = StringFormat("T%d", t);
               if(StringFind(comment, target_str) >= 0)
               {
                  Print("💰 HARVESTING TICKET ", comment, " at target profit!");
                  m_trade.PositionClose(m_position.Ticket());
                  break;
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Move Basket Stop Loss (Stepped Breakeven & Trailing Lock)        |
//+------------------------------------------------------------------+
void MoveBasketStopLoss(double base_entry, ENUM_POSITION_TYPE pos_type, int buffer_points)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double new_sl = (pos_type == POSITION_TYPE_BUY) ? base_entry + (buffer_points * point) : base_entry - (buffer_points * point);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Magic() == InpMagicNumber && m_position.Symbol() == _Symbol)
         {
            double cur_sl = m_position.StopLoss();
            if(pos_type == POSITION_TYPE_BUY)
            {
               if(cur_sl < new_sl) m_trade.PositionModify(m_position.Ticket(), new_sl, m_position.TakeProfit());
            }
            else
            {
               if(cur_sl > new_sl || cur_sl == 0.0) m_trade.PositionModify(m_position.Ticket(), new_sl, m_position.TakeProfit());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Pattern 3: Check Floating Margin Reload Pyramiding               |
//+------------------------------------------------------------------+
void CheckReloadPyramiding()
{
   if(current_pyramid_layer >= InpMaxPyramidLayers) return;
   if(!be_locked_active) return; // Only reload once prior layers are 100% risk-free!

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   ENUM_POSITION_TYPE pos_type;
   if(!GetPrimaryBasketType(pos_type)) return;

   double current_price = (pos_type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double dist_points = (pos_type == POSITION_TYPE_BUY) ? (current_price - last_layer_entry_price) / point : (last_layer_entry_price - current_price) / point;

   if(dist_points >= InpReloadStepPoints)
   {
      current_pyramid_layer++;
      last_layer_entry_price = current_price;
      Print("⚡ PYRAMID RELOAD LAYER ", current_pyramid_layer, " TRIGGERED (+", (int)dist_points, " pts continuation)! Spamming ", InpReloadTicketsCount, " orders!");

      ENUM_ORDER_TYPE otype = (pos_type == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double sl_price = (pos_type == POSITION_TYPE_BUY) ? current_price - (InpStopLossPoints * point) : current_price + (InpStopLossPoints * point);

      for(int i = 1; i <= InpReloadTicketsCount; i++)
      {
         string comment = StringFormat("Flp_L%d_T%d", current_pyramid_layer, i);
         if(otype == ORDER_TYPE_BUY)
            m_trade.Buy(CalculateMicroTicketLot(), _Symbol, current_price, sl_price, 0.0, comment);
         else
            m_trade.Sell(CalculateMicroTicketLot(), _Symbol, current_price, sl_price, 0.0, comment);
      }
   }
}

//+------------------------------------------------------------------+
//| Pattern 8: Opposing Momentum Exhaustion Dump                     |
//+------------------------------------------------------------------+
void CheckOpposingExhaustionDump()
{
   if(GetPrimaryPositionsCount() == 0) return;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 3, rates) < 3) return;

   double total_range = rates[1].high - rates[1].low;
   if(total_range <= 0) return;

   ENUM_POSITION_TYPE basket_type;
   if(!GetPrimaryBasketType(basket_type)) return;

   // If holding BUYS and candle forms a massive UPPER REJECTION WICK >= 45% at resistance
   if(basket_type == POSITION_TYPE_BUY)
   {
      double upper_wick = rates[1].high - MathMax(rates[1].open, rates[1].close);
      if(upper_wick / total_range >= 0.45 && rates[1].close < rates[1].open)
      {
         Print("🚨 OPPOSING EXHAUSTION DUMP: Upper Rejection Wick (", DoubleToString((upper_wick/total_range)*100, 1), "%) formed! Dumping basket to protect profits!");
         CloseAllPositions();
      }
   }
   // If holding SELLS and candle forms a massive LOWER REJECTION WICK >= 45% at support
   else if(basket_type == POSITION_TYPE_SELL)
   {
      double lower_wick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
      if(lower_wick / total_range >= 0.45 && rates[1].close > rates[1].open)
      {
         Print("🚨 OPPOSING EXHAUSTION DUMP: Lower Rejection Wick (", DoubleToString((lower_wick/total_range)*100, 1), "%) formed! Dumping basket to protect profits!");
         CloseAllPositions();
      }
   }
}

//+------------------------------------------------------------------+
//| Close All Positions Atomically                                   |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if((m_position.Magic() == InpMagicNumber || m_position.Magic() == InpMagicNumber + 99) && m_position.Symbol() == _Symbol)
         {
            m_trade.PositionClose(m_position.Ticket());
         }
      }
   }
   be_locked_active = false;
   current_pyramid_layer = 1;
}

//+------------------------------------------------------------------+
//| Helper Queries                                                   |
//+------------------------------------------------------------------+
int GetPrimaryPositionsCount()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Magic() == InpMagicNumber && m_position.Symbol() == _Symbol)
            count++;
      }
   }
   return count;
}

bool GetPrimaryBasketType(ENUM_POSITION_TYPE &ptype)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Magic() == InpMagicNumber && m_position.Symbol() == _Symbol)
         {
            ptype = m_position.PositionType();
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Pattern 10: On-Chart Visual Roadmap & Dracula Styling            |
//+------------------------------------------------------------------+
void ApplyDraculaTheme()
{
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, COLOR_DRACULA_BG);
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, COLOR_WHITE_TEXT);
   ChartSetInteger(0, CHART_COLOR_CHART_UP, COLOR_LIME_WIN);
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, COLOR_CORAL_LOSS);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, COLOR_LIME_WIN);
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, COLOR_PURPLE_ACCENT);
   ChartRedraw(0);
}

void DrawBasketVisualRoadmap(double entry, ENUM_ORDER_TYPE otype, double sl)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   datetime t_now = TimeCurrent();
   datetime t_end = t_now + PeriodSeconds(_Period) * 30;

   // 1. Draw Position Box
   string box_name = StringFormat("%sBox_%d", VIZ_PREFIX, (int)t_now);
   double tp_top = (otype == ORDER_TYPE_BUY) ? entry + (InpTP5_Points * point) : entry - (InpTP5_Points * point);
   
   ObjectCreate(0, box_name, OBJ_RECTANGLE, 0, t_now, entry, t_end, tp_top);
   ObjectSetInteger(0, box_name, OBJPROP_COLOR, COLOR_LIME_WIN);
   ObjectSetInteger(0, box_name, OBJPROP_BGCOLOR, (otype == ORDER_TYPE_BUY) ? (color)C'28,60,38' : (color)C'65,24,28');
   ObjectSetInteger(0, box_name, OBJPROP_BACK, true);

   // 2. Draw TP Ladder Lines
   if(InpDrawTPLines)
   {
      DrawHorizontalRoadmapLine(entry, (otype == ORDER_TYPE_BUY) ? entry + (InpTP1_Points * point) : entry - (InpTP1_Points * point), "TP1 (+20p)", COLOR_YELLOW_TP, t_now, t_end);
      DrawHorizontalRoadmapLine(entry, (otype == ORDER_TYPE_BUY) ? entry + (InpTP2_Points * point) : entry - (InpTP2_Points * point), "TP2 (+35p BE)", COLOR_CYAN_BE, t_now, t_end);
      DrawHorizontalRoadmapLine(entry, (otype == ORDER_TYPE_BUY) ? entry + (InpTP3_Points * point) : entry - (InpTP3_Points * point), "TP3 (+60p Lock)", COLOR_LIME_WIN, t_now, t_end);
      DrawHorizontalRoadmapLine(entry, (otype == ORDER_TYPE_BUY) ? entry + (InpTP4_Points * point) : entry - (InpTP4_Points * point), "TP4 (+100p)", COLOR_ORANGE_RUNNER, t_now, t_end);
      DrawHorizontalRoadmapLine(entry, (otype == ORDER_TYPE_BUY) ? entry + (InpTP5_Points * point) : entry - (InpTP5_Points * point), "TP5 (+160p Runner)", COLOR_PURPLE_ACCENT, t_now, t_end);
   }

   ChartRedraw(0);
}

void DrawHorizontalRoadmapLine(double entry, double price, string label, color clr, datetime t1, datetime t2)
{
   string line_name = StringFormat("%sLine_%s_%d", VIZ_PREFIX, label, (int)t1);
   ObjectCreate(0, line_name, OBJ_TREND, 0, t1, price, t2, price);
   ObjectSetInteger(0, line_name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, line_name, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, line_name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, line_name, OBJPROP_RAY_RIGHT, true);

   string txt_name = StringFormat("%sTxt_%s_%d", VIZ_PREFIX, label, (int)t1);
   ObjectCreate(0, txt_name, OBJ_TEXT, 0, t2, price);
   ObjectSetString(0, txt_name, OBJPROP_TEXT, "  " + label);
   ObjectSetInteger(0, txt_name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, txt_name, OBJPROP_FONTSIZE, 9);
}

void UpdateBELineVisual(double entry, ENUM_POSITION_TYPE ptype, int buffer_pts)
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double be_price = (ptype == POSITION_TYPE_BUY) ? entry + (buffer_pts * point) : entry - (buffer_pts * point);

   string line_name = StringFormat("%sBE_SHIELD", VIZ_PREFIX);
   datetime t_now = TimeCurrent();
   datetime t_end = t_now + PeriodSeconds(_Period) * 50;

   ObjectDelete(0, line_name);
   ObjectCreate(0, line_name, OBJ_TREND, 0, t_now - 3600, be_price, t_end, be_price);
   ObjectSetInteger(0, line_name, OBJPROP_COLOR, COLOR_CYAN_BE);
   ObjectSetInteger(0, line_name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, line_name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, line_name, OBJPROP_RAY_RIGHT, true);
}

void DrawTracebackRoadmap(double entry, double tp, double sl, ENUM_ORDER_TYPE otype)
{
   datetime t_now = TimeCurrent();
   string txt_name = StringFormat("%sTraceback_%d", VIZ_PREFIX, (int)t_now);
   ObjectCreate(0, txt_name, OBJ_TEXT, 0, t_now, entry);
   ObjectSetString(0, txt_name, OBJPROP_TEXT, "⚡ TRACEBACK SCALP");
   ObjectSetInteger(0, txt_name, OBJPROP_COLOR, COLOR_ORANGE_RUNNER);
   ObjectSetInteger(0, txt_name, OBJPROP_FONTSIZE, 9);
}

void DetectAndDrawStructurePoints()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 15, rates) < 15) return;

   // Check if Bar 2 is a swing high (Higher High)
   if(rates[2].high > rates[3].high && rates[2].high > rates[1].high && rates[2].high > rates[4].high)
   {
      string name = StringFormat("%sHH_%d", VIZ_PREFIX, (int)rates[2].time);
      if(ObjectFind(0, name) < 0)
      {
         ObjectCreate(0, name, OBJ_TEXT, 0, rates[2].time, rates[2].high + 25 * _Point);
         ObjectSetString(0, name, OBJPROP_TEXT, "[HH]");
         ObjectSetInteger(0, name, OBJPROP_COLOR, COLOR_CORAL_LOSS);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
      }
   }

   // Check if Bar 2 is a swing low (Higher Low)
   if(rates[2].low < rates[3].low && rates[2].low < rates[1].low && rates[2].low < rates[4].low)
   {
      string name = StringFormat("%sHL_%d", VIZ_PREFIX, (int)rates[2].time);
      if(ObjectFind(0, name) < 0)
      {
         ObjectCreate(0, name, OBJ_TEXT, 0, rates[2].time, rates[2].low - 25 * _Point);
         ObjectSetString(0, name, OBJPROP_TEXT, "[HL]");
         ObjectSetInteger(0, name, OBJPROP_COLOR, COLOR_LIME_WIN);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
      }
   }
}

void UpdateHUDDashboard()
{
   int open_tickets = 0;
   double floating_pnl = 0.0;
   string dir = "FLAT";

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if((m_position.Magic() == InpMagicNumber || m_position.Magic() == InpMagicNumber + 99) && m_position.Symbol() == _Symbol)
         {
            open_tickets++;
            floating_pnl += m_position.Profit() + m_position.Swap();
            dir = (m_position.PositionType() == POSITION_TYPE_BUY) ? "BUY BASKET" : "SELL BASKET";
         }
      }
   }

   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double flip_pct = (InpTargetEquity > 0) ? (equity / InpTargetEquity) * 100.0 : 0.0;

   string hud_text = StringFormat(
      "=== AGGRESSIVE FLIPPER MASTER HUD ===\n" +
      "Direction: %s | Open Tickets: %d\n" +
      "Basket Floating PnL: $%.2f\n" +
      "Active Pyramid Layer: L%d / %d\n" +
      "Breakeven Shield: %s\n" +
      "Account Equity: $%.2f (Balance: $%.2f)\n" +
      "Milestone Flip Target: $%.0f (Progress: %.1f%%)",
      dir, open_tickets, floating_pnl,
      current_pyramid_layer, InpMaxPyramidLayers,
      (be_locked_active ? "LOCKED (+1.0p) [RISK-FREE]" : "ARMED"),
      equity, balance, InpTargetEquity, flip_pct
   );

   UpdateHUD(hud_text);
}

void UpdateHUD(string text)
{
   string name = StringFormat("%sHUD", VIZ_PREFIX);
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 25);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, name, OBJPROP_FONT, "Lucida Console");
   }

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, (StringFind(text, "LOCKED") >= 0) ? COLOR_LIME_WIN : COLOR_CYAN_BE);
   ChartRedraw(0);
}
//+------------------------------------------------------------------+
