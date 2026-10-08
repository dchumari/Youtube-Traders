//+------------------------------------------------------------------+
//|  TradeIQ_Academy_EA.mq5                                              |
//|  Strategy: AI MACD Fusion + CPR Scalping + Dynamic Compounding   |
//|  Channel:  TradeIQ Academy                                      |
//|  Version:  2.0  |  2026-09-13 (High Alpha / Compounding Engine)  |
//+------------------------------------------------------------------+
#property copyright "Youtube-Traders Pipeline"
#property version   "2.00"
#property strict
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Compounding & Dynamic Sizing ==="
input double   RiskPercent         = 2.0;   // Base risk percent (1.0% - 3.5%)
input int      CompoundingMode     = 0;     // 0=Balance Compounding, 1=Equity Compounding, 2=Anti-Martingale Win Streak
input double   StreakMultiplier    = 1.25;  // Streak lot size growth factor (Mode 2)
input double   MaxRiskCapPercent   = 3.5;   // Maximum allowed risk percent
input bool     UseFixedLot         = false;
input double   FixedLot            = 0.01;

input group "=== Trade Management (BE & Trail) ==="
input bool     UseBreakeven        = false; // Move to Breakeven
input double   BE_Trigger_R        = 1.2;   // Move SL to BE when profit reaches X * Risk
input double   BE_Offset_Pips      = 1.0;   // Lock in X pips profit at Breakeven
input bool     UseTrailingStop     = false; // Enable dynamic trailing stop
input double   Trail_Start_R       = 1.8;   // Start trailing when profit reaches X * Risk
input double   Trail_Distance_Pips = 12.0;  // Trailing distance in pips

input group "=== System A - Supertrend + MACD ==="
input int      ST_ATR_Period       = 10;
input double   ST_Base_Factor      = 3.0;
input double   ST_AI_MaxAdjust     = 0.30;
input int      FastMACD_Fast       = 3;
input int      FastMACD_Slow       = 10;
input int      FastMACD_Signal     = 16;
input int      SlowMACD_Fast       = 12;
input int      SlowMACD_Slow       = 26;
input int      SlowMACD_Signal     = 9;
input double   SL_Pips_A          = 8.0;

input group "=== System B - Central Pivot Range (CPR) ==="
input double   CPR_NarrowMax      = 18.0;  // Narrow CPR threshold (pips)
input double   CPR_WideMin        = 30.0;  // Wide CPR threshold (pips)
input double   SL_Pips_B          = 15.0;  // System B SL in pips
input double   MinRR              = 2.5;   // Reward to Risk Ratio

input group "=== Trade Controls & Sessions ==="
input int      MaxDailyTrades     = 2;     // Max daily trade entries
input bool     UseSystemA         = true;
input bool     UseSystemB         = true;
input bool     TradeLondonSession = false; // Add London Morning Session
input int      LondonStartHour    = 8;     // London Open UTC
input int      LondonEndHour      = 12;    // London Pre-NY UTC
input int      SessionStartHour   = 13;    // NY Open UTC
input int      SessionEndHour     = 19;    // NY Session Peak UTC
input double   MaxSpread          = 20.0;

CTrade trade;
CPositionInfo pos;
int dailyTrades=0;
datetime lastTradeDay=0;
int fastMACDHandle, slowMACDHandle, atrHandle;

// CPR levels (recalculated daily)
double cpr_TC=0, cpr_BC=0, cpr_Pivot=0, cpr_Width=0;
datetime lastCPRDate=0;

int OnInit()
  {
   trade.SetExpertMagicNumber(20260009);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   fastMACDHandle=iMACD(_Symbol,PERIOD_M1,FastMACD_Fast,FastMACD_Slow,FastMACD_Signal,PRICE_CLOSE);
   slowMACDHandle=iMACD(_Symbol,PERIOD_M1,SlowMACD_Fast,SlowMACD_Slow,SlowMACD_Signal,PRICE_CLOSE);
   atrHandle=iATR(_Symbol,PERIOD_M1,ST_ATR_Period);
   if(fastMACDHandle==INVALID_HANDLE||slowMACDHandle==INVALID_HANDLE||atrHandle==INVALID_HANDLE)
     { Print("TradeIQ: Indicator init failed"); return(INIT_FAILED); }
   Print("TradeIQ Academy EA v2.0 initialized on ",_Symbol);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(fastMACDHandle);
   IndicatorRelease(slowMACDHandle);
   IndicatorRelease(atrHandle);
  }

