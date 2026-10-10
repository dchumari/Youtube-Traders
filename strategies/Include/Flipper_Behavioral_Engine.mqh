//+------------------------------------------------------------------+
//|                                  Flipper_Behavioral_Engine.mqh   |
//|               Universal Behavioral Engine for High-Velocity Trading|
//|   Incorporates the 10 Truly Unique Online Flipper Behavioral     |
//|   Patterns into Any Strategy (QM, FVG, Fib 61.8%, Breakouts)     |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/dchumari/Youtube-Traders"
#property version   "3.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Color Palette for Dracula Aesthetic On-Chart Visual Roadmap     |
//+------------------------------------------------------------------+
#define FBE_COLOR_BG_DARK        (color)C'40,42,54'     // #282A36 Dracula Dark Base
#define FBE_COLOR_WIN_LIME       (color)C'80,250,123'   // #50FA7B Dracula Lime Green
#define FBE_COLOR_LOSS_CORAL     (color)C'255,85,85'    // #FF5555 Dracula Coral Red
#define FBE_COLOR_BE_CYAN        (color)C'139,233,253'  // #8BE9FD Dracula Cyan Shield
#define FBE_COLOR_PURPLE         (color)C'189,147,249'  // #BD93F9 Dracula Purple
#define FBE_COLOR_ORANGE         (color)C'255,184,108'  // #FFB86C Dracula Orange Runner
#define FBE_COLOR_YELLOW         (color)C'241,250,140'  // #F1FA8C Dracula Yellow TP1
#define FBE_COLOR_TEXT_WHITE     (color)C'248,248,242'  // #F8F8F2 Crisp Off-White

//+------------------------------------------------------------------+
//| Configuration Structure for Behavioral Engine                    |
//+------------------------------------------------------------------+
struct SFlipperBehavioralConfig
{
   bool   enabled;
   ulong  magicNumber;
   string prefix;
   
   // Pattern 1: Multi-Ticket Slicing
   int    spamTicketsCount;
   double equityPerMinLot;
   double maxLotPerTicket;
   
   // Pattern 2: 5-Stage TP Laddering
   int    stopLossPoints;
   int    tp1Points;
   int    tp2Points;
   int    tp3Points;
   int    tp4Points;
   int    tp5Points;
   
   // Pattern 3: Traceback Engine
   bool   enableTraceback;
   int    tracebackExtensionPts;
   double tracebackWickRatio;
   int    tracebackTPPoints;
   int    tracebackSLPoints;
   bool   reloadAtHL;
   
   // Pattern 4: Floating Margin Pyramiding
   bool   enablePyramiding;
   int    maxPyramidLayers;
   int    reloadStepPoints;
   int    reloadTicketsCount;
   
   // Pattern 5: Margin-Call Spike Catcher
   bool   enableLiquidationSweep;
   double spikeMinWickPct;
   
   // Pattern 6: Pre-London Judas Flush
   bool   enableJudasFlush;
   
   // Pattern 7: Opposing Exhaustion Dump & Flip
   bool   enableDumpAndFlip;
   double dumpWickRatio;
   
   // Pattern 8: Climax Volume Absorption
   bool   enableVolumeClimaxFade;
   double volumeSpikeMultiplier;
   
   // Pattern 9: Milestone Flip Target
   bool   enableFlipMilestone;
   double targetEquity;
   
   // Pattern 10: Visual Roadmap HUD
   bool   enableVisuals;
   bool   applyDraculaTheme;
};

//+------------------------------------------------------------------+
//| Behavioral Engine Execution Class                                |
//+------------------------------------------------------------------+
class CFlipperBehavioralEngine
{
private:
   SFlipperBehavioralConfig m_cfg;
   CTrade                   m_trade;
   CPositionInfo            m_pos;
   
   int                      m_current_layer;
   double                   m_last_layer_entry;
   bool                     m_be_active;
   int                      m_traceback_ticket;
   datetime                 m_last_bar_time;

public:
   CFlipperBehavioralEngine()
   {
      m_current_layer    = 1;
      m_last_layer_entry = 0.0;
      m_be_active        = false;
      m_traceback_ticket = 0;
      m_last_bar_time    = 0;
   }

   void Init(const SFlipperBehavioralConfig &cfg)
   {
      m_cfg = cfg;
      m_trade.SetExpertMagicNumber(m_cfg.magicNumber);
      m_trade.SetMarginMode();
      m_trade.SetTypeFillingBySymbol(_Symbol);

      if(m_cfg.enableVisuals && m_cfg.applyDraculaTheme)
      {
         ApplyTheme();
      }
   }

