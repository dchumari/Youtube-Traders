//+------------------------------------------------------------------+
//|                                SMC_ICT_SD_Master_Visualizer.mq5 |
//|           Master Institutional SMC, ICT & Supply-Demand Suite   |
//|    Comprehensive Multi-Concept On-Chart Visualizer & Research Tool|
//|    Every Feature Has an Individual User Toggle (ON / OFF)       |
//|                                 Copyright 2026, Quant Research Lab|
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research Lab"
#property link      "https://github.com/dchumari/Youtube-Traders"
#property version   "3.00"
#property description "Institutional SMC, ICT & Supply-Demand Master Visualizer with Individual Feature Toggles"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0
#property strict

#include <VisualTradeSuite.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS: INDIVIDUAL FEATURE TOGGLES                     |
//+------------------------------------------------------------------+
sinput string sep_sd = "================ 1. SUPPLY & DEMAND (S&D) ================";
input bool   InpShowSupplyDemand      = true;   // [S&D] Show Fresh Supply & Demand Zones (DBR / RBD)
input bool   InpShowSRFlips           = true;   // [S&D] Show Support / Resistance Base Flips
input int    InpMaxZonesToDisplay     = 8;      // [S&D] Maximum Active Zones to Keep on Chart

sinput string sep_fvg = "================ 2. FAIR VALUE GAPS (ICT FVG) ============";
input bool   InpShowFairValueGaps     = true;   // [ICT] Show Fair Value Gaps (3-Candle Imbalance)
input bool   InpShowFVGMidpointCE     = true;   // [ICT] Show Consequent Encroachment (50% CE Line)
input int    InpMinFVGPoints          = 25;     // [ICT] Minimum FVG Gap Points (2.5 pips)
input int    InpMaxFVGsToDisplay      = 10;     // [ICT] Maximum Active FVGs to Display

sinput string sep_smc = "================ 3. SMART MONEY CONCEPTS (SMC) ==========";
input bool   InpShowOrderBlocks       = true;   // [SMC] Show Institutional Order Blocks (OB)
input bool   InpShowLiquiditySweeps   = true;   // [SMC] Show Liquidity Sweeps (BSL / SSL Purged)
input bool   InpShowInducementIDM     = true;   // [SMC] Show Retail Inducement (IDM) Traps
input bool   InpShowStructureBOS      = true;   // [SMC] Show Market Structure Shift (BOS / CHoCH)
input int    InpLookbackBars          = 30;     // [SMC] Swing Structure Lookback Bars
input int    InpMinSweepPoints        = 15;     // [SMC] Minimum Liquidity Sweep Points

sinput string sep_ict = "================ 4. ICT STRUCTURAL PATTERNS ============";
input bool   InpShowBreakerBlocks     = true;   // [ICT] Show Breaker Blocks (Violated OB Inversion)
input bool   InpShowOTEFibGrid        = true;   // [ICT] Show Optimal Trade Entry (OTE 70.5% Golden Zone)
input bool   InpShowBalancedPriceRange= true;   // [ICT] Show Balanced Price Range (BPR Vacuum)

sinput string sep_ses = "================ 5. SESSIONS & KILLZONES ================";
input bool   InpShowTradingSessions   = true;   // [SESSION] Show Asian Session Range Box (00:00-07:00 UTC)
input bool   InpShowLondonOpenLine    = true;   // [SESSION] Show London Open Divider (08:00 UTC)
input bool   InpShowNYOpenLine        = true;   // [SESSION] Show New York Open Divider (13:00 UTC)
input int    InpAsianStartHourUTC     = 0;      // Asian Start Hour UTC
input int    InpAsianEndHourUTC       = 7;      // Asian End Hour UTC
input int    InpLondonOpenHourUTC     = 8;      // London Open Hour UTC
input int    InpNYOpenHourUTC         = 13;     // NY Open Hour UTC

sinput string sep_vis = "================ 6. AESTHETICS & DASHBOARD HUD ==========";
input bool   InpApplyDraculaTheme     = true;   // Apply Dracula Dark Base Theme (#282A36)
input bool   InpShowDashboardHUD      = true;   // Show On-Chart Interactive Status HUD
input color  InpColorBullZone         = C'80,250,123'; // Bullish Zone Color (#50FA7B Dracula Lime)
input color  InpColorBearZone         = C'255,85,85';  // Bearish Zone Color (#FF5555 Dracula Red)
input color  InpColorNeutralZone      = C'189,147,249';// Neutral / IDM Color (#BD93F9 Dracula Purple)
input color  InpColorOTE              = C'241,250,140';// OTE Golden Pocket Color (#F1FA8C Yellow)

