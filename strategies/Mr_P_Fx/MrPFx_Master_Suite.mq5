//+------------------------------------------------------------------+
//|                                         MrPFx_Master_Suite.mq5   |
//|               Mr P Fx Institutional Price Action & Scalping Suite |
//|               Synthesized from YouTube Channel @MrPFx Strategies  |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://www.youtube.com/@MrPFx"
#property version   "1.00"
#property description "Synthesized Algorithmic Implementation of Mr P Fx Trading Systems:"
#property description "1. Liquidity Grab (High/Low Sweep & Rejection - $50k Gold/Nasdaq Setup)"
#property description "2. 15-Minute Trendline Break & Retest Strategy"
#property description "3. Gold Matrix Volatility Expansion Scalper"
#property description "4. Killzone Momentum Small Account Doubler"

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <TradingView_Visualizer.mqh>

enum ENUM_MRPFX_STRATEGY
{
   STRAT_LIQUIDITY_GRAB   = 0, // Liquidity Grab (Sweep & Rejection)
   STRAT_TRENDLINE_RETEST = 1, // 15-Minute Break & Retest
   STRAT_GOLD_MATRIX      = 2, // Gold Matrix Volatility Scalper
   STRAT_KILLZONE_MOM     = 3  // Killzone Momentum Scalper
};

//--- INPUT PARAMETERS ---
input group "=== Strategy Mode & General Settings ==="
input ENUM_MRPFX_STRATEGY InpStrategy         = STRAT_LIQUIDITY_GRAB; // Active Strategy Model
input ulong               InpMagicNumber      = 888001;               // Magic Number
input double              InpRiskPercent      = 1.5;                  // Risk % per Trade (0 = Fixed Lot)
input double              InpFixedLot         = 0.01;                 // Fixed Lot Size (if Risk% = 0)
input double              InpRewardRiskRatio  = 2.5;                  // Reward-to-Risk Ratio (1.5 - 4.0)
input int                 InpMaxSpreadPoints  = 50;                   // Maximum Spread Allowed (Points)

input group "=== Strategy 1: Liquidity Grab (Sweep & Rejection) ==="
input int                 InpSweepLookback    = 20;                   // Swing High/Low Lookback Bars
input int                 InpMinSweepPoints   = 30;                   // Min Points Swept Past Swing Level
input double              InpMinWickRatio     = 0.40;                 // Min Wick/Range Ratio for Rejection (0.35-0.60)
input bool                InpUseTrendFilter   = true;                 // Use Higher EMA Trend Alignment
input int                 InpTrendEMAPeriod   = 50;                   // Trend Filter EMA Period
input int                 InpMacroEMAPeriod   = 200;                  // Macro Trend EMA Period (0 = Disabled)
input int                 InpMaxSLPoints      = 40;                   // Maximum Stop Loss Distance (Points, 0 = Unlimited)
input bool                InpSkipWideSL       = false;                // Skip Trade if SL exceeds MaxSL (false = Cap SL)

input group "=== Strategy 2: 15-Min Trendline Break & Retest ==="
input int                 InpTLBreakLookback  = 15;                   // Trendline Swing Lookback
input int                 InpRetestTolerance  = 40;                   // Retest Zone Tolerance (Points)
input int                 InpFastEMAPeriod    = 20;                   // Fast Dynamic EMA Period
input int                 InpSlowEMAPeriod    = 50;                   // Slow Trend EMA Period

input group "=== Strategy 3: Gold Matrix Volatility Scalper ==="
input int                 InpATRPeriod        = 14;                   // ATR Period
input double              InpKeltnerMult      = 1.8;                  // Keltner Channel ATR Multiplier
input int                 InpRSIPeriod        = 14;                   // RSI Period
input double              InpRSIOverbought    = 65.0;                 // RSI Overbought Level
input double              InpRSIOversold      = 35.0;                 // RSI Oversold Level