   void Clean()
   {
      if(m_cfg.enableVisuals)
      {
         ObjectsDeleteAll(0, m_cfg.prefix);
         ChartRedraw(0);
      }
   }

   // --- Pattern 1: Execute Multi-Ticket Spam Basket ---
   bool ExecuteSpamBasket(ENUM_ORDER_TYPE order_type, double base_entry, int sl_points)
   {
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double entry_price = (order_type == ORDER_TYPE_BUY) ? ask : bid;
      double sl_price = (order_type == ORDER_TYPE_BUY) ? entry_price - (sl_points * point) : entry_price + (sl_points * point);

      double lot_per_ticket = CalculateLotPerTicket();
      m_current_layer = 1;
      m_last_layer_entry = entry_price;
      m_be_active = false;

      Print("⚡ BEHAVIORAL PATTERN 1: SPAMMING ", m_cfg.spamTicketsCount, " MICRO-ORDERS at ", entry_price, " (Lot: ", lot_per_ticket, ")!");

      for(int i = 1; i <= m_cfg.spamTicketsCount; i++)
      {
         string comment = StringFormat("Flp_L1_T%d", i);
         if(order_type == ORDER_TYPE_BUY)
            m_trade.Buy(lot_per_ticket, _Symbol, ask, sl_price, 0.0, comment);
         else
            m_trade.Sell(lot_per_ticket, _Symbol, bid, sl_price, 0.0, comment);
      }

      if(m_cfg.enableVisuals)
      {
         DrawBasketVisualRoadmap(entry_price, order_type, sl_price);
      }

      return true;
   }

   // --- Pattern 2 & 5: Manage 5-Stage TP Ladder & Stepped Breakeven Shield ---
   void ManageLadderAndBreakeven()
   {
      int primary_count = 0;
      double total_pnl = 0.0;
      ENUM_POSITION_TYPE ptype = POSITION_TYPE_BUY;
      double entry_price = 0.0;
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(m_pos.SelectByIndex(i))
         {
            if(m_pos.Magic() == m_cfg.magicNumber && m_pos.Symbol() == _Symbol)
            {
               primary_count++;
               total_pnl += m_pos.Profit() + m_pos.Swap();
               ptype = m_pos.PositionType();
               entry_price = m_pos.PriceOpen();
            }
         }
      }

      if(primary_count == 0) return;

      double cur_price = (ptype == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double profit_pts = (ptype == POSITION_TYPE_BUY) ? (cur_price - entry_price) / point : (entry_price - cur_price) / point;

      // Stage 1: TP1 Hit (+20 pips) -> Harvest Ticket 1
      if(profit_pts >= m_cfg.tp1Points)
      {
         CloseSpecificTicket(1);
      }

      // Stage 2: TP2 Hit (+35 pips) -> Harvest Ticket 2 & Move ALL to Breakeven (+1.0 pip)
      if(profit_pts >= m_cfg.tp2Points)
      {
         CloseSpecificTicket(2);
         if(!m_be_active)
         {
            MoveStopLoss(entry_price, ptype, 10);
            m_be_active = true;
            Print("🛡️ BEHAVIORAL PATTERN 5: STEPPED SHIELD ACTIVATED at Breakeven (+1.0 pip)!");
            if(m_cfg.enableVisuals)
            {
               DrawBreakevenShieldLine(entry_price, ptype, 10);
            }
         }
      }

      // Stage 3: TP3 Hit (+60 pips) -> Harvest Ticket 3 & Lock +25 pips Profit
      if(profit_pts >= m_cfg.tp3Points)
      {
         CloseSpecificTicket(3);
         MoveStopLoss(entry_price, ptype, 250);
      }

      // Stage 4: TP4 Hit (+100 pips) -> Harvest Ticket 4 & Lock +60 pips Profit
      if(profit_pts >= m_cfg.tp4Points)
      {
         CloseSpecificTicket(4);
         MoveStopLoss(entry_price, ptype, 600);
      }

      // Stage 5: TP5 Hit (+160 pips) -> Bank Final Moonshot Runner
      if(profit_pts >= m_cfg.tp5Points)
      {
         Print("🏆 BEHAVIORAL PATTERN 2: MOONSHOT TP5 HIT (+160 pips)! Banking all runners!");
         CloseAllPositions();
      }
   }

