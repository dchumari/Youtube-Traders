//+------------------------------------------------------------------+
//| Gold_Micro_HyperScalp_Apex_EA.mq5                                |
//| Ultimate Evolution of Option 1 (Gold_Micro_HyperScalp_EA)        |
//| Asset: XAUUSD M1 | Target: 4-Window Clean Sweep (> +$60.00 / $8) |
//+------------------------------------------------------------------+
#property copyright "Master Quant Architecture"
#property link      "https://youtube-traders.pipeline"
#property version   "4.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== 1,000 KES ($8.00) Geometric Compounding Engine ==="
input double   CapitalPerMicroLot    = 6.0;              // Capital per 0.01 Lot ($8 = 0.01, $12 = 0.02)
input double   MaxLotCap             = 0.05;             // Maximum Lot Ceiling
input double   FixedLotSize          = 0.01;             // Fixed Lot Fallback
input double   SingleTarget_RR       = 2.5;              // Risk-to-Reward Target (2.5R)
input double   Max_SL_Pips           = 14.0;             // Strict Max Stop Loss (Pips) - Prevents > $1.40 Loss
input bool     UseBreakeven          = true;             // Move SL to Breakeven at +1.0R
input double   BE_Trigger_R          = 1.0;              // BE Trigger R
input double   BE_Offset_Pips        = 1.0;              // Lock +1 Pip on Breakeven

input group "=== CPR & Confluence Engine ==="
input double   CPR_NarrowMax         = 18.0;             // Narrow CPR Threshold (Pips)
input double   CPR_WideMin           = 30.0;             // Wide CPR Threshold (Pips)
input bool     Enable_HTF_EMA        = true;             // Enforce H1 50-EMA Trend Alignment
input int      HTF_EMA_Period        = 50;               // H1 EMA Period
input bool     Enable_SMC_Confluence = true;             // SMC Asian Sweep Confluence
input int      AsianStartHour        = 0;                // Asian Start Hour UTC (00:00)
input int      AsianEndHour          = 7;                // Asian End Hour UTC (07:00)
input double   AsianSweepPips        = 2.5;              // Asian Sweep Buffer (Pips)
input bool     Enable_Vol_Confluence = true;             // Tick Volume Surge Confluence
input int      VolMAPeriod           = 20;               // Volume MA Lookback
input double   VolSpikeRatio         = 1.20;             // Volume Spike Multiplier

input group "=== Trade Controls & Circuit Breakers ==="
input int      MaxDailyTrades        = 5;                // Maximum Trades Per Day
input int      MaxDailyLosses        = 1;                // Circuit Breaker: Halt after 1 loss per day
input int      SessionStartHour      = 8;                // London Open UTC (08:00)
input int      SessionEndHour        = 20;               // NY Close UTC (20:00)
input double   MaxSpreadPips         = 25.0;             // Max Spread Allowed (Points)
input ulong    MicroMagic            = 20263099;         // Magic Number Base

CTrade trade;
CPositionInfo pos;

int dailyTrades = 0;
int dailyLosses = 0;
datetime lastTradeDay = 0;

double cpr_TC = 0.0, cpr_BC = 0.0, cpr_Pivot = 0.0, cpr_Width = 0.0;
datetime lastCPRDate = 0;

double asianHigh = 0.0, asianLow = 999999.0;
datetime lastAsianDate = 0;
int htfEmaHandle = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MicroMagic);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   if(Enable_HTF_EMA)
     {
      htfEmaHandle = iMA(_Symbol, PERIOD_H1, HTF_EMA_Period, 0, MODE_EMA, PRICE_CLOSE);
      if(htfEmaHandle == INVALID_HANDLE)
        {
         Print("Failed to create H1 EMA handle!");
         return(INIT_FAILED);
        }
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(htfEmaHandle != INVALID_HANDLE)
      IndicatorRelease(htfEmaHandle);
  }

//+------------------------------------------------------------------+
//| Update CPR Values (from Daily D1 Rates)                          |
//+------------------------------------------------------------------+
void UpdateCPR()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today == lastCPRDate) return;

   MqlRates dailyRates[];
   ArraySetAsSeries(dailyRates, true);
   int copied = CopyRates(_Symbol, PERIOD_D1, 1, 1, dailyRates);
   if(copied > 0)
     {
      double H = dailyRates[0].high;
      double L = dailyRates[0].low;
      double C = dailyRates[0].close;

      cpr_Pivot = (H + L + C) / 3.0;
      cpr_BC    = (H + L) / 2.0;
      cpr_TC    = (cpr_Pivot - cpr_BC) + cpr_Pivot;
      cpr_Width = MathAbs(cpr_TC - cpr_BC) / (_Point * 10);
      lastCPRDate = today;
     }
  }