input group "=== Strategy 4: Killzone Session Hours (UTC) ==="
input bool                InpUseSessionFilter = true;                 // Enable Session Killzone Filter
input int                 InpSessionStartH1   = 7;                    // London Session Start Hour (UTC)
input int                 InpSessionEndH1     = 11;                   // London Session End Hour (UTC)
input int                 InpSessionStartH2   = 13;                   // New York Session Start Hour (UTC)
input int                 InpSessionEndH2     = 17;                   // New York Session End Hour (UTC)

input group "=== Trade Management: Breakeven & Trailing ==="
input bool                InpUseBreakeven     = true;                 // Enable Breakeven Protection
input double              InpBETriggerR       = 1.0;                  // Move to BE at X * Risk (R-Multiple)
input int                 InpBELockPoints     = 10;                   // Points to Lock Above/Below Open
input bool                InpUseTrailing      = false;                // Enable Dynamic Trailing Stop
input int                 InpTrailPoints      = 50;                   // Trailing Distance (Points)
input int                 InpTrailStepPoints  = 20;                   // Trailing Step (Points)

input group "=== Visuals: TradingView Chart Overlay ==="
input bool                InpShowTradeBoxes   = true;                 // Enable TradingView Profit/Loss Boxes
input bool                InpShowEntryArrows  = true;                 // Enable Directional Entry Arrows
input bool                InpShowBadges       = true;                 // Enable PnL & Level Badges
input bool                InpShowConnLines    = true;                 // Enable Entry-to-Exit Connecting Line
input string              InpVisualPrefix     = "TV_MrPFx_";          // Visual Objects Unique Prefix
input bool                InpCleanOnDeinit    = false;                // Clean Visuals on Unload (false = Persist)
input bool                InpAllowDragBoxes   = true;                 // Allow Selecting & Dragging Diagram Boxes with Mouse

//--- GLOBAL OBJECTS & HANDLES ---
CTrade         ExtTrade;
CSymbolInfo    ExtSymbol;
CPositionInfo  ExtPosition;
CAccountInfo   ExtAccount;

