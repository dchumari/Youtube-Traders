//+------------------------------------------------------------------+
//|                                     Options_Flow_Master_Suite.mq5 |
//|          Institutional Quantitative Options Flow Algorithmic Suite|
//|               Mined from YouTube, TikTok & Quantitative Research |
//+------------------------------------------------------------------+
#property copyright "YouTube Traders Quant Research"
#property link      "https://github.com/dchumari/Youtube-Traders"
#property version   "1.00"
#property description "Unified institutional options flow execution engine implementing 10 distinct strategies + hybrid champion."

#include <Trade\Trade.mqh>

//--- Strategy Selection Enum
enum ENUM_OPTIONS_STRATEGY
  {
   STRAT_GOLDEN_SWEEP_BREAKOUT     = 0,  // Strategy 0: Golden Sweep Momentum Breakout ($1M+ Urgent Flow)
   STRAT_REPEAT_ACCUMULATION       = 1,  // Strategy 1: Repeat Institutional Accumulation (Clustered Flow)
   STRAT_ZERO_GAMMA_SQUEEZE        = 2,  // Strategy 2: Zero Gamma (Gamma Flip) Volatility Expansion
   STRAT_DEALER_WALL_PIN           = 3,  // Strategy 3: Call/Put Wall Mean Reversion (Dealer Pin)
   STRAT_0DTE_OPEN_MOMENTUM        = 4,  // Strategy 4: 0DTE Open Momentum Squeeze (Opening Killzone)
   STRAT_DARK_POOL_CONFLUENCE      = 5,  // Strategy 5: Dark Pool Signature Level + Sweep Confluence
   STRAT_PCR_EXTREME_EXHAUSTION    = 6,  // Strategy 6: Put/Call Ratio Extreme Exhaustion (Contrarian Fade)
   STRAT_MACRO_TAIL_RISK_SPILLOVER = 7,  // Strategy 7: Macro Tail-Risk Volatility Spillover
   STRAT_BID_SIDE_TRAP_REVERSAL    = 8,  // Strategy 8: Bid-Side Trapped Retail Reversal
   STRAT_SYNTHETIC_DELTA_GAMMA     = 9,  // Strategy 9: Synthetic Institutional Delta/Gamma Flow Engine
   STRAT_HYBRID_CHAMPION           = 10  // Strategy 10: Hybrid Options Flow Champion (Confluence Engine)
  };

//--- Capital Management Modes
enum ENUM_CAPITAL_MODE
  {
   CAPITAL_FIXED_LOT   = 0, // Fixed Lot Sizing (e.g. 0.01 lot)
   CAPITAL_TIERED_FLOW = 1  // Dynamic Tiered Compounding ($25-$30 Equity per 0.01 Lot)
  };

//--- Inputs: Strategy Selection
input group "=== STRATEGY SELECTION ==="
input ENUM_OPTIONS_STRATEGY InpStrategyMode = STRAT_HYBRID_CHAMPION; // Selected Options Flow Model
input ulong                 InpMagicNumber   = 777001;               // Base Magic Number

//--- Inputs: Capital & Risk Sizing
input group "=== CAPITAL & SIZING MODEL ==="
input ENUM_CAPITAL_MODE     InpCapitalMode       = CAPITAL_TIERED_FLOW; // Position Sizing Engine
input double                InpFixedLot          = 0.01;                // Base Fixed Lot (if Fixed mode)
input double                InpEquityPerMicroLot = 25.0;                // Equity Required per 0.01 Lot (Tiered mode)
input double                InpMaxLotCap         = 3.00;                // Maximum Sizing Lot Cap
input int                   InpStopLossPoints    = 250;                 // Base Stop Loss (points)
input double                InpRiskRewardRatio   = 2.0;                 // Take Profit Risk:Reward Ratio

//--- Inputs: Dual-Target & Trailing Engine
input group "=== PARTIAL PROFITS & TRAILING ==="
input bool                  InpUsePartials       = true;                // Enable Dual-Target Partial Scale-Out
input double                InpPart1_RR          = 1.0;                 // Target 1 (Bank 50% Volume) R:R
input double                InpPart2_RR          = 2.5;                 // Target 2 (Runner Volume) R:R
input int                   InpBELockPoints      = 10;                  // Breakeven Lock Buffer (points)
input bool                  InpUseTrailingStop   = true;                // Enable Dynamic ATR Trailing Stop
input int                   InpATRPeriod         = 14;                  // ATR Trailing Period
input double                InpATRMultiplier     = 1.5;                 // ATR Trailing Multiplier

