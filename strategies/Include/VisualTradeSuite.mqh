//+------------------------------------------------------------------+
//|                                           VisualTradeSuite.mqh   |
//|               Master Production Visual Suite for MT5 EAs         |
//|   - Auto-Dracula Dark Theme (#282A36, Zero Grid)                 |
//|   - Aesthetic Asian Session Box (Clean Border, No Candlestick Fog)|
//|   - London Open (08:00 UTC) & NY Open (13:00 UTC) Dividers       |
//|   - TradingView-Style Position Boxes (Green TP Box / Red SL Box) |
//|   - Real Account Deal History & Connecting Trade Lines           |
//|   - Respects User Auto-Scroll (Never Forces Chart to End)        |
//+------------------------------------------------------------------+
#property copyright "Master Quant Architecture"
#property link      "https://youtube-traders.pipeline"
#property strict

#ifndef VISUAL_TRADE_SUITE_MQH
#define VISUAL_TRADE_SUITE_MQH

#define VTS_PREFIX "VTS_"

//+------------------------------------------------------------------+
//| Auto-Detect Broker Server GMT Offset                             |
//+------------------------------------------------------------------+
int VTS_GetGMTOffset(int fallbackOffset = 3)
  {
   datetime sTime = TimeTradeServer();
   datetime gTime = TimeGMT();
   if(sTime > 0 && gTime > 0)
     {
      int diff = (int)(sTime - gTime);
      int h = (int)MathRound((double)diff / 3600.0);
      if(h >= -12 && h <= 14) return h;
     }
   return fallbackOffset;
  }

//+------------------------------------------------------------------+
//| Apply Dracula Theme Programmatically (Gridless & Non-Intrusive)  |
//| NOTE: Never modifies CHART_AUTOSCROLL to respect user scrolling  |
//+------------------------------------------------------------------+
void VTS_ApplyDraculaTheme()
  {
   // 1. Remove Grid Lines completely & configure candle mode
   ChartSetInteger(0, CHART_SHOW_GRID, false);
   ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
   ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, false);
   ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, true);
   ChartSetInteger(0, CHART_SHOW_TRADE_HISTORY, true);

   // 2. Exact Dracula Palette (#282A36 Dark Navy Base)
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, (color)3549737);       // #282A36 Dark Navy-Purple
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, (color)10777186);      // #F8F8F2 Light Cream Text
   ChartSetInteger(0, CHART_COLOR_CHART_UP, (color)8125265);         // #50FA7B Dracula Green
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, (color)5592575);       // #FF5555 Dracula Red
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, (color)8125265);      // #50FA7B Bull Candle Body
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, (color)5264367);      // #BD93F9 Bear Candle Body
   ChartSetInteger(0, CHART_COLOR_CHART_LINE, (color)8125265);
   ChartSetInteger(0, CHART_COLOR_VOLUME, (color)13007359);          // #BD93F9 Purple Volume
   ChartSetInteger(0, CHART_COLOR_GRID, (color)3549737);             // Hidden Grid
   ChartSetInteger(0, CHART_COLOR_BID, (color)13007359);             // #BD93F9 Bid Line
   ChartSetInteger(0, CHART_COLOR_ASK, (color)16356285);             // #FF79C6 Ask Line
   ChartSetInteger(0, CHART_COLOR_LAST, (color)9305073);
   ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, (color)5264367);
  }