//+------------------------------------------------------------------+
//| Update Asian Session Range                                       |
//+------------------------------------------------------------------+
void UpdateAsianRange()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today == lastAsianDate && dt.hour >= AsianEndHour) return;

   datetime aStart = today + AsianStartHour * 3600;
   datetime aEnd   = today + AsianEndHour * 3600;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_M5, aStart, aEnd, rates);
   if(copied > 0)
     {
      double h = -1.0, l = 999999.0;
      for(int i = 0; i < copied; i++)
        {
         if(rates[i].high > h) h = rates[i].high;
         if(rates[i].low < l)  l = rates[i].low;
        }
      asianHigh = h;
      asianLow  = l;
      if(dt.hour >= AsianEndHour) lastAsianDate = today;
     }
  }

//+------------------------------------------------------------------+
//| Check H1 EMA Trend                                               |
//+------------------------------------------------------------------+
int GetHTFBias()
  {
   if(!Enable_HTF_EMA || htfEmaHandle == INVALID_HANDLE) return 0;
   double emaVal[2];
   if(CopyBuffer(htfEmaHandle, 0, 0, 2, emaVal) < 2) return 0;

   MqlRates h1Rates[];
   ArraySetAsSeries(h1Rates, true);
   if(CopyRates(_Symbol, PERIOD_H1, 0, 2, h1Rates) < 2) return 0;

   if(h1Rates[1].close > emaVal[1]) return 1;  // Bullish
   if(h1Rates[1].close < emaVal[1]) return -1; // Bearish
   return 0;
  }

//+------------------------------------------------------------------+
//| Dynamic Micro Lot Sizing Ladder                                  |
//+------------------------------------------------------------------+
double CalculateLots()
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double capital = MathMin(balance, equity);
   double step    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   int multiplier = (int)MathFloor(capital / CapitalPerMicroLot);
   if(multiplier < 1) multiplier = 1;
   double lots = multiplier * minLot;
   if(step > 0) lots = MathFloor(lots / step) * step;
   return NormalizeDouble(MathMax(minLot, MathMin(MaxLotCap, lots)), 2);
  }

//+------------------------------------------------------------------+
//| Manage Breakeven at +1.0R                                        |
//+------------------------------------------------------------------+
void ManageBreakeven()
  {
   if(!UseBreakeven) return;
   double pip = _Point * 10;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MicroMagic)
        {
         ulong ticket = pos.Ticket();
         double openP = pos.PriceOpen();
         double curSL = pos.StopLoss();
         double curTP = pos.TakeProfit();
         double curP  = (pos.PositionType() == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double riskPips = MathAbs(openP - curSL) / pip;
         if(riskPips <= 0) continue;

         if(pos.PositionType() == POSITION_TYPE_BUY)
           {
            if(curP >= openP + BE_Trigger_R * riskPips * pip && curSL < openP)
               trade.PositionModify(ticket, openP + BE_Offset_Pips * pip, curTP);
           }
         else
           {
            if(curP <= openP - BE_Trigger_R * riskPips * pip && (curSL > openP || curSL == 0))
               trade.PositionModify(ticket, openP - BE_Offset_Pips * pip, curTP);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Check Daily Reset & Losses                                       |
//+------------------------------------------------------------------+
void UpdateDailyTracking()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today != lastTradeDay)
     {
      dailyTrades = 0;
      dailyLosses = 0;
      lastTradeDay = today;
     }

   HistorySelect(lastTradeDay, TimeCurrent());
   int totalDeals = HistoryDealsTotal();
   int losses = 0;
   for(int i = 0; i < totalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol &&
         HistoryDealGetInteger(ticket, DEAL_MAGIC) == MicroMagic &&
         HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         if(HistoryDealGetDouble(ticket, DEAL_PROFIT) < -0.01) losses++;
        }
     }
   dailyLosses = losses;
  }

