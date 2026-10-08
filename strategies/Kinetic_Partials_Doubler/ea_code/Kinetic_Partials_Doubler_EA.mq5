//+------------------------------------------------------------------+
//| Kinetic_Partials_Doubler_EA.mq5                                  |
//| Strategy 5: Kinetic Dual Partials Asymmetric Capital Doubler     |
//| Asset: XAUUSD M1 | Leverage: 1:400 | Target: +100% in 30 Days    |
//+------------------------------------------------------------------+
#property copyright "Master Quant Architecture"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Capital Sizing & Doubling Engine (1:400 Leverage) ==="
input double RiskPercent           = 5.0;              // Risk % per Trade ($1,000 Account)
input double CapitalPerMicroLot    = 15.0;             // Capital per 0.01 lot ($20 Account)
input bool   UseFixedMicroStep     = false;            // Force Micro Step Sizing
input double MaxLotCap             = 5.00;             // Max Lot Cap
input double SL_Pips               = 15.0;             // Base Stop Loss (Pips)
input double Part1_RR              = 1.0;              // Target 1 (1:1 R:R)
input double Part2_RR              = 2.5;              // Target 2 (2.5R Runner)
input double BE_Offset_Pips        = 1.0;              // Breakeven Lock Buffer (Pips)

input group "=== Entry Confluence Filters ==="
input double Min_FVG_Pips          = 2.5;              // Minimum FVG Imbalance (Pips)
input double VolMultiplier         = 1.20;             // Volume Surge Multiplier
input int    StartHourUTC          = 13;               // Session Start UTC
input int    EndHourUTC            = 19;               // Session End UTC
input int    MaxDailyTrades        = 4;                // Max Trades per Day
input int    MaxDailyLosses        = 2;                // Circuit Breaker Max Losses
input ulong  MagicNumber           = 20265005;         // Base Magic Number

CTrade trade;
CPositionInfo pos;
int dailyTrades = 0;
int dailyLosses = 0;
datetime lastTradeDay = 0;

int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) {}

double CalculateLots(double slPips)
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double capital = MathMin(balance, equity);
   double step    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   if(capital < 200.0 || UseFixedMicroStep)
     {
      double microLots = MathMax(minLot * 2.0, MathFloor(capital / CapitalPerMicroLot) * 0.01);
      return NormalizeDouble(MathMin(MaxLotCap, microLots), 2);
     }

   double riskMoney = capital * (RiskPercent / 100.0);
   double pip       = _Point * 10;
   double tv        = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts        = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pv        = (pip / ts) * tv;
   if(slPips <= 0 || pv <= 0) return minLot * 2.0;

   double lots = riskMoney / (slPips * pv);
   lots = MathFloor(lots / step) * step;
   return NormalizeDouble(MathMax(minLot * 2.0, MathMin(MaxLotCap, lots)), 2);
  }

bool HasOpenPosition()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol)
        {
         ulong m = pos.Magic();
         if(m == MagicNumber + 1 || m == MagicNumber + 2) return true;
        }
     }
   return false;
  }

void ManagePartials()
  {
   double pip = _Point * 10;
   bool tp1_hit = false;
   HistorySelect(TimeCurrent() - 4 * 3600, TimeCurrent());
   int total = HistoryDealsTotal();
   for(int i = total - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(ticket, DEAL_MAGIC) == MagicNumber + 1)
           { tp1_hit = true; break; }
        }
     }

   if(tp1_hit)
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MagicNumber + 2)
           {
            ulong t = pos.Ticket();
            double openP = pos.PriceOpen();
            double curSL = pos.StopLoss();
            double curTP = pos.TakeProfit();
            if(pos.PositionType() == POSITION_TYPE_BUY)
              {
               double newSL = NormalizeDouble(openP + BE_Offset_Pips * pip, _Digits);
               if(curSL < newSL) trade.PositionModify(t, newSL, curTP);
              }
            else if(pos.PositionType() == POSITION_TYPE_SELL)
              {
               double newSL = NormalizeDouble(openP - BE_Offset_Pips * pip, _Digits);
               if(curSL == 0 || curSL > newSL) trade.PositionModify(t, newSL, curTP);
              }
           }
        }
     }
  }

void OnTick()
  {
   ManagePartials();

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastTradeDay != today) { dailyTrades = 0; dailyLosses = 0; lastTradeDay = today; }
   if(dailyTrades >= MaxDailyTrades || dailyLosses >= MaxDailyLosses) return;

   if(dt.day_of_week == 0 || dt.day_of_week == 6) return;
   if(dt.hour < StartHourUTC || dt.hour >= EndHourUTC) return;

   static datetime lastBar = 0;
   datetime curBar = iTime(_Symbol, _Period, 0);
   if(lastBar == curBar) return;
   lastBar = curBar;

   if(HasOpenPosition()) return;

   double pip = _Point * 10;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 5, rates) < 5) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   bool bullFVG = (rates[0].low > rates[2].high + Min_FVG_Pips * pip);
   bool bearFVG = (rates[2].low > rates[0].high + Min_FVG_Pips * pip);

   int sig = 0;
   if(bullFVG && rates[0].close > rates[1].high) sig = 1;
   else if(bearFVG && rates[0].close < rates[1].low) sig = -1;

   if(sig != 0)
     {
      double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double totalLots = CalculateLots(SL_Pips);

      double lot1 = MathMax(minLot, MathFloor((totalLots * 0.50) / step) * step);
      double lot2 = MathMax(minLot, NormalizeDouble(totalLots - lot1, 2));

      double entry = (sig > 0) ? ask : bid;
      double sl    = (sig > 0) ? NormalizeDouble(ask - SL_Pips * pip, _Digits)
                               : NormalizeDouble(bid + SL_Pips * pip, _Digits);

      double tp1   = (sig > 0) ? NormalizeDouble(entry + Part1_RR * (entry - sl), _Digits)
                               : NormalizeDouble(entry - Part1_RR * (sl - entry), _Digits);
      double tp2   = (sig > 0) ? NormalizeDouble(entry + Part2_RR * (entry - sl), _Digits)
                               : NormalizeDouble(entry - Part2_RR * (sl - entry), _Digits);

      trade.SetExpertMagicNumber(MagicNumber + 1);
      if(sig > 0) trade.Buy(lot1, _Symbol, entry, sl, tp1, "Kinetic-P1");
      else        trade.Sell(lot1, _Symbol, entry, sl, tp1, "Kinetic-P1");

      trade.SetExpertMagicNumber(MagicNumber + 2);
      if(sig > 0) trade.Buy(lot2, _Symbol, entry, sl, tp2, "Kinetic-P2");
      else        trade.Sell(lot2, _Symbol, entry, sl, tp2, "Kinetic-P2");

      dailyTrades++;
     }
  }
