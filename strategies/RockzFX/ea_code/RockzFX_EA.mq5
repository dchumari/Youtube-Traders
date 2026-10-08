//+------------------------------------------------------------------+
//|  RockzFX_EA.mq5                                                  |
//|  Strategy: BST Model (Behavior-Structure-Trend)                  |
//|  Channel:  RockzFX (Tony Rockall)                               |
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

input group "=== BST Parameters ==="
input int      Structure_Lookback  = 10;    // 4H bars for swing detection
input double   WickRatioMin        = 0.50;  // Min wick ratio (1H behavior)
input int      Trend_SwingBars     = 5;     // 15M bars for minor swing
input double   SL_BufferPips       = 10.0;

input group "=== Trade Parameters ==="
input double   ATR_TrailMulti      = 2.0;
input int      ATR_Period          = 14;
input int      MaxDailyTrades      = 2;

input group "=== Sessions ==="
input int      SessionStart1       = 7;     // London killzone UTC
input int      SessionEnd1         = 9;
input int      SessionStart2       = 13;    // NY killzone UTC
input int      SessionEnd2         = 15;

input group "=== Filters ==="
input double   MaxSpread           = 25.0;

CTrade trade;
CPositionInfo pos;
int dailyTrades=0, atrHandle;
datetime lastTradeDay=0;

int OnInit()
  {
   trade.SetExpertMagicNumber(20260005);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   atrHandle=iATR(_Symbol,PERIOD_M15,ATR_Period);
   if(atrHandle==INVALID_HANDLE) return(INIT_FAILED);
   Print("RockzFX BST EA initialized on ",_Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) { IndicatorRelease(atrHandle); }

void OnTick()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime today=StringToTime(StringFormat("%04d.%02d.%02d 00:00",dt.year,dt.mon,dt.day));
   if(lastTradeDay!=today){dailyTrades=0;lastTradeDay=today;}
   if(dailyTrades>=MaxDailyTrades) return;
   if(!IsWithinSession()) return;
   if((double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)>MaxSpread) return;

   static datetime lastBar=0;
   datetime curBar=iTime(_Symbol,PERIOD_M15,0);
   if(lastBar==curBar) return;
   lastBar=curBar;

   ManageBreakeven();
   if(HasOpenPosition()) return;

   // Layer 1: 4H Structure
   int structDir=Get4HStructure();
   if(structDir==0) return;

   // Layer 2: 1H Behavior (wick at S/R)
   int behaviorDir=Get1HBehavior();
   if(behaviorDir==0||behaviorDir!=structDir) return;

   // Layer 3: 15M Trend Entry (break + retest)
   int entryDir=Get15MTrendEntry(structDir);
   if(entryDir==0||entryDir!=structDir) return;

   // All 3 aligned - execute
   double atrBuf[1]; ArraySetAsSeries(atrBuf,true);
   if(CopyBuffer(atrHandle,0,1,1,atrBuf)<1) return;
   double atr=atrBuf[0];

   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double pip=_Point*10;
   double sl,tp;

   // Get 1H behavior candle wick for SL placement
   double bhHigh=iHigh(_Symbol,PERIOD_H1,1);
   double bhLow=iLow(_Symbol,PERIOD_H1,1);

   if(structDir==1)
     {
      sl=bhLow-SL_BufferPips*pip;
      double slDist=ask-sl;
      tp=ask+2.5*slDist; // 2.5R target
      double lots=CalculateLotSize(slDist/pip);
      if(lots>0&&trade.Buy(lots,_Symbol,ask,sl,tp,"ROCKZ_BUY")) dailyTrades++;
     }
   else
     {
      sl=bhHigh+SL_BufferPips*pip;
      double slDist=sl-bid;
      tp=bid-2.5*slDist;
      double lots=CalculateLotSize(slDist/pip);
      if(lots>0&&trade.Sell(lots,_Symbol,bid,sl,tp,"ROCKZ_SELL")) dailyTrades++;
     }
  }