   // --- Pattern 3: The Traceback Pullback Scalp & Higher Low Trend Reload ---
   void CheckTraceback(double ema_val, const MqlRates &rates[])
   {
      if(!m_cfg.enableTraceback || m_traceback_ticket != 0) return;

      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double close1 = rates[1].close;
      double total_range = rates[1].high - rates[1].low;
      if(total_range < 50 * point) return;

      double dist_from_ema = MathAbs(close1 - ema_val) / point;

      // Overextended in Uptrend + Upper Rejection Wick -> Scalp Retracement
      double upper_wick = rates[1].high - MathMax(rates[1].open, rates[1].close);
      if(close1 > ema_val && dist_from_ema >= m_cfg.tracebackExtensionPts && (upper_wick / total_range) >= m_cfg.tracebackWickRatio)
      {
         Print("⚡ BEHAVIORAL PATTERN 3: TRACEBACK PULLBACK SELL SCALP ACTIVATED!");
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double sl  = bid + (m_cfg.tracebackSLPoints * point);
         double tp  = bid - (m_cfg.tracebackTPPoints * point);

         m_trade.SetExpertMagicNumber(m_cfg.magicNumber + 99);
         double tb_lot = CalculateLotPerTicket();
         if(m_trade.Sell(tb_lot, _Symbol, bid, sl, tp, "Traceback_Scalp"))
            m_traceback_ticket = (int)m_trade.ResultOrder();
         m_trade.SetExpertMagicNumber(m_cfg.magicNumber);
      }
   }

   void ManageTraceback(double ema_val)
   {
      if(m_traceback_ticket == 0) return;

      bool is_open = false;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(m_pos.SelectByIndex(i))
         {
            if(m_pos.Magic() == m_cfg.magicNumber + 99) { is_open = true; break; }
         }
      }

