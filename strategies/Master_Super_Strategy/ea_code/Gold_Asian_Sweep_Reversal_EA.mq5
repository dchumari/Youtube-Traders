//+------------------------------------------------------------------+
//|  Gold_Asian_Sweep_Reversal_EA.mq5                                |
//|  Strategy: Asian Range Liquidity Sweep & Mean Reversion Engine   |
//|  Asset:    XAUUSD M1                                             |
//+------------------------------------------------------------------+
#property copyright "Master Quant Architecture"
#property link      "https://youtube-traders.pipeline"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Execution & Risk ==="
input double   RiskPercent         = 12.0;  // Risk % for $1,000 account
input bool     UseFixedLot         = false; // Use Fixed Lot
input double   FixedLotSize        = 0.01;  // Fixed lot for $20 account
input double   SL_Pips             = 12.0;  // Stop Loss in Pips
input double   Target_RR           = 2.8;   // Reward to Risk Ratio
input bool     UseBreakeven        = true;  // Move to Breakeven
input double   BE_Trigger_R        = 1.0;   // BE Trigger R
input double   BE_Offset_Pips      = 1.0;   // BE Offset Pips

input group "=== Asian Sweep Parameters ==="
input int      AsianStartHour      = 0;     // Asian Start UTC
input int      AsianEndHour        = 7;     // Asian End UTC
input double   SweepMinPips        = 3.0;   // Sweep Buffer Pips
input int      TradeStartHour      = 7;     // Trade Start UTC (London Open)
input int      TradeEndHour        = 16;    // Trade End UTC
input double   VolMultiplier       = 1.20;  // Volume Surge Multiplier
input int      MaxDailyTrades      = 3;     // Max Daily Trades
input double   MaxSpreadPips       = 25.0;  // Max Spread Pips
input ulong    MagicNumber         = 20267001;

CTrade trade;
CPositionInfo pos;
double asianHigh = 0.0, asianLow = 999999.0;
datetime lastAsianDate = 0;
int dailyTrades = 0;
datetime lastTradeDay = 0;

int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) {}

void UpdateAsianRange()
  {
   MqlDateTime dt; TimeToStruct(TimeGMT(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today == lastAsianDate && dt.hour >= AsianEndHour) return;

   datetime startT = today + AsianStartHour * 3600;
   datetime endT   = today + AsianEndHour * 3600;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_M1, startT, endT, rates);
   if(copied > 0)
     {
      double h = -1.0, l = 999999.0;
      for(int i = 0; i < copied; i++)
        {
         if(rates[i].high > h) h = rates[i].high;
         if(rates[i].low < l)  l = rates[i].low;
        }
      asianHigh = h;
      asianLow  = l;
      lastAsianDate = today;
     }
  }

void ManageBreakeven()
  {
   if(!UseBreakeven) return;
   double pip = _Point * 10;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MagicNumber)
        {
         ulong ticket = pos.Ticket();
         double openP = pos.PriceOpen();
         double sl = pos.StopLoss();
         double curP = (pos.PositionType() == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double riskPips = MathAbs(openP - sl) / pip;
         if(pos.PositionType() == POSITION_TYPE_BUY)
           {
            if(curP >= openP + BE_Trigger_R * riskPips * pip && sl < openP)
               trade.PositionModify(ticket, openP + BE_Offset_Pips * pip, pos.TakeProfit());
           }
         else
           {
            if(curP <= openP - BE_Trigger_R * riskPips * pip && (sl > openP || sl == 0))
               trade.PositionModify(ticket, openP - BE_Offset_Pips * pip, pos.TakeProfit());
           }
        }
     }
  }

double CalculateLots(double slPips)
  {
   if(UseFixedLot) return FixedLotSize;
   double capital = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = capital * (RiskPercent / 100.0);
   double pip = _Point * 10;
   double tv  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pv  = (pip / ts) * tv;
   double lots = riskMoney / (slPips * pv);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / step) * step;
   return MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), MathMin(5.00, lots));
  }

void OnTick()
  {
   ManageBreakeven();

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastTradeDay != today) { dailyTrades = 0; lastTradeDay = today; }
   if(dailyTrades >= MaxDailyTrades) return;

   MqlDateTime gmt; TimeToStruct(TimeGMT(), gmt);
   if(gmt.hour < TradeStartHour || gmt.hour >= TradeEndHour) return;
   if((double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpreadPips) return;

   UpdateAsianRange();
   if(asianHigh <= 0 || asianLow >= 999999.0) return;

   static datetime lastBar = 0;
   datetime curBar = iTime(_Symbol, PERIOD_M1, 0);
   if(lastBar == curBar) return;
   lastBar = curBar;

   // Check open positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MagicNumber) return;

   double pip = _Point * 10;
   MqlRates r[];
   ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, PERIOD_M1, 1, 3, r) < 3) return;

   // Volume filter
   long vol[];
   ArraySetAsSeries(vol, true);
   if(CopyTickVolume(_Symbol, PERIOD_M1, 1, 21, vol) < 21) return;
   double sumV = 0;
   for(int i = 1; i <= 20; i++) sumV += (double)vol[i];
   double avgV = sumV / 20.0;
   if((double)vol[0] < avgV * VolMultiplier) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Bullish Reversal: Price swept below Asian Low by >= SweepMinPips and bar closed back above Asian Low
   if(r[1].low <= asianLow - SweepMinPips * pip && r[0].close > asianLow && r[0].close > r[0].open)
     {
      double sl = ask - SL_Pips * pip;
      double tp = ask + Target_RR * SL_Pips * pip;
      double lots = CalculateLots(SL_Pips);
      if(lots > 0 && trade.Buy(lots, _Symbol, ask, sl, tp, "AsianSweep-Buy"))
         dailyTrades++;
     }
   // Bearish Reversal: Price swept above Asian High by >= SweepMinPips and bar closed back below Asian High
   else if(r[1].high >= asianHigh + SweepMinPips * pip && r[0].close < asianHigh && r[0].close < r[0].open)
     {
      double sl = bid + SL_Pips * pip;
      double tp = bid - Target_RR * SL_Pips * pip;
      double lots = CalculateLots(SL_Pips);
      if(lots > 0 && trade.Sell(lots, _Symbol, bid, sl, tp, "AsianSweep-Sell"))
         dailyTrades++;
     }
  }
