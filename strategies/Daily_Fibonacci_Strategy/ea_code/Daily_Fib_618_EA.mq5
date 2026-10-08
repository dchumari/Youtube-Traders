//+------------------------------------------------------------------+
//|                                           Daily_Fib_618_EA.mq5   |
//|               Copyright 2026, Quantitative Fib Trading Engine    |
//|      Autonomous Execution of Daily 61.8% Retracement & Virgins   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://www.tradingview.com"
#property version   "1.00"
#property description "Automated EA for Daily 61.8% Fibonacci Retracements & Virgin Levels"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>

//--- Input parameters
input group "=== Risk & Execution ==="
input ulong    InpMagicNumber        = 618001;     // Magic Number
input double   InpFixedLot           = 0.01;       // Fixed Lot Size (Micro Account Optimized)
input double   InpRewardRiskRatio    = 2.0;        // Reward-to-Risk Ratio
input int      InpSLPoints           = 350;        // Stop Loss Distance (Points) (35 pips on Gold)
input int      InpEntryTolerance     = 50;         // Entry Proximity Tolerance (Points)
input int      InpMaxSpreadPoints    = 50;         // Maximum Spread Allowed (Points)

input group "=== Strategy Rules ==="
input bool     InpTradeImmediate     = true;       // Trade Immediate Next-Day Retests
input bool     InpTradeVirginLevels  = true;       // Trade Virgin / Untested Retests
input int      InpMaxVirginAgeDays   = 30;         // Max Age for Virgin Levels (Days)
input int      InpMaxDailyTrades     = 2;          // Max Trades per Day

input group "=== Breakeven & Trade Management ==="
input bool     InpUseBreakeven       = true;       // Use Breakeven
input double   InpBETriggerR         = 1.0;        // Breakeven Trigger (in R-multiples)
input int      InpBELockPoints       = 10;         // Points to Lock in Profit at Breakeven

input group "=== Session Filters ==="
input bool     InpUseSessionFilter   = true;       // Use London/NY Session Filter
input int      InpSessionStartHour   = 7;          // Trading Session Start Hour (Server)
input int      InpSessionEndHour     = 18;         // Trading Session End Hour (Server)

//--- Structures
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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!m_symbol.Name(_Symbol)) return(INIT_FAILED);
   m_symbol.RefreshRates();

   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(_Symbol);

   UpdateDailyLevels();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
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

      bool is_bullish = (d_close >= d_open);
      double fib_618 = 0.0;

      // Mathematical logic defined by user:
      // Bearish Day: 100% at High, 0% at Low -> Level = Low + 0.618 * Range (SELL)
      // Bullish Day: 100% at Low, 0% at High -> Level = High - 0.618 * Range (BUY)
      if(!is_bullish)
         fib_618 = d_low + 0.618 * d_range;
      else
         fib_618 = d_high - 0.618 * d_range;

      // Check if level was mitigated between day i-1 and today
      bool is_mitigated = false;
      bool touched_next_day = false;

      // Day i-1 (the day immediately after)
      if(!is_bullish)
      {
         if(daily_rates[i-1].high >= fib_618) touched_next_day = true;
      }
      else
      {
         if(daily_rates[i-1].low <= fib_618) touched_next_day = true;
      }

      if(i == 1) // Yesterday's candle: today is the immediate next day
      {
         if(!InpTradeImmediate) continue;
      }
      else // Older candles: Virgin check
      {
         if(!InpTradeVirginLevels) continue;
         if(touched_next_day) continue; // Not virgin

         // Check if any subsequent day mitigated it
         for(int k = i - 2; k >= 0; k--)
         {
            if(!is_bullish && daily_rates[k].high >= fib_618) { is_mitigated = true; break; }
            if(is_bullish && daily_rates[k].low <= fib_618)   { is_mitigated = true; break; }
         }

         if(is_mitigated) continue; // Already mitigated in the past
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

   // Manage open positions (Breakeven)
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

   // Check if we already have an open position with our magic
   if(HasOpenPosition()) return;

   double ask = m_symbol.Ask();
   double bid = m_symbol.Bid();
   double point = m_symbol.Point();

   // Check each active level for entry trigger
   for(int i = 0; i < ArraySize(g_active_levels); i++)
   {
      if(g_active_levels[i].trade_taken) continue;

      double lvl = g_active_levels[i].price_level;
      bool is_buy = g_active_levels[i].is_bullish;

      if(is_buy) // BUY SUPPORT LEVEL
      {
         // Price approaches level from above or touches it
         if(ask <= lvl + InpEntryTolerance * point && ask >= lvl - InpEntryTolerance * point)
         {
            double sl = NormalizeDouble(ask - InpSLPoints * point, _Digits);
            double tp = NormalizeDouble(ask + (InpSLPoints * InpRewardRiskRatio) * point, _Digits);

            if(m_trade.Buy(InpFixedLot, _Symbol, ask, sl, tp, "Fib618 Buy"))
            {
               g_active_levels[i].trade_taken = true;
               g_daily_trade_count++;
               break;
            }
         }
      }
      else // SELL RESISTANCE LEVEL
      {
         // Price approaches level from below or touches it
         if(bid >= lvl - InpEntryTolerance * point && bid <= lvl + InpEntryTolerance * point)
         {
            double sl = NormalizeDouble(bid + InpSLPoints * point, _Digits);
            double tp = NormalizeDouble(bid - (InpSLPoints * InpRewardRiskRatio) * point, _Digits);

            if(m_trade.Sell(InpFixedLot, _Symbol, bid, sl, tp, "Fib618 Sell"))
            {
               g_active_levels[i].trade_taken = true;
               g_daily_trade_count++;
               break;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if an open position exists                                 |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagicNumber)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Manage Breakeven on active positions                             |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   if(!InpUseBreakeven) return;

   double point = m_symbol.Point();

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != _Symbol || m_position.Magic() != InpMagicNumber) continue;

      double open_price = m_position.PriceOpen();
      double current_sl = m_position.StopLoss();
      ENUM_POSITION_TYPE type = m_position.PositionType();

      double risk_dist = InpSLPoints * point;
      if(risk_dist <= 0) continue;

      if(type == POSITION_TYPE_BUY)
      {
         double current_bid = m_symbol.Bid();
         double profit_dist = current_bid - open_price;
         if(profit_dist >= risk_dist * InpBETriggerR)
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
         if(profit_dist >= risk_dist * InpBETriggerR)
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
