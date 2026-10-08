//+------------------------------------------------------------------+
//|  ACT_Forex_Academy_EA.mq5                                        |
//|  Strategy: Analyse-Confirm-Trade (A.C.T.) System                |
//|  Channel:  A.C.T. Forex Academy                                 |
//|  Version:  1.0  |  2026-09-13                                   |
//+------------------------------------------------------------------+
#property copyright "Youtube-Traders Pipeline"
#property version   "1.00"
#property strict
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Risk Management ==="
input double   RiskPercent         = 1.0;
input bool     UseFixedLot         = false;
input double   FixedLot            = 0.01;

input group "=== A.C.T. Parameters ==="
input int      LRC_Period          = 20;   // Linear regression channel period (4H)
input double   LRC_StdDev_Multi    = 1.5;  // StdDev multiplier for corridor
input int      Breakout_Lookback   = 10;   // 15M bars for consolidation
input double   Breakout_MinStrength= 0.60; // Min body ratio for breakout candle
input double   SL_BufferPips       = 5.0;

input group "=== Trade Parameters ==="
input double   TP1_RR              = 1.0;  // TP1 at 1:1
input double   TP1_ClosePercent    = 50.0; // % close at TP1
input double   TP2_RR              = 2.0;  // TP2 at 1:2
input int      MaxDailyTrades      = 2;

input group "=== Sessions ==="
input int      SessionStart1       = 7;    // London UTC
input int      SessionEnd1         = 10;
input int      SessionStart2       = 13;   // NY UTC
input int      SessionEnd2         = 16;

input group "=== Filters ==="
input double   MaxSpread           = 15.0; // STRICT
input bool     UseNewsFilter       = true;
input int      NewsBufferMin       = 30;
input string   NewsHour1           = "8:30";
input string   NewsHour2           = "13:30";

CTrade trade;
CPositionInfo pos;
int dailyTrades=0;
datetime lastTradeDay=0;
bool tp1Hit=false;

int OnInit()
  {
   trade.SetExpertMagicNumber(20260008);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   Print("ACT Forex Academy EA initialized on ",_Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason){}

void OnTick()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime today=StringToTime(StringFormat("%04d.%02d.%02d 00:00",dt.year,dt.mon,dt.day));
   if(lastTradeDay!=today){dailyTrades=0;lastTradeDay=today;}
   if(dailyTrades>=MaxDailyTrades) return;
   if(!IsWithinSession()) return;
   if(UseNewsFilter&&IsNearNews()) return;
   if((double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)>MaxSpread) return;

   static datetime lastBar=0;
   datetime curBar=iTime(_Symbol,PERIOD_M15,0);
   if(lastBar==curBar) return;
   lastBar=curBar;

   ManagePositions();
   if(HasOpenPosition()) return;

   // Step 1: ANALYSE - Get corridor bias from 4H
   int corridorBias=GetCorridorBias();
   if(corridorBias==0) return;

   // Step 2: CONFIRM - Breakout + retest on 15M
   int confirmDir=GetBreakoutRetest(corridorBias);
   if(confirmDir==0||confirmDir!=corridorBias) return;

   // Step 3: TRADE
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double pip=_Point*10;

   double recentHigh=iHigh(_Symbol,PERIOD_M15,1);
   double recentLow=iLow(_Symbol,PERIOD_M15,1);

   if(corridorBias==1)
     {
      double sl=recentLow-SL_BufferPips*pip;
      double slDist=ask-sl;
      double tp1=ask+TP1_RR*slDist;
      double tp2=ask+TP2_RR*slDist;
      double lots=CalculateLotSize(slDist/pip);
      if(lots>0&&trade.Buy(lots,_Symbol,ask,sl,tp2,"ACT_BUY")){dailyTrades++;tp1Hit=false;}
     }
   else
     {
      double sl=recentHigh+SL_BufferPips*pip;
      double slDist=sl-bid;
      double tp1=bid-TP1_RR*slDist;
      double tp2=bid-TP2_RR*slDist;
      double lots=CalculateLotSize(slDist/pip);
      if(lots>0&&trade.Sell(lots,_Symbol,bid,sl,tp2,"ACT_SELL")){dailyTrades++;tp1Hit=false;}
     }
  }

