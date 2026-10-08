//+------------------------------------------------------------------+
//| SMT_Void_Doubler_EA.mq5                                          |
//| Strategy 3: SMT Synthetic Divergence + Liquidity Void Harvester  |
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
input double SL_Pips               = 14.0;             // Base Stop Loss (Pips)
input double Target_RR             = 3.0;              // Target Reward:Risk (3.0R)

input group "=== SMT & Void Parameters ==="
input double Sweep_Pips            = 2.5;              // Liquidity Sweep Buffer (Pips)
input int    StartHourUTC          = 12;               // Session Start UTC
input int    EndHourUTC            = 19;               // Session End UTC
input int    MaxDailyTrades        = 4;                // Max Trades per Day
input int    MaxDailyLosses        = 2;                // Circuit Breaker Max Losses
input ulong  MagicNumber           = 20265003;         // Magic Number

CTrade trade;
CPositionInfo pos;
int dailyTrades = 0;
int dailyLosses = 0;
datetime lastTradeDay = 0;

double pdh = 0.0, pdl = 0.0;
datetime lastD1Date = 0;

int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) {}

void UpdatePDH_PDL()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastD1Date == today) return;
   lastD1Date = today;

   double dH[], dL[];
   ArraySetAsSeries(dH, true); ArraySetAsSeries(dL, true);
   if(CopyHigh(_Symbol, PERIOD_D1, 1, 1, dH) >= 1 && CopyLow(_Symbol, PERIOD_D1, 1, 1, dL) >= 1)
     {
      pdh = dH[0];
      pdl = dL[0];
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
   if(dt.hour < StartHourUTC || dt.hour >= EndHourUTC) return;

   UpdatePDH_PDL();

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

   // SMT Liquidity Void Sweep: Bar 1 sweeps PDH/PDL or structural extreme, but Bar 0 rejects strongly
   int sig = 0;
   if(pdl > 0 && rates[1].low <= pdl - Sweep_Pips * pip && rates[0].close > pdl)
     {
      // Smart money accumulation shift
      sig = 1;
     }
   else if(pdh > 0 && rates[1].high >= pdh + Sweep_Pips * pip && rates[0].close < pdh)
     {
      // Smart money distribution shift
      sig = -1;
     }

   if(sig != 0)
     {
      double sl = (sig > 0) ? NormalizeDouble(ask - SL_Pips * pip, _Digits)
                            : NormalizeDouble(bid + SL_Pips * pip, _Digits);
      double tp = (sig > 0) ? NormalizeDouble(ask + Target_RR * SL_Pips * pip, _Digits)
                            : NormalizeDouble(bid - Target_RR * SL_Pips * pip, _Digits);
      double lots = CalculateLots(SL_Pips);
      if(lots > 0)
        {
         if(sig > 0) trade.Buy(lots, _Symbol, ask, sl, tp, "SMT-Void-Buy");
         else        trade.Sell(lots, _Symbol, bid, sl, tp, "SMT-Void-Sell");
         dailyTrades++;
        }
     }
  }
