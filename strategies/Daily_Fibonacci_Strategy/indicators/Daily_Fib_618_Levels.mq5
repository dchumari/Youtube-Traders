//+------------------------------------------------------------------+
//|                                        Daily_Fib_618_Levels.mq5  |
//|               Copyright 2026, Quantitative Fib Trading Engine    |
//|      Displays Daily 61.8% Fibonacci Retracement & Virgin Levels  |
//+------------------------------------------------------------------+
#property copyright   "Quantitative Trading Research"
#property link        "https://www.tradingview.com"
#property version     "1.00"
#property description "Plots Daily 61.8% Fibonacci Retracement Levels on all timeframes (M1-D1)"
#property description "Includes Virgin / Untested Level tracking, Session Filtering & Alerts"
#property indicator_chart_window
#property indicator_plots 0

//--- Input parameters
input group "=== Lookback & Level Settings ==="
input int      InpDaysLookback       = 30;         // Lookback Period (Days)
input bool     InpShowTodayActive    = true;       // Show Current Day Active 61.8% Level
input bool     InpShowHistorical     = true;       // Show Historical Daily 61.8% Levels
input bool     InpTrackVirginLevels  = true;       // Track Untested (Virgin) 61.8% Levels
input bool     InpShowOnlyVirgin     = false;      // Show ONLY Untested (Virgin) Levels
input int      InpMaxVirginAgeDays   = 45;         // Max Age to Keep Virgin Lines (Days)

input group "=== Visual Styles & Colors ==="
input color    InpColorBullish       = clrDodgerBlue; // Bullish Day 61.8% Support Color
input color    InpColorBearish       = clrCoral;      // Bearish Day 61.8% Resistance Color
input color    InpColorVirgin        = clrGold;       // Virgin (Untested) Level Color
input ENUM_LINE_STYLE InpStyleActive = STYLE_SOLID;   // Active Level Line Style
input ENUM_LINE_STYLE InpStyleHist   = STYLE_DOT;     // Historical Level Line Style
input ENUM_LINE_STYLE InpStyleVirgin = STYLE_DASH;    // Virgin Level Line Style
input int      InpLineWidthActive    = 2;             // Active Level Line Width
input int      InpLineWidthHist      = 1;             // Historical Level Line Width
input int      InpLineWidthVirgin    = 2;             // Virgin Level Line Width

input group "=== Labels & Display ==="
input bool     InpShowPriceLabels    = true;       // Show Price & Direction Labels
input int      InpFontSize           = 8;          // Label Font Size
input string   InpFontName           = "Trebuchet MS"; // Label Font Name

input group "=== Alerts ==="
input bool     InpEnableAlerts       = true;       // Alert on Level Touch
input double   InpAlertDistancePoints= 50.0;       // Alert Distance Threshold (Points)
input bool     InpAlertPush          = false;      // Send Mobile Push Notification

//--- Prefix for chart objects
#define OBJ_PREFIX "DF618_"

//--- Structure to store level metadata
struct SFibLevel
{
   datetime time_start;
   datetime time_end;
   datetime day_date;
   double   price_level;
   bool     is_bullish;
   bool     is_virgin;
   bool     is_mitigated;
   datetime time_mitigated;
   string   id;
};

SFibLevel g_levels[];
int       g_total_levels = 0;
datetime  g_last_calc_time = 0;
datetime  g_last_alert_time = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   CleanObjects();
   RecalculateLevels();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   CleanObjects();
}