//+------------------------------------------------------------------+
//| Draw Visual Session Boxes & Dividers                             |
//+------------------------------------------------------------------+
void VTS_DrawSessionZones(const MqlRates &rates[], int totalBars, int gmtOffset = 3, bool fillAsian = false)
  {
   // Guard: Do not clutter Daily or H4 charts with intraday session dividers
   if(_Period >= PERIOD_H4 || totalBars < 50) return;

   datetime lastProcessedDay = 0;

   for(int i = 0; i < totalBars; i++)
     {
      MqlDateTime dt;
      TimeToStruct(rates[i].time, dt);
      datetime dayStart = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));

      if(dayStart == lastProcessedDay) continue;
      lastProcessedDay = dayStart;

      if(dt.day_of_week == 0 || dt.day_of_week == 6) continue;

      datetime aStart  = dayStart + (0 + gmtOffset) * 3600;  // 00:00 UTC
      datetime aEnd    = dayStart + (7 + gmtOffset) * 3600;  // 07:00 UTC
      datetime lonOpen = dayStart + (8 + gmtOffset) * 3600;  // 08:00 UTC
      datetime nyOpen  = dayStart + (13 + gmtOffset) * 3600; // 13:00 UTC

      // 1. Calculate Asian High / Low
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
      string asianBox = VTS_PREFIX + "AsianBox_" + IntegerToString(dayStart);
      if(foundBars > 0 && ObjectFind(0, asianBox) < 0)
        {
         ObjectCreate(0, asianBox, OBJ_RECTANGLE, 0, aStart, aHigh, aEnd, aLow);
         ObjectSetInteger(0, asianBox, OBJPROP_COLOR, (color)C'98,114,164'); // Dracula Slate Border
         ObjectSetInteger(0, asianBox, OBJPROP_STYLE, STYLE_DASH);
         ObjectSetInteger(0, asianBox, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, asianBox, OBJPROP_BACK, true);
         ObjectSetInteger(0, asianBox, OBJPROP_FILL, fillAsian);
         if(fillAsian)
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
      string lonLine = VTS_PREFIX + "Lon_" + IntegerToString(dayStart);
      if(ObjectFind(0, lonLine) < 0)
        {
         ObjectCreate(0, lonLine, OBJ_VLINE, 0, lonOpen, 0);
         ObjectSetInteger(0, lonLine, OBJPROP_COLOR, (color)C'80,250,123'); // Neon Green
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
      string nyLine = VTS_PREFIX + "NY_" + IntegerToString(dayStart);
      if(ObjectFind(0, nyLine) < 0)
        {
         ObjectCreate(0, nyLine, OBJ_VLINE, 0, nyOpen, 0);
         ObjectSetInteger(0, nyLine, OBJPROP_COLOR, (color)C'255,121,198'); // Vibrant Pink
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
void VTS_DrawTradeBox(string id, datetime tEntry, int dir, double entryPrice, double slPrice, double tpPrice, 
                      string badgeText, bool isWin, datetime tExit = 0)
  {
   datetime endT = (tExit > tEntry) ? tExit : tEntry + 3600;

   string tpBoxName = VTS_PREFIX + "TPBox_" + id;
   string slBoxName = VTS_PREFIX + "SLBox_" + id;
   string tpLine    = VTS_PREFIX + "TPLine_" + id;
   string slLine    = VTS_PREFIX + "SLLine_" + id;
   string entryLine = VTS_PREFIX + "Entry_" + id;
   string badgeName = VTS_PREFIX + "Badge_" + id;
   string tagEntry  = VTS_PREFIX + "Tag_" + id;

   if(ObjectFind(0, tpBoxName) >= 0) return;

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
//| Plot Real Account Trades from Deal History                       |
//+------------------------------------------------------------------+
void VTS_PlotAccountDeals(string symbol, double pip)
  {
   if(!HistorySelect(0, TimeCurrent())) return;

   int totalDeals = HistoryDealsTotal();

   for(int i = 0; i < totalDeals; i++)
     {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != symbol) continue;

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
         string arrowName = VTS_PREFIX + "Arr_" + id;
         if(ObjectFind(0, arrowName) >= 0) continue;

         if(dealType == DEAL_TYPE_BUY)
           {
            ObjectCreate(0, arrowName, OBJ_ARROW, 0, dealT, price);
            ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 233);
            ObjectSetInteger(0, arrowName, OBJPROP_COLOR, (color)C'80,250,123');
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
            ObjectSetInteger(0, arrowName, OBJPROP_COLOR, (color)C'255,85,85');
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
         string exitName = VTS_PREFIX + "Exit_" + id;
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

         // Connect entry to exit with dotted trendline
         for(int j = 0; j < totalDeals; j++)
           {
            ulong inTicket = HistoryDealGetTicket(j);
            if(inTicket > 0 && 
               HistoryDealGetInteger(inTicket, DEAL_POSITION_ID) == posId &&
               HistoryDealGetInteger(inTicket, DEAL_ENTRY) == DEAL_ENTRY_IN)
              {
               datetime inTime  = (datetime)HistoryDealGetInteger(inTicket, DEAL_TIME);
               double   inPrice = HistoryDealGetDouble(inTicket, DEAL_PRICE);
               string connLine = VTS_PREFIX + "Conn_" + IntegerToString(posId);
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
//| Clean All Visual Objects                                         |
//+------------------------------------------------------------------+
void VTS_CleanAll()
  {
   ObjectsDeleteAll(0, VTS_PREFIX);
   ChartRedraw(0);
  }

#endif // VISUAL_TRADE_SUITE_MQH