//+------------------------------------------------------------------+
//| GLOBAL CONSTANTS & VARIABLES                                     |
//+------------------------------------------------------------------+
#define VIS_PREFIX "SMCICT_VIS_"

int      ExtGMTOffset = 3;
datetime ExtLastProcessedBar = 0;

//+------------------------------------------------------------------+
//| Helper: Auto-Detect GMT Offset                                   |
//+------------------------------------------------------------------+
int DetectGMTOffset()
{
   datetime sTime = TimeTradeServer();
   datetime gTime = TimeGMT();
   if(sTime > 0 && gTime > 0)
   {
      int diff = (int)(sTime - gTime);
      int h = (int)MathRound((double)diff / 3600.0);
      if(h >= -12 && h <= 14) return h;
   }
   return 3;
}

//+------------------------------------------------------------------+
//| Helper: Create/Update Rectangle Zone                             |
//+------------------------------------------------------------------+
void PlotRectZone(string name, datetime t1, double p1, datetime t2, double p2, color clr, string labelText)
{
   string objName = VIS_PREFIX + name;
   string lblName = objName + "_lbl";

   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, objName, OBJPROP_BACK, true);
      ObjectSetInteger(0, objName, OBJPROP_FILL, true);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   }
   else
   {
      ObjectSetInteger(0, objName, OBJPROP_TIME, 1, t2);
   }

   if(ObjectFind(0, lblName) < 0)
   {
      ObjectCreate(0, lblName, OBJ_TEXT, 0, t1, MathMax(p1, p2));
      ObjectSetString(0, lblName, OBJPROP_TEXT, "  " + labelText);
      ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
      ObjectSetString(0, lblName, OBJPROP_FONT, "Segoe UI Bold");
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| Helper: Create/Update Horizontal Ray Line                        |
//+------------------------------------------------------------------+
void PlotHLine(string name, datetime t1, double price, color clr, ENUM_LINE_STYLE style, string labelText)
{
   string objName = VIS_PREFIX + name;
   datetime t2 = t1 + PeriodSeconds(_Period) * 30;

   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_TREND, 0, t1, price, t2, price);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, style);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);

      string lblName = objName + "_lbl";
      ObjectCreate(0, lblName, OBJ_TEXT, 0, t2, price);
      ObjectSetString(0, lblName, OBJPROP_TEXT, "  " + labelText);
      ObjectSetInteger(0, lblName, OBJPROP_COLOR, clr);
      ObjectSetString(0, lblName, OBJPROP_FONT, "Segoe UI");
      ObjectSetInteger(0, lblName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, lblName, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| 1. Scan & Plot Supply & Demand Zones                             |
//+------------------------------------------------------------------+
void DrawSupplyDemand(const MqlRates &rates[], int total)
{
   if(!InpShowSupplyDemand || total < 20) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   int count = 0;
   for(int i = 3; i < total - 5 && count < InpMaxZonesToDisplay; i++)
   {
      // Drop-Base-Rally (DBR Demand)
      double drop = (rates[i + 2].open - rates[i + 2].close) / point;
      double baseRange = (rates[i + 1].high - rates[i + 1].low) / point;
      double rally = (rates[i].close - rates[i].open) / point;

      if(drop >= 25 && baseRange <= 30 && rally >= 35)
      {
         datetime tStart = rates[i + 1].time;
         datetime tEnd = rates[0].time + PeriodSeconds(_Period) * 15;
         PlotRectZone("DBR_" + IntegerToString(tStart), tStart, rates[i + 1].high, tEnd, rates[i + 1].low, 
                      InpColorBullZone, "[S&D Fresh Demand (DBR)]");
         count++;
      }

      // Rally-Base-Drop (RBD Supply)
      double preRally = (rates[i + 2].close - rates[i + 2].open) / point;
      double dropAfter = (rates[i].open - rates[i].close) / point;

      if(preRally >= 25 && baseRange <= 30 && dropAfter >= 35)
      {
         datetime tStart = rates[i + 1].time;
         datetime tEnd = rates[0].time + PeriodSeconds(_Period) * 15;
         PlotRectZone("RBD_" + IntegerToString(tStart), tStart, rates[i + 1].high, tEnd, rates[i + 1].low, 
                      InpColorBearZone, "[S&D Fresh Supply (RBD)]");
         count++;
      }
   }
}

//+------------------------------------------------------------------+
//| 2. Scan & Plot ICT Fair Value Gaps (FVG & 50% CE)                |
//+------------------------------------------------------------------+
void DrawFairValueGaps(const MqlRates &rates[], int total)
{
   if(!InpShowFairValueGaps || total < 15) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   int count = 0;
   for(int i = 2; i < total - 2 && count < InpMaxFVGsToDisplay; i++)
   {
      // Bullish FVG: Bar i-1 Low > Bar i+1 High
      if(rates[i - 1].low > rates[i + 1].high + (InpMinFVGPoints * point))
      {
         double gapHigh = rates[i - 1].low;
         double gapLow  = rates[i + 1].high;
         double ceMid   = gapLow + ((gapHigh - gapLow) * 0.50);
         datetime tStart = rates[i].time;
         datetime tEnd   = rates[0].time + PeriodSeconds(_Period) * 10;

         PlotRectZone("BullFVG_" + IntegerToString(tStart), tStart, gapHigh, tEnd, gapLow, 
                      InpColorBullZone, "[ICT Bullish FVG]");

         if(InpShowFVGMidpointCE)
         {
            PlotHLine("BullCE_" + IntegerToString(tStart), tStart, ceMid, (color)C'139,233,253', STYLE_DOT, "50% CE");
         }
         count++;
      }
      // Bearish FVG: Bar i+1 Low > Bar i-1 High
      else if(rates[i + 1].low > rates[i - 1].high + (InpMinFVGPoints * point))
      {
         double gapHigh = rates[i + 1].low;
         double gapLow  = rates[i - 1].high;
         double ceMid   = gapLow + ((gapHigh - gapLow) * 0.50);
         datetime tStart = rates[i].time;
         datetime tEnd   = rates[0].time + PeriodSeconds(_Period) * 10;

         PlotRectZone("BearFVG_" + IntegerToString(tStart), tStart, gapHigh, tEnd, gapLow, 
                      InpColorBearZone, "[ICT Bearish FVG]");

         if(InpShowFVGMidpointCE)
         {
            PlotHLine("BearCE_" + IntegerToString(tStart), tStart, ceMid, (color)C'139,233,253', STYLE_DOT, "50% CE");
         }
         count++;
      }
   }
}

//+------------------------------------------------------------------+
//| 3. Scan & Plot SMC Order Blocks, Liquidity Sweeps & IDM          |
//+------------------------------------------------------------------+
void DrawSMCConcepts(const MqlRates &rates[], int total)
{
   if(total < InpLookbackBars + 5) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // Find Major Swing Extremes
   double swingHigh = 0.0, swingLow = 999999.0;
   int shIdx = -1, slIdx = -1;
   for(int i = 3; i <= InpLookbackBars; i++)
   {
      if(rates[i].high > swingHigh) { swingHigh = rates[i].high; shIdx = i; }
      if(rates[i].low < swingLow)   { swingLow  = rates[i].low;  slIdx = i; }
   }

   // 1. Plot Liquidity Sweeps (BSL / SSL)
   if(InpShowLiquiditySweeps)
   {
      if(rates[1].high > swingHigh + (InpMinSweepPoints * point) && rates[1].close < swingHigh)
      {
         PlotHLine("BSL_Swept_" + IntegerToString(rates[1].time), rates[shIdx].time, swingHigh, 
                   InpColorBearZone, STYLE_DASH, "⚡ [BSL Swept - Retail Liquidity Purged]");
      }
      if(rates[1].low < swingLow - (InpMinSweepPoints * point) && rates[1].close > swingLow)
      {
         PlotHLine("SSL_Swept_" + IntegerToString(rates[1].time), rates[slIdx].time, swingLow, 
                   InpColorBullZone, STYLE_DASH, "⚡ [SSL Swept - Retail Liquidity Purged]");
      }
   }

   // 2. Plot Order Blocks
   if(InpShowOrderBlocks)
   {
      for(int i = 2; i < 20; i++)
      {
         // Bullish Order Block (last down candle before strong rally)
         if(rates[i].close < rates[i].open && rates[i - 1].close > rates[i - 1].open && (rates[i - 1].close - rates[i - 1].open) > 35 * point)
         {
            datetime tStart = rates[i].time;
            datetime tEnd = rates[0].time + PeriodSeconds(_Period) * 15;
            PlotRectZone("OB_Bull_" + IntegerToString(tStart), tStart, rates[i].open, tEnd, rates[i].low, 
                         InpColorBullZone, "[SMC Bullish Order Block]");
            break;
         }
         // Bearish Order Block
         if(rates[i].close > rates[i].open && rates[i - 1].close < rates[i - 1].open && (rates[i - 1].open - rates[i - 1].close) > 35 * point)
         {
            datetime tStart = rates[i].time;
            datetime tEnd = rates[0].time + PeriodSeconds(_Period) * 15;
            PlotRectZone("OB_Bear_" + IntegerToString(tStart), tStart, rates[i].high, tEnd, rates[i].open, 
                         InpColorBearZone, "[SMC Bearish Order Block]");
            break;
         }
      }
   }

   // 3. Plot Inducement (Retail IDM Bait)
   if(InpShowInducementIDM)
   {
      for(int i = 3; i < 15; i++)
      {
         bool isIDMHigh = (rates[i].high > rates[i + 1].high && rates[i].high > rates[i - 1].high);
         if(isIDMHigh && rates[i].high < swingHigh)
         {
            PlotHLine("IDM_High_" + IntegerToString(rates[i].time), rates[i].time, rates[i].high, 
                      InpColorNeutralZone, STYLE_DOT, "⚠️ [Retail Inducement IDM Bait]");
            break;
         }
      }
   }

   // 4. Plot Market Structure (BOS / CHoCH)
   if(InpShowStructureBOS && shIdx > 0 && slIdx > 0)
   {
      PlotHLine("SwingH_" + IntegerToString(rates[shIdx].time), rates[shIdx].time, swingHigh, 
                InpColorBearZone, STYLE_SOLID, "[BOS / CHoCH Pivot High]");
      PlotHLine("SwingL_" + IntegerToString(rates[slIdx].time), rates[slIdx].time, swingLow, 
                InpColorBullZone, STYLE_SOLID, "[BOS / CHoCH Pivot Low]");
   }
}

//+------------------------------------------------------------------+
//| 4. Scan & Plot ICT OTE Golden Zone & Breakers                    |
//+------------------------------------------------------------------+
void DrawICTPatterns(const MqlRates &rates[], int total)
{
   if(total < 25) return;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   // ICT OTE Fib Corridor
   if(InpShowOTEFibGrid)
   {
      double legHigh = 0.0, legLow = 999999.0;
      int hIdx = -1, lIdx = -1;
      for(int i = 2; i <= 18; i++)
      {
         if(rates[i].high > legHigh) { legHigh = rates[i].high; hIdx = i; }
         if(rates[i].low < legLow)   { legLow  = rates[i].low;  lIdx = i; }
      }

      if((legHigh - legLow) >= 60 * point && hIdx > 0 && lIdx > 0)
      {
         datetime tStart = (hIdx > lIdx) ? rates[hIdx].time : rates[lIdx].time;
         datetime tEnd   = rates[0].time + PeriodSeconds(_Period) * 12;

         if(lIdx > hIdx) // Bullish impulse leg
         {
            double f62 = legHigh - (0.618 * (legHigh - legLow));
            double f70 = legHigh - (0.705 * (legHigh - legLow));
            double f79 = legHigh - (0.786 * (legHigh - legLow));

            PlotRectZone("OTE_Bull", tStart, f62, tEnd, f79, InpColorOTE, "[ICT OTE 70.5% Golden Pocket]");
            PlotHLine("OTE_SweetBull", tStart, f70, InpColorOTE, STYLE_DASH, "OTE Sweet Spot (70.5%)");
         }
         else // Bearish impulse leg
         {
            double f62 = legLow + (0.618 * (legHigh - legLow));
            double f70 = legLow + (0.705 * (legHigh - legLow));
            double f79 = legLow + (0.786 * (legHigh - legLow));

            PlotRectZone("OTE_Bear", tStart, f79, tEnd, f62, InpColorOTE, "[ICT OTE 70.5% Golden Pocket]");
            PlotHLine("OTE_SweetBear", tStart, f70, InpColorOTE, STYLE_DASH, "OTE Sweet Spot (70.5%)");
         }
      }
   }

   // Breaker Blocks
   if(InpShowBreakerBlocks)
   {
      for(int i = 4; i <= 14; i++)
      {
         if(rates[i].close > rates[i].open && rates[2].close < rates[i].low - (20 * point))
         {
            PlotRectZone("Breaker_Bear_" + IntegerToString(rates[i].time), rates[i].time, rates[i].high, 
                         rates[0].time + PeriodSeconds(_Period) * 10, rates[i].low, 
                         InpColorBearZone, "[ICT Bearish Breaker]");
            break;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 5. Scan & Plot Trading Sessions & Killzones                      |
//+------------------------------------------------------------------+
void DrawSessions(const MqlRates &rates[], int total)
{
   if(!InpShowTradingSessions || total < 40) return;

   datetime lastDay = 0;
   for(int i = 0; i < total; i++)
   {
      MqlDateTime dt;
      TimeToStruct(rates[i].time, dt);
      datetime dayStart = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));

      if(dayStart == lastDay) continue;
      lastDay = dayStart;

      if(dt.day_of_week == 0 || dt.day_of_week == 6) continue;

      datetime aStart  = dayStart + (InpAsianStartHourUTC + ExtGMTOffset) * 3600;
      datetime aEnd    = dayStart + (InpAsianEndHourUTC   + ExtGMTOffset) * 3600;
      datetime lonOpen = dayStart + (InpLondonOpenHourUTC + ExtGMTOffset) * 3600;
      datetime nyOpen  = dayStart + (InpNYOpenHourUTC     + ExtGMTOffset) * 3600;

      // Asian Range Box
      double aHigh = 0.0, aLow = 999999.0;
      int foundBars = 0;
      for(int j = i; j < total; j++)
      {
         if(rates[j].time >= aStart && rates[j].time < aEnd)
         {
            if(rates[j].high > aHigh) aHigh = rates[j].high;
            if(rates[j].low < aLow)   aLow  = rates[j].low;
            foundBars++;
         }
         if(rates[j].time >= aEnd) break;
      }

      if(foundBars > 0)
      {
         string asianBox = VIS_PREFIX + "Asian_" + IntegerToString(dayStart);
         if(ObjectFind(0, asianBox) < 0)
         {
            ObjectCreate(0, asianBox, OBJ_RECTANGLE, 0, aStart, aHigh, aEnd, aLow);
            ObjectSetInteger(0, asianBox, OBJPROP_COLOR, (color)C'98,114,164');
            ObjectSetInteger(0, asianBox, OBJPROP_STYLE, STYLE_DASH);
            ObjectSetInteger(0, asianBox, OBJPROP_BACK, true);
            ObjectSetInteger(0, asianBox, OBJPROP_FILL, false);
            ObjectSetInteger(0, asianBox, OBJPROP_SELECTABLE, false);

            string lbl = asianBox + "_lbl";
            ObjectCreate(0, lbl, OBJ_TEXT, 0, aStart, aHigh);
            ObjectSetString(0, lbl, OBJPROP_TEXT, "  ASIAN RANGE (00:00 - 07:00 UTC)");
            ObjectSetInteger(0, lbl, OBJPROP_COLOR, (color)C'189,147,249');
            ObjectSetString(0, lbl, OBJPROP_FONT, "Segoe UI");
            ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE, 8);
         }
      }

      // London Open Divider Line
      if(InpShowLondonOpenLine)
      {
         string lonLine = VIS_PREFIX + "Lon_" + IntegerToString(dayStart);
         if(ObjectFind(0, lonLine) < 0)
         {
            ObjectCreate(0, lonLine, OBJ_VLINE, 0, lonOpen, 0);
            ObjectSetInteger(0, lonLine, OBJPROP_COLOR, (color)C'80,250,123');
            ObjectSetInteger(0, lonLine, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, lonLine, OBJPROP_BACK, true);
         }
      }

      // NY Open Divider Line
      if(InpShowNYOpenLine)
      {
         string nyLine = VIS_PREFIX + "NY_" + IntegerToString(dayStart);
         if(ObjectFind(0, nyLine) < 0)
         {
            ObjectCreate(0, nyLine, OBJ_VLINE, 0, nyOpen, 0);
            ObjectSetInteger(0, nyLine, OBJPROP_COLOR, (color)C'255,121,198');
            ObjectSetInteger(0, nyLine, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, nyLine, OBJPROP_BACK, true);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 6. Render On-Chart Interactive HUD Dashboard                     |
//+------------------------------------------------------------------+
void UpdateDashboardHUD()
{
   if(!InpShowDashboardHUD) return;

   string name = VIS_PREFIX + "DASHBOARD";
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, 20);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 25);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, name, OBJPROP_FONT, "Lucida Console");
   }

   string hudText = StringFormat(
      "╔═══════════════════════════════════════╗\n" +
      "║   INSTITUTIONAL SMC/ICT/SD SUITE     ║\n" +
      "╠═══════════════════════════════════════╣\n" +
      "║ Supply & Demand (S&D) : %-13s ║\n" +
      "║ Fair Value Gaps (FVG) : %-13s ║\n" +
      "║ Order Blocks (SMC OB) : %-13s ║\n" +
      "║ Liquidity Sweeps      : %-13s ║\n" +
      "║ Retail Inducement(IDM): %-13s ║\n" +
      "║ ICT OTE (70.5%% Pocket): %-13s ║\n" +
      "║ Breaker Blocks        : %-13s ║\n" +
      "║ Sessions & Killzones  : %-13s ║\n" +
      "╠═══════════════════════════════════════╣\n" +
      "║ Dracula Base Theme    : %-13s ║\n" +
      "╚═══════════════════════════════════════╝",
      (InpShowSupplyDemand ? "ACTIVE [ON]" : "MUTED [OFF]"),
      (InpShowFairValueGaps ? "ACTIVE [ON]" : "MUTED [OFF]"),
      (InpShowOrderBlocks ? "ACTIVE [ON]" : "MUTED [OFF]"),
      (InpShowLiquiditySweeps ? "ACTIVE [ON]" : "MUTED [OFF]"),
      (InpShowInducementIDM ? "ACTIVE [ON]" : "MUTED [OFF]"),
      (InpShowOTEFibGrid ? "ACTIVE [ON]" : "MUTED [OFF]"),
      (InpShowBreakerBlocks ? "ACTIVE [ON]" : "MUTED [OFF]"),
      (InpShowTradingSessions ? "ACTIVE [ON]" : "MUTED [OFF]"),
      (InpApplyDraculaTheme ? "ENABLED" : "DEFAULT")
   );

   ObjectSetString(0, name, OBJPROP_TEXT, hudText);
   ObjectSetInteger(0, name, OBJPROP_COLOR, (color)C'139,233,253'); // Cyan
}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   ExtGMTOffset = DetectGMTOffset();

   if(InpApplyDraculaTheme)
   {
      VTS_ApplyDraculaTheme();
   }

   Print("🎨 SMC_ICT_SD_Master_Visualizer initialized successfully! GMT Offset: ", ExtGMTOffset);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll(0, VIS_PREFIX);
   ChartRedraw(0);
   Print("🧹 Cleaned all institutional visualizer drawings from chart.");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total < 40) return 0;

   datetime curBar = iTime(_Symbol, _Period, 0);
   if(curBar == ExtLastProcessedBar && prev_calculated > 0)
   {
      UpdateDashboardHUD();
      return rates_total;
   }
   ExtLastProcessedBar = curBar;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 0, MathMin(rates_total, 250), rates);
   if(copied < 35) return 0;

   // Execute Enabled Concept Detectors
   DrawSupplyDemand(rates, copied);
   DrawFairValueGaps(rates, copied);
   DrawSMCConcepts(rates, copied);
   DrawICTPatterns(rates, copied);
   DrawSessions(rates, copied);
   UpdateDashboardHUD();

   ChartRedraw(0);
   return rates_total;
}
//+------------------------------------------------------------------+
