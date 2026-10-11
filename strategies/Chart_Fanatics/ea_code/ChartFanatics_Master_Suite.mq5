//+------------------------------------------------------------------+
//|                                   ChartFanatics_Master_Suite.mq5 |
//|           Institutional Multi-Trader Algorithmic Strategy Suite  |
//|               Codified from the Chart Fanatics Masterclasses     |
//|           (Matteo Conti, Trader Yush, Okala, Anthony Crudele,    |
//|                    Kris Verma, Tipsy Trader, Gianluca Bruni)     |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/dchumari/Youtube-Traders"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| Enums for Strategy Models & Settings Modes                       |
//+------------------------------------------------------------------+
enum ENUM_STRATEGY_MODEL
{
   MODEL_MATTEO_CONTI_BANK_ORB        = 0, // Model 0: Matteo Conti Bank Opening Range Breakout + VWAP
   MODEL_MATTEO_CONTI_1M_MOMENTUM     = 1, // Model 1: Matteo Conti 1-Minute Institutional Momentum (671% Model)
   MODEL_TRADER_YUSH_VALUE_AREA       = 2, // Model 2: Trader Yush Value Area & Delta Absorption Scalp ($2M+)
   MODEL_OKALA_8020_DISTRIBUTION      = 3, // Model 3: Okala 80/20 Tail Distribution Strategy ($5M+)
   MODEL_CRUDELE_BOLLINGER_TREND      = 4, // Model 4: Anthony Crudele 3-Step Bollinger Band Trend Rider
   MODEL_KRIS_VERMA_GAP_SHORT         = 5, // Model 5: Kris Verma Parabolic Exhaustion Short ($3K to $2.1M)
   MODEL_CHART_FANATICS_HYBRID        = 6  // Model 6: Chart Fanatics Master Institutional Confluence Engine
};

enum ENUM_SETTINGS_MODE
{
   MODE_ORIGINAL_TRADER               = 0, // Setting A: Original Trader's Exact Settings (from Video)
   MODE_CALIBRATED_OPTIMAL            = 1, // Setting B: Calibrated Optimal Settings (Multi-Horizon Compounding)
   MODE_CONSERVATIVE_PROP             = 2  // Setting C: Conservative Prop Firm Risk-Managed Settings
};

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "=== STRATEGY SELECTION & DUAL-SETTING MODE ==="
input ENUM_STRATEGY_MODEL InpStrategyModel = MODEL_MATTEO_CONTI_BANK_ORB; // Active Strategy Model
input ENUM_SETTINGS_MODE  InpSettingsMode  = MODE_CALIBRATED_OPTIMAL;     // Settings Tier (Original vs Optimal)
input ulong               InpMagicNumber   = 888100;                      // Magic Number Base

input group "=== CAPITAL SIZING & EXECUTION ==="
input double InpFixedLot          = 0.01;      // Base Fixed Lot (for Original/Prop mode)
input double InpEquityPerMinLot   = 25.0;      // Equity Step per 0.01 lot (Optimal Compounding)
input double InpMaxLotCap         = 2.00;      // Maximum Single Order Lot Cap
input int    InpTicketSlices      = 5;         // Ticket Cluster Slices (1=Single, 3-5=Cluster)
input bool   InpEnablePyramiding  = true;      // Enable Floating Equity Pyramiding
input int    InpMaxPyramidLayers  = 4;         // Max Pyramiding Layers
input int    InpPyramidSpacingPts = 350;       // Pyramiding Step (35.0 pips)

input group "=== MODEL 0: MATTEO CONTI BANK ORB + VWAP ==="
input int    InpORB_Minutes       = 15;        // Opening Range Duration (minutes)
input int    InpORB_StartHour     = 8;         // Session Open Hour (UTC, 8=London, 13=NY)
input int    InpORB_StartMinute   = 0;         // Session Open Minute
input double InpORB_TPMultiplier  = 2.0;       // Take Profit Multiplier of ORB Range Width
input bool   InpORB_UseMidlineSL  = true;      // Use 50% Midline SL (Cuts risk in half)

input group "=== MODEL 1: MATTEO CONTI 1M MOMENTUM (671%) ==="
input int    InpMomFastEMA        = 9;         // Fast Momentum EMA
input int    InpMomSlowEMA        = 21;        // Slow Momentum EMA
input int    InpMomTrendEMA       = 50;        // Macro Trend Filter EMA
input double InpMomATRMultiplier  = 1.5;       // ATR Stop Loss Multiplier
input double InpMomTP_RR          = 2.5;       // Momentum Target R:R Ratio

