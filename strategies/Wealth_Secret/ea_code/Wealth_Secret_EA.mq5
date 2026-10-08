//+------------------------------------------------------------------+
//|  Wealth_Secret_EA.mq5                                            |
//|  Strategy: High-Impact Macro News Breakout                      |
//|  Channel:  Wealth Secret                                        |
//|  Version:  1.0  |  2026-09-13                                   |
//+------------------------------------------------------------------+
#property copyright "Youtube-Traders Pipeline"
#property version   "1.00"
#property strict
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Risk Management ==="
input double   RiskPercent         = 1.5;
input bool     UseFixedLot         = false;
input double   FixedLot            = 0.01;

input group "=== News Event Schedule (UTC datetime strings) ==="
input string   NewsEvent1          = "2024.01.11 13:30";
input string   NewsEvent2          = "2024.01.12 13:30";
input string   NewsEvent3          = "2024.02.02 13:30";
input string   NewsEvent4          = "2024.02.13 13:30";
input string   NewsEvent5          = "2024.03.08 13:30";

input group "=== News Range Parameters ==="
input int      PreNewsWindow_Min   = 30;    // Minutes before news for range
input double   SpikeMin_Pips       = 15.0;  // Min spike to qualify
input double   RetracMin_Pct       = 0.20;  // Min retracement of spike
input double   RetracMax_Pct       = 0.618; // Max retracement (Fibonacci)
input double   MaxSpreadAtEntry    = 50.0;  // Max points at entry

input group "=== Trade Parameters ==="
input double   TP1_RangeMulti      = 2.0;   // TP1 = 2x pre-news range
input double   TP1_ClosePercent    = 50.0;
input int      SpikeObserveSec     = 60;    // Seconds to observe spike
input int      EntryWindowMin      = 10;    // Minutes post-news to allow entry

CTrade trade;
CPositionInfo pos;

// News state machine
enum NewsState { STATE_IDLE, STATE_BUILDING_RANGE, STATE_OBSERVING_SPIKE, STATE_SEEKING_ENTRY, STATE_DONE };
NewsState newsState = STATE_IDLE;

datetime currentEventTime = 0;
double   rangeHigh=0, rangeLow=0, rangeMid=0;
double   spikeHigh=0, spikeLow=0;
int      spikeDir=0;  // 1=bullish, -1=bearish
bool     tradeExecuted=false;

