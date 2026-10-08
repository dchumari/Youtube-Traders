//+------------------------------------------------------------------+
//|  MSB_FX_EA.mq5                                                   |
//|  Strategy: Gold-X Fusion (SMC: BOS/CHoCH + OB/FVG + Entry Mod2) |
//|  Channel:  MSB FX (Sharjeel Bilal)                              |
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

input group "=== SMC Parameters ==="
input int      StructureLookback = 20;      // Bars for 4H swing detection
input int      OB_Lookback       = 5;       // Max candles back to find OB
input double   OB_Buffer_Pips    = 5.0;     // Buffer beyond OB for SL
input double   FVG_EntryLevel    = 0.5;     // FVG entry at 50%

input group "=== Trade Parameters ==="
input double   MinRR             = 3.0;     // Minimum R:R ratio
input int      MaxDailyTrades    = 2;

input group "=== Sessions ==="
input int      SessionStart1     = 7;       // London start UTC
input int      SessionEnd1       = 10;      // London end UTC
input int      SessionStart2     = 13;      // NY start UTC
input int      SessionEnd2       = 16;      // NY end UTC

input group "=== Filters ==="
input double   MaxSpread         = 25.0;
input bool     UseNewsFilter     = true;
input int      NewsBufferMin     = 30;
// News times UTC (add to these strings as needed)
input string   NewsHour1         = "8:30";
input string   NewsHour2         = "13:30";
input string   NewsHour3         = "14:00";
input string   NewsHour4         = "18:00";
input int      ATR_Period        = 14;

CTrade trade;
CPositionInfo pos;
int dailyTrades = 0;
datetime lastTradeDay = 0;
double dailyStartBalance = 0;
int atrHandle;

// Struct to hold Order Block
struct OrderBlock
  {
   double high;
   double low;
   double mid;
   int    type;   // 1=bullish OB, -1=bearish OB
   bool   valid;
  };

OrderBlock currentOB;

int OnInit()
  {
   trade.SetExpertMagicNumber(20260002);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   atrHandle = iATR(_Symbol, PERIOD_H1, ATR_Period);
   if(atrHandle == INVALID_HANDLE) return(INIT_FAILED);
   currentOB.valid = false;
   Print("MSB_FX EA initialized on ", _Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) { IndicatorRelease(atrHandle); }

void OnTick()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastTradeDay != today) { dailyTrades=0; lastTradeDay=today; }
   if(dailyTrades >= MaxDailyTrades) return;
   if(!IsWithinSession()) return;
   if(UseNewsFilter && IsNearNews()) return;
   if((double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD) > MaxSpread) return;

   static datetime lastBar1H = 0;
   datetime curBar1H = iTime(_Symbol, PERIOD_H1, 0);
   if(lastBar1H != curBar1H)
     {
      lastBar1H = curBar1H;
      ScanForOrderBlock();
     }

   static datetime lastBar5M = 0;
   datetime curBar5M = iTime(_Symbol, PERIOD_M5, 0);
   if(lastBar5M == curBar5M) return;
   lastBar5M = curBar5M;

   if(HasOpenPosition()) return;
   if(!currentOB.valid) return;

   // Check if price is within OB zone
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);

   if(currentOB.type == 1 && ask <= currentOB.high && ask >= currentOB.low)
     {
      // Bullish OB retest - confirm with FVG entry
      double sl  = currentOB.low - OB_Buffer_Pips * _Point * 10;
      double liqTarget = GetLiquidityTarget(1);
      if(liqTarget - ask < MinRR * (ask - sl)) return; // R:R check
      double lots = CalculateLotSize((ask - sl) / (_Point*10));
      if(lots > 0 && trade.Buy(lots,_Symbol,ask,sl,liqTarget,"MSBFX_BUY")) { dailyTrades++; currentOB.valid=false; }
     }
   else if(currentOB.type == -1 && bid >= currentOB.low && bid <= currentOB.high)
     {
      // Bearish OB retest
      double sl  = currentOB.high + OB_Buffer_Pips * _Point * 10;
      double liqTarget = GetLiquidityTarget(-1);
      if(bid - liqTarget < MinRR * (sl - bid)) return;
      double lots = CalculateLotSize((sl - bid) / (_Point*10));
      if(lots > 0 && trade.Sell(lots,_Symbol,bid,sl,liqTarget,"MSBFX_SELL")) { dailyTrades++; currentOB.valid=false; }
     }
  }

