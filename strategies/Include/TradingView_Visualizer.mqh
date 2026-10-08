//+------------------------------------------------------------------+
//|                                     TradingView_Visualizer.mqh   |
//|               TradingView-Style Visual Trade Box & Overlay Engine|
//|               Compatible with MQL5 Strategy Tester & Live Charts |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://www.youtube.com/@MrPFx"
#property version   "1.10"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Color Palette & Theme Constants (TradingView Dracula Dark Mode)  |
//+------------------------------------------------------------------+
#define TV_COLOR_BG_DARK        (color)C'20,24,35'
#define TV_COLOR_WIN_BOX_FILL   (color)C'28,60,38'      // Deep Forest Pine Green Fill
#define TV_COLOR_WIN_LINE       (color)C'80,250,123'    // Bright Lime Green Accent
#define TV_COLOR_LOSS_BOX_FILL  (color)C'65,24,28'      // Deep Crimson Burgundy Fill
#define TV_COLOR_LOSS_LINE      (color)C'255,85,85'     // Bright Coral Red Accent
#define TV_COLOR_ENTRY_LINE     (color)C'248,248,242'   // Crisp Off-White
#define TV_COLOR_TRAIL_LINE     (color)C'139,233,253'   // Cyan Accent

//+------------------------------------------------------------------+
//| Configuration Structure                                          |
//+------------------------------------------------------------------+
struct STVVisualizerConfig
{
   bool   enabled;
   ulong  magicNumber;
   string prefix;
   bool   showArrows;
   bool   showBadges;
   bool   showBoxes;
   bool   showConnectingLine;
   bool   cleanOnDeinit;
   bool   makeSelectable;
   int    fontPillSize;
   int    fontBadgeSize;
   string fontName;
};

static STVVisualizerConfig g_tvConfig;

//+------------------------------------------------------------------+
//| Initialize Visualizer Engine                                     |
//+------------------------------------------------------------------+
void TV_Visualizer_Init(ulong magic = 0,
                        bool enabled = true,
                        string prefix = "TV_Trade_",
                        bool showArrows = true,
                        bool showBadges = true,
                        bool showBoxes = true,
                        bool showConnectingLine = true,
                        bool cleanOnDeinit = false,
                        bool makeSelectable = true)
{
   g_tvConfig.enabled            = enabled;
   g_tvConfig.magicNumber        = magic;
   g_tvConfig.prefix             = prefix;
   g_tvConfig.showArrows         = showArrows;
   g_tvConfig.showBadges         = showBadges;
   g_tvConfig.showBoxes          = showBoxes;
   g_tvConfig.showConnectingLine = showConnectingLine;
   g_tvConfig.cleanOnDeinit      = cleanOnDeinit;
   g_tvConfig.makeSelectable     = makeSelectable;
   g_tvConfig.fontPillSize       = 8;
   g_tvConfig.fontBadgeSize      = 9;
   g_tvConfig.fontName           = "Segoe UI";
}

