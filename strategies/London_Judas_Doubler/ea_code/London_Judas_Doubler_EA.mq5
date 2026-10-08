//+------------------------------------------------------------------+
//| London_Judas_Doubler_EA.mq5                                      |
//| Strategy 4: London Open Asian Judas Manipulation & Expansion     |
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
input double SL_Pips               = 12.0;             // Base Stop Loss (Pips)
input double Target_RR             = 2.8;              // Target Reward:Risk (2.8R)

input group "=== London Judas Parameters ==="
input double AsianSweepPips        = 2.5;              // Asian Sweep Buffer (Pips)
input int    AsianEndHourUTC       = 7;                // Asian End Hour (07:00 UTC)
input int    LondonStartHourUTC    = 7;                // London Start UTC
input int    LondonEndHourUTC      = 11;               // London End UTC
input int    MaxDailyTrades        = 3;                // Max Trades per Day
input int    MaxDailyLosses        = 2;                // Circuit Breaker Max Losses
input ulong  MagicNumber           = 20265004;         // Magic Number

CTrade trade;
CPositionInfo pos;
int dailyTrades = 0;
int dailyLosses = 0;
datetime lastTradeDay = 0;

double asianHigh = 0.0, asianLow = 999999.0;
datetime lastAsianDate = 0;

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
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today == lastAsianDate && dt.hour >= AsianEndHourUTC) return;

   datetime startT = today;
   datetime endT   = today + AsianEndHourUTC * 3600;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_M5, startT, endT, rates);
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
      if(dt.hour >= AsianEndHourUTC) lastAsianDate = today;
     }
  }

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
   if(dt.hour < LondonStartHourUTC || dt.hour >= LondonEndHourUTC) return;

   UpdateAsianRange();

   static datetime lastBar = 0;
   datetime curBar = iTime(_Symbol, _Period, 0);
   if(lastBar == curBar) return;
   lastBar = curBar;

   if(HasOpenPosition()) return;
   if(asianHigh <= 0 || asianLow >= 900000.0) return;

   double pip = _Point * 10;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 5, rates) < 5) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   int sig = 0;
   // London Judas Swing Buy: Price sweeps Asian Low, then closes firmly back inside
   if(rates[1].low <= asianLow - AsianSweepPips * pip && rates[0].close > asianLow) sig = 1;
   // London Judas Swing Sell: Price sweeps Asian High, then closes firmly back inside
   else if(rates[1].high >= asianHigh + AsianSweepPips * pip && rates[0].close < asianHigh) sig = -1;

   if(sig != 0)
     {
      double sl = (sig > 0) ? NormalizeDouble(ask - SL_Pips * pip, _Digits)
                            : NormalizeDouble(bid + SL_Pips * pip, _Digits);
      double tp = (sig > 0) ? NormalizeDouble(ask + Target_RR * SL_Pips * pip, _Digits)
                            : NormalizeDouble(bid - Target_RR * SL_Pips * pip, _Digits);
      double lots = CalculateLots(SL_Pips);
      if(lots > 0)
        {
         if(sig > 0) trade.Buy(lots, _Symbol, ask, sl, tp, "London-Judas-Buy");
         else        trade.Sell(lots, _Symbol, bid, sl, tp, "London-Judas-Sell");
         dailyTrades++;
        }
     }
  }
