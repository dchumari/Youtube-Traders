//+------------------------------------------------------------------+
//|  WicksDontLie_EA.mq5                                             |
//|  Strategy: Price Action Clean Range + Wick Rejection             |
//|  Channel:  WicksDontLie (Raja Banks)                            |
//|  Version:  1.0  |  2026-09-13                                   |
//+------------------------------------------------------------------+
#property copyright "Youtube-Traders Pipeline"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Inputs
input group "=== Risk Management ==="
input double   RiskPercent       = 1.0;     // Risk per trade (%)
input bool     UseFixedLot       = false;   // Use fixed lot instead of risk %
input double   FixedLot          = 0.01;    // Fixed lot size

input group "=== Range Detection ==="
input int      RangePeriod       = 20;      // Donchian channel lookback (1H bars)
input double   ATR_RangeFilter   = 15.0;   // Max ATR (points) for clean range condition
input double   WickRatioMin      = 0.60;   // Minimum wick-to-total-range ratio

input group "=== Trade Parameters ==="
input double   SL_Pips           = 12.0;   // Stop loss in pips
input double   TP1_Pips          = 12.0;   // Take profit 1 in pips
input double   TP1_ClosePercent  = 75.0;   // % of position to close at TP1
input int      MaxDailyTrades    = 3;       // Max trades per day

input group "=== Session Filter ==="
input int      SessionStartHour  = 11;     // Session start UTC (NY Open)
input int      SessionEndHour    = 17;     // Session end UTC

input group "=== Filters ==="
input double   MaxSpread         = 20.0;   // Max spread in points
input double   MaxATR_Trade      = 40.0;   // Max ATR (pips) to avoid extreme volatility
input double   MaxDailyLoss_Pct  = 2.0;   // Stop trading if daily loss > X%
input int      ATR_Period        = 14;     // ATR period

//--- Global variables
CTrade         trade;
CPositionInfo  pos;
int            dailyTrades       = 0;
datetime       lastTradeDay      = 0;
double         dailyStartBalance = 0;
int            atrHandle;

//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(20260001);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   atrHandle = iATR(_Symbol, PERIOD_H1, ATR_Period);
   if(atrHandle == INVALID_HANDLE) return(INIT_FAILED);
   Print("WicksDontLie EA initialized on ", _Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) { IndicatorRelease(atrHandle); }

void OnTick()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastTradeDay != today) { dailyTrades = 0; lastTradeDay = today; dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE); }

   double curBal = AccountInfoDouble(ACCOUNT_BALANCE);
   if(dailyStartBalance > 0 && (dailyStartBalance - curBal) / dailyStartBalance * 100 >= MaxDailyLoss_Pct) return;
   if(dailyTrades >= MaxDailyTrades) return;
   if(!IsWithinSession()) return;
   if((double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpread) return;

   static datetime lastBar = 0;
   datetime currentBar = iTime(_Symbol, PERIOD_M5, 0);
   if(lastBar == currentBar) return;
   lastBar = currentBar;

   ManagePositions();
   if(HasOpenPosition()) return;

   double rHigh, rLow;
   if(!GetDonchianRange(rHigh, rLow)) return;

   double atrBuf[1];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(atrHandle, 0, 1, 1, atrBuf) < 1) return;
   double atrPips = atrBuf[0] / (_Point * 10);
   if(atrPips > ATR_RangeFilter || atrPips > MaxATR_Trade) return;

   int signal = GetWickSignal(rHigh, rLow);
   if(signal == 0) return;

   double lotSize = CalculateLotSize(SL_Pips);
   if(lotSize <= 0) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pip = _Point * 10;

   if(signal == 1)
     { if(trade.Buy(lotSize, _Symbol, ask, ask - SL_Pips*pip, ask + TP1_Pips*pip, "WDL_BUY")) dailyTrades++; }
   else if(signal == -1)
     { if(trade.Sell(lotSize, _Symbol, bid, bid + SL_Pips*pip, bid - TP1_Pips*pip, "WDL_SELL")) dailyTrades++; }
  }

bool GetDonchianRange(double &rHigh, double &rLow)
  {
   double h[], l[];
   ArraySetAsSeries(h, true); ArraySetAsSeries(l, true);
   if(CopyHigh(_Symbol, PERIOD_H1, 1, RangePeriod, h) < RangePeriod) return false;
   if(CopyLow(_Symbol, PERIOD_H1, 1, RangePeriod, l) < RangePeriod) return false;
   rHigh = h[ArrayMaximum(h, 0, RangePeriod)];
   rLow  = l[ArrayMinimum(l, 0, RangePeriod)];
   return true;
  }

int GetWickSignal(double rHigh, double rLow)
  {
   double o = iOpen(_Symbol,PERIOD_M5,1), h = iHigh(_Symbol,PERIOD_M5,1);
   double l = iLow(_Symbol,PERIOD_M5,1), c = iClose(_Symbol,PERIOD_M5,1);
   double range = h - l;
   if(range < _Point * 5) return 0;
   double tol = 15 * _Point * 10;
   if(l <= rLow + tol) { double lw = MathMin(o,c)-l; if(lw/range>=WickRatioMin && c>l+range*0.5) return 1; }
   if(h >= rHigh - tol) { double uw = h-MathMax(o,c); if(uw/range>=WickRatioMin && c<h-range*0.5) return -1; }
   return 0;
  }

void ManagePositions()
  {
   for(int i = PositionsTotal()-1; i >= 0; i--)
     {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol || pos.Magic()!=20260001) continue;
      double ep = pos.PriceOpen(), pip = _Point*10;
      double plPips = (pos.PositionType()==POSITION_TYPE_BUY) ? (SymbolInfoDouble(_Symbol,SYMBOL_BID)-ep)/pip : (ep-SymbolInfoDouble(_Symbol,SYMBOL_ASK))/pip;
      if(plPips >= TP1_Pips*0.95 && pos.StopLoss()!=ep)
        {
         double cv = NormalizeDouble(pos.Volume()*TP1_ClosePercent/100.0,2);
         if(cv >= SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN)) trade.PositionClosePartial(pos.Ticket(),cv);
         trade.PositionModify(pos.Ticket(),ep,0);
        }
     }
  }

bool IsWithinSession()
  {
   MqlDateTime dt; TimeToStruct(TimeGMT(),dt);
   if(dt.day_of_week==0||dt.day_of_week==6) return false;
   return (dt.hour>=SessionStartHour && dt.hour<SessionEndHour);
  }

bool HasOpenPosition()
  {
   for(int i=0;i<PositionsTotal();i++)
      if(pos.SelectByIndex(i)&&pos.Symbol()==_Symbol&&pos.Magic()==20260001) return true;
   return false;
  }

double CalculateLotSize(double slPips)
  {
   if(UseFixedLot) return NormalizeDouble(FixedLot,2);
   double bal=AccountInfoDouble(ACCOUNT_BALANCE);
   double risk=bal*RiskPercent/100.0;
   double pip=_Point*10;
   double tv=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double ts=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double pv=(pip/ts)*tv;
   double lots=risk/(slPips*pv);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   lots=MathFloor(lots/step)*step;
   return NormalizeDouble(MathMax(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN),MathMin(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX),lots)),2);
  }