bool IsSessionAllowed(const MqlDateTime &gmt)
  {
   if(gmt.day_of_week==0||gmt.day_of_week==6) return false;
   bool inNY = (gmt.hour>=SessionStartHour && gmt.hour<SessionEndHour);
   bool inLondon = (TradeLondonSession && gmt.hour>=LondonStartHour && gmt.hour<LondonEndHour);
   return inNY || inLondon;
  }

int GetConsecutiveWins()
  {
   HistorySelect(TimeCurrent()-14*86400, TimeCurrent());
   int totalDeals = HistoryDealsTotal();
   int wins = 0;
   for(int i = totalDeals - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol && HistoryDealGetInteger(ticket, DEAL_MAGIC) == 20260009)
           {
            double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
            if(profit > 0)
               wins++;
            else if(profit < 0)
               break;
           }
        }
     }
   return wins;
  }

double CalculateLotSize(double slPips)
  {
   if(UseFixedLot) return NormalizeDouble(FixedLot,2);
   
   double capital = (CompoundingMode == 1) ? AccountInfoDouble(ACCOUNT_EQUITY) : AccountInfoDouble(ACCOUNT_BALANCE);
   double effRisk = RiskPercent;
   
   if(CompoundingMode == 2)
     {
      int wins = GetConsecutiveWins();
      effRisk = RiskPercent * MathPow(StreakMultiplier, MathMin(wins, 3));
      effRisk = MathMin(effRisk, MaxRiskCapPercent);
     }
     
   double riskMoney = capital * effRisk / 100.0;
   double pip = _Point * 10;
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pv = (pip / ts) * tv;
   double lots = riskMoney / (slPips * pv);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots / step) * step;
   return NormalizeDouble(MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), MathMin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), lots)), 2);
  }

void ManageOpenPositions()
  {
   if(!UseBreakeven && !UseTrailingStop) return;
   double pip = _Point * 10;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == 20260009)
        {
         ulong ticket = pos.Ticket();
         double openPrice = pos.PriceOpen();
         double currentSL = pos.StopLoss();
         double currentTP = pos.TakeProfit();
         ENUM_POSITION_TYPE type = pos.PositionType();
         
         double riskPips = MathAbs(openPrice - currentSL) / pip;
         if(riskPips <= 0) riskPips = SL_Pips_B;
         
         if(type == POSITION_TYPE_BUY)
           {
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double profitPips = (bid - openPrice) / pip;
            
            if(UseBreakeven && profitPips >= BE_Trigger_R * riskPips)
              {
               double newSL = NormalizeDouble(openPrice + BE_Offset_Pips * pip, _Digits);
               if(currentSL < newSL)
                 {
                  trade.PositionModify(ticket, newSL, currentTP);
                  currentSL = newSL;
                 }
              }
              
            if(UseTrailingStop && profitPips >= Trail_Start_R * riskPips)
              {
               double trailSL = NormalizeDouble(bid - Trail_Distance_Pips * pip, _Digits);
               if(trailSL > currentSL && trailSL > openPrice)
                 {
                  trade.PositionModify(ticket, trailSL, currentTP);
                 }
              }
           }
         else if(type == POSITION_TYPE_SELL)
           {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double profitPips = (openPrice - ask) / pip;
            
            if(UseBreakeven && profitPips >= BE_Trigger_R * riskPips)
              {
               double newSL = NormalizeDouble(openPrice - BE_Offset_Pips * pip, _Digits);
               if(currentSL == 0 || currentSL > newSL)
                 {
                  trade.PositionModify(ticket, newSL, currentTP);
                  currentSL = newSL;
                 }
              }
              
            if(UseTrailingStop && profitPips >= Trail_Start_R * riskPips)
              {
               double trailSL = NormalizeDouble(ask + Trail_Distance_Pips * pip, _Digits);
               if((currentSL == 0 || trailSL < currentSL) && trailSL < openPrice)
                 {
                  trade.PositionModify(ticket, trailSL, currentTP);
                 }
              }
           }
        }
     }
  }

