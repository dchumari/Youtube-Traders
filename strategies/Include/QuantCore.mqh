//+------------------------------------------------------------------+
//|                                                    QuantCore.mqh |
//|                           Institutional Algorithmic Trading Core |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

class CQuantTrade
{
private:
   CTrade         m_trade;
   CSymbolInfo    m_symbol;
   CPositionInfo  m_position;
   CAccountInfo   m_account;
   ulong          m_magic;
   datetime       m_last_bar_time;

public:
   CQuantTrade() : m_magic(100001), m_last_bar_time(0) {}
   
   bool Init(ulong magic, string symbol_name)
   {
      m_magic = magic;
      m_trade.SetExpertMagicNumber(m_magic);
      m_trade.SetMarginMode();
      m_trade.SetTypeFillingBySymbol(symbol_name);
      m_trade.SetDeviationInPoints(20);
      
      if(!m_symbol.Name(symbol_name))
         return false;
      m_symbol.RefreshRates();
      return true;
   }
   
   bool IsNewBar(ENUM_TIMEFRAMES period)
   {
      datetime bar_time = iTime(_Symbol, period, 0);
      if(bar_time == 0) return false;
      if(bar_time != m_last_bar_time)
      {
         m_last_bar_time = bar_time;
         return true;
      }
      return false;
   }
   
   double CalculateLotSize(double sl_distance_points, double risk_percent)
   {
      m_symbol.RefreshRates();
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double risk_amount = equity * (risk_percent / 100.0);
      
      double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double point      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      
      if(tick_value <= 0 || tick_size <= 0 || point <= 0 || sl_distance_points <= 0)
         return 0.01;
         
      double point_value = tick_value * (point / tick_size);
      double loss_per_lot = sl_distance_points * point_value;
      if(loss_per_lot <= 0) return 0.01;
      
      double raw_lot = risk_amount / loss_per_lot;
      
      double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double step_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      
      if(min_lot <= 0) min_lot = 0.01;
      if(step_lot <= 0) step_lot = 0.01;
      
      double lots = MathFloor(raw_lot / step_lot) * step_lot;
      if(lots < min_lot) lots = min_lot;
      if(lots > max_lot) lots = max_lot;
      
      return NormalizeDouble(lots, 2);
   }
   
   bool HasOpenPosition(long &pos_type, double &open_price, double &pos_sl, double &pos_tp, ulong &ticket)
   {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(m_position.SelectByIndex(i))
         {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == m_magic)
            {
               pos_type   = m_position.PositionType();
               open_price = m_position.PriceOpen();
               pos_sl     = m_position.StopLoss();
               pos_tp     = m_position.TakeProfit();
               ticket     = m_position.Ticket();
               return true;
            }
         }
      }
      return false;
   }
   
   bool OpenBuy(double sl_distance_points, double tp_distance_points, double risk_percent, string comment="")
   {
      m_symbol.RefreshRates();
      double ask = m_symbol.Ask();
      double point = m_symbol.Point();
      
      double sl = (sl_distance_points > 0) ? NormalizeDouble(ask - sl_distance_points * point, _Digits) : 0;
      double tp = (tp_distance_points > 0) ? NormalizeDouble(ask + tp_distance_points * point, _Digits) : 0;
      
      double lots = CalculateLotSize(sl_distance_points, risk_percent);
      return m_trade.Buy(lots, _Symbol, ask, sl, tp, comment);
   }
   
   bool OpenSell(double sl_distance_points, double tp_distance_points, double risk_percent, string comment="")
   {
      m_symbol.RefreshRates();
      double bid = m_symbol.Bid();
      double point = m_symbol.Point();
      
      double sl = (sl_distance_points > 0) ? NormalizeDouble(bid + sl_distance_points * point, _Digits) : 0;
      double tp = (tp_distance_points > 0) ? NormalizeDouble(bid - tp_distance_points * point, _Digits) : 0;
      
      double lots = CalculateLotSize(sl_distance_points, risk_percent);
      return m_trade.Sell(lots, _Symbol, bid, sl, tp, comment);
   }
   
   void ManageBreakevenAndTrailing(double be_trigger_points, double be_lock_points, double trail_points, double trail_step_points)
   {
      m_symbol.RefreshRates();
      double point = m_symbol.Point();
      double ask = m_symbol.Ask();
      double bid = m_symbol.Bid();
      
      long pos_type;
      double open_price, pos_sl, pos_tp;
      ulong ticket;
      
      if(!HasOpenPosition(pos_type, open_price, pos_sl, pos_tp, ticket))
         return;
         
      if(pos_type == POSITION_TYPE_BUY)
      {
         double profit_points = (bid - open_price) / point;
         
         // Breakeven
         if(be_trigger_points > 0 && profit_points >= be_trigger_points)
         {
            double new_sl = NormalizeDouble(open_price + be_lock_points * point, _Digits);
            if(pos_sl < new_sl || pos_sl == 0)
            {
               m_trade.PositionModify(ticket, new_sl, pos_tp);
               return;
            }
         }
         
         // Trailing Stop
         if(trail_points > 0 && profit_points >= trail_points)
         {
            double proposed_sl = NormalizeDouble(bid - trail_points * point, _Digits);
            if(proposed_sl > pos_sl + trail_step_points * point)
            {
               m_trade.PositionModify(ticket, proposed_sl, pos_tp);
            }
         }
      }
      else if(pos_type == POSITION_TYPE_SELL)
      {
         double profit_points = (open_price - ask) / point;
         
         // Breakeven
         if(be_trigger_points > 0 && profit_points >= be_trigger_points)
         {
            double new_sl = NormalizeDouble(open_price - be_lock_points * point, _Digits);
            if(pos_sl > new_sl || pos_sl == 0)
            {
               m_trade.PositionModify(ticket, new_sl, pos_tp);
               return;
            }
         }
         
         // Trailing Stop
         if(trail_points > 0 && profit_points >= trail_points)
         {
            double proposed_sl = NormalizeDouble(ask + trail_points * point, _Digits);
            if(pos_sl == 0 || proposed_sl < pos_sl - trail_step_points * point)
            {
               m_trade.PositionModify(ticket, proposed_sl, pos_tp);
            }
         }
      }
   }
   
   static bool IsInHourWindow(int start_hour, int end_hour)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      if(start_hour <= end_hour)
         return (dt.hour >= start_hour && dt.hour < end_hour);
      else
         return (dt.hour >= start_hour || dt.hour < end_hour);
   }
};