//+------------------------------------------------------------------+
//| Cleanup Visualizer Objects                                       |
//+------------------------------------------------------------------+
void TV_Visualizer_Clean()
{
   ObjectsDeleteAll(0, g_tvConfig.prefix);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Deinitialization Handler                                         |
//+------------------------------------------------------------------+
void TV_Visualizer_Deinit()
{
   if(g_tvConfig.cleanOnDeinit)
   {
      TV_Visualizer_Clean();
   }
}

//+------------------------------------------------------------------+
//| Draw Single Directional Entry Marker                             |
//+------------------------------------------------------------------+
void TV_DrawEntryMarker(string id, datetime tEntry, int dir, double entryPrice, double volume)
{
   if(!g_tvConfig.enabled || !g_tvConfig.showArrows) return;

   string arrowName = g_tvConfig.prefix + "Arr_" + id;
   string labelName = g_tvConfig.prefix + "Lbl_" + id;

   if(ObjectFind(0, arrowName) >= 0) return; // Prevent duplicate

   double pip = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10.0;
   color arrowColor = (dir > 0) ? TV_COLOR_WIN_LINE : TV_COLOR_LOSS_LINE;
   int arrowCode    = (dir > 0) ? 233 : 234; // 233 = Arrow Up, 234 = Arrow Down

   // 1. Directional Entry Arrow
   ObjectCreate(0, arrowName, OBJ_ARROW, 0, tEntry, entryPrice);
   ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, arrowName, OBJPROP_COLOR, arrowColor);
   ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 3);
   ObjectSetInteger(0, arrowName, OBJPROP_SELECTABLE, g_tvConfig.makeSelectable);
   ObjectSetInteger(0, arrowName, OBJPROP_BACK, false);

   // 2. Entry Price Pill Badge
   if(g_tvConfig.showBadges)
   {
      double labelY = (dir > 0) ? (entryPrice - 12.0 * pip) : (entryPrice + 12.0 * pip);
      string entryTxt = (dir > 0) ? StringFormat("  ▲ BUY %.2fL @ %.2f", volume, entryPrice)
                                  : StringFormat("  ▼ SELL %.2fL @ %.2f", volume, entryPrice);

      ObjectCreate(0, labelName, OBJ_TEXT, 0, tEntry, labelY);
      ObjectSetString(0, labelName, OBJPROP_TEXT, entryTxt);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, arrowColor);
      ObjectSetString(0, labelName, OBJPROP_FONT, g_tvConfig.fontName);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, g_tvConfig.fontPillSize);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, g_tvConfig.makeSelectable);
      ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
   }
}