input group "=== MODEL 2: TRADER YUSH VALUE AREA & ABSORPTION ==="
input int    InpVA_LookbackBars   = 48;        // Value Area Lookback Bars
input double InpVA_Percentage     = 70.0;      // Value Area Volume % (Standard 70%)
input double InpAbsorptionVolMult = 2.0;       // Tick Volume Surge Multiplier
input double InpRejectionWickMin  = 0.35;      // Min Rejection Wick Ratio (35%)

input group "=== MODEL 3: OKALA 80/20 DISTRIBUTION TAILS ==="
input int    InpOkalaRangeBars    = 96;        // Range Lookback Bars (Daily/Session)
input double InpOkalaTailPct      = 20.0;      // Outer Distribution Tail % (Top/Bottom 10%)
input int    InpOkalaStopPts      = 200;       // Stop Loss Points beyond Tail (20.0 pips)
input int    InpOkalaTP_Pts       = 500;       // Target Points to Median Mean (50.0 pips)

input group "=== MODEL 4: ANTHONY CRUDELE BOLLINGER TREND ==="
input int    InpBB_Period         = 20;        // Bollinger Bands Period
input double InpBB_Deviation      = 2.0;       // Bollinger Bands Deviation
input int    InpBB_TrendEMA       = 50;        // Trend Backbone EMA
input int    InpBB_StopPts        = 220;       // Stop Loss Points (22.0 pips)
input int    InpBB_TargetPts      = 550;       // Target Points (55.0 pips, 2.5 R:R)

input group "=== MODEL 5: KRIS VERMA PARABOLIC GAP SHORT ==="
input int    InpGapMinPoints      = 250;       // Min Exhaustion Deviation Gap (25.0 pips)
input double InpVermaWickMin      = 0.40;      // Min Exhaustion Shooting Star Wick
input int    InpVermaStopPts      = 200;       // Stop Loss Points above high (20.0 pips)
input int    InpVermaTP_Pts       = 600;       // Target Points (60.0 pips, 3.0 R:R)

input group "=== TRADE MANAGEMENT & STEERING ==="
input bool   InpUseSteppedBE      = true;      // Enable Stepped Breakeven Shield
input int    InpBE_TriggerPoints  = 250;       // Profit to trigger Breakeven (25 pips)
input int    InpBE_LockPoints     = 10;        // Points locked in profit at Breakeven
input bool   InpUseTrailingATR    = true;      // Enable Trailing ATR Stop
input int    InpTrailingATRPeriod = 14;        // Trailing ATR Period
input double InpTrailingATRMult   = 1.5;       // Trailing ATR Multiplier

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade         m_trade;
CPositionInfo  m_position;

datetime       m_lastBarTime;
int            m_atrHandle;
int            m_bbHandle;
int            m_emaFastHandle;
int            m_emaSlowHandle;
int            m_emaTrendHandle;

// Opening Range variables
datetime       m_orbDay;
double         m_orbHigh;
double         m_orbLow;
bool           m_orbEstablished;
bool           m_orbTradedLong;
bool           m_orbTradedShort;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_trade.SetExpertMagicNumber(InpMagicNumber + (ulong)InpStrategyModel);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(_Symbol);

   m_lastBarTime = 0;
   m_orbDay = 0;
   m_orbHigh = 0;
   m_orbLow = 0;
   m_orbEstablished = false;
   m_orbTradedLong = false;
   m_orbTradedShort = false;

   // Initialize Indicators
   m_atrHandle = iATR(_Symbol, _Period, InpTrailingATRPeriod);
   m_bbHandle  = iBands(_Symbol, _Period, InpBB_Period, 0, InpBB_Deviation, PRICE_CLOSE);
   m_emaFastHandle  = iMA(_Symbol, _Period, InpMomFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   m_emaSlowHandle  = iMA(_Symbol, _Period, InpMomSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   m_emaTrendHandle = iMA(_Symbol, _Period, InpMomTrendEMA, 0, MODE_EMA, PRICE_CLOSE);

   PrintFormat("[ChartFanatics_Master_Suite] Initialized. Model: %d, Settings Mode: %d, Magic: %d",
               InpStrategyModel, InpSettingsMode, InpMagicNumber + (ulong)InpStrategyModel);

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(m_atrHandle);
   IndicatorRelease(m_bbHandle);
   IndicatorRelease(m_emaFastHandle);
   IndicatorRelease(m_emaSlowHandle);
   IndicatorRelease(m_emaTrendHandle);
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Lot Sizing based on Settings Mode              |
//+------------------------------------------------------------------+
double CalculateLotSize(double riskMultiplier = 1.0)
{
   double lot = InpFixedLot;
   
   if(InpSettingsMode == MODE_CALIBRATED_OPTIMAL)
   {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      int steps = (int)MathFloor(equity / MathMax(10.0, InpEquityPerMinLot));
      if(steps < 1) steps = 1;
      lot = steps * 0.01;
   }
   else if(InpSettingsMode == MODE_CONSERVATIVE_PROP)
   {
      lot = 0.01; // Strict 0.01 cap for prop preservation
   }
   
   lot = lot * riskMultiplier;
   
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   lot = MathMax(minLot, MathMin(InpMaxLotCap, lot));
   lot = MathFloor(lot / stepLot) * stepLot;
   
   return lot;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Helper Functions for Position Management & Pyramiding            |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   ulong magic = InpMagicNumber + (ulong)InpStrategyModel;
   int cnt = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == magic)
            cnt++;
      }
   }
   return cnt;
}