void OnTick()
  {
   ManageOpenPositions();

   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime today=StringToTime(StringFormat("%04d.%02d.%02d 00:00",dt.year,dt.mon,dt.day));
   if(lastTradeDay!=today){dailyTrades=0;lastTradeDay=today;}
   if(dailyTrades>=MaxDailyTrades) return;

   MqlDateTime gmt; TimeToStruct(TimeGMT(),gmt);
   if(!IsSessionAllowed(gmt)) return;
   if((double)SymbolInfoInteger(_Symbol,SYMBOL_SPREAD)>MaxSpread) return;

   UpdateCPR();

   static datetime lastBar=0;
   datetime curBar=iTime(_Symbol,PERIOD_M1,0);
   if(lastBar==curBar) return;
   lastBar=curBar;

   if(HasOpenPosition()) return;

   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double pip=_Point*10;

   // System A: Supertrend + Dual MACD
   if(UseSystemA)
     {
      int stSignal=GetSupertrendSignal();
      int macdSignal=GetDualMACDSignal();
      if(stSignal!=0&&stSignal==macdSignal)
        {
         double sl,tp;
         double atrBuf[1]; ArraySetAsSeries(atrBuf,true);
         CopyBuffer(atrHandle,0,1,1,atrBuf);
         if(stSignal==1)
           {
            sl=ask-SL_Pips_A*pip;
            tp=ask+MinRR*SL_Pips_A*pip;
            double lots=CalculateLotSize(SL_Pips_A);
            if(lots>0&&trade.Buy(lots,_Symbol,ask,sl,tp,"TIQ_A_BUY")) dailyTrades++;
           }
         else if(stSignal==-1)
           {
            sl=bid+SL_Pips_A*pip;
            tp=bid-MinRR*SL_Pips_A*pip;
            double lots=CalculateLotSize(SL_Pips_A);
            if(lots>0&&trade.Sell(lots,_Symbol,bid,sl,tp,"TIQ_A_SELL")) dailyTrades++;
           }
         return;
        }
     }

   // System B: CPR
   if(UseSystemB&&cpr_TC>0&&cpr_BC>0)
     {
      bool narrow=(cpr_Width<=CPR_NarrowMax);
      bool wide=(cpr_Width>=CPR_WideMin);

      if(narrow)
        {
         if(bid>cpr_TC&&ask-cpr_TC<SL_Pips_B*pip*2)
           {
            double sl=cpr_BC-SL_Pips_B*pip;
            double tp=bid+MinRR*(bid-sl);
            double lots=CalculateLotSize((bid-sl)/pip);
            if(lots>0&&trade.Buy(lots,_Symbol,ask,sl,tp,"TIQ_B_BUY")) dailyTrades++;
           }
         else if(bid<cpr_BC&&cpr_BC-ask<SL_Pips_B*pip*2)
           {
            double sl=cpr_TC+SL_Pips_B*pip;
            double tp=bid-MinRR*(sl-bid);
            double lots=CalculateLotSize((sl-bid)/pip);
            if(lots>0&&trade.Sell(lots,_Symbol,bid,sl,tp,"TIQ_B_SELL")) dailyTrades++;
           }
        }
      else if(wide)
        {
         if(MathAbs(bid-cpr_TC)<SL_Pips_B*pip)
           {
            double sl=cpr_TC+SL_Pips_B*2*pip;
            double tp=cpr_BC;
            if(cpr_TC-cpr_BC>=MinRR*(sl-cpr_TC))
              {
               double lots=CalculateLotSize(SL_Pips_B*2);
               if(lots>0&&trade.Sell(lots,_Symbol,bid,sl,tp,"TIQ_B_SELL")) dailyTrades++;
              }
           }
         else if(MathAbs(ask-cpr_BC)<SL_Pips_B*pip)
           {
            double sl=cpr_BC-SL_Pips_B*2*pip;
            double tp=cpr_TC;
            if(cpr_TC-cpr_BC>=MinRR*(cpr_BC-sl))
              {
               double lots=CalculateLotSize(SL_Pips_B*2);
               if(lots>0&&trade.Buy(lots,_Symbol,ask,sl,tp,"TIQ_B_BUY")) dailyTrades++;
              }
           }
        }
     }
  }