//+------------------------------------------------------------------+
//| Draw Completed TradingView Profit / Loss Position Box            |
//+------------------------------------------------------------------+
void TV_DrawTradeBox(string id, datetime tEntry, datetime tExit, int dir, 
                     double entryPrice, double exitPrice, double profit, double volume,
                     double slPrice = 0.0, double tpPrice = 0.0)
{
   if(!g_tvConfig.enabled) return;

   // Guarantee non-zero time span
   if(tExit <= tEntry)
      tExit = tEntry + PeriodSeconds(_Period) * 3;

   bool isWin = (profit >= 0.0);
   color boxFillColor  = isWin ? TV_COLOR_WIN_BOX_FILL : TV_COLOR_LOSS_BOX_FILL;
   color boxLineColor  = isWin ? TV_COLOR_WIN_LINE : TV_COLOR_LOSS_LINE;
   double pointVal     = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double pipsGained   = (pointVal > 0.0) ? MathAbs(exitPrice - entryPrice) / pointVal : 0.0;

   string boxName   = g_tvConfig.prefix + "Box_" + id;
   string entryLine = g_tvConfig.prefix + "EntLine_" + id;
   string exitLine  = g_tvConfig.prefix + "ExtLine_" + id;
   string connLine  = g_tvConfig.prefix + "Conn_" + id;
   string badgeName = g_tvConfig.prefix + "Badge_" + id;

   // 1. Shaded TradingView Outcome Box (Entry to Exit)
   if(g_tvConfig.showBoxes)
   {
      double topY = MathMax(entryPrice, exitPrice);
      double botY = MathMin(entryPrice, exitPrice);
      
      // If flat or instant exit, give minimal thickness
      if(topY - botY < 5.0 * pointVal)
      {
         topY += 3.0 * pointVal;
         botY -= 3.0 * pointVal;
      }

      ObjectDelete(0, boxName);
      ObjectCreate(0, boxName, OBJ_RECTANGLE, 0, tEntry, topY, tExit, botY);
      ObjectSetInteger(0, boxName, OBJPROP_COLOR, boxLineColor);
      ObjectSetInteger(0, boxName, OBJPROP_BGCOLOR, boxFillColor);
      ObjectSetInteger(0, boxName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, boxName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, boxName, OBJPROP_FILL, true);
      ObjectSetInteger(0, boxName, OBJPROP_BACK, true); // Behind candles
      ObjectSetInteger(0, boxName, OBJPROP_SELECTABLE, g_tvConfig.makeSelectable);

      // 2. Horizontal Entry Level Line
      ObjectDelete(0, entryLine);
      ObjectCreate(0, entryLine, OBJ_TREND, 0, tEntry, entryPrice, tExit, entryPrice);
      ObjectSetInteger(0, entryLine, OBJPROP_COLOR, TV_COLOR_ENTRY_LINE);
      ObjectSetInteger(0, entryLine, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, entryLine, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, entryLine, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, entryLine, OBJPROP_BACK, false);
      ObjectSetInteger(0, entryLine, OBJPROP_SELECTABLE, g_tvConfig.makeSelectable);

      // 3. Horizontal Exit Level Line
      ObjectDelete(0, exitLine);
      ObjectCreate(0, exitLine, OBJ_TREND, 0, tEntry, exitPrice, tExit, exitPrice);
      ObjectSetInteger(0, exitLine, OBJPROP_COLOR, boxLineColor);
      ObjectSetInteger(0, exitLine, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, exitLine, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, exitLine, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, exitLine, OBJPROP_BACK, false);
      ObjectSetInteger(0, exitLine, OBJPROP_SELECTABLE, g_tvConfig.makeSelectable);
   }

   // 4. Connecting Trajectory Line (Entry Point -> Exit Point)
   if(g_tvConfig.showConnectingLine)
   {
      ObjectDelete(0, connLine);
      ObjectCreate(0, connLine, OBJ_TREND, 0, tEntry, entryPrice, tExit, exitPrice);
      ObjectSetInteger(0, connLine, OBJPROP_COLOR, boxLineColor);
      ObjectSetInteger(0, connLine, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, connLine, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, connLine, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, connLine, OBJPROP_BACK, false);
      ObjectSetInteger(0, connLine, OBJPROP_SELECTABLE, g_tvConfig.makeSelectable);
   }

   // 5. Outcome Badge Text (Displayed at exit price)
   if(g_tvConfig.showBadges)
   {
      string badgeText = "";
      if(isWin)
         badgeText = StringFormat("  ★ WIN +$%.2f (+%.1f pts)", profit, pipsGained);
      else
         badgeText = StringFormat("  ✖ LOSS -$%.2f (-%.1f pts)", MathAbs(profit), pipsGained);

      ObjectDelete(0, badgeName);
      ObjectCreate(0, badgeName, OBJ_TEXT, 0, tExit, exitPrice);
      ObjectSetString(0, badgeName, OBJPROP_TEXT, badgeText);
      ObjectSetInteger(0, badgeName, OBJPROP_COLOR, boxLineColor);
      ObjectSetString(0, badgeName, OBJPROP_FONT, g_tvConfig.fontName + " Bold");
      ObjectSetInteger(0, badgeName, OBJPROP_FONTSIZE, g_tvConfig.fontBadgeSize);
      ObjectSetInteger(0, badgeName, OBJPROP_BACK, false);
      ObjectSetInteger(0, badgeName, OBJPROP_SELECTABLE, g_tvConfig.makeSelectable);
   }

   // 6. Ensure Entry Arrow is Present
   TV_DrawEntryMarker(id, tEntry, dir, entryPrice, volume);
}

