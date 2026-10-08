//+------------------------------------------------------------------+
//|  Gold_Micro_HyperScalp_EA.mq5                                     |
//|  Strategy: Micro-Account $20 Small-Account Flipping Engine        |
//|  Core:     Institutional CPR + SMC Asian Sweep + Volume Surge     |
//|            + Geometric Micro-Compounding Ladder ($20 ➔ $2,000+)   |
//|  Visuals:  Auto-Dracula Dark Theme + Gridless + Shaded Sessions   |
//|            (Clean Asian Range Box, London Line, NY Line)          |
//|            + TradingView-Style Position Boxes (Green TP / Red SL) |
//|            (Live Deals & Past Would-Be Strategy Trades with TP/SL)|
//|  Asset:    XAUUSD (Gold) M1                                       |
//|  Version:  3.80 | Aesthetic Visual Suite & TradingView Box Engine |
//+------------------------------------------------------------------+
#property copyright "Master Quant Architecture"
#property link      "https://youtube-traders.pipeline"
#property version   "3.80"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

enum ENUM_MICRO_EXEC_MODE
  {
   MICRO_EXEC_SINGLE_RUNNER = 0, // Single Full Target (2.5R - 2.8R Runner)
   MICRO_EXEC_DUAL_PARTIAL  = 1  // Dual Partials (50% @ 1:1, 50% @ 1:2 + BE)
  };

enum ENUM_MICRO_LOT_MODE
  {
   MICRO_LOT_GEOMETRIC_STEP = 0, // Geometric Micro-Compounding Ladder ($ per 0.01 lot)
   MICRO_LOT_RISK_PERCENT   = 1, // Dynamic Balance Risk Percent
   MICRO_LOT_FIXED          = 2  // Fixed Lot Size
  };

//--- Input Groups
input group "=== $20 Micro Account Compounding Engine ==="
input ENUM_MICRO_LOT_MODE  LotSizingMode         = MICRO_LOT_GEOMETRIC_STEP; // Lot Sizing Architecture
input double               CapitalPerMicroLot    = 12.0;             // Capital per 0.01 Lot ($) [Geometric Step]
input double               RiskPercent           = 15.0;             // Fallback Risk % Per Trade
input double               MaxLotCap             = 3.00;             // Maximum Lot Size Cap
input double               FixedLotSize          = 0.01;             // Fixed Lot Size (if Fixed Mode)

input group "=== Execution & Target Management ==="
input ENUM_MICRO_EXEC_MODE ExecutionMode         = MICRO_EXEC_SINGLE_RUNNER; // Execution Mode
input double               SingleTarget_RR       = 2.8;              // Single Runner R:R Target (2.5R - 2.8R)
input double               Part1_RR              = 1.0;              // Dual Partial: Target 1 (1:1 R:R)
input double               Part2_RR              = 2.0;              // Dual Partial: Target 2 (1:2 R:R)
input bool                 MoveBE_On_TP1         = true;             // Move SL to Breakeven when TP1 Hits
input double               BE_Offset_Pips        = 1.0;              // Breakeven Buffer (Pips)
input double               SL_Pips               = 15.0;             // Base Stop Loss Distance (Pips)

input group "=== CPR & Confluence Engine ==="
input double               CPR_NarrowMax         = 18.0;             // Narrow CPR Threshold (Pips)
input double               CPR_WideMin           = 30.0;             // Wide CPR Threshold (Pips)
input bool                 Enable_SMC_Confluence = true;             // SMC Asian Liquidity Sweep Confluence
input int                  AsianStartHour        = 0;                // Asian Start Hour UTC (00:00)
input int                  AsianEndHour          = 7;                // Asian End Hour UTC (07:00)
input double               AsianSweepPips        = 2.5;              // Asian Sweep Buffer (Pips)
input bool                 Enable_Vol_Confluence = true;             // Volume Spike Confluence
input int                  VolMAPeriod           = 20;               // Volume MA Lookback
input double               VolSpikeRatio         = 1.20;             // Volume Spike Multiplier
input double               ConfluenceBoost       = 1.20;             // Lot Boost when Confluence Confirms

input group "=== Trade Controls & Protection ==="
input int                  MaxDailyTrades        = 5;                // Maximum Trades Per Day
input int                  MaxDailyLosses        = 2;                // Maximum Consecutive Daily Losses Circuit Breaker
input int                  SessionStartHour      = 8;                // London Open UTC (08:00)
input int                  SessionEndHour        = 20;               // NY Close UTC (20:00)
input double               MaxSpreadPips         = 25.0;             // Max Spread Allowed (Points)
input ulong                MicroMagic            = 20263050;         // Magic Number Base

input group "=== Chart Visuals & Theme Styling ==="
input bool                 AutoApplyDraculaTheme = true;             // Auto-Apply Dracula Theme (No Grid)
input bool                 ShowSessionDivides    = true;             // Show Asian Box, London & NY Lines
input bool                 FillAsianBox          = false;            // Fill Asian Box (false = Clean Crisp Border)
input bool                 ShowWouldBeTrades     = true;             // Color-Code Would-Be Past Strategy Trades
input bool                 ShowTradeBoxes        = true;             // Draw Trades as Position Boxes (Green TP / Red SL)
input bool                 ShowAccountDeals      = true;             // Color-Code Actual Account Deals/History
input int                  HistoryBarsToScan     = 5000;             // M1 Bars to Scan for Trades (~3-4 Days)
input int                  Broker_GMT_Offset     = 3;                // Broker Server GMT Offset (EET/Summer = 3)
input bool                 AutoDetectGMTOffset   = true;             // Auto-Detect GMT Offset from Server Clock