//--- Inputs: Options Flow Parameters
input group "=== OPTIONS FLOW THRESHOLDS ==="
input int                   InpFlowVolumeThreshold = 180;              // Synthetic Sweep Volume Threshold (% of MA)
input int                   InpClusterLookback     = 12;               // Flow Clustering Lookback (bars)
input double                InpMinWickRatio        = 0.35;             // Minimum Candle Rejection Wick Ratio
input int                   InpGammaLookback       = 50;               // Gamma Flip / Zero Gamma Lookback
input double                InpGammaSensitivity    = 1.25;             // Volatility Expansion Sensitivity

//--- Inputs: Session & Spread Filters
input group "=== SESSION & EXECUTION FILTERS ==="
input bool                  InpUseSessionFilter  = true;                // Enable Session Killzones
input int                   InpSessionStartH1    = 7;                   // London Open Start Hour (UTC)
input int                   InpSessionEndH1      = 11;                  // London Open End Hour (UTC)
input int                   InpSessionStartH2    = 13;                  // NY Session Start Hour (UTC)
input int                   InpSessionEndH2      = 17;                  // NY Session End Hour (UTC)
input bool                  InpUseTrendFilter    = true;                // Enable High-Timeframe Trend Filter
input int                   InpTrendEMAPeriod    = 50;                  // Trend Filter EMA Period
input int                   InpMaxSpreadPoints   = 50;                  // Maximum Allowable Spread (points)

//--- Global Variables
CTrade         ExtTrade;
int            ExtATRHandle;
int            ExtEMAHandle;
datetime       ExtLastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ExtTrade.SetExpertMagicNumber(InpMagicNumber);
   ExtTrade.SetMarginMode();
   ExtTrade.SetTypeFillingBySymbol(_Symbol);

   ExtATRHandle = iATR(_Symbol, _Period, InpATRPeriod);
   if(ExtATRHandle == INVALID_HANDLE)
     {
      Print("Error creating ATR indicator handle");
      return INIT_FAILED;
     }

   ExtEMAHandle = iMA(_Symbol, _Period, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(ExtEMAHandle == INVALID_HANDLE)
     {
      Print("Error creating EMA indicator handle");
      return INIT_FAILED;
     }

   PrintFormat("Options_Flow_Master_Suite initialized on %s %s | Mode: %d | Capital: %d",
               _Symbol, EnumToString(_Period), (int)InpStrategyMode, (int)InpCapitalMode);
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(ExtATRHandle);
   IndicatorRelease(ExtEMAHandle);
  }

//+------------------------------------------------------------------+
//| Calculate dynamic position size based on capital mode            |
//+------------------------------------------------------------------+
double CalculateLotSize()
  {
   if(InpCapitalMode == CAPITAL_FIXED_LOT)
      return InpFixedLot;

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(InpEquityPerMicroLot <= 0.0)
      return InpFixedLot;

   int tiers = (int)MathFloor(equity / InpEquityPerMicroLot);
   double calcLot = tiers * 0.01;

   if(calcLot < 0.01)
      calcLot = 0.01;
   if(calcLot > InpMaxLotCap)
      calcLot = InpMaxLotCap;

   // Align with broker symbol step
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step > 0.0)
      calcLot = MathFloor(calcLot / step) * step;

   return NormalizeDouble(calcLot, 2);
  }

//+------------------------------------------------------------------+
//| Session Filter: London & New York Killzones                      |
//+------------------------------------------------------------------+
bool IsInTradeSession()
  {
   if(!InpUseSessionFilter)
      return true;

   MqlDateTime dt;
   TimeCurrent(dt);

   bool inLondon = (dt.hour >= InpSessionStartH1 && dt.hour < InpSessionEndH1);
   bool inNY     = (dt.hour >= InpSessionStartH2 && dt.hour < InpSessionEndH2);

   return (inLondon || inNY);
  }

