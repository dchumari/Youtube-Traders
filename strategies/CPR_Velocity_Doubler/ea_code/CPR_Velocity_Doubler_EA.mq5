//+------------------------------------------------------------------+
//| CPR_Velocity_Doubler_EA.mq5                                      |
//| Strategy 1: Institutional CPR Compression + FVG Velocity Scalper  |
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
input double Target_RR             = 2.8;              // Target Reward:Risk (2.8R)

input group "=== CPR & FVG Velocity Parameters ==="
input double CPR_NarrowMaxPips     = 18.0;             // Max Narrow CPR Width (Pips)
input double Min_FVG_Pips          = 2.5;              // Minimum Displacement FVG (Pips)
input double VolMultiplier         = 1.25;             // Volume Surge Multiplier
input int    StartHourUTC          = 13;               // NY Session Start UTC
input int    EndHourUTC            = 19;               // NY Session End UTC
input int    MaxDailyTrades        = 4;                // Max Trades per Day
input int    MaxDailyLosses        = 2;                // Circuit Breaker Max Losses
input ulong  MagicNumber           = 20265001;         // Magic Number

CTrade trade;
CPositionInfo pos;
int dailyTrades = 0;
int dailyLosses = 0;
datetime lastTradeDay = 0;

double cpr_TC = 0.0, cpr_BC = 0.0, cpr_Pivot = 0.0, cpr_Width = 0.0;
datetime lastCPRDate = 0;

int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) {}

void UpdateCPR()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastCPRDate == today) return;
   lastCPRDate = today;

   double dH[], dL[], dC[];
   ArraySetAsSeries(dH, true); ArraySetAsSeries(dL, true); ArraySetAsSeries(dC, true);
   if(CopyHigh(_Symbol, PERIOD_D1, 1, 1, dH) < 1 || CopyLow(_Symbol, PERIOD_D1, 1, 1, dL) < 1 || CopyClose(_Symbol, PERIOD_D1, 1, 1, dC) < 1) return;

   cpr_Pivot = (dH[0] + dL[0] + dC[0]) / 3.0;
   cpr_BC    = (dH[0] + dL[0]) / 2.0;
   cpr_TC    = (cpr_Pivot - cpr_BC) + cpr_Pivot;
   cpr_Width = MathAbs(cpr_TC - cpr_BC) / (_Point * 10);
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
   if(dt.hour < StartHourUTC || dt.hour >= EndHourUTC) return;

   UpdateCPR();

   static datetime lastBar = 0;
   datetime curBar = iTime(_Symbol, _Period, 0);
   if(lastBar == curBar) return;
   lastBar = curBar;

   if(HasOpenPosition()) return;
   if(cpr_Width > CPR_NarrowMaxPips || cpr_Width <= 0.0) return;

   double pip = _Point * 10;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 5, rates) < 5) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Volume filter
   long vols[];
   ArraySetAsSeries(vols, true);
   CopyTickVolume(_Symbol, _Period, 1, 20, vols);
   double sumV = 0.0;
   for(int v = 0; v < 20; v++) sumV += (double)vols[v];
   double avgV = sumV / 20.0;
   bool volSurge = ((double)rates[1].tick_volume > avgV * VolMultiplier);

   // FVG logic
   bool bullFVG = (rates[0].low > rates[2].high + Min_FVG_Pips * pip);
   bool bearFVG = (rates[2].low > rates[0].high + Min_FVG_Pips * pip);

   int sig = 0;
   if(bullFVG && rates[0].close > cpr_TC && volSurge) sig = 1;
   else if(bearFVG && rates[0].close < cpr_BC && volSurge) sig = -1;

   if(sig != 0)
     {
      double sl = (sig > 0) ? NormalizeDouble(ask - SL_Pips * pip, _Digits)
                            : NormalizeDouble(bid + SL_Pips * pip, _Digits);
      double tp = (sig > 0) ? NormalizeDouble(ask + Target_RR * SL_Pips * pip, _Digits)
                            : NormalizeDouble(bid - Target_RR * SL_Pips * pip, _Digits);
      double lots = CalculateLots(SL_Pips);
      if(lots > 0)
        {
         if(sig > 0) trade.Buy(lots, _Symbol, ask, sl, tp, "CPR-Velocity-Buy");
         else        trade.Sell(lots, _Symbol, bid, sl, tp, "CPR-Velocity-Sell");
         dailyTrades++;
        }
     }
  }