//+------------------------------------------------------------------+
//| Scan and Render Historical Closed Deals on the Current Chart     |
//+------------------------------------------------------------------+
void TV_Visualizer_PlotHistory()
{
   if(!g_tvConfig.enabled) return;
   if(!HistorySelect(0, TimeCurrent())) return;

   int totalDeals = HistoryDealsTotal();
   for(int i = 0; i < totalDeals; i++)
   {
      ulong outTicket = HistoryDealGetTicket(i);
      if(outTicket <= 0) continue;
      if(HistoryDealGetString(outTicket, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(outTicket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;

      long dealMagic = HistoryDealGetInteger(outTicket, DEAL_MAGIC);
      if(g_tvConfig.magicNumber > 0 && dealMagic != (long)g_tvConfig.magicNumber) continue;

      long posId        = HistoryDealGetInteger(outTicket, DEAL_POSITION_ID);
      datetime exitTime = (datetime)HistoryDealGetInteger(outTicket, DEAL_TIME);
      double exitPrice  = HistoryDealGetDouble(outTicket, DEAL_PRICE);
      double profit     = HistoryDealGetDouble(outTicket, DEAL_PROFIT);
      double volume     = HistoryDealGetDouble(outTicket, DEAL_VOLUME);

      // Locate corresponding entry deal
      for(int j = 0; j < totalDeals; j++)
      {
         ulong inTicket = HistoryDealGetTicket(j);
         if(inTicket > 0 &&
            HistoryDealGetInteger(inTicket, DEAL_POSITION_ID) == posId &&
            HistoryDealGetInteger(inTicket, DEAL_ENTRY) == DEAL_ENTRY_IN)
         {
            datetime inTime  = (datetime)HistoryDealGetInteger(inTicket, DEAL_TIME);
            double inPrice   = HistoryDealGetDouble(inTicket, DEAL_PRICE);
            long dealType    = HistoryDealGetInteger(inTicket, DEAL_TYPE);
            int dir          = (dealType == DEAL_TYPE_BUY) ? 1 : -1;

            string id = "Pos_" + IntegerToString(posId);
            TV_DrawTradeBox(id, inTime, exitTime, dir, inPrice, exitPrice, profit, volume);
            break;
         }
      }
   }
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Handle Trade Transactions (Live & Visual Backtester Handler)     |
//+------------------------------------------------------------------+
void TV_Visualizer_OnTradeTransaction(const MqlTradeTransaction &trans,
                                      const MqlTradeRequest &request,
                                      const MqlTradeResult &result)
{
   if(!g_tvConfig.enabled) return;

   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      ulong dealTicket = trans.deal;
      if(dealTicket > 0 && HistoryDealSelect(dealTicket))
      {
         string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
         if(dealSymbol != _Symbol) return;

         long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
         if(g_tvConfig.magicNumber > 0 && dealMagic != (long)g_tvConfig.magicNumber) return;

         long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
         long posId     = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
         string id      = "Pos_" + IntegerToString(posId);

         // Handle Entry Deal
         if(dealEntry == DEAL_ENTRY_IN)
         {
            datetime inTime  = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
            double inPrice   = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
            double volume    = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
            long dealType    = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
            int dir          = (dealType == DEAL_TYPE_BUY) ? 1 : -1;

            TV_DrawEntryMarker(id, inTime, dir, inPrice, volume);
            ChartRedraw(0);
         }
         // Handle Exit Deal
         else if(dealEntry == DEAL_ENTRY_OUT)
         {
            datetime exitTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
            double exitPrice  = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
            double profit     = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
            double volume     = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);

            // Fetch matching entry deal from history
            if(HistorySelect(0, TimeCurrent()))
            {
               int totalDeals = HistoryDealsTotal();
               for(int j = 0; j < totalDeals; j++)
               {
                  ulong inTicket = HistoryDealGetTicket(j);
                  if(inTicket > 0 &&
                     HistoryDealGetInteger(inTicket, DEAL_POSITION_ID) == posId &&
                     HistoryDealGetInteger(inTicket, DEAL_ENTRY) == DEAL_ENTRY_IN)
                  {
                     datetime inTime = (datetime)HistoryDealGetInteger(inTicket, DEAL_TIME);
                     double inPrice  = HistoryDealGetDouble(inTicket, DEAL_PRICE);
                     long dealType   = HistoryDealGetInteger(inTicket, DEAL_TYPE);
                     int dir         = (dealType == DEAL_TYPE_BUY) ? 1 : -1;

                     TV_DrawTradeBox(id, inTime, exitTime, dir, inPrice, exitPrice, profit, volume);
                     ChartRedraw(0);
                     break;
                  }
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