//+------------------------------------------------------------------+
//| Removes all indicator objects from the chart                     |
//+------------------------------------------------------------------+
void CleanObjects()
{
   ObjectsDeleteAll(0, OBJ_PREFIX);
   ChartRedraw(0);
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
   // Check if new day opened or 1 minute passed
   datetime current_time = TimeCurrent();
   if(current_time - g_last_calc_time >= 60)
   {
      RecalculateLevels();
      g_last_calc_time = current_time;
   }
   
   // Check for touch alerts if enabled
   if(InpEnableAlerts && rates_total > 0)
   {
      CheckAlerts(close[rates_total - 1]);
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
//| Recalculates all daily 61.8% Fibonacci levels                    |
//+------------------------------------------------------------------+
void RecalculateLevels()
{
   CleanObjects();
   ArrayResize(g_levels, 0);
   g_total_levels = 0;

   // Request Daily rates
   MqlRates daily_rates[];
   ArraySetAsSeries(daily_rates, true);
   int copied = CopyRates(_Symbol, PERIOD_D1, 0, InpDaysLookback + 5, daily_rates);
   if(copied < 2) return;

   // Allocate level structure
   ArrayResize(g_levels, copied);

   datetime now = TimeCurrent();

   // Loop backwards through daily bars (index 1 is previous completed day, index 0 is today)
   for(int i = 1; i < copied; i++)
   {
      datetime d_time   = daily_rates[i].time;
      double   d_open   = daily_rates[i].open;
      double   d_high   = daily_rates[i].high;
      double   d_low    = daily_rates[i].low;
      double   d_close  = daily_rates[i].close;
      double   d_range  = d_high - d_low;

      if(d_range <= 0) continue;

      bool is_bullish = (d_close >= d_open);
      double fib_618  = 0.0;

      // Mathematical logic defined by user:
      // Bearish Day: 100% at High, 0% at Low -> Level = Low + 0.618 * Range
      // Bullish Day: 100% at Low, 0% at High -> Level = High - 0.618 * Range
      if(!is_bullish)
      {
         fib_618 = d_low + 0.618 * d_range;
      }
      else
      {
         fib_618 = d_high - 0.618 * d_range;
      }

      // Check next day (i-1) touch
      datetime next_day_start = daily_rates[i-1].time;
      datetime next_day_end   = next_day_start + PeriodSeconds(PERIOD_D1);
      
      bool touched_next_day = false;
      if(!is_bullish)
      {
         // Resistance: touched if next day high reached or exceeded level
         if(daily_rates[i-1].high >= fib_618) touched_next_day = true;
      }
      else
      {
         // Support: touched if next day low reached or dropped below level
         if(daily_rates[i-1].low <= fib_618) touched_next_day = true;
      }

      bool is_virgin = !touched_next_day;
      bool is_mitigated = false;
      datetime time_mitigated = 0;

      // If virgin, search forward through subsequent days (i-2, i-3, down to 0) to find when it was mitigated
      if(is_virgin && InpTrackVirginLevels)
      {
         for(int k = i - 2; k >= 0; k--)
         {
            if(!is_bullish)
            {
               if(daily_rates[k].high >= fib_618)
               {
                  is_mitigated = true;
                  time_mitigated = daily_rates[k].time + PeriodSeconds(PERIOD_D1)/2;
                  break;
               }
            }
            else
            {
               if(daily_rates[k].low <= fib_618)
               {
                  is_mitigated = true;
                  time_mitigated = daily_rates[k].time + PeriodSeconds(PERIOD_D1)/2;
                  break;
               }
            }
         }
      }

      // Populate structure
      SFibLevel lvl;
      lvl.time_start     = next_day_start;
      lvl.time_end       = (is_virgin && !is_mitigated) ? now + PeriodSeconds(PERIOD_D1)*2 : (is_mitigated ? time_mitigated : next_day_end);
      lvl.day_date       = d_time;
      lvl.price_level    = NormalizeDouble(fib_618, _Digits);
      lvl.is_bullish     = is_bullish;
      lvl.is_virgin      = is_virgin;
      lvl.is_mitigated   = is_mitigated;
      lvl.time_mitigated = time_mitigated;
      lvl.id             = StringFormat("%s_%d", TimeToString(d_time, TIME_DATE), i);

      // Filter settings
      if(InpShowOnlyVirgin && !lvl.is_virgin) continue;
      if(!InpShowHistorical && i > 1) continue;
      if(i == 1 && !InpShowTodayActive) continue;

      DrawLevel(lvl, i == 1);
      g_total_levels++;
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Draws a Fibonacci level line and optional price tag              |
//+------------------------------------------------------------------+
void DrawLevel(const SFibLevel &lvl, bool is_current_day)
{
   string line_name  = OBJ_PREFIX + "LINE_" + lvl.id;
   string label_name = OBJ_PREFIX + "TXT_" + lvl.id;

   color line_color;
   ENUM_LINE_STYLE line_style;
   int line_width;

   if(is_current_day)
   {
      line_color = lvl.is_bullish ? InpColorBullish : InpColorBearish;
      line_style = InpStyleActive;
      line_width = InpLineWidthActive;
   }
   else if(lvl.is_virgin && !lvl.is_mitigated)
   {
      line_color = InpColorVirgin;
      line_style = InpStyleVirgin;
      line_width = InpLineWidthVirgin;
   }
   else
   {
      line_color = lvl.is_bullish ? InpColorBullish : InpColorBearish;
      line_style = InpStyleHist;
      line_width = InpLineWidthHist;
   }

   // Create or update trend line
   if(ObjectFind(0, line_name) < 0)
   {
      ObjectCreate(0, line_name, OBJ_TREND, 0, lvl.time_start, lvl.price_level, lvl.time_end, lvl.price_level);
   }
   else
   {
      ObjectSetInteger(0, line_name, OBJPROP_TIME, 0, lvl.time_start);
      ObjectSetDouble(0, line_name, OBJPROP_PRICE, 0, lvl.price_level);
      ObjectSetInteger(0, line_name, OBJPROP_TIME, 1, lvl.time_end);
      ObjectSetDouble(0, line_name, OBJPROP_PRICE, 1, lvl.price_level);
   }

   ObjectSetInteger(0, line_name, OBJPROP_COLOR, line_color);
   ObjectSetInteger(0, line_name, OBJPROP_STYLE, line_style);
   ObjectSetInteger(0, line_name, OBJPROP_WIDTH, line_width);
   ObjectSetInteger(0, line_name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, line_name, OBJPROP_BACK, true);
   ObjectSetInteger(0, line_name, OBJPROP_SELECTABLE, false);

   // Create text label if enabled
   if(InpShowPriceLabels)
   {
      string desc = "";
      if(is_current_day)
      {
         desc = StringFormat(" TODAY 61.8%% %s [%.2f]", lvl.is_bullish ? "BUY" : "SELL", lvl.price_level);
      }
      else if(lvl.is_virgin && !lvl.is_mitigated)
      {
         desc = StringFormat(" VIRGIN 61.8%% %s (%s) [%.2f]", lvl.is_bullish ? "BUY" : "SELL", TimeToString(lvl.day_date, TIME_DATE), lvl.price_level);
      }
      else
      {
         desc = StringFormat(" 61.8%% %s (%.2f)", lvl.is_bullish ? "B" : "S", lvl.price_level);
      }

      if(ObjectFind(0, label_name) < 0)
      {
         ObjectCreate(0, label_name, OBJ_TEXT, 0, lvl.time_start, lvl.price_level);
      }
      else
      {
         ObjectSetInteger(0, label_name, OBJPROP_TIME, 0, lvl.time_start);
         ObjectSetDouble(0, label_name, OBJPROP_PRICE, 0, lvl.price_level);
      }

      ObjectSetString(0, label_name, OBJPROP_TEXT, desc);
      ObjectSetString(0, label_name, OBJPROP_FONT, InpFontName);
      ObjectSetInteger(0, label_name, OBJPROP_FONTSIZE, InpFontSize);
      ObjectSetInteger(0, label_name, OBJPROP_COLOR, line_color);
      ObjectSetInteger(0, label_name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, label_name, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| Checks current price distance to levels for alerts               |
//+------------------------------------------------------------------+
void CheckAlerts(double current_price)
{
   datetime now = TimeCurrent();
   if(now - g_last_alert_time < 300) return; // Limit alert rate to 1 per 5 mins

   for(int i = 0; i < ArraySize(g_levels); i++)
   {
      if(g_levels[i].is_mitigated) continue;

      double diff_points = MathAbs(current_price - g_levels[i].price_level) / _Point;
      if(diff_points <= InpAlertDistancePoints)
      {
         string msg = StringFormat("[FIB 61.8 ALERT] %s approaching %s 61.8%% level %.2f (Dist: %.1f pts)",
                                   _Symbol,
                                   g_levels[i].is_bullish ? "SUPPORT (BUY)" : "RESISTANCE (SELL)",
                                   g_levels[i].price_level,
                                   diff_points);
         Alert(msg);
         if(InpAlertPush) SendNotification(msg);
         g_last_alert_time = now;
         break;
      }
   }
}
//+------------------------------------------------------------------+