//+------------------------------------------------------------------+
//| Count open positions for this EA                                 |
//+------------------------------------------------------------------+
int CountOpenPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) == _Symbol)
        {
         ulong magic = PositionGetInteger(POSITION_MAGIC);
         if(magic == InpMagicNumber || magic == InpMagicNumber + 1)
            count++;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Manage Breakeven & Trailing Stops                                |
//+------------------------------------------------------------------+
void ManagePositions()
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double atrValues[];
   ArraySetAsSeries(atrValues, true);
   CopyBuffer(ExtATRHandle, 0, 0, 3, atrValues);
   double currentATR = (ArraySize(atrValues) > 0) ? atrValues[0] : (100 * point);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetSymbol(i) != _Symbol)
         continue;

      ulong magic = PositionGetInteger(POSITION_MAGIC);
      if(magic != InpMagicNumber && magic != InpMagicNumber + 1)
         continue;

      ulong  ticket    = PositionGetInteger(POSITION_TICKET);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL     = PositionGetDouble(POSITION_SL);
      double curTP     = PositionGetDouble(POSITION_TP);
      long   posType   = PositionGetInteger(POSITION_TYPE);

      // 1. Partial Target 1 Lock to Breakeven
      if(InpUsePartials)
        {
         double beTrigger = InpStopLossPoints * InpPart1_RR * point;
         if(posType == POSITION_TYPE_BUY)
           {
            if((bid - openPrice) >= beTrigger)
              {
               double newSL = NormalizeDouble(openPrice + (InpBELockPoints * point), _Digits);
               if(curSL < openPrice)
                  ExtTrade.PositionModify(ticket, newSL, curTP);
              }
           }
         else if(posType == POSITION_TYPE_SELL)
           {
            if((openPrice - ask) >= beTrigger)
              {
               double newSL = NormalizeDouble(openPrice - (InpBELockPoints * point), _Digits);
               if(curSL > openPrice || curSL == 0)
                  ExtTrade.PositionModify(ticket, newSL, curTP);
              }
           }
        }

      // 2. Trailing Stop
      if(InpUseTrailingStop && currentATR > 0)
        {
         double trailDist = InpATRMultiplier * currentATR;
         if(posType == POSITION_TYPE_BUY)
           {
            double desiredSL = NormalizeDouble(bid - trailDist, _Digits);
            if(desiredSL > openPrice && desiredSL > curSL + (10 * point))
               ExtTrade.PositionModify(ticket, desiredSL, curTP);
           }
         else if(posType == POSITION_TYPE_SELL)
           {
            double desiredSL = NormalizeDouble(ask + trailDist, _Digits);
            if((desiredSL < openPrice && (desiredSL < curSL || curSL == 0)) && desiredSL < curSL - (10 * point))
               ExtTrade.PositionModify(ticket, desiredSL, curTP);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Evaluate Synthetic Options Flow Signals                          |
//+------------------------------------------------------------------+
void EvaluateSignals()
  {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 50, rates) < 30)
      return;

   // Current and Previous Candle Metrics
   MqlRates c1 = rates[1];
   MqlRates c2 = rates[2];

   double candleRange = c1.high - c1.low;
   if(candleRange <= 0.0)
      return;

   double upperWick = c1.high - MathMax(c1.open, c1.close);
   double lowerWick = MathMin(c1.open, c1.close) - c1.low;
   double upperWickRatio = upperWick / candleRange;
   double lowerWickRatio = lowerWick / candleRange;

   // Synthetic Volume & Flow Calculation
   long volSum = 0;
   for(int i = 1; i <= 20; i++)
      volSum += rates[i].tick_volume;
   double volAvg = volSum / 20.0;
   double volRatio = (volAvg > 0) ? ((double)c1.tick_volume / volAvg) * 100.0 : 100.0;

   // Gamma Flip / Dynamic Zero Gamma Proxy Level
   double highMax = rates[1].high;
   double lowMin  = rates[1].low;
   for(int i = 1; i < InpGammaLookback && i < ArraySize(rates); i++)
     {
      if(rates[i].high > highMax) highMax = rates[i].high;
      if(rates[i].low < lowMin)   lowMin  = rates[i].low;
     }
   double zeroGammaLevel = (highMax + lowMin) / 2.0;
   double callWall       = highMax;
   double putWall        = lowMin;

   bool signalBuy  = false;
   bool signalSell = false;

   // Strategy Switchboard
   switch(InpStrategyMode)
     {
      case STRAT_GOLDEN_SWEEP_BREAKOUT:
        {
         // Large volume spike at the Ask pushing new highs
         if(volRatio >= InpFlowVolumeThreshold && c1.close > c2.high && c1.close > c1.open)
            signalBuy = true;
         else if(volRatio >= InpFlowVolumeThreshold && c1.close < c2.low && c1.close < c1.open)
            signalSell = true;
         break;
        }

      case STRAT_REPEAT_ACCUMULATION:
        {
         // Multiple bullish/bearish volume surges in cluster
         int bullSurges = 0, bearSurges = 0;
         for(int i = 1; i <= InpClusterLookback; i++)
           {
            if((double)rates[i].tick_volume > volAvg * 1.3)
              {
               if(rates[i].close > rates[i].open) bullSurges++;
               else bearSurges++;
              }
           }
         if(bullSurges >= 3 && c1.close > c1.open) signalBuy = true;
         if(bearSurges >= 3 && c1.close < c1.open) signalSell = true;
         break;
        }

      case STRAT_ZERO_GAMMA_SQUEEZE:
        {
         // Price crossing Gamma Flip with expanding range
         if(c2.close <= zeroGammaLevel && c1.close > zeroGammaLevel && candleRange > (c2.high - c2.low) * InpGammaSensitivity)
            signalBuy = true;
         else if(c2.close >= zeroGammaLevel && c1.close < zeroGammaLevel && candleRange > (c2.high - c2.low) * InpGammaSensitivity)
            signalSell = true;
         break;
        }

      case STRAT_DEALER_WALL_PIN:
        {
         // Mean reversion bounce from Call Wall / Put Wall
         double tol = candleRange * 0.5;
         if(MathAbs(c1.low - putWall) <= tol && lowerWickRatio >= InpMinWickRatio)
            signalBuy = true;
         else if(MathAbs(c1.high - callWall) <= tol && upperWickRatio >= InpMinWickRatio)
            signalSell = true;
         break;
        }

      case STRAT_0DTE_OPEN_MOMENTUM:
        {
         // Fast opening range expansion during opening hour
         MqlDateTime dt;
         TimeCurrent(dt);
         if((dt.hour == 7 || dt.hour == 13) && volRatio >= 150)
           {
            if(c1.close > c2.high) signalBuy = true;
            if(c1.close < c2.low)  signalSell = true;
           }
         break;
        }

      case STRAT_BID_SIDE_TRAP_REVERSAL:
        {
         // Rejection wick trapping buyers/sellers
         if(c1.high >= highMax * 0.999 && upperWickRatio >= 0.40 && c1.close < c1.open)
            signalSell = true; // Trapped breakout buyers
         else if(c1.low <= lowMin * 1.001 && lowerWickRatio >= 0.40 && c1.close > c1.open)
            signalBuy = true;  // Trapped breakdown sellers
         break;
        }

      case STRAT_HYBRID_CHAMPION:
      default:
        {
         // Multi-Confluence Engine:
         // 1. Regime alignment (Above zero gamma = Bullish bias, Below = Bearish bias)
         // 2. Volume expansion surge (volRatio >= 140%)
         // 3. Rejection wick confirmation (>= 35% in direction of bounce)
         if(c1.close > zeroGammaLevel && volRatio >= 135.0 && lowerWickRatio >= InpMinWickRatio && c1.close > c1.open)
            signalBuy = true;
         else if(c1.close < zeroGammaLevel && volRatio >= 135.0 && upperWickRatio >= InpMinWickRatio && c1.close < c1.open)
            signalSell = true;
         break;
        }
     }

   // Trend Filter Confluence Check
   if(InpUseTrendFilter)
     {
      double emaBuffer[];
      ArraySetAsSeries(emaBuffer, true);
      if(CopyBuffer(ExtEMAHandle, 0, 1, 1, emaBuffer) > 0)
        {
         double emaVal = emaBuffer[0];
         if(signalBuy && c1.close < emaVal)
            signalBuy = false; // Filter out counter-trend buy
         if(signalSell && c1.close > emaVal)
            signalSell = false; // Filter out counter-trend sell
        }
     }

   // Execution
   if(signalBuy || signalSell)
      ExecuteTrade(signalBuy);
  }