      if(!is_open)
      {
         Print("🎯 BEHAVIORAL PATTERN 3: TRACEBACK HIT HIGHER LOW TARGET! Triggering HEAVY CONTINUATION RELOAD!");
         m_traceback_ticket = 0;
         if(m_cfg.reloadAtHL && GetPrimaryCount() == 0)
         {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            if(bid > ema_val)
               ExecuteSpamBasket(ORDER_TYPE_BUY, bid, m_cfg.stopLossPoints);
         }
      }
   }

   // --- Pattern 4: Floating Margin Pyramiding Reload ---
   void CheckPyramiding()
   {
      if(!m_cfg.enablePyramiding || m_current_layer >= m_cfg.maxPyramidLayers || !m_be_active) return;

      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      ENUM_POSITION_TYPE ptype;
      if(!GetPrimaryType(ptype)) return;

      double cur_price = (ptype == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double dist = (ptype == POSITION_TYPE_BUY) ? (cur_price - m_last_layer_entry) / point : (m_last_layer_entry - cur_price) / point;

      if(dist >= m_cfg.reloadStepPoints)
      {
         m_current_layer++;
         m_last_layer_entry = cur_price;
         Print("⚡ BEHAVIORAL PATTERN 4: PYRAMID RELOAD LAYER ", m_current_layer, " TRIGGERED (+", (int)dist, " pts)! Spamming ", m_cfg.reloadTicketsCount, " orders!");

         ENUM_ORDER_TYPE otype = (ptype == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
         double sl_price = (ptype == POSITION_TYPE_BUY) ? cur_price - (m_cfg.stopLossPoints * point) : cur_price + (m_cfg.stopLossPoints * point);

         for(int i = 1; i <= m_cfg.reloadTicketsCount; i++)
         {
            string comment = StringFormat("Flp_L%d_T%d", m_current_layer, i);
            if(otype == ORDER_TYPE_BUY)
               m_trade.Buy(CalculateLotPerTicket(), _Symbol, cur_price, sl_price, 0.0, comment);
            else
               m_trade.Sell(CalculateLotPerTicket(), _Symbol, cur_price, sl_price, 0.0, comment);
         }
      }
   }

   // --- Pattern 7: Opposing Exhaustion Dump & Flip ---
   void CheckOpposingDumpAndFlip(const MqlRates &rates[])
   {
      if(!m_cfg.enableDumpAndFlip || GetPrimaryCount() == 0) return;

      double total_range = rates[1].high - rates[1].low;
      if(total_range <= 0) return;

      ENUM_POSITION_TYPE ptype;
      if(!GetPrimaryType(ptype)) return;

      // Holding BUYS and an aggressive UPPER REJECTION WICK >= 45% prints at resistance
      if(ptype == POSITION_TYPE_BUY)
      {
         double upper_wick = rates[1].high - MathMax(rates[1].open, rates[1].close);
         if((upper_wick / total_range) >= m_cfg.dumpWickRatio && rates[1].close < rates[1].open)
         {
            Print("🚨 BEHAVIORAL PATTERN 7: OPPOSING EXHAUSTION DUMP & FLIP! Wiping buy basket & entering short!");
            CloseAllPositions();
            ExecuteSpamBasket(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), m_cfg.stopLossPoints);
         }
      }
      else if(ptype == POSITION_TYPE_SELL)
      {
         double lower_wick = MathMin(rates[1].open, rates[1].close) - rates[1].low;
         if((lower_wick / total_range) >= m_cfg.dumpWickRatio && rates[1].close > rates[1].open)
         {
            Print("🚨 BEHAVIORAL PATTERN 7: OPPOSING EXHAUSTION DUMP & FLIP! Wiping sell basket & entering long!");
            CloseAllPositions();
            ExecuteSpamBasket(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), m_cfg.stopLossPoints);
         }
      }
   }

   // --- Pattern 8: Climax Volume Absorption Fade ---
   void CheckVolumeClimaxFade(const MqlRates &rates[], int total_bars)
   {
      if(!m_cfg.enableVolumeClimaxFade || GetPrimaryCount() > 0 || ArraySize(rates) < 22) return;

      long avg_vol = 0;
      for(int i = 2; i <= 21; i++) avg_vol += rates[i].tick_volume;
      avg_vol /= 20;

      if(avg_vol <= 0) return;

      // Volume climax > 3.0x average on massive candle
      if(rates[1].tick_volume >= (avg_vol * m_cfg.volumeSpikeMultiplier))
      {
         double total_range = rates[1].high - rates[1].low;
         double upper_wick = rates[1].high - MathMax(rates[1].open, rates[1].close);
         double lower_wick = MathMin(rates[1].open, rates[1].close) - rates[1].low;

         if((upper_wick / total_range) >= 0.40)
         {
            Print("⚡ BEHAVIORAL PATTERN 8: CLIMAX VOLUME ABSORPTION FADE! Smart money absorbed retail buyers. Entering SELL!");
            ExecuteSpamBasket(ORDER_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID), m_cfg.stopLossPoints);
         }
         else if((lower_wick / total_range) >= 0.40)
         {
            Print("⚡ BEHAVIORAL PATTERN 8: CLIMAX VOLUME ABSORPTION FADE! Smart money absorbed retail panic sellers. Entering BUY!");
            ExecuteSpamBasket(ORDER_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK), m_cfg.stopLossPoints);
         }
      }
   }

   // --- Pattern 9: Milestone Flip Target Cashout ---
   bool CheckMilestoneFlipTarget()
   {
      if(!m_cfg.enableFlipMilestone) return false;

      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(equity >= m_cfg.targetEquity)
      {
         Print("🎯 BEHAVIORAL PATTERN 9: MILESTONE FLIP TARGET CASHED OUT ($", m_cfg.targetEquity, ")! Liquidating all positions!");
         CloseAllPositions();
         UpdateHUDText("TARGET REACHED! CASHOUT ACHIEVED!");
         return true;
      }
      return false;
   }

   // --- Pattern 10: Visual Roadmap & On-Chart HUD ---
   void UpdateHUD()
   {
      if(!m_cfg.enableVisuals) return;

      int open_tickets = GetPrimaryCount();
      double pnl = GetTotalPnL();
      ENUM_POSITION_TYPE ptype;
      string dir = GetPrimaryType(ptype) ? (ptype == POSITION_TYPE_BUY ? "BUY BASKET" : "SELL BASKET") : "FLAT";

      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double progress = (m_cfg.targetEquity > 0) ? (equity / m_cfg.targetEquity) * 100.0 : 0.0;

      string hud = StringFormat(
         "=== FLIPPER BEHAVIORAL ENGINE HUD ===\n" +
         "Status: %s | Active Tickets: %d\n" +
         "Floating Basket PnL: $%.2f\n" +
         "Pyramid Layer: L%d / %d\n" +
         "Breakeven Shield: %s\n" +
         "Account Equity: $%.2f (Bal: $%.2f)\n" +
         "Flip Target: $%.0f (Progress: %.1f%%)",
         dir, open_tickets, pnl,
         m_current_layer, m_cfg.maxPyramidLayers,
         (m_be_active ? "LOCKED (+1.0p) [RISK-FREE]" : "ARMED"),
         equity, balance, m_cfg.targetEquity, progress
      );

      UpdateHUDText(hud);
   }

   void CloseAllPositions()
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(m_pos.SelectByIndex(i))
         {
            if((m_pos.Magic() == m_cfg.magicNumber || m_pos.Magic() == m_cfg.magicNumber + 99) && m_pos.Symbol() == _Symbol)
               m_trade.PositionClose(m_pos.Ticket());
         }
      }
      m_be_active = false;
      m_current_layer = 1;
   }

