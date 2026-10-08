//+------------------------------------------------------------------+
//|  Lorenzo_Corrado_EA.mq5                                          |
//|  Strategy: LTA Concepts - Volume OB + DXY Correlation           |
//|  Channel:  Lorenzo Corrado                                      |
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

input group "=== LTA Parameters ==="
input double   OB_VolMultiplier    = 1.8;  // Volume multiplier for OB detection
input int      OB_AvgPeriod        = 20;   // Bars for average volume
input double   OB_MinImpulse_Pips  = 15.0; // Min impulse after OB
input int      DXY_StructureBars   = 10;   // 4H bars for DXY trend

input group "=== Trade Parameters ==="
input double   MaxDailyDD_Pct      = 4.0;  // Max daily drawdown
input int      MaxDailyTrades      = 3;

input group "=== Sessions ==="
input int      SessionStartHour    = 13;   // NY UTC
input int      SessionEndHour      = 18;

input group "=== Filters ==="
input double   MaxSpread           = 25.0;
input bool     UseDXY_Filter       = true;
input string   DXY_Symbol          = "EURUSD"; // EURUSD as DXY proxy (inverse)

CTrade trade;
CPositionInfo pos;
int dailyTrades=0;
datetime lastTradeDay=0;
double dailyStartBalance=0;

struct VolOB
  {
   double high, low;
   int    type;   // 1=bull, -1=bear
   bool   valid;
  };
VolOB currentOB;

int OnInit()
  {
   trade.SetExpertMagicNumber(20260006);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   currentOB.valid=false;
   Print("Lorenzo Corrado LTA EA initialized on ",_Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason){}

void OnTick()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime today=StringToTime(StringFormat("%04d.%02d.%02d 00:00",dt.year,dt.mon,dt.day));
   if(lastTradeDay!=today){dailyTrades=0;lastTradeDay=today;dailyStartBalance=AccountInfoDouble(ACCOUNT_BALANCE);}

   // Daily DD check
   double curBal=AccountInfoDouble(ACCOUNT_BALANCE);
   if(dailyStartBalance>0&&(dailyStartBalance-curBal)/dailyStartBalance*100>=MaxDailyDD_Pct) return;
   if(dailyTrades>=MaxDailyTrades) return;

   MqlDateTime gmt; TimeToStruct(TimeGMT(),gmt);
   if(gmt.day_of_week==0||gmt.day_of_week==6) return;
   if(gmt.hour<SessionStartHour||gmt.hour>=SessionEndHour) return;
   if((double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)>MaxSpread) return;

   // Scan for OB on H1 candle close
   static datetime lastH1=0;
   datetime curH1=iTime(_Symbol,PERIOD_H1,0);
   if(lastH1!=curH1){lastH1=curH1; ScanVolumeOB();}

   static datetime lastM5=0;
   datetime curM5=iTime(_Symbol,PERIOD_M5,0);
   if(lastM5==curM5) return;
   lastM5=curM5;

   if(HasOpenPosition()||!currentOB.valid) return;

   // DXY filter
   if(UseDXY_Filter&&!DXY_Aligned(currentOB.type)) return;

   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double pip=_Point*10;

   if(currentOB.type==1&&ask<=currentOB.high&&ask>=currentOB.low)
     {
      double sl=currentOB.low-5*pip;
      double tp=GetWarMapTarget(1);
      if(tp==0||tp-ask<2.0*(ask-sl)) return;
      double lots=CalculateLotSize((ask-sl)/pip);
      if(lots>0&&trade.Buy(lots,_Symbol,ask,sl,tp,"LTA_BUY")){dailyTrades++;currentOB.valid=false;}
     }
   else if(currentOB.type==-1&&bid>=currentOB.low&&bid<=currentOB.high)
     {
      double sl=currentOB.high+5*pip;
      double tp=GetWarMapTarget(-1);
      if(tp==0||bid-tp<2.0*(sl-bid)) return;
      double lots=CalculateLotSize((sl-bid)/pip);
      if(lots>0&&trade.Sell(lots,_Symbol,bid,sl,tp,"LTA_SELL")){dailyTrades++;currentOB.valid=false;}
     }
  }

