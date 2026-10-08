//+------------------------------------------------------------------+
//|  FX_WOLF_EA.mq5                                                  |
//|  Strategy: Volume Profile POC + Cumulative Delta Divergence      |
//|  Channel:  FX WOLF (@FX_WOLF__1)                                |
//|  Version:  1.01  |  2026-09-13 (fix: long[] for CopyTickVolume) |
//+------------------------------------------------------------------+
#property copyright "Youtube-Traders Pipeline"
#property version   "1.01"
#property strict
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Risk Management ==="
input double   RiskPercent       = 1.0;
input bool     UseFixedLot       = false;
input double   FixedLot          = 0.01;

input group "=== Volume Profile ==="
input int      VP_Bars           = 48;
input double   HVN_Multiplier    = 1.5;
input double   LVN_Multiplier    = 0.5;

input group "=== CDV Parameters ==="
input int      CDV_Period        = 20;
input double   CDV_DivThreshold  = 0.25;

input group "=== Trade Parameters ==="
input double   ATR_SL_Multi      = 1.5;
input int      ATR_Period        = 14;
input double   MaxATR_Range      = 10.0;
input int      MaxDailyTrades    = 4;

input group "=== Sessions ==="
input int      SessionStart1     = 0;
input int      SessionEnd1       = 6;
input int      SessionStart2     = 13;
input int      SessionEnd2       = 17;

input group "=== Filters ==="
input double   MaxSpread         = 25.0;

CTrade trade;
CPositionInfo pos;
int dailyTrades=0, atrHandle;
datetime lastTradeDay=0;

int OnInit()
  {
   trade.SetExpertMagicNumber(20260003);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   atrHandle=iATR(_Symbol,PERIOD_M15,ATR_Period);
   if(atrHandle==INVALID_HANDLE) return(INIT_FAILED);
   Print("FX_WOLF EA initialized on ",_Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason){IndicatorRelease(atrHandle);}

void OnTick()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime today=StringToTime(StringFormat("%04d.%02d.%02d 00:00",dt.year,dt.mon,dt.day));
   if(lastTradeDay!=today){dailyTrades=0;lastTradeDay=today;}
   if(dailyTrades>=MaxDailyTrades) return;
   if(!IsWithinSession()) return;
   if((double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)>MaxSpread) return;

   static datetime lastBar=0;
   datetime curBar=iTime(_Symbol,PERIOD_M5,0);
   if(lastBar==curBar) return;
   lastBar=curBar;

   if(HasOpenPosition()) return;

   double atrBuf[1];
   ArraySetAsSeries(atrBuf,true);
   if(CopyBuffer(atrHandle,0,1,1,atrBuf)<1) return;

   double poc=CalculatePOC();
   if(poc==0) return;

   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double pip=_Point*10;

   int cdvSignal=GetCDVDivergence();
   if(cdvSignal==0) return;

   if(MathAbs(bid-poc)>10*pip) return;

   if(cdvSignal==1)
     {
      double sl=ask-ATR_SL_Multi*atrBuf[0];
      double slPips=(ask-sl)/pip;
      double tp=ask+2.0*ATR_SL_Multi*atrBuf[0];
      double lots=CalculateLotSize(slPips);
      if(lots>0&&trade.Buy(lots,_Symbol,ask,sl,tp,"WOLF_BUY")) dailyTrades++;
     }
   else if(cdvSignal==-1)
     {
      double sl=bid+ATR_SL_Multi*atrBuf[0];
      double slPips=(sl-bid)/pip;
      double tp=bid-2.0*ATR_SL_Multi*atrBuf[0];
      double lots=CalculateLotSize(slPips);
      if(lots>0&&trade.Sell(lots,_Symbol,bid,sl,tp,"WOLF_SELL")) dailyTrades++;
     }
  }

double CalculatePOC()
  {
   double h[],l[];
   long   v[];
   ArraySetAsSeries(h,true); ArraySetAsSeries(l,true); ArraySetAsSeries(v,true);
   if(CopyHigh(_Symbol,PERIOD_M5,1,VP_Bars,h)<VP_Bars) return 0;
   if(CopyLow(_Symbol,PERIOD_M5,1,VP_Bars,l)<VP_Bars) return 0;
   if(CopyTickVolume(_Symbol,PERIOD_M5,1,VP_Bars,v)<VP_Bars) return 0;
   int maxIdx=0;
   long maxVol=0;
   for(int i=0;i<VP_Bars;i++)
      if(v[i]>maxVol){maxVol=v[i];maxIdx=i;}
   return (h[maxIdx]+l[maxIdx])/2.0;
  }

int GetCDVDivergence()
  {
   double o[],c[];
   long   v[];
   ArraySetAsSeries(o,true); ArraySetAsSeries(c,true); ArraySetAsSeries(v,true);
   if(CopyOpen(_Symbol,PERIOD_M5,1,CDV_Period,o)<CDV_Period) return 0;
   if(CopyClose(_Symbol,PERIOD_M5,1,CDV_Period,c)<CDV_Period) return 0;
   if(CopyTickVolume(_Symbol,PERIOD_M5,1,CDV_Period,v)<CDV_Period) return 0;

   double priceDir=c[0]-c[CDV_Period-1];
   double cdvEarly=0, cdvLate=0;
   int half=CDV_Period/2;
   for(int i=CDV_Period-1;i>=half;i--)
      cdvEarly+=(c[i]>o[i])?(double)v[i]:-(double)v[i];
   for(int i=half-1;i>=0;i--)
      cdvLate+=(c[i]>o[i])?(double)v[i]:-(double)v[i];

   double maxVol=0;
   for(int i=0;i<CDV_Period;i++) if((double)v[i]>maxVol) maxVol=(double)v[i];
   if(maxVol==0) return 0;

   if(priceDir<0&&(cdvLate-cdvEarly)/maxVol>CDV_DivThreshold) return 1;
   if(priceDir>0&&(cdvEarly-cdvLate)/maxVol>CDV_DivThreshold) return -1;
   return 0;
  }

bool IsWithinSession()
  {
   MqlDateTime dt; TimeToStruct(TimeGMT(),dt);
   if(dt.day_of_week==0||dt.day_of_week==6) return false;
   int h=dt.hour;
   return (h>=SessionStart1&&h<SessionEnd1)||(h>=SessionStart2&&h<SessionEnd2);
  }

bool HasOpenPosition()
  {
   for(int i=0;i<PositionsTotal();i++)
      if(pos.SelectByIndex(i)&&pos.Symbol()==_Symbol&&pos.Magic()==20260003) return true;
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