int            ExtTrendEMAHandle   = INVALID_HANDLE;
int            ExtMacroEMAHandle   = INVALID_HANDLE;
int            ExtFastEMAHandle    = INVALID_HANDLE;
int            ExtSlowEMAHandle    = INVALID_HANDLE;
int            ExtATRHandle        = INVALID_HANDLE;
int            ExtRSIHandle        = INVALID_HANDLE;
datetime       ExtLastBarTime      = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!ExtSymbol.Name(_Symbol))
      return INIT_FAILED;
      
   ExtSymbol.RefreshRates();
   
   ExtTrade.SetExpertMagicNumber(InpMagicNumber);
   ExtTrade.SetMarginMode();
   ExtTrade.SetTypeFillingBySymbol(_Symbol);
   ExtTrade.SetDeviationInPoints(20);
   
   // Initialize Indicators
   ExtTrendEMAHandle = iMA(_Symbol, _Period, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   ExtFastEMAHandle  = iMA(_Symbol, _Period, InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   ExtSlowEMAHandle  = iMA(_Symbol, _Period, InpSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   ExtATRHandle      = iATR(_Symbol, _Period, InpATRPeriod);
   ExtRSIHandle      = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   
   if(InpMacroEMAPeriod > 0)
      ExtMacroEMAHandle = iMA(_Symbol, _Period, InpMacroEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   
   if(ExtTrendEMAHandle == INVALID_HANDLE || ExtFastEMAHandle == INVALID_HANDLE || 
      ExtSlowEMAHandle == INVALID_HANDLE || ExtATRHandle == INVALID_HANDLE || ExtRSIHandle == INVALID_HANDLE)
   {
      Print("Error creating indicator handles.");
      return INIT_FAILED;
   }
   
   // Initialize TradingView Visualizer Overlay & Plot Past Trades
   TV_Visualizer_Init(InpMagicNumber, InpShowTradeBoxes, InpVisualPrefix,
                      InpShowEntryArrows, InpShowBadges, InpShowTradeBoxes,
                      InpShowConnLines, InpCleanOnDeinit, InpAllowDragBoxes);
   TV_Visualizer_PlotHistory();
   
   PrintFormat("Mr P Fx Master Suite Initialized. Strategy: %d on %s", InpStrategy, _Symbol);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(ExtTrendEMAHandle);
   IndicatorRelease(ExtFastEMAHandle);
   IndicatorRelease(ExtSlowEMAHandle);
   IndicatorRelease(ExtATRHandle);
   IndicatorRelease(ExtRSIHandle);
   if(ExtMacroEMAHandle != INVALID_HANDLE)
      IndicatorRelease(ExtMacroEMAHandle);

   TV_Visualizer_Deinit();
}

//+------------------------------------------------------------------+
//| Check if New Bar has opened                                      |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   datetime bar_time = iTime(_Symbol, _Period, 0);
   if(bar_time == 0) return false;
   if(bar_time != ExtLastBarTime)
   {
      ExtLastBarTime = bar_time;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Session Filter                                                   |
//+------------------------------------------------------------------+
bool IsInsideKillzone()
{
   if(!InpUseSessionFilter) return true;
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   
   bool in_london = (dt.hour >= InpSessionStartH1 && dt.hour < InpSessionEndH1);
   bool in_ny     = (dt.hour >= InpSessionStartH2 && dt.hour < InpSessionEndH2);
   return (in_london || in_ny);
}

//+------------------------------------------------------------------+
//| Has Open Position for this EA                                    |
//+------------------------------------------------------------------+
bool HasOpenPosition(long &pos_type, double &open_price, double &pos_sl, double &pos_tp, ulong &ticket)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(ExtPosition.SelectByIndex(i))
      {
         if(ExtPosition.Symbol() == _Symbol && ExtPosition.Magic() == InpMagicNumber)
         {
            pos_type   = ExtPosition.PositionType();
            open_price = ExtPosition.PriceOpen();
            pos_sl     = ExtPosition.StopLoss();
            pos_tp     = ExtPosition.TakeProfit();
            ticket     = ExtPosition.Ticket();
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Lot Size Calculation                                             |
//+------------------------------------------------------------------+
double CalculateLots(double sl_distance_points)
{
   if(InpRiskPercent <= 0.0)
      return InpFixedLot;
      
   ExtSymbol.RefreshRates();
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_amount = equity * (InpRiskPercent / 100.0);
   
   double tick_val  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point     = ExtSymbol.Point();
   
   if(tick_val <= 0 || tick_size <= 0 || point <= 0 || sl_distance_points <= 0)
      return InpFixedLot;
      
   double point_val = tick_val * (point / tick_size);
   double loss_per_lot = sl_distance_points * point_val;
   if(loss_per_lot <= 0) return InpFixedLot;
   
   double raw_lots = risk_amount / loss_per_lot;
   double min_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(step_lot <= 0) step_lot = 0.01;
   double lots = MathFloor(raw_lots / step_lot) * step_lot;
   if(lots < min_lot) lots = min_lot;
   if(lots > max_lot) lots = max_lot;
   
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Manage Breakeven & Trailing Stop                                 |
//+------------------------------------------------------------------+
void ManageOpenTrades()
{
   long pos_type;
   double open_price, pos_sl, pos_tp;
   ulong ticket;
   
   if(!HasOpenPosition(pos_type, open_price, pos_sl, pos_tp, ticket))
      return;
      
   ExtSymbol.RefreshRates();
   double point = ExtSymbol.Point();
   double bid = ExtSymbol.Bid();
   double ask = ExtSymbol.Ask();
   
   double risk_points = MathAbs(open_price - pos_sl) / point;
   if(risk_points <= 0) return;
   
   if(pos_type == POSITION_TYPE_BUY)
   {
      double profit_points = (bid - open_price) / point;
      
      // Breakeven check
      if(InpUseBreakeven && profit_points >= (InpBETriggerR * risk_points))
      {
         double target_be = NormalizeDouble(open_price + InpBELockPoints * point, _Digits);
         if(pos_sl < target_be)
         {
            ExtTrade.PositionModify(ticket, target_be, pos_tp);
            return;
         }
      }
      
      // Trailing stop
      if(InpUseTrailing && profit_points >= InpTrailPoints)
      {
         double new_sl = NormalizeDouble(bid - InpTrailPoints * point, _Digits);
         if(new_sl > pos_sl + InpTrailStepPoints * point)
         {
            ExtTrade.PositionModify(ticket, new_sl, pos_tp);
         }
      }
   }
   else if(pos_type == POSITION_TYPE_SELL)
   {
      double profit_points = (open_price - ask) / point;
      
      // Breakeven check
      if(InpUseBreakeven && profit_points >= (InpBETriggerR * risk_points))
      {
         double target_be = NormalizeDouble(open_price - InpBELockPoints * point, _Digits);
         if(pos_sl == 0 || pos_sl > target_be)
         {
            ExtTrade.PositionModify(ticket, target_be, pos_tp);
            return;
         }
      }
      
      // Trailing stop
      if(InpUseTrailing && profit_points >= InpTrailPoints)
      {
         double new_sl = NormalizeDouble(ask + InpTrailPoints * point, _Digits);
         if(pos_sl == 0 || new_sl < pos_sl - InpTrailStepPoints * point)
         {
            ExtTrade.PositionModify(ticket, new_sl, pos_tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Strategy 1: Liquidity Grab (Sweep & Rejection)                   |
//+------------------------------------------------------------------+
void CheckLiquidityGrabSignals()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, InpSweepLookback + 5, rates) < InpSweepLookback + 5)
      return;
      
   double point = ExtSymbol.Point();
   double spread = (double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpreadPoints) return;
   
   // Bar 1 is the completed sweep & rejection candle
   double high1 = rates[1].high;
   double low1  = rates[1].low;
   double open1 = rates[1].open;
   double close1= rates[1].close;
   double range1= high1 - low1;
   if(range1 <= 0) return;
   
   // Find swing high/low of prior bars (bars 2 to InpSweepLookback + 1)
   double swing_high = rates[2].high;
   double swing_low  = rates[2].low;
   for(int i = 3; i <= InpSweepLookback + 1; i++)
   {
      if(rates[i].high > swing_high) swing_high = rates[i].high;
      if(rates[i].low  < swing_low)  swing_low  = rates[i].low;
   }
   
   // Trend Filter
   double trend_ema[];
   ArraySetAsSeries(trend_ema, true);
   CopyBuffer(ExtTrendEMAHandle, 0, 1, 2, trend_ema);
   
   // 1. Bearish Liquidity Sweep of High
   // Price broke swing high by at least InpMinSweepPoints, but closed back below it with upper wick
   double sweep_dist_high = (high1 - swing_high) / point;
   double upper_wick = high1 - MathMax(open1, close1);
   double upper_wick_ratio = upper_wick / range1;
   
   if(sweep_dist_high >= InpMinSweepPoints && close1 < swing_high && upper_wick_ratio >= InpMinWickRatio)
   {
      double macro_ema[];
      ArraySetAsSeries(macro_ema, true);
      bool macro_ok = true;
      if(InpMacroEMAPeriod > 0 && ExtMacroEMAHandle != INVALID_HANDLE)
      {
         if(CopyBuffer(ExtMacroEMAHandle, 0, 1, 1, macro_ema) > 0)
            macro_ok = (close1 <= macro_ema[0]);
      }

      bool trend_ok = (!InpUseTrendFilter || close1 <= trend_ema[0] + 50 * point) && macro_ok;
      if(trend_ok)
      {
         ExtSymbol.RefreshRates();
         double bid = ExtSymbol.Bid();
         double sl_price = high1 + 10 * point;
         double sl_dist_points = (sl_price - bid) / point;
         
         if(InpMaxSLPoints > 0 && sl_dist_points > InpMaxSLPoints)
         {
            if(InpSkipWideSL) return;
            sl_dist_points = InpMaxSLPoints;
            sl_price = bid + sl_dist_points * point;
         }
         
         if(sl_dist_points > 10)
         {
            double tp_dist_points = sl_dist_points * InpRewardRiskRatio;
            double tp_price = NormalizeDouble(bid - tp_dist_points * point, _Digits);
            double lots = CalculateLots(sl_dist_points);
            ExtTrade.Sell(lots, _Symbol, bid, NormalizeDouble(sl_price, _Digits), tp_price, "MrPFx_Sweep_Sell");
            return;
         }
      }
   }
   
   // 2. Bullish Liquidity Sweep of Low
   // Price broke swing low by at least InpMinSweepPoints, but closed back above it with lower wick
   double sweep_dist_low = (swing_low - low1) / point;
   double lower_wick = MathMin(open1, close1) - low1;
   double lower_wick_ratio = lower_wick / range1;
   
   if(sweep_dist_low >= InpMinSweepPoints && close1 > swing_low && lower_wick_ratio >= InpMinWickRatio)
   {
      double macro_ema[];
      ArraySetAsSeries(macro_ema, true);
      bool macro_ok = true;
      if(InpMacroEMAPeriod > 0 && ExtMacroEMAHandle != INVALID_HANDLE)
      {
         if(CopyBuffer(ExtMacroEMAHandle, 0, 1, 1, macro_ema) > 0)
            macro_ok = (close1 >= macro_ema[0]);
      }

      bool trend_ok = (!InpUseTrendFilter || close1 >= trend_ema[0] - 50 * point) && macro_ok;
      if(trend_ok)
      {
         ExtSymbol.RefreshRates();
         double ask = ExtSymbol.Ask();
         double sl_price = low1 - 10 * point;
         double sl_dist_points = (ask - sl_price) / point;
         
         if(InpMaxSLPoints > 0 && sl_dist_points > InpMaxSLPoints)
         {
            if(InpSkipWideSL) return;
            sl_dist_points = InpMaxSLPoints;
            sl_price = ask - sl_dist_points * point;
         }
         
         if(sl_dist_points > 10)
         {
            double tp_dist_points = sl_dist_points * InpRewardRiskRatio;
            double tp_price = NormalizeDouble(ask + tp_dist_points * point, _Digits);
            double lots = CalculateLots(sl_dist_points);
            ExtTrade.Buy(lots, _Symbol, ask, NormalizeDouble(sl_price, _Digits), tp_price, "MrPFx_Sweep_Buy");
            return;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Strategy 2: 15-Minute Trendline Break & Retest                   |
//+------------------------------------------------------------------+
void CheckTrendlineRetestSignals()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, InpTLBreakLookback + 5, rates) < InpTLBreakLookback + 5)
      return;
      
   double fast_ema[], slow_ema[];
   ArraySetAsSeries(fast_ema, true);
   ArraySetAsSeries(slow_ema, true);
   CopyBuffer(ExtFastEMAHandle, 0, 1, 2, fast_ema);
   CopyBuffer(ExtSlowEMAHandle, 0, 1, 2, slow_ema);
   
   double point = ExtSymbol.Point();
   double close1 = rates[1].close;
   double low1   = rates[1].low;
   double high1  = rates[1].high;
   double open1  = rates[1].open;
   
   // Bullish Break & Retest: Fast EMA > Slow EMA, Bar 1 tested near Fast EMA and rejected upwards
   if(fast_ema[0] > slow_ema[0])
   {
      bool touched_retest = (low1 <= fast_ema[0] + InpRetestTolerance * point && close1 > fast_ema[0]);
      bool is_bull_rejection = (close1 > open1 && (close1 - open1) >= 0.3 * (high1 - low1));
      
      if(touched_retest && is_bull_rejection)
      {
         ExtSymbol.RefreshRates();
         double ask = ExtSymbol.Ask();
         double sl_price = low1 - 15 * point;
         double sl_dist_points = (ask - sl_price) / point;
         if(sl_dist_points > 10)
         {
            double tp_dist_points = sl_dist_points * InpRewardRiskRatio;
            double tp_price = NormalizeDouble(ask + tp_dist_points * point, _Digits);
            double lots = CalculateLots(sl_dist_points);
            ExtTrade.Buy(lots, _Symbol, ask, NormalizeDouble(sl_price, _Digits), tp_price, "MrPFx_TL_Buy");
            return;
         }
      }
   }
   // Bearish Break & Retest: Fast EMA < Slow EMA, Bar 1 tested near Fast EMA and rejected downwards
   else if(fast_ema[0] < slow_ema[0])
   {
      bool touched_retest = (high1 >= fast_ema[0] - InpRetestTolerance * point && close1 < fast_ema[0]);
      bool is_bear_rejection = (close1 < open1 && (open1 - close1) >= 0.3 * (high1 - low1));
      
      if(touched_retest && is_bear_rejection)
      {
         ExtSymbol.RefreshRates();
         double bid = ExtSymbol.Bid();
         double sl_price = high1 + 15 * point;
         double sl_dist_points = (sl_price - bid) / point;
         if(sl_dist_points > 10)
         {
            double tp_dist_points = sl_dist_points * InpRewardRiskRatio;
            double tp_price = NormalizeDouble(bid - tp_dist_points * point, _Digits);
            double lots = CalculateLots(sl_dist_points);
            ExtTrade.Sell(lots, _Symbol, bid, NormalizeDouble(sl_price, _Digits), tp_price, "MrPFx_TL_Sell");
            return;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Strategy 3: Gold Matrix Volatility Scalper                       |
//+------------------------------------------------------------------+
void CheckGoldMatrixSignals()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 5, rates) < 5)
      return;
      
   double fast_ema[], atr[], rsi[];
   ArraySetAsSeries(fast_ema, true);
   ArraySetAsSeries(atr, true);
   ArraySetAsSeries(rsi, true);
   
   CopyBuffer(ExtFastEMAHandle, 0, 1, 2, fast_ema);
   CopyBuffer(ExtATRHandle, 0, 1, 2, atr);
   CopyBuffer(ExtRSIHandle, 0, 1, 2, rsi);
   
   double point = ExtSymbol.Point();
   double upper_channel = fast_ema[0] + InpKeltnerMult * atr[0];
   double lower_channel = fast_ema[0] - InpKeltnerMult * atr[0];
   
   double close1 = rates[1].close;
   double open1  = rates[1].open;
   double high1  = rates[1].high;
   double low1   = rates[1].low;
   
   // Matrix Bullish Expansion
   if(close1 > upper_channel && rates[2].close <= upper_channel && rsi[0] > 55.0 && rsi[0] < InpRSIOverbought)
   {
      ExtSymbol.RefreshRates();
      double ask = ExtSymbol.Ask();
      double sl_dist_points = (atr[0] * 1.5) / point;
      if(sl_dist_points > 10)
      {
         double sl_price = ask - sl_dist_points * point;
         double tp_dist_points = sl_dist_points * InpRewardRiskRatio;
         double tp_price = NormalizeDouble(ask + tp_dist_points * point, _Digits);
         double lots = CalculateLots(sl_dist_points);
         ExtTrade.Buy(lots, _Symbol, ask, NormalizeDouble(sl_price, _Digits), tp_price, "MrPFx_Matrix_Buy");
         return;
      }
   }
   // Matrix Bearish Expansion
   else if(close1 < lower_channel && rates[2].close >= lower_channel && rsi[0] < 45.0 && rsi[0] > InpRSIOversold)
   {
      ExtSymbol.RefreshRates();
      double bid = ExtSymbol.Bid();
      double sl_dist_points = (atr[0] * 1.5) / point;
      if(sl_dist_points > 10)
      {
         double sl_price = bid + sl_dist_points * point;
         double tp_dist_points = sl_dist_points * InpRewardRiskRatio;
         double tp_price = NormalizeDouble(bid - tp_dist_points * point, _Digits);
         double lots = CalculateLots(sl_dist_points);
         ExtTrade.Sell(lots, _Symbol, bid, NormalizeDouble(sl_price, _Digits), tp_price, "MrPFx_Matrix_Sell");
         return;
      }
   }
}

//+------------------------------------------------------------------+
//| Strategy 4: Killzone Momentum Scalper                            |
//+------------------------------------------------------------------+
void CheckKillzoneMomentumSignals()
{
   if(!IsInsideKillzone()) return;
   
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 5, rates) < 5)
      return;
      
   double fast_ema[], slow_ema[], atr[];
   ArraySetAsSeries(fast_ema, true);
   ArraySetAsSeries(slow_ema, true);
   ArraySetAsSeries(atr, true);
   
   CopyBuffer(ExtFastEMAHandle, 0, 1, 2, fast_ema);
   CopyBuffer(ExtSlowEMAHandle, 0, 1, 2, slow_ema);
   CopyBuffer(ExtATRHandle, 0, 1, 2, atr);
   
   double point = ExtSymbol.Point();
   double close1 = rates[1].close;
   double open1  = rates[1].open;
   double high1  = rates[1].high;
   double low1   = rates[1].low;
   
   // Momentum Buy: Fast EMA > Slow EMA, Bar 1 is strong bullish candle expanding out of EMA pocket
   if(fast_ema[0] > slow_ema[0] && close1 > fast_ema[0] && open1 <= fast_ema[0] + 15 * point && close1 > open1)
   {
      ExtSymbol.RefreshRates();
      double ask = ExtSymbol.Ask();
      double sl_dist_points = (atr[0] * 1.2) / point;
      if(sl_dist_points > 10)
      {
         double sl_price = ask - sl_dist_points * point;
         double tp_dist_points = sl_dist_points * InpRewardRiskRatio;
         double tp_price = NormalizeDouble(ask + tp_dist_points * point, _Digits);
         double lots = CalculateLots(sl_dist_points);
         ExtTrade.Buy(lots, _Symbol, ask, NormalizeDouble(sl_price, _Digits), tp_price, "MrPFx_KZ_Buy");
         return;
      }
   }
   // Momentum Sell: Fast EMA < Slow EMA, Bar 1 is strong bearish candle breaking below EMA pocket
   else if(fast_ema[0] < slow_ema[0] && close1 < fast_ema[0] && open1 >= fast_ema[0] - 15 * point && close1 < open1)
   {
      ExtSymbol.RefreshRates();
      double bid = ExtSymbol.Bid();
      double sl_dist_points = (atr[0] * 1.2) / point;
      if(sl_dist_points > 10)
      {
         double sl_price = bid + sl_dist_points * point;
         double tp_dist_points = sl_dist_points * InpRewardRiskRatio;
         double tp_price = NormalizeDouble(bid - tp_dist_points * point, _Digits);
         double lots = CalculateLots(sl_dist_points);
         ExtTrade.Sell(lots, _Symbol, bid, NormalizeDouble(sl_price, _Digits), tp_price, "MrPFx_KZ_Sell");
         return;
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Always manage trailing and breakeven on every tick
   ManageOpenTrades();
   
   // Signal generation occurs strictly on bar completion
   if(!IsNewBar())
      return;
      
   long pos_type;
   double open_price, pos_sl, pos_tp;
   ulong ticket;
   if(HasOpenPosition(pos_type, open_price, pos_sl, pos_tp, ticket))
      return; // 1 concurrent position per strategy instance
      
   switch(InpStrategy)
   {
      case STRAT_LIQUIDITY_GRAB:
         CheckLiquidityGrabSignals();
         break;
      case STRAT_TRENDLINE_RETEST:
         CheckTrendlineRetestSignals();
         break;
      case STRAT_GOLD_MATRIX:
         CheckGoldMatrixSignals();
         break;
      case STRAT_KILLZONE_MOM:
         CheckKillzoneMomentumSignals();
         break;
   }
}

//+------------------------------------------------------------------+
//| Trade transaction handler for visual box updates                 |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   TV_Visualizer_OnTradeTransaction(trans, request, result);
}
//+------------------------------------------------------------------+