bool CheckPyramidingAllowed(int signal)
{
   ulong magic = InpMagicNumber + (ulong)InpStrategyModel;
   double curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(m_position.SelectByIndex(i))
      {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == magic)
         {
            ENUM_POSITION_TYPE posType = m_position.PositionType();
            if((signal > 0 && posType != POSITION_TYPE_BUY) || (signal < 0 && posType != POSITION_TYPE_SELL))
               return false; // Opposing hedge prohibited
               
            double openPrice = m_position.PriceOpen();
            double profitPts = 0;
            if(posType == POSITION_TYPE_BUY)
               profitPts = (curBid - openPrice) / _Point;
            else
               profitPts = (openPrice - curAsk) / _Point;
               
            if(profitPts < InpPyramidSpacingPts)
               return false; // Inadequate floating profit buffer
         }
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Manage Active Positions (Breakeven & Trailing)
   ManageOpenPositions();

   // 2. Bar-by-bar execution logic
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == m_lastBarTime)
      return; // Run analytical checks on bar close

   m_lastBarTime = currentBarTime;

   // 3. Check Signal according to selected Model
   int signal = 0; // 1 = Buy, -1 = Sell
   int stopLossPts = 0;
   int takeProfitPts = 0;

   switch(InpStrategyModel)
   {
      case MODEL_MATTEO_CONTI_BANK_ORB:
         signal = CheckMatteoBankORB(stopLossPts, takeProfitPts);
         break;
      case MODEL_MATTEO_CONTI_1M_MOMENTUM:
         signal = CheckMatteo1MMomentum(stopLossPts, takeProfitPts);
         break;
      case MODEL_TRADER_YUSH_VALUE_AREA:
         signal = CheckTraderYushValueArea(stopLossPts, takeProfitPts);
         break;
      case MODEL_OKALA_8020_DISTRIBUTION:
         signal = CheckOkala8020(stopLossPts, takeProfitPts);
         break;
      case MODEL_CRUDELE_BOLLINGER_TREND:
         signal = CheckCrudeleBollinger(stopLossPts, takeProfitPts);
         break;
      case MODEL_KRIS_VERMA_GAP_SHORT:
         signal = CheckKrisVermaShort(stopLossPts, takeProfitPts);
         break;
      case MODEL_CHART_FANATICS_HYBRID:
         signal = CheckMasterHybrid(stopLossPts, takeProfitPts);
         break;
   }

   // 4. Execute Orders if Signal is valid
   if(signal != 0)
   {
      int currentPos = CountOpenPositions();
      int slices = (InpSettingsMode == MODE_CALIBRATED_OPTIMAL) ? InpTicketSlices : 1;
      int maxAllowed = InpEnablePyramiding ? (InpMaxPyramidLayers * slices) : slices;

      if(currentPos < maxAllowed)
      {
         bool canExecute = true;
         if(currentPos > 0 && InpEnablePyramiding)
         {
            canExecute = CheckPyramidingAllowed(signal);
         }
         else if(currentPos > 0 && !InpEnablePyramiding)
         {
            canExecute = false;
         }

         if(canExecute)
         {
            ExecuteSignal(signal, stopLossPts, takeProfitPts);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| MODEL 0: Matteo Conti Bank Opening Range Breakout (ORB) + VWAP   |
//+------------------------------------------------------------------+
int CheckMatteoBankORB(int &slPts, int &tpPts)
{
   MqlDateTime dt;
   TimeCurrent(dt);

   datetime currentDay = (datetime)(TimeCurrent() / 86400) * 86400;
   if(currentDay != m_orbDay)
   {
      m_orbDay = currentDay;
      m_orbHigh = 0;
      m_orbLow = 0;
      m_orbEstablished = false;
      m_orbTradedLong = false;
      m_orbTradedShort = false;
   }

   int startMinutesTotal = InpORB_StartHour * 60 + InpORB_StartMinute;
   int currentMinutesTotal = dt.hour * 60 + dt.min;
   int endMinutesTotal = startMinutesTotal + InpORB_Minutes;

   if(currentMinutesTotal < endMinutesTotal)
      return 0; // Still before or inside opening range window

   if(!m_orbEstablished)
   {
      datetime orbStart = currentDay + startMinutesTotal * 60;
      datetime orbEnd   = currentDay + endMinutesTotal * 60;

      int startBar = iBarShift(_Symbol, _Period, orbStart, false);
      int endBar   = iBarShift(_Symbol, _Period, orbEnd, false);

      if(startBar < 0 || endBar < 0) return 0;

      int fromBar = MathMin(startBar, endBar);
      int toBar   = MathMax(startBar, endBar);

      m_orbHigh = 0;
      m_orbLow  = 9999999.0;

      for(int b = fromBar; b <= toBar; b++)
      {
         datetime bTime = iTime(_Symbol, _Period, b);
         if(bTime >= orbStart && bTime < orbEnd)
         {
            double h = iHigh(_Symbol, _Period, b);
            double l = iLow(_Symbol, _Period, b);
            if(h > m_orbHigh) m_orbHigh = h;
            if(l < m_orbLow)  m_orbLow = l;
         }
      }

      if(m_orbHigh > 0 && m_orbLow < 9999999.0 && m_orbHigh > m_orbLow)
      {
         m_orbEstablished = true;
      }
      else
      {
         return 0;
      }
   }

   double orbRange = m_orbHigh - m_orbLow;
   if(orbRange <= 0) return 0;

   double close1 = iClose(_Symbol, _Period, 1);
   double close2 = iClose(_Symbol, _Period, 2);

   // Bullish Breakout
   if(!m_orbTradedLong && close1 > m_orbHigh && close2 <= m_orbHigh)
   {
      m_orbTradedLong = true;
      if(InpSettingsMode == MODE_ORIGINAL_TRADER)
      {
         slPts = (int)MathRound(orbRange / _Point);
         tpPts = (int)MathRound((orbRange * 1.5) / _Point);
      }
      else
      {
         slPts = (int)MathRound((orbRange * 0.5) / _Point); // Midline SL
         tpPts = (int)MathRound((orbRange * InpORB_TPMultiplier) / _Point);
      }
      if(slPts < 150) slPts = 150;
      if(tpPts < 300) tpPts = 300;
      return 1;
   }

   // Bearish Breakdown
   if(!m_orbTradedShort && close1 < m_orbLow && close2 >= m_orbLow)
   {
      m_orbTradedShort = true;
      if(InpSettingsMode == MODE_ORIGINAL_TRADER)
      {
         slPts = (int)MathRound(orbRange / _Point);
         tpPts = (int)MathRound((orbRange * 1.5) / _Point);
      }
      else
      {
         slPts = (int)MathRound((orbRange * 0.5) / _Point);
         tpPts = (int)MathRound((orbRange * InpORB_TPMultiplier) / _Point);
      }
      if(slPts < 150) slPts = 150;
      if(tpPts < 300) tpPts = 300;
      return -1;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| MODEL 1: Matteo Conti 1-Minute Momentum Scalp (671% Model)       |
//+------------------------------------------------------------------+
int CheckMatteo1MMomentum(int &slPts, int &tpPts)
{
   double emaFast[], emaSlow[], emaTrend[], atr[];
   ArraySetAsSeries(emaFast, true);
   ArraySetAsSeries(emaSlow, true);
   ArraySetAsSeries(emaTrend, true);
   ArraySetAsSeries(atr, true);

   if(CopyBuffer(m_emaFastHandle, 0, 1, 2, emaFast) < 2) return 0;
   if(CopyBuffer(m_emaSlowHandle, 0, 1, 2, emaSlow) < 2) return 0;
   if(CopyBuffer(m_emaTrendHandle, 0, 1, 1, emaTrend) < 1) return 0;
   if(CopyBuffer(m_atrHandle, 0, 1, 1, atr) < 1) return 0;

   double currentATR = atr[0];
   slPts = (int)MathRound((currentATR * InpMomATRMultiplier) / _Point);
   if(slPts < 150) slPts = 150;
   tpPts = (int)MathRound((slPts * InpMomTP_RR));

   // Bullish Cross above Trend EMA (emaFast[0] = bar 1, emaFast[1] = bar 2)
   if(emaFast[0] > emaSlow[0] && emaFast[1] <= emaSlow[1] && iClose(_Symbol, _Period, 1) > emaTrend[0])
   {
      return 1;
   }

   // Bearish Cross below Trend EMA
   if(emaFast[0] < emaSlow[0] && emaFast[1] >= emaSlow[1] && iClose(_Symbol, _Period, 1) < emaTrend[0])
   {
      return -1;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| MODEL 2: Trader Yush Value Area & Delta Absorption Scalper       |
//+------------------------------------------------------------------+
int CheckTraderYushValueArea(int &slPts, int &tpPts)
{
   double highest = iHigh(_Symbol, _Period, 1);
   double lowest  = iLow(_Symbol, _Period, 1);

   for(int i = 2; i <= InpVA_LookbackBars; i++)
   {
      double h = iHigh(_Symbol, _Period, i);
      double l = iLow(_Symbol, _Period, i);
      if(h > highest) highest = h;
      if(l < lowest)  lowest = l;
   }

   double range = highest - lowest;
   if(range <= 0) return 0;

   // 70% Value Area Boundaries
   double vah = lowest + (range * (0.5 + (InpVA_Percentage / 200.0)));
   double val = lowest + (range * (0.5 - (InpVA_Percentage / 200.0)));
   double poc = lowest + (range * 0.50);

   // Volume Surge
   long curVol = iTickVolume(_Symbol, _Period, 1);
   long sumVol = 0;
   for(int i = 2; i <= 21; i++) sumVol += iTickVolume(_Symbol, _Period, i);
   double avgVol = (double)sumVol / 20.0;
   double volMult = (InpSettingsMode == MODE_CALIBRATED_OPTIMAL) ? 1.3 : InpAbsorptionVolMult;
   bool volSurge = (avgVol > 0 && curVol >= (avgVol * volMult));

   // Candle Wick Rejection
   double high1 = iHigh(_Symbol, _Period, 1);
   double low1  = iLow(_Symbol, _Period, 1);
   double open1 = iOpen(_Symbol, _Period, 1);
   double close1= iClose(_Symbol, _Period, 1);
   double candleLen = high1 - low1;
   if(candleLen <= 0) return 0;

   double upperWick = high1 - MathMax(open1, close1);
   double lowerWick = MathMin(open1, close1) - low1;

   slPts = 200; // 20 pips
   tpPts = 500; // 50 pips

   // VAL Rejection Buy (Tested below VAL, absorbed, closed inside)
   if(low1 < val && close1 > val && (lowerWick / candleLen) >= InpRejectionWickMin && volSurge)
   {
      tpPts = (int)MathRound((poc - close1) / _Point);
      if(tpPts < 250) tpPts = 400;
      return 1;
   }

   // VAH Rejection Sell (Tested above VAH, absorbed, closed inside)
   if(high1 > vah && close1 < vah && (upperWick / candleLen) >= InpRejectionWickMin && volSurge)
   {
      tpPts = (int)MathRound((close1 - poc) / _Point);
      if(tpPts < 250) tpPts = 400;
      return -1;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| MODEL 3: Okala 80/20 Distribution Tail Strategy                  |
//+------------------------------------------------------------------+
int CheckOkala8020(int &slPts, int &tpPts)
{
   double highest = iHigh(_Symbol, _Period, 1);
   double lowest  = iLow(_Symbol, _Period, 1);

   for(int i = 2; i <= InpOkalaRangeBars; i++)
   {
      double h = iHigh(_Symbol, _Period, i);
      double l = iLow(_Symbol, _Period, i);
      if(h > highest) highest = h;
      if(l < lowest)  lowest = l;
   }

   double range = highest - lowest;
   if(range <= 0) return 0;

   double upperTail = highest - (range * (InpOkalaTailPct / 100.0));
   double lowerTail = lowest + (range * (InpOkalaTailPct / 100.0));

   double close1 = iClose(_Symbol, _Period, 1);
   double close2 = iClose(_Symbol, _Period, 2);

   slPts = InpOkalaStopPts;
   tpPts = InpOkalaTP_Pts;

   // Lower Tail Reversal (Bounced out of bottom 20% tail)
   if(close2 < lowerTail && close1 > lowerTail)
   {
      return 1;
   }

   // Upper Tail Reversal (Rejected from top 20% tail)
   if(close2 > upperTail && close1 < upperTail)
   {
      return -1;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| MODEL 4: Anthony Crudele 3-Step Bollinger Band Trend System      |
//+------------------------------------------------------------------+
int CheckCrudeleBollinger(int &slPts, int &tpPts)
{
   double bbMid[], bbUpper[], bbLower[], emaTrend[];
   ArraySetAsSeries(bbMid, true);
   ArraySetAsSeries(bbUpper, true);
   ArraySetAsSeries(bbLower, true);
   ArraySetAsSeries(emaTrend, true);

   if(CopyBuffer(m_bbHandle, 0, 1, 1, bbMid) < 1) return 0;
   if(CopyBuffer(m_bbHandle, 1, 1, 1, bbUpper) < 1) return 0;
   if(CopyBuffer(m_bbHandle, 2, 1, 1, bbLower) < 1) return 0;
   if(CopyBuffer(m_emaTrendHandle, 0, 1, 1, emaTrend) < 1) return 0;

   double close1 = iClose(_Symbol, _Period, 1);
   double low1   = iLow(_Symbol, _Period, 1);
   double high1  = iHigh(_Symbol, _Period, 1);

   slPts = InpBB_StopPts;
   tpPts = InpBB_TargetPts;

   // Step 2 & 3: Uptrend pullback to Midline and reject upward
   if(close1 > emaTrend[0] && low1 <= bbMid[0] && close1 > bbMid[0])
   {
      return 1;
   }

   // Downtrend pullback to Midline and reject downward
   if(close1 < emaTrend[0] && high1 >= bbMid[0] && close1 < bbMid[0])
   {
      return -1;
   }

   return 0;
}

//+------------------------------------------------------------------+
//| MODEL 5: Kris Verma Parabolic Gap-Up Exhaustion Short            |
//+------------------------------------------------------------------+
int CheckKrisVermaShort(int &slPts, int &tpPts)
{
   double close1 = iClose(_Symbol, _Period, 1);
   double close5 = iClose(_Symbol, _Period, 5);
   double high1  = iHigh(_Symbol, _Period, 1);
   double low1   = iLow(_Symbol, _Period, 1);
   double open1  = iOpen(_Symbol, _Period, 1);

   double deviation = (close1 - close5) / _Point;
   if(deviation < InpGapMinPoints)
      return 0;

   double candleLen = high1 - low1;
   if(candleLen <= 0) return 0;

   double upperWick = high1 - MathMax(open1, close1);
   if((upperWick / candleLen) < InpVermaWickMin)
      return 0;

   slPts = InpVermaStopPts;
   tpPts = InpVermaTP_Pts;

   return -1;
}

//+------------------------------------------------------------------+
//| MODEL 6: Master Hybrid Confluence Engine                         |
//+------------------------------------------------------------------+
int CheckMasterHybrid(int &slPts, int &tpPts)
{
   int signalORB = CheckMatteoBankORB(slPts, tpPts);
   int signalVA  = CheckTraderYushValueArea(slPts, tpPts);

   if(signalORB != 0 && signalORB == signalVA)
   {
      slPts = 180;
      tpPts = 550;
      return signalORB; // Confluence between ORB and Value Area
   }

   if(signalORB != 0)
      return signalORB;

   if(signalVA != 0)
      return signalVA;

   return 0;
}

//+------------------------------------------------------------------+
//| Execute Signals (Multi-Ticket Slicing & Compounding)             |
//+------------------------------------------------------------------+
void ExecuteSignal(int signal, int slPts, int tpPts)
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   int slices = (InpSettingsMode == MODE_CALIBRATED_OPTIMAL) ? InpTicketSlices : 1;
   double totalLot = CalculateLotSize();
   double sliceLot = totalLot / (double)slices;
   
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   sliceLot = MathMax(minLot, MathFloor(sliceLot / stepLot) * stepLot);

   for(int i = 0; i < slices; i++)
   {
      double sl = 0;
      double tp = 0;

      if(signal > 0)
      {
         sl = (slPts > 0) ? (ask - slPts * _Point) : 0;
         int targetPts = tpPts;
         if(InpSettingsMode == MODE_CALIBRATED_OPTIMAL && slices > 1)
         {
            if(i == 0) targetPts = (int)(tpPts * 0.5); // TP1
            else if(i == 1) targetPts = (int)(tpPts * 0.8); // TP2
            else targetPts = (int)(tpPts * (1.0 + (i - 1) * 0.3)); // Runners
         }
         tp = (targetPts > 0) ? (ask + targetPts * _Point) : 0;
         m_trade.Buy(sliceLot, _Symbol, ask, sl, tp, "CF_M" + IntegerToString(InpStrategyModel));
      }
      else if(signal < 0)
      {
         sl = (slPts > 0) ? (bid + slPts * _Point) : 0;
         int targetPts = tpPts;
         if(InpSettingsMode == MODE_CALIBRATED_OPTIMAL && slices > 1)
         {
            if(i == 0) targetPts = (int)(tpPts * 0.5);
            else if(i == 1) targetPts = (int)(tpPts * 0.8);
            else targetPts = (int)(tpPts * (1.0 + (i - 1) * 0.3));
         }
         tp = (targetPts > 0) ? (bid - targetPts * _Point) : 0;
         m_trade.Sell(sliceLot, _Symbol, bid, sl, tp, "CF_M" + IntegerToString(InpStrategyModel));
      }
   }
}

//+------------------------------------------------------------------+
//| Manage Open Positions (Stepped Breakeven & Trailing Stops)       |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   ulong magic = InpMagicNumber + (ulong)InpStrategyModel;

   double atrVal = 0;
   if(InpUseTrailingATR)
   {
      double atrBuf[];
      ArraySetAsSeries(atrBuf, true);
      if(CopyBuffer(m_atrHandle, 0, 1, 1, atrBuf) >= 1)
         atrVal = atrBuf[0];
   }

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!m_position.SelectByIndex(i))
         continue;

      if(m_position.Symbol() != _Symbol || m_position.Magic() != magic)
         continue;

      double openPrice = m_position.PriceOpen();
      double curPrice  = m_position.PriceCurrent();
      double curSL     = m_position.StopLoss();
      ENUM_POSITION_TYPE posType = m_position.PositionType();

      // Stepped Breakeven
      if(InpUseSteppedBE)
      {
         if(posType == POSITION_TYPE_BUY)
         {
            double profitPts = (curPrice - openPrice) / _Point;
            if(profitPts >= InpBE_TriggerPoints)
            {
               double newSL = openPrice + (InpBE_LockPoints * _Point);
               if(curSL < openPrice)
               {
                  m_trade.PositionModify(m_position.Ticket(), newSL, m_position.TakeProfit());
                  curSL = newSL;
               }
            }
         }
         else if(posType == POSITION_TYPE_SELL)
         {
            double profitPts = (openPrice - curPrice) / _Point;
            if(profitPts >= InpBE_TriggerPoints)
            {
               double newSL = openPrice - (InpBE_LockPoints * _Point);
               if(curSL > openPrice || curSL == 0)
               {
                  m_trade.PositionModify(m_position.Ticket(), newSL, m_position.TakeProfit());
                  curSL = newSL;
               }
            }
         }
      }

      // Trailing ATR Stop
      if(InpUseTrailingATR && atrVal > 0)
      {
         double trailDist = atrVal * InpTrailingATRMult;
         if(posType == POSITION_TYPE_BUY)
         {
            double desiredSL = curPrice - trailDist;
            if(desiredSL > curSL && desiredSL > openPrice)
            {
               m_trade.PositionModify(m_position.Ticket(), desiredSL, m_position.TakeProfit());
            }
         }
         else if(posType == POSITION_TYPE_SELL)
         {
            double desiredSL = curPrice + trailDist;
            if((curSL == 0 || desiredSL < curSL) && desiredSL < openPrice)
            {
               m_trade.PositionModify(m_position.Ticket(), desiredSL, m_position.TakeProfit());
            }
         }
      }
   }
}