int GetCorridorBias()
  {
   // Linear regression slope on 4H
   double c[];
   ArraySetAsSeries(c,true);
   if(CopyClose(_Symbol,PERIOD_H4,1,LRC_Period,c)<LRC_Period) return 0;
   // Simple slope: compare average of first half vs second half
   double sumEarly=0,sumLate=0;
   int half=LRC_Period/2;
   for(int i=0;i<half;i++) sumLate+=c[i];
   for(int i=half;i<LRC_Period;i++) sumEarly+=c[i];
   double slope=(sumLate/half)-(sumEarly/half);
   double pip=_Point*10;
   if(slope>5*pip) return 1;  // Bullish corridor
   if(slope<-5*pip) return -1; // Bearish corridor
   return 0;
  }

int GetBreakoutRetest(int bias)
  {
   double h[],l[],c[],o[];
   ArraySetAsSeries(h,true); ArraySetAsSeries(l,true);
   ArraySetAsSeries(c,true); ArraySetAsSeries(o,true);
   if(CopyHigh(_Symbol,PERIOD_M15,1,Breakout_Lookback,h)<Breakout_Lookback) return 0;
   if(CopyLow(_Symbol,PERIOD_M15,1,Breakout_Lookback,l)<Breakout_Lookback) return 0;
   if(CopyClose(_Symbol,PERIOD_M15,1,Breakout_Lookback,c)<Breakout_Lookback) return 0;
   if(CopyOpen(_Symbol,PERIOD_M15,1,Breakout_Lookback,o)<Breakout_Lookback) return 0;

   double pip=_Point*10;
   if(bias==1)
     {
      // Find highest close in recent range
      double resistance=h[ArrayMaximum(h,1,Breakout_Lookback-1)];
      // Most recent bar: breakout above resistance with strong body
      double bodyRatio=MathAbs(c[0]-o[0])/(h[0]-l[0]+_Point);
      if(c[0]>resistance&&bodyRatio>=Breakout_MinStrength) return 1;
     }
   else if(bias==-1)
     {
      double support=l[ArrayMinimum(l,1,Breakout_Lookback-1)];
      double bodyRatio=MathAbs(c[0]-o[0])/(h[0]-l[0]+_Point);
      if(c[0]<support&&bodyRatio>=Breakout_MinStrength) return -1;
     }
   return 0;
  }

void ManagePositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=20260008) continue;
      if(tp1Hit) continue;
      double ep=pos.PriceOpen(), pip=_Point*10;
      double tp=pos.TakeProfit(), sl=pos.StopLoss();
      double slDist=MathAbs(ep-sl);
      bool atTP1=false;
      if(pos.PositionType()==POSITION_TYPE_BUY)
         atTP1=(SymbolInfoDouble(_Symbol,SYMBOL_BID)-ep>=TP1_RR*slDist*0.95);
      else
         atTP1=(ep-SymbolInfoDouble(_Symbol,SYMBOL_ASK)>=TP1_RR*slDist*0.95);
      if(atTP1)
        {
         double cv=NormalizeDouble(pos.Volume()*TP1_ClosePercent/100.0,2);
         if(cv>=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN)) trade.PositionClosePartial(pos.Ticket(),cv);
         trade.PositionModify(pos.Ticket(),ep,tp);
         tp1Hit=true;
        }
     }
  }

bool IsWithinSession()
  {
   MqlDateTime dt; TimeToStruct(TimeGMT(),dt);
   if(dt.day_of_week==0||dt.day_of_week==6) return false;
   int h=dt.hour;
   return (h>=SessionStart1&&h<SessionEnd1)||(h>=SessionStart2&&h<SessionEnd2);
  }

bool IsNearNews()
  {
   MqlDateTime dt; TimeToStruct(TimeGMT(),dt);
   string nh[2]; nh[0]=NewsHour1; nh[1]=NewsHour2;
   for(int i=0;i<2;i++)
     {
      if(nh[i]=="") continue;
      string p[]; StringSplit(nh[i],':',p);
      if(ArraySize(p)!=2) continue;
      int ev=(int)StringToInteger(p[0])*60+(int)StringToInteger(p[1]);
      if(MathAbs(dt.hour*60+dt.min-ev)<=NewsBufferMin) return true;
     }
   return false;
  }

bool HasOpenPosition()
  {
   for(int i=0;i<PositionsTotal();i++)
      if(pos.SelectByIndex(i)&&pos.Symbol()==_Symbol&&pos.Magic()==20260008) return true;
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