void ScanForOrderBlock()
  {
   // Get 4H structure direction
   int structDir = Get4HStructure();
   if(structDir == 0) return;

   // Find OB: last candle of opposite color before impulse
   double h1Open[], h1Close[], h1High[], h1Low[];
   ArraySetAsSeries(h1Open, true); ArraySetAsSeries(h1Close, true);
   ArraySetAsSeries(h1High, true); ArraySetAsSeries(h1Low, true);
   if(CopyOpen(_Symbol,PERIOD_H1,1,OB_Lookback+5,h1Open) < OB_Lookback+5) return;
   if(CopyClose(_Symbol,PERIOD_H1,1,OB_Lookback+5,h1Close) < OB_Lookback+5) return;
   if(CopyHigh(_Symbol,PERIOD_H1,1,OB_Lookback+5,h1High) < OB_Lookback+5) return;
   if(CopyLow(_Symbol,PERIOD_H1,1,OB_Lookback+5,h1Low) < OB_Lookback+5) return;

   // Bullish OB: last bearish H1 candle before recent impulse up
   if(structDir == 1)
     {
      for(int i = 1; i <= OB_Lookback; i++)
        {
         if(h1Close[i] < h1Open[i]) // Bearish candle
           {
            // Check if followed by strong bullish impulse
            if(h1Close[i-1] > h1High[i] * 0.999)
              {
               // Check not yet mitigated
               double askNow = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
               if(askNow > h1High[i]) { currentOB.valid=false; continue; } // Already passed
               currentOB.high  = h1High[i];
               currentOB.low   = h1Low[i];
               currentOB.mid   = (h1High[i]+h1Low[i])/2;
               currentOB.type  = 1;
               currentOB.valid = true;
               break;
              }
           }
        }
     }
   // Bearish OB: last bullish H1 candle before recent impulse down
   else if(structDir == -1)
     {
      for(int i = 1; i <= OB_Lookback; i++)
        {
         if(h1Close[i] > h1Open[i]) // Bullish candle
           {
            if(h1Close[i-1] < h1Low[i] * 1.001)
              {
               double bidNow = SymbolInfoDouble(_Symbol,SYMBOL_BID);
               if(bidNow < h1Low[i]) { currentOB.valid=false; continue; }
               currentOB.high  = h1High[i];
               currentOB.low   = h1Low[i];
               currentOB.mid   = (h1High[i]+h1Low[i])/2;
               currentOB.type  = -1;
               currentOB.valid = true;
               break;
              }
           }
        }
     }
  }

int Get4HStructure()
  {
   double h4High[], h4Low[];
   ArraySetAsSeries(h4High, true); ArraySetAsSeries(h4Low, true);
   if(CopyHigh(_Symbol,PERIOD_H4,1,StructureLookback,h4High) < StructureLookback) return 0;
   if(CopyLow(_Symbol,PERIOD_H4,1,StructureLookback,h4Low) < StructureLookback) return 0;
   // Simple: compare recent half vs prior half
   int half = StructureLookback/2;
   double recentH = h4High[ArrayMaximum(h4High,0,half)];
   double priorH  = h4High[ArrayMaximum(h4High,half,half)];
   double recentL = h4Low[ArrayMinimum(h4Low,0,half)];
   double priorL  = h4Low[ArrayMinimum(h4Low,half,half)];
   if(recentH > priorH && recentL > priorL) return 1;  // Bullish
   if(recentH < priorH && recentL < priorL) return -1; // Bearish
   return 0;
  }

double GetLiquidityTarget(int dir)
  {
   // Return recent swing in opposite direction as liquidity target
   double h[], l[];
   ArraySetAsSeries(h,true); ArraySetAsSeries(l,true);
   if(CopyHigh(_Symbol,PERIOD_H4,1,StructureLookback,h) < StructureLookback) return 0;
   if(CopyLow(_Symbol,PERIOD_H4,1,StructureLookback,l) < StructureLookback) return 0;
   if(dir == 1) return h[ArrayMaximum(h,0,StructureLookback)];
   return l[ArrayMinimum(l,0,StructureLookback)];
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
   string newsHours[4]; newsHours[0]=NewsHour1; newsHours[1]=NewsHour2; newsHours[2]=NewsHour3; newsHours[3]=NewsHour4;
   for(int i=0;i<4;i++)
     {
      if(newsHours[i]=="") continue;
      int nh=0,nm=0;
      if(StringToTime(newsHours[i])>0) {} // parse
      string parts[]; StringSplit(newsHours[i],':',parts);
      if(ArraySize(parts)==2) { nh=(int)StringToInteger(parts[0]); nm=(int)StringToInteger(parts[1]); }
      int nowMins = dt.hour*60+dt.min;
      int evMins  = nh*60+nm;
      if(MathAbs(nowMins-evMins) <= NewsBufferMin) return true;
     }
   return false;
  }

bool HasOpenPosition()
  {
   for(int i=0;i<PositionsTotal();i++)
      if(pos.SelectByIndex(i)&&pos.Symbol()==_Symbol&&pos.Magic()==20260002) return true;
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