void ScanVolumeOB()
  {
   double o[],c[],h[],l[];
   long v[];
   ArraySetAsSeries(o,true); ArraySetAsSeries(c,true);
   ArraySetAsSeries(h,true); ArraySetAsSeries(l,true); ArraySetAsSeries(v,true);
   int needed=OB_AvgPeriod+5;
   if(CopyOpen(_Symbol,PERIOD_H1,1,needed,o)<needed) return;
   if(CopyClose(_Symbol,PERIOD_H1,1,needed,c)<needed) return;
   if(CopyHigh(_Symbol,PERIOD_H1,1,needed,h)<needed) return;
   if(CopyLow(_Symbol,PERIOD_H1,1,needed,l)<needed) return;
   if(CopyTickVolume(_Symbol,PERIOD_H1,1,needed,v)<needed) return;

   // Compute avg volume
   double avgVol=0;
   for(int i=0;i<OB_AvgPeriod;i++) avgVol+=(double)v[i];
   avgVol/=OB_AvgPeriod;
   if(avgVol==0) return;

   double pip=_Point*10;
   // Look for recent OB with high volume + impulse
   for(int i=1;i<=5;i++)
     {
      if((double)v[i]<OB_VolMultiplier*avgVol) continue;
      bool bearCandle=(c[i]<o[i]);
      bool bullCandle=(c[i]>o[i]);
      // Bullish OB: high-vol bear candle followed by bullish impulse
      if(bearCandle&&c[i-1]-h[i]>OB_MinImpulse_Pips*pip)
        {
         double askNow=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         if(askNow>h[i]) continue;
         currentOB.high=h[i]; currentOB.low=l[i]; currentOB.type=1; currentOB.valid=true;
         return;
        }
      // Bearish OB: high-vol bull candle followed by bearish impulse
      if(bullCandle&&l[i]-c[i-1]>OB_MinImpulse_Pips*pip)
        {
         double bidNow=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         if(bidNow<l[i]) continue;
         currentOB.high=h[i]; currentOB.low=l[i]; currentOB.type=-1; currentOB.valid=true;
         return;
        }
     }
  }

bool DXY_Aligned(int goldDir)
  {
   // EURUSD as DXY proxy (inverse): if EURUSD 4H trending down = DXY up = Gold down
   if(DXY_Symbol=="") return true;
   double dh[],dl[];
   ArraySetAsSeries(dh,true); ArraySetAsSeries(dl,true);
   if(CopyHigh(DXY_Symbol,PERIOD_H4,1,DXY_StructureBars,dh)<DXY_StructureBars) return true;
   if(CopyLow(DXY_Symbol,PERIOD_H4,1,DXY_StructureBars,dl)<DXY_StructureBars) return true;
   int half=DXY_StructureBars/2;
   double rH=dh[ArrayMaximum(dh,0,half)],pH=dh[ArrayMaximum(dh,half,half)];
   double rL=dl[ArrayMinimum(dl,0,half)],pL=dl[ArrayMinimum(dl,half,half)];
   int eurusdDir=0;
   if(rH>pH&&rL>pL) eurusdDir=1;  // EURUSD up = DXY down = Gold up
   else if(rH<pH&&rL<pL) eurusdDir=-1; // EURUSD down = DXY up = Gold down
   if(eurusdDir==0) return false;
   return (eurusdDir==goldDir);
  }

double GetWarMapTarget(int dir)
  {
   if(dir==1)
     {
      double h[]; ArraySetAsSeries(h,true);
      if(CopyHigh(_Symbol,PERIOD_D1,1,5,h)<5) return 0;
      return h[ArrayMaximum(h,0,5)];
     }
   else
     {
      double l[]; ArraySetAsSeries(l,true);
      if(CopyLow(_Symbol,PERIOD_D1,1,5,l)<5) return 0;
      return l[ArrayMinimum(l,0,5)];
     }
  }

bool HasOpenPosition()
  {
   for(int i=0;i<PositionsTotal();i++)
      if(pos.SelectByIndex(i)&&pos.Symbol()==_Symbol&&pos.Magic()==20260006) return true;
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
