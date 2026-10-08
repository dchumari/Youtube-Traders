//+------------------------------------------------------------------+
//|  DonVo_EA.mq5                                                    |
//|  Strategy: Drive Range Liquidity (DRL) - Session Sweep          |
//|  Channel:  DonVo (DVS / @itsdonvo)                              |
//|  Version:  1.0  |  2026-09-13                                   |
//+------------------------------------------------------------------+
#property copyright "Youtube-Traders Pipeline"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Risk Management ==="
input double   RiskPercent       = 1.0;
input bool     UseFixedLot       = false;
input double   FixedLot          = 0.01;

input group "=== Session Ranges ==="
input int      AsianStartHour    = 0;       // UTC
input int      AsianEndHour      = 6;       // UTC
input int      LondonStartHour   = 7;       // UTC
input int      LondonEndHour     = 10;      // UTC
input int      NYStartHour       = 13;      // UTC
input int      NYEndHour         = 18;      // UTC

input group "=== Sweep Parameters ==="
input double   SweepMinPips      = 5.0;    // Minimum pip sweep beyond level
input double   SweepMaxPips      = 30.0;   // Maximum pip sweep (above = real breakout)
input int      SweepConfirmBars  = 3;      // Max 5M bars to return below level
input double   SL_BufferPips     = 5.0;    // Buffer pips beyond sweep wick

input group "=== Trade Parameters ==="
input double   TP1_Percent       = 50.0;   // % close at Asian midpoint
input double   MinRR             = 2.0;
input int      MaxDailyTrades    = 2;

input group "=== Filters ==="
input double   MaxSpread         = 20.0;
input bool     UseNewsFilter     = true;
input int      NewsBufferMin     = 30;
input string   NewsHour1         = "13:30";
input string   NewsHour2         = "14:00";
input string   NewsHour3         = "";

CTrade trade;
CPositionInfo pos;
int dailyTrades = 0;
datetime lastTradeDay = 0;

// Session ranges
double asianHigh=0, asianLow=0, asianMid=0;
double londonHigh=0, londonLow=0;
bool   asianRangeSet=false, londonRangeSet=false;
bool   tp1Hit=false;

int OnInit()
  {
   trade.SetExpertMagicNumber(20260004);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   Print("DonVo DRL EA initialized on ", _Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) {}

void OnTick()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   static datetime lastDay = 0;
   if(lastDay != today) { dailyTrades=0; lastDay=today; asianRangeSet=false; londonRangeSet=false; asianHigh=0; asianLow=0; londonHigh=0; londonLow=0; }

   if(dailyTrades >= MaxDailyTrades) return;
   if((double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD) > MaxSpread) return;
   if(UseNewsFilter && IsNearNews()) return;

   static datetime lastBar5M = 0;
   datetime curBar5M = iTime(_Symbol,PERIOD_M5,0);
   if(lastBar5M == curBar5M) return;
   lastBar5M = curBar5M;

   MqlDateTime gmt; TimeToStruct(TimeGMT(),gmt);
   int gmtHour = gmt.hour;

   // Build Asian range at session close
   if(!asianRangeSet && gmtHour >= AsianEndHour)
      BuildAsianRange();

   // Build London range at session close
   if(!londonRangeSet && gmtHour >= LondonEndHour)
      BuildLondonRange();

   // Manage positions (partial close at midpoint)
   ManagePositions();

   // Only trade during NY session
   if(gmtHour < NYStartHour || gmtHour >= NYEndHour) return;
   if(!asianRangeSet && !londonRangeSet) return;
   if(HasOpenPosition()) return;

   // Look for sweep and entry
   CheckForSweepEntry();
  }

void BuildAsianRange()
  {
   datetime asianStart = GetSessionStart(AsianStartHour);
   datetime asianEnd   = GetSessionStart(AsianEndHour);
   double h[], l[];
   ArraySetAsSeries(h,true); ArraySetAsSeries(l,true);
   int bars = Bars(_Symbol,PERIOD_M5,asianStart,asianEnd);
   if(bars <= 0) return;
   if(CopyHigh(_Symbol,PERIOD_M5,asianEnd,bars+1,h) < bars) return;
   if(CopyLow(_Symbol,PERIOD_M5,asianEnd,bars+1,l) < bars) return;
   asianHigh = h[ArrayMaximum(h,0,bars)];
   asianLow  = l[ArrayMinimum(l,0,bars)];
   asianMid  = (asianHigh + asianLow) / 2.0;
   asianRangeSet = (asianHigh - asianLow > 15 * _Point * 10);
  }

void BuildLondonRange()
  {
   datetime londonStart = GetSessionStart(LondonStartHour);
   datetime londonEnd   = GetSessionStart(LondonEndHour);
   double h[], l[];
   ArraySetAsSeries(h,true); ArraySetAsSeries(l,true);
   int bars = Bars(_Symbol,PERIOD_M5,londonStart,londonEnd);
   if(bars <= 0) return;
   if(CopyHigh(_Symbol,PERIOD_M5,londonEnd,bars+1,h) < bars) return;
   if(CopyLow(_Symbol,PERIOD_M5,londonEnd,bars+1,l) < bars) return;
   londonHigh = h[ArrayMaximum(h,0,bars)];
   londonLow  = l[ArrayMinimum(l,0,bars)];
   londonRangeSet = true;
  }