private:
   double CalculateLotPerTicket()
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      int steps = (int)MathFloor(equity / m_cfg.equityPerMinLot);
      if(steps < 1) steps = 1;

      double base_lot = (steps * 0.01) / m_cfg.spamTicketsCount;
      double step_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double max_lot  = MathMin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), m_cfg.maxLotPerTicket);

      if(step_lot > 0)
         base_lot = MathFloor(base_lot / step_lot) * step_lot;

      if(base_lot < min_lot) base_lot = min_lot;
      if(base_lot > max_lot) base_lot = max_lot;

      return NormalizeDouble(base_lot, 2);
   }

   void CloseSpecificTicket(int ticket_idx)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(m_pos.SelectByIndex(i))
         {
            if(m_pos.Magic() == m_cfg.magicNumber && m_pos.Symbol() == _Symbol)
            {
               string comment = m_pos.Comment();
               string target_str = StringFormat("T%d", ticket_idx);
               if(StringFind(comment, target_str) >= 0)
               {
                  Print("💰 HARVESTING TICKET ", comment, " at target!");
                  m_trade.PositionClose(m_pos.Ticket());
                  break;
               }
            }
         }
      }
   }

   void MoveStopLoss(double base_entry, ENUM_POSITION_TYPE ptype, int buffer_pts)
   {
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double new_sl = (ptype == POSITION_TYPE_BUY) ? base_entry + (buffer_pts * point) : base_entry - (buffer_pts * point);

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(m_pos.SelectByIndex(i))
         {
            if(m_pos.Magic() == m_cfg.magicNumber && m_pos.Symbol() == _Symbol)
            {
               double cur_sl = m_pos.StopLoss();
               if(ptype == POSITION_TYPE_BUY)
               {
                  if(cur_sl < new_sl) m_trade.PositionModify(m_pos.Ticket(), new_sl, m_pos.TakeProfit());
               }
               else
               {
                  if(cur_sl > new_sl || cur_sl == 0.0) m_trade.PositionModify(m_pos.Ticket(), new_sl, m_pos.TakeProfit());
               }
            }
         }
      }
   }

   int GetPrimaryCount()
   {
      int count = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(m_pos.SelectByIndex(i))
         {
            if(m_pos.Magic() == m_cfg.magicNumber && m_pos.Symbol() == _Symbol)
               count++;
         }
      }
      return count;
   }

   bool GetPrimaryType(ENUM_POSITION_TYPE &ptype)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(m_pos.SelectByIndex(i))
         {
            if(m_pos.Magic() == m_cfg.magicNumber && m_pos.Symbol() == _Symbol)
            {
               ptype = m_pos.PositionType();
               return true;
            }
         }
      }
      return false;
   }

   double GetTotalPnL()
   {
      double pnl = 0.0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(m_pos.SelectByIndex(i))
         {
            if((m_pos.Magic() == m_cfg.magicNumber || m_pos.Magic() == m_cfg.magicNumber + 99) && m_pos.Symbol() == _Symbol)
               pnl += m_pos.Profit() + m_pos.Swap();
         }
      }
      return pnl;
   }

   void ApplyTheme()
   {
      ChartSetInteger(0, CHART_SHOW_GRID, false);
      ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, FBE_COLOR_BG_DARK);
      ChartSetInteger(0, CHART_COLOR_FOREGROUND, FBE_COLOR_TEXT_WHITE);
      ChartSetInteger(0, CHART_COLOR_CHART_UP, FBE_COLOR_WIN_LIME);
      ChartSetInteger(0, CHART_COLOR_CHART_DOWN, FBE_COLOR_LOSS_CORAL);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, FBE_COLOR_WIN_LIME);
      ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, FBE_COLOR_PURPLE);
      ChartRedraw(0);
   }

   void DrawBasketVisualRoadmap(double entry, ENUM_ORDER_TYPE otype, double sl)
   {
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      datetime t_now = TimeCurrent();
      datetime t_end = t_now + PeriodSeconds(_Period) * 30;

      string box_name = StringFormat("%sBox_%d", m_cfg.prefix, (int)t_now);
      double tp_top = (otype == ORDER_TYPE_BUY) ? entry + (m_cfg.tp5Points * point) : entry - (m_cfg.tp5Points * point);

      ObjectCreate(0, box_name, OBJ_RECTANGLE, 0, t_now, entry, t_end, tp_top);
      ObjectSetInteger(0, box_name, OBJPROP_COLOR, FBE_COLOR_WIN_LIME);
      ObjectSetInteger(0, box_name, OBJPROP_BGCOLOR, (otype == ORDER_TYPE_BUY) ? (color)C'28,60,38' : (color)C'65,24,28');
      ObjectSetInteger(0, box_name, OBJPROP_BACK, true);

      // TP Ladder Lines
      DrawLine(entry, (otype == ORDER_TYPE_BUY) ? entry + (m_cfg.tp1Points * point) : entry - (m_cfg.tp1Points * point), "TP1 (+20p)", FBE_COLOR_YELLOW, t_now, t_end);
      DrawLine(entry, (otype == ORDER_TYPE_BUY) ? entry + (m_cfg.tp2Points * point) : entry - (m_cfg.tp2Points * point), "TP2 (+35p BE)", FBE_COLOR_BE_CYAN, t_now, t_end);
      DrawLine(entry, (otype == ORDER_TYPE_BUY) ? entry + (m_cfg.tp3Points * point) : entry - (m_cfg.tp3Points * point), "TP3 (+60p Lock)", FBE_COLOR_WIN_LIME, t_now, t_end);
      DrawLine(entry, (otype == ORDER_TYPE_BUY) ? entry + (m_cfg.tp4Points * point) : entry - (m_cfg.tp4Points * point), "TP4 (+100p)", FBE_COLOR_ORANGE, t_now, t_end);
      DrawLine(entry, (otype == ORDER_TYPE_BUY) ? entry + (m_cfg.tp5Points * point) : entry - (m_cfg.tp5Points * point), "TP5 (+160p Runner)", FBE_COLOR_PURPLE, t_now, t_end);

      ChartRedraw(0);
   }

   void DrawLine(double entry, double price, string label, color clr, datetime t1, datetime t2)
   {
      string line_name = StringFormat("%sLine_%s_%d", m_cfg.prefix, label, (int)t1);
      ObjectCreate(0, line_name, OBJ_TREND, 0, t1, price, t2, price);
      ObjectSetInteger(0, line_name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, line_name, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, line_name, OBJPROP_RAY_RIGHT, true);

      string txt_name = StringFormat("%sTxt_%s_%d", m_cfg.prefix, label, (int)t1);
      ObjectCreate(0, txt_name, OBJ_TEXT, 0, t2, price);
      ObjectSetString(0, txt_name, OBJPROP_TEXT, "  " + label);
      ObjectSetInteger(0, txt_name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, txt_name, OBJPROP_FONTSIZE, 8);
   }

   void DrawBreakevenShieldLine(double entry, ENUM_POSITION_TYPE ptype, int buffer_pts)
   {
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double be_price = (ptype == POSITION_TYPE_BUY) ? entry + (buffer_pts * point) : entry - (buffer_pts * point);

      string line_name = StringFormat("%sBE_SHIELD", m_cfg.prefix);
      datetime t_now = TimeCurrent();
      datetime t_end = t_now + PeriodSeconds(_Period) * 50;

      ObjectDelete(0, line_name);
      ObjectCreate(0, line_name, OBJ_TREND, 0, t_now - 3600, be_price, t_end, be_price);
      ObjectSetInteger(0, line_name, OBJPROP_COLOR, FBE_COLOR_BE_CYAN);
      ObjectSetInteger(0, line_name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, line_name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, line_name, OBJPROP_RAY_RIGHT, true);
   }

   void UpdateHUDText(string text)
   {
      string name = StringFormat("%sHUD", m_cfg.prefix);
      if(ObjectFind(0, name) < 0)
      {
         ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 20);
         ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 25);
         ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
         ObjectSetString(0, name, OBJPROP_FONT, "Lucida Console");
      }

      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, (StringFind(text, "LOCKED") >= 0) ? FBE_COLOR_WIN_LIME : FBE_COLOR_BE_CYAN);
      ChartRedraw(0);
   }
};
//+------------------------------------------------------------------+