//--- Global Objects
CTrade trade;
CPositionInfo pos;

int dailyTrades = 0;
int dailyLosses = 0;
datetime lastTradeDay = 0;

// CPR variables
double cpr_TC = 0.0, cpr_BC = 0.0, cpr_Pivot = 0.0, cpr_Width = 0.0;
datetime lastCPRDate = 0;

// Asian Session variables
double asianHigh = 0.0, asianLow = 999999.0;
datetime lastAsianDate = 0;

// Prefix for all visual objects created on chart
#define OBJ_PREFIX "MicroChart_"

//+------------------------------------------------------------------+
//| Auto-Detect Broker Server GMT Offset                             |
//+------------------------------------------------------------------+
int GetBrokerGMTOffset()
  {
   if(!AutoDetectGMTOffset) return Broker_GMT_Offset;
   datetime sTime = TimeTradeServer();
   datetime gTime = TimeGMT();
   if(sTime > 0 && gTime > 0)
     {
      int diff = (int)(sTime - gTime);
      int h = (int)MathRound((double)diff / 3600.0);
      if(h >= -12 && h <= 14) return h;
     }
   return Broker_GMT_Offset;
  }

//+------------------------------------------------------------------+
//| Apply Dracula Theme Programmatically (Gridless & Non-Intrusive)  |
//| NOTE: Never modifies CHART_AUTOSCROLL to respect user scrolling  |
//+------------------------------------------------------------------+
void ApplyDraculaTheme()
  {
   if(!AutoApplyDraculaTheme) return;

   // 1. Remove Grid Lines completely & configure chart mode
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
   // NOTE: We deliberately DO NOT force CHART_AUTOSCROLL so the user can scroll back freely!
   ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);
   ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, true);
   ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, true);

   // 2. Exact Dracula Colors (Mapped from dracula.tpl)
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, (color)3549737);       // #282A36 Dark Navy-Purple
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, (color)10777186);      // #F8F8F2 Light Cream Text
   ChartSetInteger(0, CHART_COLOR_CHART_UP, (color)8125265);         // #50FA7B Green
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, (color)5592575);       // #FF5555 Pink/Red
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, (color)8125265);      // #50FA7B Bull Body
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, (color)5264367);      // #BD93F9 Bear Body
   ChartSetInteger(0, CHART_COLOR_CHART_LINE, (color)8125265);
   ChartSetInteger(0, CHART_COLOR_VOLUME, (color)13007359);          // #BD93F9 Purple
   ChartSetInteger(0, CHART_COLOR_GRID, (color)3549737);             // Hidden grid
   ChartSetInteger(0, CHART_COLOR_BID, (color)13007359);
   ChartSetInteger(0, CHART_COLOR_ASK, (color)16356285);
   ChartSetInteger(0, CHART_COLOR_LAST, (color)9305073);
   ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, (color)5264367);
  }