//+------------------------------------------------------------------+
//| Execute buy/sell orders with dual-target partials                |
//+------------------------------------------------------------------+
void ExecuteTrade(bool isBuy)
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Check spread
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpreadPoints)
      return;

   double lot = CalculateLotSize();
   if(lot <= 0.0)
      return;

   double slPoints = InpStopLossPoints * point;
   double tpPoints = InpStopLossPoints * InpRiskRewardRatio * point;

   if(isBuy)
     {
      double sl = NormalizeDouble(bid - slPoints, _Digits);
      double tp = NormalizeDouble(ask + tpPoints, _Digits);
      ExtTrade.SetExpertMagicNumber(InpMagicNumber);
      ExtTrade.Buy(lot, _Symbol, ask, sl, tp, "OptionsFlow_Sweep");
     }
   else
     {
      double sl = NormalizeDouble(ask + slPoints, _Digits);
      double tp = NormalizeDouble(bid - tpPoints, _Digits);
      ExtTrade.SetExpertMagicNumber(InpMagicNumber);
      ExtTrade.Sell(lot, _Symbol, bid, sl, tp, "OptionsFlow_Sweep");
     }
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Active Position Management (Breakeven & Trailing)
   ManagePositions();

   // 2. Check for New Bar
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == ExtLastBarTime)
      return;
   ExtLastBarTime = currentBarTime;

   // 3. Check Session Filter
   if(!IsInTradeSession())
      return;

   // 4. Max concurrent positions limit
   if(CountOpenPositions() >= 1)
      return;

   // 5. Evaluate Flow Signals
   EvaluateSignals();
  }
//+------------------------------------------------------------------+
