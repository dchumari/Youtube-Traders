//+------------------------------------------------------------------+
//| Macro_Judas_Doubler_EA.mq5                                       |
//| Strategy 2: High-Impact Macro News Judas Expansion Reversal       |
//| Asset: XAUUSD M1 | Leverage: 1:400 | Target: +100% in 30 Days    |
//+------------------------------------------------------------------+
#property copyright "Master Quant Architecture"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Capital Sizing & Doubling Engine (1:400 Leverage) ==="
input double RiskPercent           = 4.5;              // Risk % per Trade ($1,000 Account)
input double CapitalPerMicroLot    = 16.0;             // Capital per 0.01 lot ($20 Account)
input bool   UseFixedMicroStep     = false;            // Force Micro Step Sizing
input double MaxLotCap             = 5.00;             // Max Lot Cap
input double SL_Pips               = 15.0;             // Base Stop Loss (Pips)
input double Target_RR             = 2.5;              // Target Reward:Risk (2.5R)

input group "=== News Judas Parameters ==="
input double MinNewsSpikePips      = 5.0;              // Minimum Expansion Spike (Pips)
input double VolMultiplier         = 1.30;             // Volume Expansion Multiplier
input int    StartHourUTC          = 13;               // News Window Start UTC
input int    EndHourUTC            = 16;               // News Window End UTC
input int    MaxDailyTrades        = 3;                // Max Trades per Day
input int    MaxDailyLosses        = 2;                // Circuit Breaker Max Losses
input ulong  MagicNumber           = 20265002;         // Magic Number

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
      double microLots = MathMax(minLot, MathFloor(capital / CapitalPerMicroLot) * 0.01);
      return NormalizeDouble(MathMin(MaxLotCap, microLots), 2);
     }

   double riskMoney = capital * (RiskPercent / 100.0);
   double pip       = _Point * 10;
   double tv        = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts        = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pv        = (pip / ts) * tv;
   if(slPips <= 0 || pv <= 0) return minLot;

   double lots = riskMoney / (slPips * pv);
   lots = MathFloor(lots / step) * step;
   return NormalizeDouble(MathMax(minLot, MathMin(MaxLotCap, lots)), 2);
  }

bool HasOpenPosition()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MagicNumber) return true;
     }
   return false;
  }

void OnTick()
  {
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

   // Check prior bar was a large expansion candle
   double candleRange = (rates[1].high - rates[1].low) / pip;
   if(candleRange < MinNewsSpikePips) return;

   // Check volume surge on expansion
   long vols[];
   ArraySetAsSeries(vols, true);
   CopyTickVolume(_Symbol, _Period, 1, 20, vols);
   double sumV = 0.0;
   for(int v = 0; v < 20; v++) sumV += (double)vols[v];
   if((double)rates[1].tick_volume < (sumV / 20.0) * VolMultiplier) return;

   int sig = 0;
   // Bullish Reversal: Bar 1 was violent selloff, Bar 0 closes above Bar 1 High (Wicks sweep, body displaces!)
   if(rates[1].close < rates[1].open && rates[0].close > rates[1].high) sig = 1;
   // Bearish Reversal: Bar 1 was violent rally, Bar 0 closes below Bar 1 Low
   else if(rates[1].close > rates[1].open && rates[0].close < rates[1].low) sig = -1;

   if(sig != 0)
     {
      double sl = (sig > 0) ? NormalizeDouble(ask - SL_Pips * pip, _Digits)
                            : NormalizeDouble(bid + SL_Pips * pip, _Digits);
      double tp = (sig > 0) ? NormalizeDouble(ask + Target_RR * SL_Pips * pip, _Digits)
                            : NormalizeDouble(bid - Target_RR * SL_Pips * pip, _Digits);
      double lots = CalculateLots(SL_Pips);
      if(lots > 0)
        {
         if(sig > 0) trade.Buy(lots, _Symbol, ask, sl, tp, "News-Judas-Buy");
         else        trade.Sell(lots, _Symbol, bid, sl, tp, "News-Judas-Sell");
         dailyTrades++;
        }
     }
  }