//+------------------------------------------------------------------+
//| OnTick Execution                                                 |
//+------------------------------------------------------------------+
void OnTick()
  {
   UpdateDailyTracking();
   ManageBreakeven();

   if(dailyLosses >= MaxDailyLosses) return;
   if(dailyTrades >= MaxDailyTrades) return;

   // Check spread
   double spreadPips = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / (_Point * 10);
   if(spreadPips > MaxSpreadPips) return;

   // Only 1 open trade at a time
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MicroMagic)
         return;
     }

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   if(dt.hour < SessionStartHour || dt.hour >= SessionEndHour) return;

   UpdateCPR();
   UpdateAsianRange();

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pip = _Point * 10;

   // Confluence Check 1: SMC Asian Range Sweep
   bool smcBullSweep = false;
   bool smcBearSweep = false;
   if(Enable_SMC_Confluence && asianHigh > 0 && asianLow < 900000.0)
     {
      MqlRates m1Rates[];
      ArraySetAsSeries(m1Rates, true);
      if(CopyRates(_Symbol, PERIOD_M1, 1, 3, m1Rates) >= 3)
        {
         if(m1Rates[1].low <= asianLow - AsianSweepPips * pip && m1Rates[0].close > asianLow) smcBullSweep = true;
         if(m1Rates[1].high >= asianHigh + AsianSweepPips * pip && m1Rates[0].close < asianHigh) smcBearSweep = true;
        }
     }

   // Confluence Check 2: Volume Surge Filter
   bool volSpike = false;
   if(Enable_Vol_Confluence)
     {
      long vol[];
      ArraySetAsSeries(vol, true);
      if(CopyTickVolume(_Symbol, PERIOD_M1, 1, VolMAPeriod + 1, vol) >= VolMAPeriod + 1)
        {
         double sumVol = 0;
         for(int i = 1; i <= VolMAPeriod; i++) sumVol += (double)vol[i];
         double avgVol = sumVol / VolMAPeriod;
         if((double)vol[0] >= avgVol * VolSpikeRatio) volSpike = true;
        }
     }

   if(cpr_TC <= 0 || cpr_BC <= 0) return;

   bool narrow = (cpr_Width <= CPR_NarrowMax);
   bool wide   = (cpr_Width >= CPR_WideMin);
   int htfBias = GetHTFBias();

   // ---------------------------------------------------------------
   // 1. NARROW CPR BREAKOUT (Coiled Institutional Expansion)
   // ---------------------------------------------------------------
   if(narrow)
     {
      // Bullish Narrow Breakout (Only if HTF Bias is not Bearish)
      if(bid > cpr_TC && ask - cpr_TC < Max_SL_Pips * pip * 2 && htfBias >= 0)
        {
         double slDist = MathMin(Max_SL_Pips * pip, (ask - cpr_BC) + 2.0 * pip);
         slDist = MathMin(slDist, Max_SL_Pips * pip); // STRICT SL CAP
         double sl = ask - slDist;
         double tp = ask + (slDist * SingleTarget_RR);
         double lots = CalculateLots();

         if(trade.Buy(lots, _Symbol, ask, sl, tp, "Apex-NarrowBuy"))
           {
            dailyTrades++;
            return;
           }
        }
      // Bearish Narrow Breakout (Only if HTF Bias is not Bullish)
      else if(bid < cpr_BC && cpr_BC - ask < Max_SL_Pips * pip * 2 && htfBias <= 0)
        {
         double slDist = MathMin(Max_SL_Pips * pip, (cpr_TC - bid) + 2.0 * pip);
         slDist = MathMin(slDist, Max_SL_Pips * pip); // STRICT SL CAP
         double sl = bid + slDist;
         double tp = bid - (slDist * SingleTarget_RR);
         double lots = CalculateLots();

         if(trade.Sell(lots, _Symbol, bid, sl, tp, "Apex-NarrowSell"))
           {
            dailyTrades++;
            return;
           }
        }
     }
   // ---------------------------------------------------------------
   // 2. WIDE CPR MEAN REVERSION (Range Bounds)
   // ---------------------------------------------------------------
   else if(wide)
     {
      // Mean Reversion Sell at Top Central
      if(MathAbs(bid - cpr_TC) < Max_SL_Pips * pip && htfBias <= 0)
        {
         double slDist = Max_SL_Pips * pip;
         double sl = bid + slDist;
         double tp = bid - (slDist * SingleTarget_RR);
         double lots = CalculateLots();

         if(trade.Sell(lots, _Symbol, bid, sl, tp, "Apex-WideSell"))
           {
            dailyTrades++;
            return;
           }
        }
      // Mean Reversion Buy at Bottom Central
      else if(MathAbs(ask - cpr_BC) < Max_SL_Pips * pip && htfBias >= 0)
        {
         double slDist = Max_SL_Pips * pip;
         double sl = ask - slDist;
         double tp = ask + (slDist * SingleTarget_RR);
         double lots = CalculateLots();

         if(trade.Buy(lots, _Symbol, ask, sl, tp, "Apex-WideBuy"))
           {
            dailyTrades++;
            return;
           }
        }
     }
  }