int OnInit()
  {
   trade.SetExpertMagicNumber(20260010);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   Print("Wealth Secret News EA initialized on ",_Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason){}

void OnTick()
  {
   // Find next upcoming news event
   if(newsState==STATE_IDLE||newsState==STATE_DONE)
     {
      datetime nextEvent=GetNextNewsEvent();
      if(nextEvent==0) return;
      datetime now=TimeCurrent();
      long secsToEvent=(long)(nextEvent-now);
      // Start building range 30 min before
      if(secsToEvent<=PreNewsWindow_Min*60&&secsToEvent>0)
        {
         currentEventTime=nextEvent;
         newsState=STATE_BUILDING_RANGE;
         tradeExecuted=false;
         rangeHigh=0; rangeLow=0;
         Print("WS EA: Building pre-news range for event at ",TimeToString(nextEvent));
        }
      return;
     }

   datetime now=TimeCurrent();
   long secsToEvent=(long)(currentEventTime-now);
   long secsSinceEvent=(long)(now-currentEventTime);

   if(newsState==STATE_BUILDING_RANGE)
     {
      // Expand range with current price
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      if(rangeHigh==0||ask>rangeHigh) rangeHigh=ask;
      if(rangeLow==0||bid<rangeLow) rangeLow=bid;
      rangeMid=(rangeHigh+rangeLow)/2.0;

      // Switch to spike observation when news fires
      if(secsToEvent<=0)
        {
         newsState=STATE_OBSERVING_SPIKE;
         spikeHigh=rangeHigh; spikeLow=rangeLow; spikeDir=0;
         Print(StringFormat("WS EA: News fired! Range H=%.2f L=%.2f",rangeHigh,rangeLow));
        }
      return;
     }

   if(newsState==STATE_OBSERVING_SPIKE)
     {
      // Track spike for SpikeObserveSec seconds
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      if(ask>spikeHigh) spikeHigh=ask;
      if(bid<spikeLow)  spikeLow=bid;

      if(secsSinceEvent>=SpikeObserveSec)
        {
         double pip=_Point*10;
         double upSpike=(spikeHigh-rangeHigh)/pip;
         double dnSpike=(rangeLow-spikeLow)/pip;
         if(upSpike>=SpikeMin_Pips&&upSpike>dnSpike) spikeDir=1;
         else if(dnSpike>=SpikeMin_Pips&&dnSpike>upSpike) spikeDir=-1;

         if(spikeDir==0)
           { Print("WS EA: Spike too small or unclear - skipping"); newsState=STATE_DONE; }
         else
           { newsState=STATE_SEEKING_ENTRY; Print("WS EA: Spike direction=",spikeDir); }
        }
      return;
     }

   if(newsState==STATE_SEEKING_ENTRY&&!tradeExecuted)
     {
      if(secsSinceEvent>EntryWindowMin*60) { newsState=STATE_DONE; return; }
      if(HasOpenPosition()) return;

      double pip=_Point*10;
      double spread=(double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);
      if(spread>MaxSpreadAtEntry) return;

      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

      // Check retracement from spike
      double spikeSize=0, retrace=0;
      if(spikeDir==1)
        {
         spikeSize=spikeHigh-rangeHigh;
         retrace=spikeHigh-bid;
         double retracePct=retrace/spikeSize;
         if(retracePct>=RetracMin_Pct&&retracePct<=RetracMax_Pct)
           {
            // Entry on next bullish 1M close
            double c1=iClose(_Symbol,PERIOD_M1,1),c2=iClose(_Symbol,PERIOD_M1,2);
            if(c1>c2) // Retracement ending, bullish close
              {
               double rangeWidth=rangeHigh-rangeLow;
               double sl=rangeMid;
               double tp1=ask+TP1_RangeMulti*rangeWidth;
               double lots=CalculateLotSize((ask-sl)/pip);
               if(lots>0&&trade.Buy(lots,_Symbol,ask,sl,tp1,"WS_BUY")){tradeExecuted=true;newsState=STATE_DONE;}
              }
           }
        }
      else if(spikeDir==-1)
        {
         spikeSize=rangeLow-spikeLow;
         retrace=ask-spikeLow;
         double retracePct=retrace/spikeSize;
         if(retracePct>=RetracMin_Pct&&retracePct<=RetracMax_Pct)
           {
            double c1=iClose(_Symbol,PERIOD_M1,1),c2=iClose(_Symbol,PERIOD_M1,2);
            if(c1<c2) // Bearish close during retracement
              {
               double rangeWidth=rangeHigh-rangeLow;
               double sl=rangeMid;
               double tp1=bid-TP1_RangeMulti*rangeWidth;
               double lots=CalculateLotSize((sl-bid)/pip);
               if(lots>0&&trade.Sell(lots,_Symbol,bid,sl,tp1,"WS_SELL")){tradeExecuted=true;newsState=STATE_DONE;}
              }
           }
        }
     }
  }

datetime GetNextNewsEvent()
  {
   string events[5];
   events[0]=NewsEvent1; events[1]=NewsEvent2; events[2]=NewsEvent3;
   events[3]=NewsEvent4; events[4]=NewsEvent5;
   datetime now=TimeCurrent();
   datetime best=0;
   for(int i=0;i<5;i++)
     {
      if(events[i]=="") continue;
      datetime t=StringToTime(events[i]);
      if(t>now&&(best==0||t<best)) best=t;
     }
   return best;
  }

bool HasOpenPosition()
  {
   for(int i=0;i<PositionsTotal();i++)
      if(pos.SelectByIndex(i)&&pos.Symbol()==_Symbol&&pos.Magic()==20260010) return true;
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