void UpdateCPR()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime today=StringToTime(StringFormat("%04d.%02d.%02d 00:00",dt.year,dt.mon,dt.day));
   if(lastCPRDate==today) return;
   lastCPRDate=today;
   double dH[],dL[],dC[];
   ArraySetAsSeries(dH,true); ArraySetAsSeries(dL,true); ArraySetAsSeries(dC,true);
   if(CopyHigh(_Symbol,PERIOD_D1,1,1,dH)<1) return;
   if(CopyLow(_Symbol,PERIOD_D1,1,1,dL)<1) return;
   if(CopyClose(_Symbol,PERIOD_D1,1,1,dC)<1) return;
   cpr_Pivot=(dH[0]+dL[0]+dC[0])/3.0;
   cpr_BC=(dH[0]+dL[0])/2.0;
   cpr_TC=(cpr_Pivot-cpr_BC)+cpr_Pivot;
   cpr_Width=(cpr_TC-cpr_BC)/(_Point*10);
  }

int GetSupertrendSignal()
  {
   double atrBuf[2]; ArraySetAsSeries(atrBuf,true);
   if(CopyBuffer(atrHandle,0,1,2,atrBuf)<2) return 0;
   double atrAvg=(atrBuf[0]+atrBuf[1])/2.0;
   double adjFactor=ST_Base_Factor;
   if(atrAvg>0)
     {
      double regime=(atrBuf[0]-atrAvg)/atrAvg;
      regime=MathMax(-ST_AI_MaxAdjust,MathMin(ST_AI_MaxAdjust,regime));
      adjFactor=ST_Base_Factor*(1+regime);
     }
   double h[],l[],c[];
   ArraySetAsSeries(h,true); ArraySetAsSeries(l,true); ArraySetAsSeries(c,true);
   if(CopyHigh(_Symbol,PERIOD_M1,1,3,h)<3) return 0;
   if(CopyLow(_Symbol,PERIOD_M1,1,3,l)<3) return 0;
   if(CopyClose(_Symbol,PERIOD_M1,1,3,c)<3) return 0;
   double mid=(h[1]+l[1])/2.0;
   double upperST=mid+adjFactor*atrBuf[1];
   double lowerST=mid-adjFactor*atrBuf[1];
   if(c[0]>upperST) return 1;
   if(c[0]<lowerST) return -1;
   return 0;
  }

int GetDualMACDSignal()
  {
   double fMain[2],fSig[2],sMain[2],sSig[2];
   ArraySetAsSeries(fMain,true); ArraySetAsSeries(fSig,true);
   ArraySetAsSeries(sMain,true); ArraySetAsSeries(sSig,true);
   if(CopyBuffer(fastMACDHandle,0,1,2,fMain)<2) return 0;
   if(CopyBuffer(fastMACDHandle,1,1,2,fSig)<2) return 0;
   if(CopyBuffer(slowMACDHandle,0,1,2,sMain)<2) return 0;
   if(CopyBuffer(slowMACDHandle,1,1,2,sSig)<2) return 0;
   bool fastBull=(fMain[0]>0&&fMain[0]>fMain[1]);
   bool fastBear=(fMain[0]<0&&fMain[0]<fMain[1]);
   bool slowBull=(sMain[0]>sSig[0]);
   bool slowBear=(sMain[0]<sSig[0]);
   if(fastBull&&slowBull) return 1;
   if(fastBear&&slowBear) return -1;
   return 0;
  }

bool HasOpenPosition()
  {
   for(int i=0;i<PositionsTotal();i++)
      if(pos.SelectByIndex(i)&&pos.Symbol()==_Symbol&&pos.Magic()==20260009) return true;
   return false;
  }
