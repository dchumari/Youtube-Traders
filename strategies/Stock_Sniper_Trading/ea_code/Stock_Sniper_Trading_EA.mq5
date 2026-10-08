//+------------------------------------------------------------------+
//|  Stock_Sniper_Trading_EA.mq5                                     |
//|  Strategy: Structural PA + Candlestick Confirmation             |
//|  Channel:  Stock Sniper Trading (Coach Ronny)                   |
//|  Version:  1.0  |  2026-09-13                                   |
//+------------------------------------------------------------------+
#property copyright "Youtube-Traders Pipeline"
#property version   "1.00"
#property strict
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Risk Management ==="
input double   RiskPercent        = 1.0;
input bool     UseFixedLot        = false;
input double   FixedLot           = 0.01;

input group "=== Level Detection ==="
input int      KeyLevel_Lookback  = 20;    // 4H bars for swing levels
input double   Level_Tolerance    = 10.0;  // Pips from level
input double   RoundNumber_Step   = 10.0;  // $10 XAUUSD round numbers

input group "=== Pattern Detection ==="
input double   PinBar_WickRatio   = 2.0;   // Wick must be 2x body
input double   SL_PipBuffer       = 12.0;

input group "=== Trade Parameters ==="
input double   MinRR              = 2.0;
input int      MaxDailyTrades     = 3;

input group "=== Sessions ==="
input int      SessionStart1      = 0;     // Tokyo UTC
input int      SessionEnd1        = 6;
input int      SessionStart2      = 13;    // NY UTC
input int      SessionEnd2        = 17;

input group "=== Filters ==="
input double   MaxSpread          = 20.0;
input bool     UseNewsFilter      = true;
input int      NewsBufferMin      = 30;
input string   NewsHour1          = "13:30";
input string   NewsHour2          = "14:00";

CTrade trade;
CPositionInfo pos;
int dailyTrades=0;
datetime lastTradeDay=0;

int OnInit()
  {
   trade.SetExpertMagicNumber(20260007);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   Print("Stock Sniper Trading EA initialized on ",_Symbol);
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

   if(HasOpenPosition()) return;

   // Get key levels
   double keyLevels[10];
   int numLevels=GetKeyLevels(keyLevels);
   if(numLevels==0) return;

   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double pip=_Point*10;
   double tol=Level_Tolerance*pip;

   for(int li=0;li<numLevels;li++)
     {
      double level=keyLevels[li];
      // Is price near this level?
      if(MathAbs(bid-level)>tol) continue;

      // Check for candlestick pattern on M15
      int pattern=GetCandlePattern();
      if(pattern==0) continue;

      // Determine if level is support or resistance
      bool isSupport=(bid<=level);
      bool isResist =(bid>=level);

      if(isSupport&&pattern==1) // Bullish pattern at support
        {
         double sl=iLow(_Symbol,PERIOD_M15,1)-SL_PipBuffer*pip;
         double nextLevel=GetNextLevel(keyLevels,numLevels,level,1);
         if(nextLevel==0) continue;
         double slDist=ask-sl;
         double tpDist=nextLevel-ask;
         if(tpDist<MinRR*slDist) continue;
         double lots=CalculateLotSize(slDist/pip);
         if(lots>0&&trade.Buy(lots,_Symbol,ask,sl,nextLevel,"SST_BUY")){dailyTrades++;break;}
        }
      else if(isResist&&pattern==-1) // Bearish pattern at resistance
        {
         double sl=iHigh(_Symbol,PERIOD_M15,1)+SL_PipBuffer*pip;
         double nextLevel=GetNextLevel(keyLevels,numLevels,level,-1);
         if(nextLevel==0) continue;
         double slDist=sl-bid;
         double tpDist=bid-nextLevel;
         if(tpDist<MinRR*slDist) continue;
         double lots=CalculateLotSize(slDist/pip);
         if(lots>0&&trade.Sell(lots,_Symbol,bid,sl,nextLevel,"SST_SELL")){dailyTrades++;break;}
        }
     }
  }

int GetKeyLevels(double &levels[])
  {
   double h[],l[];
   ArraySetAsSeries(h,true); ArraySetAsSeries(l,true);
   if(CopyHigh(_Symbol,PERIOD_H4,1,KeyLevel_Lookback,h)<KeyLevel_Lookback) return 0;
   if(CopyLow(_Symbol,PERIOD_H4,1,KeyLevel_Lookback,l)<KeyLevel_Lookback) return 0;

   int cnt=0;
   double pip=_Point*10;
   // Add swing highs and lows
   for(int i=1;i<KeyLevel_Lookback-1&&cnt<8;i++)
     {
      if(h[i]>h[i-1]&&h[i]>h[i+1]) { levels[cnt++]=h[i]; }
      if(l[i]<l[i-1]&&l[i]<l[i+1]) { levels[cnt++]=l[i]; }
     }
   // Add round numbers near current price
   double midPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double step=RoundNumber_Step;
   for(int j=-3;j<=3&&cnt<10;j++)
     {
      double rn=MathRound(midPrice/step)*step+j*step;
      levels[cnt++]=rn;
     }
   return cnt;
  }

int GetCandlePattern()
  {
   double o1=iOpen(_Symbol,PERIOD_M15,1),h1=iHigh(_Symbol,PERIOD_M15,1);
   double l1=iLow(_Symbol,PERIOD_M15,1),c1=iClose(_Symbol,PERIOD_M15,1);
   double o2=iOpen(_Symbol,PERIOD_M15,2),h2=iHigh(_Symbol,PERIOD_M15,2);
   double l2=iLow(_Symbol,PERIOD_M15,2),c2=iClose(_Symbol,PERIOD_M15,2);
   double range1=h1-l1, body1=MathAbs(c1-o1);
   if(range1<_Point*5) return 0;

   // Bullish engulfing
   if(c2<o2&&c1>o1&&c1>o2&&o1<c2) return 1;
   // Bearish engulfing
   if(c2>o2&&c1<o1&&c1<o2&&o1>c2) return -1;
   // Bullish pin bar
   double lw=MathMin(o1,c1)-l1;
   if(lw>PinBar_WickRatio*body1&&c1>l1+range1*0.5) return 1;
   // Bearish pin bar
   double uw=h1-MathMax(o1,c1);
   if(uw>PinBar_WickRatio*body1&&c1<h1-range1*0.5) return -1;
   return 0;
  }

double GetNextLevel(double &levels[], int cnt, double current, int dir)
  {
   double pip=_Point*10;
   double best=0;
   for(int i=0;i<cnt;i++)
     {
      double diff=levels[i]-current;
      if(dir==1&&diff>20*pip)
        { if(best==0||levels[i]<best) best=levels[i]; }
      else if(dir==-1&&diff<-20*pip)
        { if(best==0||levels[i]>best) best=levels[i]; }
     }
   return best;
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
      if(pos.SelectByIndex(i)&&pos.Symbol()==_Symbol&&pos.Magic()==20260007) return true;
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