//+------------------------------------------------------------------+
//| Draw Visual Session Boxes & Dividers from M1 Bar History         |
//+------------------------------------------------------------------+
void DrawSessionZones(const MqlRates &rates[], int totalBars)
  {
   // Guard: Do not draw intraday session divides on H4 or Daily charts
   if(!ShowSessionDivides || _Period >= PERIOD_H4 || totalBars < 50) return;

   int gmtOffset = GetBrokerGMTOffset();
   datetime lastProcessedDay = 0;

   for(int i = 0; i < totalBars; i++)
     {
      MqlDateTime dt;
      TimeToStruct(rates[i].time, dt);
      datetime dayStart = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));

      if(dayStart == lastProcessedDay) continue;
      lastProcessedDay = dayStart;

      if(dt.day_of_week == 0 || dt.day_of_week == 6) continue;

      datetime aStart  = dayStart + (AsianStartHour + gmtOffset) * 3600;
      datetime aEnd    = dayStart + (AsianEndHour + gmtOffset) * 3600;
      datetime lonOpen = dayStart + (8 + gmtOffset) * 3600;
      datetime nyOpen  = dayStart + (13 + gmtOffset) * 3600;

      // 1. Calculate Asian High / Low from M1 bars
      double aHigh = 0.0, aLow = 999999.0;
      int foundBars = 0;
      for(int j = i; j < totalBars; j++)
        {
         if(rates[j].time >= aStart && rates[j].time < aEnd)
           {
            if(rates[j].high > aHigh) aHigh = rates[j].high;
            if(rates[j].low < aLow)   aLow  = rates[j].low;
            foundBars++;
           }
         if(rates[j].time >= aEnd) break;
        }

      // Draw Asian Range Box (Clean, non-obscuring)
      string asianBox = OBJ_PREFIX + "AsianBox_" + IntegerToString(dayStart);
      if(foundBars > 0 && ObjectFind(0, asianBox) < 0)
        {
         ObjectCreate(0, asianBox, OBJ_RECTANGLE, 0, aStart, aHigh, aEnd, aLow);
         ObjectSetInteger(0, asianBox, OBJPROP_COLOR, (color)C'98,114,164'); // Dracula Slate Border
         ObjectSetInteger(0, asianBox, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, asianBox, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, asianBox, OBJPROP_BACK, true);
         ObjectSetInteger(0, asianBox, OBJPROP_FILL, FillAsianBox);
         if(FillAsianBox)
            ObjectSetInteger(0, asianBox, OBJPROP_BGCOLOR, (color)C'32,34,44'); // Very subtle dark fill
         ObjectSetInteger(0, asianBox, OBJPROP_SELECTABLE, false);

         string lbl = asianBox + "_lbl";
         ObjectCreate(0, lbl, OBJ_TEXT, 0, aStart, aHigh);
         string textDesc = StringFormat("  ASIAN RANGE (00:00 - 07:00 UTC) [H: %.2f | L: %.2f]", aHigh, aLow);
         ObjectSetString(0, lbl, OBJPROP_TEXT, textDesc);
         ObjectSetInteger(0, lbl, OBJPROP_COLOR, (color)C'189,147,249'); // Dracula Light Purple
         ObjectSetString(0, lbl, OBJPROP_FONT, "Segoe UI");
         ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
        }

      // 2. Draw London Open Line (08:00 UTC)
      string lonLine = OBJ_PREFIX + "Lon_" + IntegerToString(dayStart);
      if(ObjectFind(0, lonLine) < 0)
        {
         ObjectCreate(0, lonLine, OBJ_VLINE, 0, lonOpen, 0);
         ObjectSetInteger(0, lonLine, OBJPROP_COLOR, (color)C'80,250,123'); // Bright Green
         ObjectSetInteger(0, lonLine, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, lonLine, OBJPROP_BACK, true);
         ObjectSetInteger(0, lonLine, OBJPROP_SELECTABLE, false);

         string lbl = lonLine + "_lbl";
         ObjectCreate(0, lbl, OBJ_TEXT, 0, lonOpen, 0);
         ObjectSetString(0, lbl, OBJPROP_TEXT, " LONDON (08:00 UTC)");
         ObjectSetInteger(0, lbl, OBJPROP_COLOR, (color)C'80,250,123');
         ObjectSetString(0, lbl, OBJPROP_FONT, "Segoe UI");
         ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
        }

      // 3. Draw New York Open Line (13:00 UTC)
      string nyLine = OBJ_PREFIX + "NY_" + IntegerToString(dayStart);
      if(ObjectFind(0, nyLine) < 0)
        {
         ObjectCreate(0, nyLine, OBJ_VLINE, 0, nyOpen, 0);
         ObjectSetInteger(0, nyLine, OBJPROP_COLOR, (color)C'255,121,198'); // Pink
         ObjectSetInteger(0, nyLine, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, nyLine, OBJPROP_BACK, true);
         ObjectSetInteger(0, nyLine, OBJPROP_SELECTABLE, false);

         string lbl = nyLine + "_lbl";
         ObjectCreate(0, lbl, OBJ_TEXT, 0, nyOpen, 0);
         ObjectSetString(0, lbl, OBJPROP_TEXT, " NY OPEN (13:00 UTC)");
         ObjectSetInteger(0, lbl, OBJPROP_COLOR, (color)C'255,121,198');
         ObjectSetString(0, lbl, OBJPROP_FONT, "Segoe UI");
         ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
        }
     }
  }