int Get4HStructure()
  {
   double h[],l[];
   ArraySetAsSeries(h,true); ArraySetAsSeries(l,true);
   if(CopyHigh(_Symbol,PERIOD_H4,1,Structure_Lookback,h)<Structure_Lookback) return 0;
   if(CopyLow(_Symbol,PERIOD_H4,1,Structure_Lookback,l)<Structure_Lookback) return 0;
   int half=Structure_Lookback/2;
   double rH=h[ArrayMaximum(h,0,half)],pH=h[ArrayMaximum(h,half,half)];
   double rL=l[ArrayMinimum(l,0,half)],pL=l[ArrayMinimum(l,half,half)];
   if(rH>pH&&rL>pL) return 1;
   if(rH<pH&&rL<pL) return -1;
   return 0;
  }

int Get1HBehavior()
  {
   // Check last 3 1H candles for wick rejection at S/R
   for(int i=1;i<=3;i++)
     {
      double o=iOpen(_Symbol,PERIOD_H1,i),h=iHigh(_Symbol,PERIOD_H1,i);
      double l=iLow(_Symbol,PERIOD_H1,i),c=iClose(_Symbol,PERIOD_H1,i);
      double range=h-l;
      if(range<_Point*50) continue;
      double mid=(h+l)/2;
      // Bullish wick: lower wick >= 50% of range, close in upper half
      double lw=MathMin(o,c)-l;
      if(lw/range>=WickRatioMin&&c>mid) return 1;
      // Bearish wick: upper wick >= 50% of range, close in lower half
      double uw=h-MathMax(o,c);
      if(uw/range>=WickRatioMin&&c<mid) return -1;
     }
   return 0;
  }

int Get15MTrendEntry(int bias)
  {
   // Find minor swing high/low on 15M and check for break+retest
   double h[],l[],c[];
   ArraySetAsSeries(h,true); ArraySetAsSeries(l,true); ArraySetAsSeries(c,true);
   int lookback=Trend_SwingBars*3;
   if(CopyHigh(_Symbol,PERIOD_M15,1,lookback,h)<lookback) return 0;
   if(CopyLow(_Symbol,PERIOD_M15,1,lookback,l)<lookback) return 0;
   if(CopyClose(_Symbol,PERIOD_M15,1,lookback,c)<lookback) return 0;

   if(bias==1) // Bullish: look for swing low break upward + retest
     {
      // Find recent swing low
      double swingLow=l[ArrayMinimum(l,0,Trend_SwingBars*2)];
      // Most recent candle closed above swing low (break)
      if(c[0]>swingLow && c[1]<=swingLow)
         return 1; // Break of minor swing low to upside = bullish entry
     }
   else if(bias==-1) // Bearish: swing high break downward
     {
      double swingHigh=h[ArrayMaximum(h,0,Trend_SwingBars*2)];
      if(c[0]<swingHigh && c[1]>=swingHigh)
         return -1;
     }
   return 0;
  }

void ManageBreakeven()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol||pos.Magic()!=20260005) continue;
      double ep=pos.PriceOpen(), pip=_Point*10;
      double tp=pos.TakeProfit(), sl=pos.StopLoss();
      double dist=MathAbs(tp-ep);
      bool atBE=false;
      if(pos.PositionType()==POSITION_TYPE_BUY)
         atBE=(SymbolInfoDouble(_Symbol,SYMBOL_BID)-ep>=dist*0.4&&sl<ep);
      else
         atBE=(ep-SymbolInfoDouble(_Symbol,SYMBOL_ASK)>=dist*0.4&&sl>ep);
      if(atBE) trade.PositionModify(pos.Ticket(),ep,tp);
     }
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
      if(pos.SelectByIndex(i)&&pos.Symbol()==_Symbol&&pos.Magic()==20260005) return true;
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