datetime GetSessionStart(int hour)
  {
   MqlDateTime dt; TimeToStruct(TimeGMT(),dt);
   dt.hour=hour; dt.min=0; dt.sec=0;
   return StructToTime(dt);
  }

void CheckForSweepEntry()
  {
   double pip = _Point * 10;
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   // Determine active range high/low
   double rHigh = asianHigh, rLow = asianLow;
   if(londonRangeSet)
     {
      rHigh = MathMax(asianHigh, londonHigh);
      rLow  = MathMin(asianLow,  londonLow);
     }

   // Check last N candles for sweep above range high (then close back below)
   double hHigh[], hLow[], hClose[];
   ArraySetAsSeries(hHigh,true); ArraySetAsSeries(hLow,true); ArraySetAsSeries(hClose,true);
   if(CopyHigh(_Symbol,PERIOD_M5,1,SweepConfirmBars+1,hHigh) < SweepConfirmBars) return;
   if(CopyLow(_Symbol,PERIOD_M5,1,SweepConfirmBars+1,hLow) < SweepConfirmBars) return;
   if(CopyClose(_Symbol,PERIOD_M5,1,SweepConfirmBars+1,hClose) < SweepConfirmBars) return;

   // BEARISH SWEEP: spike above rHigh then close back below
   for(int i=0;i<SweepConfirmBars;i++)
     {
      double sweepAmount = (hHigh[i] - rHigh) / pip;
      if(sweepAmount >= SweepMinPips && sweepAmount <= SweepMaxPips && hClose[i] < rHigh)
        {
         // Valid bearish sweep confirmed
         double sweepWickHigh = hHigh[0]; // highest of recent bars
         double sl = sweepWickHigh + SL_BufferPips * pip;
         double target = (asianRangeSet) ? asianLow : rLow;
         double slDist = sl - bid;
         double tpDist = bid - target;
         if(tpDist < MinRR * slDist) return;
         double lots = CalculateLotSize(slDist / pip);
         if(lots > 0 && trade.Sell(lots,_Symbol,bid,sl,target,"DRL_SELL")) { dailyTrades++; tp1Hit=false; }
         return;
        }
     }

   // BULLISH SWEEP: spike below rLow then close back above
   for(int i=0;i<SweepConfirmBars;i++)
     {
      double sweepAmount = (rLow - hLow[i]) / pip;
      if(sweepAmount >= SweepMinPips && sweepAmount <= SweepMaxPips && hClose[i] > rLow)
        {
         double sweepWickLow = hLow[0];
         double sl = sweepWickLow - SL_BufferPips * pip;
         double target = (asianRangeSet) ? asianHigh : rHigh;
         double slDist = ask - sl;
         double tpDist = target - ask;
         if(tpDist < MinRR * slDist) return;
         double lots = CalculateLotSize(slDist / pip);
         if(lots > 0 && trade.Buy(lots,_Symbol,ask,sl,target,"DRL_BUY")) { dailyTrades++; tp1Hit=false; }
         return;
        }
     }
  }

void ManagePositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=20260004) continue;
      double ep=pos.PriceOpen(), pip=_Point*10;
      // Partial close at Asian midpoint
      if(!tp1Hit && asianMid > 0)
        {
         bool atMid = (pos.PositionType()==POSITION_TYPE_SELL && SymbolInfoDouble(_Symbol,SYMBOL_ASK)<=asianMid) ||
                      (pos.PositionType()==POSITION_TYPE_BUY  && SymbolInfoDouble(_Symbol,SYMBOL_BID)>=asianMid);
         if(atMid)
           {
            double cv=NormalizeDouble(pos.Volume()*TP1_Percent/100.0,2);
            if(cv>=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN)) trade.PositionClosePartial(pos.Ticket(),cv);
            trade.PositionModify(pos.Ticket(),ep,pos.TakeProfit());
            tp1Hit=true;
           }
        }
     }
  }

bool IsNearNews()
  {
   MqlDateTime dt; TimeToStruct(TimeGMT(),dt);
   string nh[3]; nh[0]=NewsHour1; nh[1]=NewsHour2; nh[2]=NewsHour3;
   for(int i=0;i<3;i++)
     {
      if(nh[i]=="") continue;
      string p[]; StringSplit(nh[i],':',p);
      if(ArraySize(p)!=2) continue;
      int evMin=(int)StringToInteger(p[0])*60+(int)StringToInteger(p[1]);
      int nowMin=dt.hour*60+dt.min;
      if(MathAbs(nowMin-evMin)<=NewsBufferMin) return true;
     }
   return false;
  }

bool HasOpenPosition()
  {
   for(int i=0;i<PositionsTotal();i++)
      if(pos.SelectByIndex(i)&&pos.Symbol()==_Symbol&&pos.Magic()==20260004) return true;
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