//+------------------------------------------------------------------+
//| Draw TradingView-Style Position Risk/Reward Trade Box            |
//| (Green Shaded TP Zone Box + Red Shaded SL Zone Box + Crisp Entry)|
//+------------------------------------------------------------------+
void DrawTradeBox(string id, datetime tEntry, int dir, double entryPrice, double slPrice, double tpPrice, 
                  string badgeText, bool isWin, datetime tExit = 0)
  {
   if(!ShowTradeBoxes) return;

   datetime endT = (tExit > tEntry) ? tExit : tEntry + 3600;

   string tpBoxName = OBJ_PREFIX + "TPBox_" + id;
   string slBoxName = OBJ_PREFIX + "SLBox_" + id;
   string tpLine    = OBJ_PREFIX + "TPLine_" + id;
   string slLine    = OBJ_PREFIX + "SLLine_" + id;
   string entryLine = OBJ_PREFIX + "Entry_" + id;
   string badgeName = OBJ_PREFIX + "Badge_" + id;
   string tagEntry  = OBJ_PREFIX + "Tag_" + id;

   if(ObjectFind(0, tpBoxName) >= 0) return; // Already plotted

   // 1. Target / Profit Box (Green Shaded Rectangle)
   ObjectCreate(0, tpBoxName, OBJ_RECTANGLE, 0, tEntry, entryPrice, endT, tpPrice);
   ObjectSetInteger(0, tpBoxName, OBJPROP_COLOR, isWin ? (color)C'28,60,38' : (color)C'18,34,24');
   ObjectSetInteger(0, tpBoxName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, tpBoxName, OBJPROP_BACK, true);
   ObjectSetInteger(0, tpBoxName, OBJPROP_FILL, true);
   ObjectSetInteger(0, tpBoxName, OBJPROP_SELECTABLE, false);

   // Bright TP Cap Line
   ObjectCreate(0, tpLine, OBJ_TREND, 0, tEntry, tpPrice, endT, tpPrice);
   ObjectSetInteger(0, tpLine, OBJPROP_COLOR, isWin ? (color)C'80,250,123' : (color)C'50,120,70');
   ObjectSetInteger(0, tpLine, OBJPROP_STYLE, isWin ? STYLE_SOLID : STYLE_DASH);
   ObjectSetInteger(0, tpLine, OBJPROP_WIDTH, isWin ? 2 : 1);
   ObjectSetInteger(0, tpLine, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, tpLine, OBJPROP_BACK, false);
   ObjectSetInteger(0, tpLine, OBJPROP_SELECTABLE, false);

   // 2. Risk / Stop Loss Box (Red Shaded Rectangle)
   ObjectCreate(0, slBoxName, OBJ_RECTANGLE, 0, tEntry, entryPrice, endT, slPrice);
   ObjectSetInteger(0, slBoxName, OBJPROP_COLOR, !isWin ? (color)C'65,24,28' : (color)C'32,15,18');
   ObjectSetInteger(0, slBoxName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, slBoxName, OBJPROP_BACK, true);
   ObjectSetInteger(0, slBoxName, OBJPROP_FILL, true);
   ObjectSetInteger(0, slBoxName, OBJPROP_SELECTABLE, false);

   // Bright SL Floor Line
   ObjectCreate(0, slLine, OBJ_TREND, 0, tEntry, slPrice, endT, slPrice);
   ObjectSetInteger(0, slLine, OBJPROP_COLOR, !isWin ? (color)C'255,85,85' : (color)C'120,45,50');
   ObjectSetInteger(0, slLine, OBJPROP_STYLE, !isWin ? STYLE_SOLID : STYLE_DASH);
   ObjectSetInteger(0, slLine, OBJPROP_WIDTH, !isWin ? 2 : 1);
   ObjectSetInteger(0, slLine, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, slLine, OBJPROP_BACK, false);
   ObjectSetInteger(0, slLine, OBJPROP_SELECTABLE, false);

   // 3. Central Entry Divider Line
   ObjectCreate(0, entryLine, OBJ_TREND, 0, tEntry, entryPrice, endT, entryPrice);
   ObjectSetInteger(0, entryLine, OBJPROP_COLOR, (color)C'248,248,242'); // Cream White
   ObjectSetInteger(0, entryLine, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, entryLine, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, entryLine, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, entryLine, OBJPROP_BACK, false);
   ObjectSetInteger(0, entryLine, OBJPROP_SELECTABLE, false);

   // 4. Outcome Badge Text (Placed at the hit level)
   double badgeY = isWin ? tpPrice : slPrice;
   ObjectCreate(0, badgeName, OBJ_TEXT, 0, tEntry, badgeY);
   ObjectSetString(0, badgeName, OBJPROP_TEXT, "  " + badgeText);
   ObjectSetInteger(0, badgeName, OBJPROP_COLOR, isWin ? (color)C'80,250,123' : (color)C'255,85,85');
   ObjectSetString(0, badgeName, OBJPROP_FONT, "Segoe UI Bold");
   ObjectSetInteger(0, badgeName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, badgeName, OBJPROP_SELECTABLE, false);

   // 5. Entry Pill Label
   ObjectCreate(0, tagEntry, OBJ_TEXT, 0, tEntry, entryPrice);
   string entryTxt = (dir > 0) ? StringFormat("  ▲ BUY @ %.2f", entryPrice)
                               : StringFormat("  ▼ SELL @ %.2f", entryPrice);
   ObjectSetString(0, tagEntry, OBJPROP_TEXT, entryTxt);
   ObjectSetInteger(0, tagEntry, OBJPROP_COLOR, (color)C'248,248,242');
   ObjectSetString(0, tagEntry, OBJPROP_FONT, "Segoe UI");
   ObjectSetInteger(0, tagEntry, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, tagEntry, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
//| Plot "Would-Be" Strategy Trades Directly from M1 Price Action    |
//+------------------------------------------------------------------+
void PlotWouldBeStrategyTrades(const MqlRates &rates[], int totalBars)
  {
   if(!ShowWouldBeTrades || _Period >= PERIOD_H4 || totalBars < 100) return;

   double pip = _Point * 10;
   int gmtOffset = GetBrokerGMTOffset();
   datetime lastDay = 0;

   // Process day by day in chronological order
   for(int i = 0; i < totalBars - 60; i++)
     {
      MqlDateTime dt;
      TimeToStruct(rates[i].time, dt);
      datetime dayStart = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));

      if(dayStart == lastDay) continue;
      lastDay = dayStart;

      if(dt.day_of_week == 0 || dt.day_of_week == 6) continue;

      datetime aStart = dayStart + (AsianStartHour + gmtOffset) * 3600;
      datetime aEnd   = dayStart + (AsianEndHour + gmtOffset) * 3600;
      datetime sStart = dayStart + (SessionStartHour + gmtOffset) * 3600;
      datetime sEnd   = dayStart + (SessionEndHour + gmtOffset) * 3600;

      // 1. Calculate Asian High / Low
      double aHigh = 0.0, aLow = 999999.0;
      int aBars = 0;
      for(int j = i; j < totalBars; j++)
        {
         if(rates[j].time >= aStart && rates[j].time < aEnd)
           {
            if(rates[j].high > aHigh) aHigh = rates[j].high;
            if(rates[j].low < aLow)   aLow  = rates[j].low;
            aBars++;
           }
         if(rates[j].time >= aEnd) break;
        }

      if(aBars < 10 || aHigh <= 0 || aLow >= 999999.0) continue;

      // 2. Scan London & NY sessions for Liquidity Sweeps & Reversal Breakouts
      int tradesThisDay = 0;
      bool sweptLow = false, sweptHigh = false;
      datetime skipUntil = 0;

      for(int k = i; k < totalBars - 10; k++)
        {
         if(rates[k].time < sStart) continue;
         if(rates[k].time >= sEnd) break;
         if(tradesThisDay >= MaxDailyTrades) break;
         if(rates[k].time < skipUntil) continue; // Skip while previous trade is running

         // Check if a sweep has occurred
         if(rates[k].low <= aLow - AsianSweepPips * pip)   sweptLow = true;
         if(rates[k].high >= aHigh + AsianSweepPips * pip)  sweptHigh = true;

         // Would-Be BUY: Swept Asian Low, then bullish candle closes back above sweep level
         if(sweptLow && rates[k].close > aLow && rates[k].close > rates[k].open)
           {
            double entry = rates[k].close;
            double sweepLowExtreme = aLow;
            for(int s = MathMax(i, k - 40); s <= k; s++)
              {
               if(rates[s].low < sweepLowExtreme) sweepLowExtreme = rates[s].low;
              }
            double slDistance = MathMax(entry - sweepLowExtreme + 2.0 * pip, SL_Pips * pip);
            double sl = NormalizeDouble(entry - slDistance, _Digits);
            double tp = NormalizeDouble(entry + SingleTarget_RR * slDistance, _Digits);

            // Forward simulate trade outcome
            bool win = true;
            datetime exitT = rates[k].time + 3600;
            for(int f = k + 1; f < totalBars; f++)
              {
               if(rates[f].low <= sl)  { win = false; exitT = rates[f].time; break; }
               if(rates[f].high >= tp) { win = true;  exitT = rates[f].time; break; }
              }

            string id = "WouldBe_Buy_" + IntegerToString(rates[k].time);
            string lbl = win ? StringFormat("★ WIN +%.1fR", SingleTarget_RR)
                             : "✖ SL -1.0R";
            DrawTradeBox(id, rates[k].time, 1, entry, sl, tp, lbl, win, exitT);
            tradesThisDay++;
            sweptLow = false;
            skipUntil = exitT;
            continue;
           }

         // Would-Be SELL: Swept Asian High, then bearish candle closes back below sweep level
         else if(sweptHigh && rates[k].close < aHigh && rates[k].close < rates[k].open)
           {
            double entry = rates[k].close;
            double sweepHighExtreme = aHigh;
            for(int s = MathMax(i, k - 40); s <= k; s++)
              {
               if(rates[s].high > sweepHighExtreme) sweepHighExtreme = rates[s].high;
              }
            double slDistance = MathMax(sweepHighExtreme - entry + 2.0 * pip, SL_Pips * pip);
            double sl = NormalizeDouble(entry + slDistance, _Digits);
            double tp = NormalizeDouble(entry - SingleTarget_RR * slDistance, _Digits);

            // Forward simulate trade outcome
            bool win = true;
            datetime exitT = rates[k].time + 3600;
            for(int f = k + 1; f < totalBars; f++)
              {
               if(rates[f].high >= sl) { win = false; exitT = rates[f].time; break; }
               if(rates[f].low <= tp)  { win = true;  exitT = rates[f].time; break; }
              }

            string id = "WouldBe_Sell_" + IntegerToString(rates[k].time);
            string lbl = win ? StringFormat("★ WIN +%.1fR", SingleTarget_RR)
                             : "✖ SL -1.0R";
            DrawTradeBox(id, rates[k].time, -1, entry, sl, tp, lbl, win, exitT);
            tradesThisDay++;
            sweptHigh = false;
            skipUntil = exitT;
            continue;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Plot Real Account Trades from Deal History                       |
//+------------------------------------------------------------------+
void PlotAccountTradeHistory()
  {
   if(!ShowAccountDeals) return;
   if(!HistorySelect(0, TimeCurrent())) return;

   int totalDeals = HistoryDealsTotal();
   double pip = _Point * 10;

   for(int i = 0; i < totalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != _Symbol) continue;

      long entryType = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      long dealType  = HistoryDealGetInteger(ticket, DEAL_TYPE);
      datetime dealT = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      double price   = HistoryDealGetDouble(ticket, DEAL_PRICE);
      double volume  = HistoryDealGetDouble(ticket, DEAL_VOLUME);
      double profit  = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      long posId     = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);

      string id = "AccDeal_" + IntegerToString(ticket);

      if(entryType == DEAL_ENTRY_IN)
        {
         string arrowName = OBJ_PREFIX + "Arr_" + id;
         if(ObjectFind(0, arrowName) >= 0) continue;

         if(dealType == DEAL_TYPE_BUY)
           {
            ObjectCreate(0, arrowName, OBJ_ARROW, 0, dealT, price);
            ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 233);
            ObjectSetInteger(0, arrowName, OBJPROP_COLOR, (color)C'80,250,123'); // Bright Green
            ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 3);
            ObjectSetInteger(0, arrowName, OBJPROP_SELECTABLE, false);

            string lbl = arrowName + "_txt";
            ObjectCreate(0, lbl, OBJ_TEXT, 0, dealT, price - 12 * pip);
            ObjectSetString(0, lbl, OBJPROP_TEXT, "  REAL BUY " + DoubleToString(volume, 2) + "L @ " + DoubleToString(price, 2));
            ObjectSetInteger(0, lbl, OBJPROP_COLOR, (color)C'80,250,123');
            ObjectSetString(0, lbl, OBJPROP_FONT, "Segoe UI");
            ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
            ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
           }
         else if(dealType == DEAL_TYPE_SELL)
           {
            ObjectCreate(0, arrowName, OBJ_ARROW, 0, dealT, price);
            ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 234);
            ObjectSetInteger(0, arrowName, OBJPROP_COLOR, (color)C'255,85,85'); // Bright Red
            ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 3);
            ObjectSetInteger(0, arrowName, OBJPROP_SELECTABLE, false);

            string lbl = arrowName + "_txt";
            ObjectCreate(0, lbl, OBJ_TEXT, 0, dealT, price + 12 * pip);
            ObjectSetString(0, lbl, OBJPROP_TEXT, "  REAL SELL " + DoubleToString(volume, 2) + "L @ " + DoubleToString(price, 2));
            ObjectSetInteger(0, lbl, OBJPROP_COLOR, (color)C'255,85,85');
            ObjectSetString(0, lbl, OBJPROP_FONT, "Segoe UI");
            ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
            ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
           }
        }
      else if(entryType == DEAL_ENTRY_OUT)
        {
         string exitName = OBJ_PREFIX + "Exit_" + id;
         if(ObjectFind(0, exitName) >= 0) continue;

         bool isWin = (profit >= 0);
         color clr = isWin ? (color)C'80,250,123' : (color)C'255,85,85';

         ObjectCreate(0, exitName, OBJ_ARROW_CHECK, 0, dealT, price);
         ObjectSetInteger(0, exitName, OBJPROP_COLOR, clr);
         ObjectSetInteger(0, exitName, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, exitName, OBJPROP_SELECTABLE, false);

         string lbl = exitName + "_txt";
         ObjectCreate(0, lbl, OBJ_TEXT, 0, dealT, price);
         string profStr = (profit >= 0 ? "  EXIT: +$" : "  EXIT: -$") + DoubleToString(MathAbs(profit), 2);
         ObjectSetString(0, lbl, OBJPROP_TEXT, profStr);
         ObjectSetInteger(0, lbl, OBJPROP_COLOR, clr);
         ObjectSetString(0, lbl, OBJPROP_FONT, "Segoe UI Bold");
         ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);

         // Draw connecting trade line from entry deal to exit deal
         for(int j = 0; j < totalDeals; j++)
           {
            ulong inTicket = HistoryDealGetTicket(j);
            if(inTicket > 0 && 
               HistoryDealGetInteger(inTicket, DEAL_POSITION_ID) == posId &&
               HistoryDealGetInteger(inTicket, DEAL_ENTRY) == DEAL_ENTRY_IN)
              {
               datetime inTime  = (datetime)HistoryDealGetInteger(inTicket, DEAL_TIME);
               double   inPrice = HistoryDealGetDouble(inTicket, DEAL_PRICE);
               string connLine = OBJ_PREFIX + "Conn_" + IntegerToString(posId);
               if(ObjectFind(0, connLine) < 0)
                 {
                  ObjectCreate(0, connLine, OBJ_TREND, 0, inTime, inPrice, dealT, price);
                  ObjectSetInteger(0, connLine, OBJPROP_COLOR, clr);
                  ObjectSetInteger(0, connLine, OBJPROP_STYLE, STYLE_DOT);
                  ObjectSetInteger(0, connLine, OBJPROP_RAY_RIGHT, false);
                  ObjectSetInteger(0, connLine, OBJPROP_WIDTH, 1);
                  ObjectSetInteger(0, connLine, OBJPROP_SELECTABLE, false);
                 }
               break;
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Master Visuals Engine (Coordinates Dracula Theme, Sessions & Boxes)
//+------------------------------------------------------------------+
void RenderAllChartVisuals(bool cleanFirst = false)
  {
   if(cleanFirst)
     {
      ObjectsDeleteAll(0, OBJ_PREFIX);
      ObjectsDeleteAll(0, "VTS_");
     }

   ApplyDraculaTheme();

   MqlRates rates[];
   ArraySetAsSeries(rates, false); // Oldest to newest
   int total = CopyRates(_Symbol, PERIOD_M1, 0, HistoryBarsToScan, rates);

   if(total > 50)
     {
      DrawSessionZones(rates, total);
      PlotWouldBeStrategyTrades(rates, total);
     }

   PlotAccountTradeHistory();
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MicroMagic);
   trade.SetDeviationInPoints(30);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   // Render complete visual suite with clean slate
   RenderAllChartVisuals(true);

   // Set timer for periodic rendering (refreshes even when market is closed on weekends)
   EventSetTimer(10);

   Print("Gold Micro HyperScalp EA v3.80 (TradingView Position Boxes + Non-Intrusive Auto-Scroll) Initialized on ", _Symbol);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   ObjectsDeleteAll(0, OBJ_PREFIX);
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| OnTimer                                                          |
//+------------------------------------------------------------------+
void OnTimer()
  {
   static int timerTicks = 0;
   timerTicks++;

   // Refresh visuals on startup and every 30 seconds (WITHOUT touching autoscroll!)
   if(timerTicks == 1 || timerTicks % 3 == 0)
     {
      RenderAllChartVisuals();
     }
  }

//+------------------------------------------------------------------+
//| Update CPR (Verified Formulation)                                |
//+------------------------------------------------------------------+
void UpdateCPR()
  {
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastCPRDate == today) return;
   lastCPRDate = today;

   double dH[], dL[], dC[];
   ArraySetAsSeries(dH, true); ArraySetAsSeries(dL, true); ArraySetAsSeries(dC, true);
   if(CopyHigh(_Symbol, PERIOD_D1, 1, 1, dH) < 1) return;
   if(CopyLow(_Symbol, PERIOD_D1, 1, 1, dL) < 1)  return;
   if(CopyClose(_Symbol, PERIOD_D1, 1, 1, dC) < 1) return;

   cpr_Pivot = (dH[0] + dL[0] + dC[0]) / 3.0;
   cpr_BC    = (dH[0] + dL[0]) / 2.0;
   cpr_TC    = (cpr_Pivot - cpr_BC) + cpr_Pivot;
   cpr_Width = MathAbs(cpr_TC - cpr_BC) / (_Point * 10);
  }

//+------------------------------------------------------------------+
//| Update Asian Session High/Low Range                              |
//+------------------------------------------------------------------+
void UpdateAsianRange()
  {
   MqlDateTime dt; TimeToStruct(TimeGMT(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(today == lastAsianDate && dt.hour >= AsianEndHour) return;

   int gmtOffset = GetBrokerGMTOffset();
   datetime startT = today + (AsianStartHour + gmtOffset) * 3600;
   datetime endT   = today + (AsianEndHour + gmtOffset) * 3600;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_M1, startT, endT, rates);
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
//| Check Open Positions                                             |
//+------------------------------------------------------------------+
bool HasOpenPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol)
        {
         ulong m = pos.Magic();
         if(m >= MicroMagic && m <= MicroMagic + 3) return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Session Filter                                                   |
//+------------------------------------------------------------------+
bool IsSessionAllowed(const MqlDateTime &gmt)
  {
   if(gmt.day_of_week == 0 || gmt.day_of_week == 6) return false;
   return (gmt.hour >= SessionStartHour && gmt.hour < SessionEndHour);
  }

//+------------------------------------------------------------------+
//| Micro-Account Geometric Compounding Calculator                   |
//+------------------------------------------------------------------+
double CalculateMicroLots(double slPips, bool hasConfluence)
  {
   if(LotSizingMode == MICRO_LOT_FIXED)
      return NormalizeDouble(FixedLotSize, 2);

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double capital = MathMin(balance, equity);

   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = MathMin(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX), MaxLotCap);

   double lots = minLot;

   if(LotSizingMode == MICRO_LOT_GEOMETRIC_STEP)
     {
      if(CapitalPerMicroLot > 0)
        {
         int multiplier = (int)MathFloor(capital / CapitalPerMicroLot);
         if(multiplier < 1) multiplier = 1;
         lots = multiplier * minLot;
         if(hasConfluence) lots = lots * ConfluenceBoost;
        }
     }
   else if(LotSizingMode == MICRO_LOT_RISK_PERCENT)
     {
      double riskCapital = capital * (RiskPercent / 100.0);
      double pipVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(pipVal <= 0) pipVal = 0.10;
      if(slPips > 0) lots = riskCapital / (slPips * pipVal * 10.0);
     }

   if(step > 0) lots = MathFloor(lots / step) * step;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   return NormalizeDouble(lots, 2);
  }

//+------------------------------------------------------------------+
//| Order Execution Engine with Live TradingView Position Box        |
//+------------------------------------------------------------------+
void PlaceMicroTrade(int dir, double lots, double entryPrice, double slPrice, double slPips)
  {
   double pip = _Point * 10;
   if(ExecutionMode == MICRO_EXEC_SINGLE_RUNNER)
     {
      double tpPrice = (dir > 0) ? NormalizeDouble(entryPrice + SingleTarget_RR * slPips * pip, _Digits)
                                 : NormalizeDouble(entryPrice - SingleTarget_RR * slPips * pip, _Digits);

      trade.SetExpertMagicNumber(MicroMagic);
      bool res = false;
      if(dir > 0) res = trade.Buy(lots, _Symbol, entryPrice, slPrice, tpPrice, "Micro-SingleBuy");
      else        res = trade.Sell(lots, _Symbol, entryPrice, slPrice, tpPrice, "Micro-SingleSell");

      if(res)
        {
         dailyTrades++;
         string tId = "Live_" + IntegerToString(TimeCurrent());
         string lbl = StringFormat("LIVE %s (%.2fL)", (dir > 0 ? "BUY" : "SELL"), lots);
         DrawTradeBox(tId, TimeCurrent(), dir, entryPrice, slPrice, tpPrice, lbl, true);
         ChartRedraw(0);
        }
      return;
     }
   else if(ExecutionMode == MICRO_EXEC_DUAL_PARTIAL)
     {
      double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      double halfLot = MathFloor((lots * 0.5) / step) * step;
      if(halfLot < minLot) halfLot = minLot;

      double lot1 = halfLot;
      double lot2 = lots - halfLot;
      if(lot2 < minLot) lot2 = minLot;

      double tp1 = (dir > 0) ? NormalizeDouble(entryPrice + Part1_RR * (entryPrice - slPrice), _Digits)
                             : NormalizeDouble(entryPrice - Part1_RR * (slPrice - entryPrice), _Digits);
      double tp2 = (dir > 0) ? NormalizeDouble(entryPrice + Part2_RR * (entryPrice - slPrice), _Digits)
                             : NormalizeDouble(entryPrice - Part2_RR * (slPrice - entryPrice), _Digits);

      trade.SetExpertMagicNumber(MicroMagic + 1);
      if(dir > 0) trade.Buy(lot1, _Symbol, entryPrice, slPrice, tp1, "Micro-Dual-TP1");
      else        trade.Sell(lot1, _Symbol, entryPrice, slPrice, tp1, "Micro-Dual-TP1");

      trade.SetExpertMagicNumber(MicroMagic + 2);
      if(dir > 0) trade.Buy(lot2, _Symbol, entryPrice, slPrice, tp2, "Micro-Dual-TP2");
      else        trade.Sell(lot2, _Symbol, entryPrice, slPrice, tp2, "Micro-Dual-TP2");

      dailyTrades++;
      return;
     }
  }

//+------------------------------------------------------------------+
//| Manage Partials (Breakeven on TP1 Hit)                           |
//+------------------------------------------------------------------+
void ManagePartials()
  {
   if(ExecutionMode == MICRO_EXEC_SINGLE_RUNNER) return;
   double pip = _Point * 10;
   bool tp1_hit = false;

   HistorySelect(TimeCurrent() - 4 * 3600, TimeCurrent());
   int totalDeals = HistoryDealsTotal();
   for(int i = totalDeals - 1; i >= 0; i--)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
           {
            ulong m = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            if(m == MicroMagic + 1) tp1_hit = true;
           }
        }
     }

   if(tp1_hit && MoveBE_On_TP1)
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(pos.SelectByIndex(i) && pos.Symbol() == _Symbol && pos.Magic() == MicroMagic + 2)
           {
            ulong ticket     = pos.Ticket();
            double openPrice = pos.PriceOpen();
            double curSL     = pos.StopLoss();
            double curTP     = pos.TakeProfit();
            ENUM_POSITION_TYPE type = pos.PositionType();

            if(type == POSITION_TYPE_BUY)
              {
               double newSL = NormalizeDouble(openPrice + BE_Offset_Pips * pip, _Digits);
               if(curSL < newSL) trade.PositionModify(ticket, newSL, curTP);
              }
            else if(type == POSITION_TYPE_SELL)
              {
               double newSL = NormalizeDouble(openPrice - BE_Offset_Pips * pip, _Digits);
               if(curSL == 0 || curSL > newSL) trade.PositionModify(ticket, newSL, curTP);
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Check Daily Losses from Deal History                             |
//+------------------------------------------------------------------+
void UpdateDailyLosses(datetime today)
  {
   dailyLosses = 0;
   HistorySelect(today, TimeCurrent());
   int totalDeals = HistoryDealsTotal();
   int consecLoss = 0;

   for(int i = 0; i < totalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
        {
         if(HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
           {
            ulong m = HistoryDealGetInteger(ticket, DEAL_MAGIC);
            if(m >= MicroMagic && m <= MicroMagic + 3)
              {
               double prof = HistoryDealGetDouble(ticket, DEAL_PROFIT);
               if(prof < 0) consecLoss++;
               else if(prof > 0) consecLoss = 0;
              }
           }
        }
     }
   dailyLosses = consecLoss;
  }

//+------------------------------------------------------------------+
//| OnTick Handling                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   ManagePartials();

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(lastTradeDay != today) { dailyTrades = 0; lastTradeDay = today; }
   if(dailyTrades >= MaxDailyTrades) return;

   UpdateDailyLosses(today);
   if(dailyLosses >= MaxDailyLosses) return;

   MqlDateTime gmt; TimeToStruct(TimeGMT(), gmt);
   if(!IsSessionAllowed(gmt)) return;
   if((double)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > MaxSpreadPips) return;

   UpdateCPR();
   UpdateAsianRange();

   static datetime lastBar = 0;
   datetime curBar = iTime(_Symbol, PERIOD_M1, 0);
   if(lastBar == curBar) return;
   lastBar = curBar;

   if(HasOpenPositions()) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pip = _Point * 10;

   // Confluence Check 1: SMC Asian Range Sweep
   bool smcBullSweep = false;
   bool smcBearSweep = false;
   if(Enable_SMC_Confluence && asianHigh > 0 && asianLow < 999999.0)
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

   // Core CPR Engine Execution
   if(cpr_TC > 0 && cpr_BC > 0)
     {
      bool narrow = (cpr_Width <= CPR_NarrowMax);
      bool wide   = (cpr_Width >= CPR_WideMin);

      if(narrow)
        {
         // Bullish Narrow CPR Breakout
         if(bid > cpr_TC && ask - cpr_TC < SL_Pips * pip * 2)
           {
            double sl = cpr_BC - SL_Pips * pip;
            double slPips = (bid - sl) / pip;
            bool confluence = (smcBullSweep || volSpike);
            double lots = CalculateMicroLots(slPips, confluence);
            if(lots > 0) PlaceMicroTrade(1, lots, ask, sl, slPips);
           }
         // Bearish Narrow CPR Breakout
         else if(bid < cpr_BC && cpr_BC - ask < SL_Pips * pip * 2)
           {
            double sl = cpr_TC + SL_Pips * pip;
            double slPips = (sl - ask) / pip;
            bool confluence = (smcBearSweep || volSpike);
            double lots = CalculateMicroLots(slPips, confluence);
            if(lots > 0) PlaceMicroTrade(-1, lots, bid, sl, slPips);
           }
        }
      else if(wide)
        {
         // Mean Reversion Sell at Top Central
         if(MathAbs(bid - cpr_TC) < SL_Pips * pip)
           {
            double sl = cpr_TC + SL_Pips * 2 * pip;
            double slPips = (sl - bid) / pip;
            if(cpr_TC - cpr_BC >= SingleTarget_RR * (sl - cpr_TC))
              {
               double lots = CalculateMicroLots(slPips, volSpike);
               if(lots > 0) PlaceMicroTrade(-1, lots, bid, sl, slPips);
              }
           }
         // Mean Reversion Buy at Bottom Central
         else if(MathAbs(ask - cpr_BC) < SL_Pips * pip)
           {
            double sl = cpr_BC - SL_Pips * 2 * pip;
            double slPips = (ask - sl) / pip;
            if(cpr_TC - cpr_BC >= SingleTarget_RR * (cpr_BC - sl))
              {
               double lots = CalculateMicroLots(slPips, volSpike);
               if(lots > 0) PlaceMicroTrade(1, lots, ask, sl, slPips);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
