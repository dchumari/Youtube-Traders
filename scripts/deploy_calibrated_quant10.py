import os
import sys
import shutil

sys.path.insert(0, os.path.dirname(__file__))
from tester_runner import DATA_FOLDER, compile_ea

REPO_STRATEGIES = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies"
MT5_EXPERTS_Q10 = os.path.join(DATA_FOLDER, "MQL5", "Experts", "Quant10")
os.makedirs(MT5_EXPERTS_Q10, exist_ok=True)

# -------------------------------------------------------------
# 1. Quant01_Asian_Sweep_Sniper_EA.mq5 (Order Flow / Sweeps)
# -------------------------------------------------------------
q01_code = """//+------------------------------------------------------------------+
//|                               Quant01_Asian_Sweep_Sniper_EA.mq5  |
//|               Archetype: Institutional Order Flow / Liquidity    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 8.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 20.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 5.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 8.0;    // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Liquidity Sweep Parameters ==="
input int      InpAsianStartHour       = 0;      // Asian Start Hour (00:00 UTC)
input int      InpAsianEndHour         = 7;      // Asian End Hour (07:00 UTC)
input int      InpTradeStartHour       = 7;      // London Killzone Start (07:00 UTC)
input int      InpTradeEndHour         = 14;     // London Killzone End (14:00 UTC)
input double   InpSweepMinPips         = 1.0;    // Min Sweep Distance (Pips)
input double   InpSweepMaxPips         = 15.0;   // Max Sweep Distance (Pips)
input int      InpTrendEMAPeriod       = 50;     // H1 Regime Filter EMA
input ulong    InpMagicNumber          = 202601; // Magic Number

CQuantTrade    quant;
double         asian_high, asian_low;
datetime       last_asian_day, last_trade_day;
bool           asian_ready;
int            ema_handle;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   ema_handle = iMA(_Symbol, PERIOD_H1, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(ema_handle == INVALID_HANDLE) return INIT_FAILED;
   asian_high = 0; asian_low = 999999; last_asian_day = 0; last_trade_day = 0;
   asian_ready = false; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(ema_handle);
}

void UpdateAsianRange()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_asian_day)
   {
      last_asian_day = cur_day;
      asian_high = 0; asian_low = 999999; asian_ready = false;
   }
   if(dt.hour >= InpAsianStartHour && dt.hour < InpAsianEndHour)
   {
      MqlRates r[]; ArraySetAsSeries(r, true);
      if(CopyRates(_Symbol, _Period, 0, 2, r) >= 2)
      {
         if(r[1].high > asian_high) asian_high = r[1].high;
         if(r[1].low < asian_low)   asian_low  = r[1].low;
      }
   }
   else if(dt.hour >= InpAsianEndHour && asian_high > 0 && asian_low < 999999)
   {
      asian_ready = true;
   }
}

void OnTick()
{
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;
   double pip = point * pip_mult;

   if(InpUseBreakeven || InpUseTrailing)
   {
      quant.ManageBreakevenAndTrailing(
         InpUseBreakeven ? InpBreakevenTriggerPips * pip_mult : 0,
         InpUseBreakeven ? InpBreakevenLockPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingStepPips * pip_mult : 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   UpdateAsianRange();

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;
   if(!asian_ready || asian_high <= 0 || asian_low >= 999999) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   double ema_val[]; ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   double c_high = rates[0].high, c_low = rates[0].low, c_open = rates[0].open, c_close = rates[0].close;
   double c_range = c_high - c_low;
   if(c_range <= 0) return;

   double sw_min = InpSweepMinPips * pip;
   double sw_max = InpSweepMaxPips * pip;

   // Bearish Sweep of Asian High in Downtrend / Reversal
   if(c_high >= asian_high + sw_min && c_high <= asian_high + sw_max)
   {
      if(c_close < asian_high && c_close < ema_val[0])
      {
         double wick = c_high - MathMax(c_open, c_close);
         if(wick / c_range >= 0.30)
         {
            if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q01_Asian_Sweep_Sell"))
               daily_trades++;
            return;
         }
      }
   }

   // Bullish Sweep of Asian Low in Uptrend / Reversal
   if(c_low <= asian_low - sw_min && c_low >= asian_low - sw_max)
   {
      if(c_close > asian_low && c_close > ema_val[0])
      {
         double wick = MathMin(c_open, c_close) - c_low;
         if(wick / c_range >= 0.30)
         {
            if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q01_Asian_Sweep_Buy"))
               daily_trades++;
            return;
         }
      }
   }
}
"""

# -------------------------------------------------------------
# 2. Quant02_FVG_Mitigation_Flow_EA.mq5 (Order Flow / Imbalance)
# -------------------------------------------------------------
q02_code = """//+------------------------------------------------------------------+
//|                               Quant02_FVG_Mitigation_Flow_EA.mq5 |
//|               Archetype: Institutional Order Flow / Imbalance    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 9.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 22.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 6.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Fair Value Gap & Displacement Parameters ==="
input int      InpATRPeriod            = 14;     // ATR Volatility Period
input double   InpDisplacementATRMult  = 1.2;    // Displacement Body ATR Multiplier
input int      InpTrendEMAPeriod       = 50;     // H1 Regime Filter EMA
input int      InpTradeStartHour       = 8;      // Active Killzone Start (08:00 UTC)
input int      InpTradeEndHour         = 17;     // Active Killzone End (17:00 UTC)
input ulong    InpMagicNumber          = 202602; // Magic Number

CQuantTrade    quant;
int            atr_handle;
int            ema_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   atr_handle = iATR(_Symbol, _Period, InpATRPeriod);
   ema_handle = iMA(_Symbol, PERIOD_H1, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(atr_handle == INVALID_HANDLE || ema_handle == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(atr_handle);
   IndicatorRelease(ema_handle);
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven || InpUseTrailing)
   {
      quant.ManageBreakevenAndTrailing(
         InpUseBreakeven ? InpBreakevenTriggerPips * pip_mult : 0,
         InpUseBreakeven ? InpBreakevenLockPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingStepPips * pip_mult : 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 4, rates) < 4) return;

   double atr_val[]; ArraySetAsSeries(atr_val, true);
   if(CopyBuffer(atr_handle, 0, 1, 2, atr_val) < 2) return;

   double ema_val[]; ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   double bar2_body = MathAbs(rates[1].close - rates[1].open);
   if(bar2_body < InpDisplacementATRMult * atr_val[0]) return;

   // Bullish FVG: Bar 2 was strong bullish, Low of Bar 1 > High of Bar 3, trend above H1 EMA
   if(rates[1].close > rates[1].open && rates[0].low > rates[2].high && rates[0].close > ema_val[0])
   {
      double fvg_ce = (rates[0].low + rates[2].high) / 2.0;
      if(rates[0].close > fvg_ce)
      {
         if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q02_FVG_Flow_Buy"))
            daily_trades++;
         return;
      }
   }

   // Bearish FVG: Bar 2 was strong bearish, High of Bar 1 < Low of Bar 3, trend below H1 EMA
   if(rates[1].close < rates[1].open && rates[0].high < rates[2].low && rates[0].close < ema_val[0])
   {
      double fvg_ce = (rates[0].high + rates[2].low) / 2.0;
      if(rates[0].close < fvg_ce)
      {
         if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q02_FVG_Flow_Sell"))
            daily_trades++;
         return;
      }
   }
}
"""

# -------------------------------------------------------------
# 3. Quant03_Triple_Supertrend_Donchian_EA.mq5 (Trend Breakout)
# -------------------------------------------------------------
q03_code = """//+------------------------------------------------------------------+
//|                     Quant03_Triple_Supertrend_Donchian_EA.mq5    |
//|               Archetype: Multi-Timeframe Trend Continuation      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 24.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 7.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Trend & Donchian Breakout Parameters ==="
input int      InpH1EMAPeriod          = 100;    // Macro Regime Filter EMA
input int      InpDonchianPeriod       = 16;     // Donchian Breakout Period
input int      InpADXPeriod            = 14;     // ADX Trend Filter Period
input double   InpMinADX               = 22.0;   // Minimum ADX Threshold
input int      InpTradeStartHour       = 7;      // Trade Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 18;     // Trade End Hour (18:00 UTC)
input ulong    InpMagicNumber          = 202603; // Magic Number

CQuantTrade    quant;
int            ema_handle;
int            adx_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   ema_handle = iMA(_Symbol, PERIOD_H1, InpH1EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   adx_handle = iADX(_Symbol, _Period, InpADXPeriod);
   if(ema_handle == INVALID_HANDLE || adx_handle == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(ema_handle);
   IndicatorRelease(adx_handle);
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven || InpUseTrailing)
   {
      quant.ManageBreakevenAndTrailing(
         InpUseBreakeven ? InpBreakevenTriggerPips * pip_mult : 0,
         InpUseBreakeven ? InpBreakevenLockPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingStepPips * pip_mult : 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double ema_val[]; ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   double adx_val[]; ArraySetAsSeries(adx_val, true);
   if(CopyBuffer(adx_handle, 0, 1, 2, adx_val) < 2) return;
   if(adx_val[0] < InpMinADX) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, 1, InpDonchianPeriod + 2, rates);
   if(copied < InpDonchianPeriod + 2) return;

   double donchian_high = rates[1].high;
   double donchian_low  = rates[1].low;
   for(int i = 2; i <= InpDonchianPeriod; i++)
   {
      if(rates[i].high > donchian_high) donchian_high = rates[i].high;
      if(rates[i].low < donchian_low)   donchian_low  = rates[i].low;
   }

   // Bullish Breakout above Donchian High + Trend above H1 EMA
   if(rates[0].close > donchian_high && rates[0].close > ema_val[0])
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q03_Donchian_Buy"))
         daily_trades++;
      return;
   }

   // Bearish Breakdown below Donchian Low + Trend below H1 EMA
   if(rates[0].close < donchian_low && rates[0].close < ema_val[0])
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q03_Donchian_Sell"))
         daily_trades++;
      return;
   }
}
"""

# -------------------------------------------------------------
# 4. Quant04_EMA_Ribbon_Pullback_EA.mq5 (Trend Pullback)
# -------------------------------------------------------------
q04_code = """//+------------------------------------------------------------------+
//|                         Quant04_EMA_Ribbon_Pullback_EA.mq5       |
//|               Archetype: Multi-Timeframe Trend Continuation      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 24.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 7.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Ribbon & Oscillator Pullback Parameters ==="
input int      InpFastEMA              = 8;      // Fast Ribbon EMA
input int      InpMedEMA               = 21;     // Medium Ribbon EMA
input int      InpSlowEMA              = 55;     // Slow Ribbon EMA
input int      InpH1TrendEMA           = 100;    // H1 Trend Filter EMA
input int      InpTradeStartHour       = 6;      // Session Start Hour (06:00 UTC)
input int      InpTradeEndHour         = 18;     // Session End Hour (18:00 UTC)
input ulong    InpMagicNumber          = 202604; // Magic Number

CQuantTrade    quant;
int            fast_ema_h, med_ema_h, slow_ema_h, h1_ema_h;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   fast_ema_h = iMA(_Symbol, _Period, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   med_ema_h  = iMA(_Symbol, _Period, InpMedEMA,  0, MODE_EMA, PRICE_CLOSE);
   slow_ema_h = iMA(_Symbol, _Period, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   h1_ema_h   = iMA(_Symbol, PERIOD_H1, InpH1TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   
   if(fast_ema_h == INVALID_HANDLE || med_ema_h == INVALID_HANDLE || slow_ema_h == INVALID_HANDLE || h1_ema_h == INVALID_HANDLE)
      return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(fast_ema_h);
   IndicatorRelease(med_ema_h);
   IndicatorRelease(slow_ema_h);
   IndicatorRelease(h1_ema_h);
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven || InpUseTrailing)
   {
      quant.ManageBreakevenAndTrailing(
         InpUseBreakeven ? InpBreakevenTriggerPips * pip_mult : 0,
         InpUseBreakeven ? InpBreakevenLockPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingStepPips * pip_mult : 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double f_ema[], m_ema[], s_ema[], h1_ema[];
   ArraySetAsSeries(f_ema, true); ArraySetAsSeries(m_ema, true); ArraySetAsSeries(s_ema, true); ArraySetAsSeries(h1_ema, true);
   if(CopyBuffer(fast_ema_h, 0, 1, 2, f_ema) < 2) return;
   if(CopyBuffer(med_ema_h, 0, 1, 2, m_ema) < 2) return;
   if(CopyBuffer(slow_ema_h, 0, 1, 2, s_ema) < 2) return;
   if(CopyBuffer(h1_ema_h, 0, 1, 2, h1_ema) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   bool ribbon_bull = (f_ema[0] > m_ema[0] && m_ema[0] > s_ema[0] && rates[0].close > h1_ema[0]);
   bool ribbon_bear = (f_ema[0] < m_ema[0] && m_ema[0] < s_ema[0] && rates[0].close < h1_ema[0]);

   // Bullish Pullback: low touched med EMA, closed back above fast EMA
   if(ribbon_bull && rates[0].low <= m_ema[0] && rates[0].close > f_ema[0])
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q04_Ribbon_Buy"))
         daily_trades++;
      return;
   }

   // Bearish Pullback: high touched med EMA, closed back below fast EMA
   if(ribbon_bear && rates[0].high >= m_ema[0] && rates[0].close < f_ema[0])
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q04_Ribbon_Sell"))
         daily_trades++;
      return;
   }
}
"""

# -------------------------------------------------------------
# 5. Quant05_Turtle_ATR_Breakout_EA.mq5 (Donchian / Turtle)
# -------------------------------------------------------------
q05_code = """//+------------------------------------------------------------------+
//|                          Quant05_Turtle_ATR_Breakout_EA.mq5      |
//|               Archetype: Multi-Timeframe Trend Continuation      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 12.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 28.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 8.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 2.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 12.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 3.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Turtle Breakout & ATR Regime Parameters ==="
input int      InpChannelPeriod        = 20;     // Donchian Breakout Channel Length
input int      InpH1EMAPeriod          = 100;    // Trend Baseline Filter
input int      InpTradeStartHour       = 6;      // Session Start Hour (06:00 UTC)
input int      InpTradeEndHour         = 19;     // Session End Hour (19:00 UTC)
input ulong    InpMagicNumber          = 202605; // Magic Number

CQuantTrade    quant;
int            ema_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   ema_handle = iMA(_Symbol, _Period, InpH1EMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(ema_handle == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(ema_handle);
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven || InpUseTrailing)
   {
      quant.ManageBreakevenAndTrailing(
         InpUseBreakeven ? InpBreakevenTriggerPips * pip_mult : 0,
         InpUseBreakeven ? InpBreakevenLockPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingStepPips * pip_mult : 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double ema_val[]; ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   int rates_copied = CopyRates(_Symbol, _Period, 1, InpChannelPeriod + 2, rates);
   if(rates_copied < InpChannelPeriod + 2) return;

   double ch_high = rates[1].high;
   double ch_low  = rates[1].low;
   for(int i = 2; i <= InpChannelPeriod; i++)
   {
      if(rates[i].high > ch_high) ch_high = rates[i].high;
      if(rates[i].low < ch_low)   ch_low  = rates[i].low;
   }

   // Turtle Long Breakout above channel high and above EMA
   if(rates[0].close > ch_high && rates[0].close > ema_val[0])
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q05_Turtle_Buy"))
         daily_trades++;
      return;
   }

   // Turtle Short Breakdown below channel low and below EMA
   if(rates[0].close < ch_low && rates[0].close < ema_val[0])
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q05_Turtle_Sell"))
         daily_trades++;
      return;
   }
}
"""

# -------------------------------------------------------------
# 6. Quant06_Bollinger_Keltner_Squeeze_EA.mq5 (Squeeze Pro)
# -------------------------------------------------------------
q06_code = """//+------------------------------------------------------------------+
//|                     Quant06_Bollinger_Keltner_Squeeze_EA.mq5     |
//|               Archetype: Mean Reversion & Volatility Compression |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 9.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 22.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 6.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Squeeze Compression Parameters ==="
input int      InpBBPeriod             = 20;     // Bollinger Bands Period
input double   InpBBDeviation          = 2.0;    // Bollinger Bands Deviation
input int      InpKeltnerATRPeriod     = 20;     // Keltner Channel ATR Period
input double   InpKeltnerMult          = 1.5;    // Keltner Channel ATR Multiplier
input int      InpTrendEMAPeriod       = 50;     // Trend Filter EMA
input int      InpTradeStartHour       = 7;      // Session Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 18;     // Session End Hour (18:00 UTC)
input ulong    InpMagicNumber          = 202606; // Magic Number

CQuantTrade    quant;
int            bb_handle, atr_handle, ema_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   bb_handle  = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   atr_handle = iATR(_Symbol, _Period, InpKeltnerATRPeriod);
   ema_handle = iMA(_Symbol, PERIOD_H1, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(bb_handle == INVALID_HANDLE || atr_handle == INVALID_HANDLE || ema_handle == INVALID_HANDLE)
      return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(bb_handle);
   IndicatorRelease(atr_handle);
   IndicatorRelease(ema_handle);
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven || InpUseTrailing)
   {
      quant.ManageBreakevenAndTrailing(
         InpUseBreakeven ? InpBreakevenTriggerPips * pip_mult : 0,
         InpUseBreakeven ? InpBreakevenLockPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingStepPips * pip_mult : 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double bb_up[], bb_low[], bb_mid[];
   ArraySetAsSeries(bb_up, true); ArraySetAsSeries(bb_low, true); ArraySetAsSeries(bb_mid, true);
   if(CopyBuffer(bb_handle, 1, 1, 3, bb_up) < 3) return;
   if(CopyBuffer(bb_handle, 2, 1, 3, bb_low) < 3) return;
   if(CopyBuffer(bb_handle, 0, 1, 3, bb_mid) < 3) return;

   double atr_val[], ema_val[];
   ArraySetAsSeries(atr_val, true); ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(atr_handle, 0, 1, 3, atr_val) < 3) return;
   if(CopyBuffer(ema_handle, 0, 1, 3, ema_val) < 3) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   double keltner_up_prev  = bb_mid[1] + InpKeltnerMult * atr_val[1];
   double keltner_low_prev = bb_mid[1] - InpKeltnerMult * atr_val[1];
   double keltner_up_curr  = bb_mid[0] + InpKeltnerMult * atr_val[0];
   double keltner_low_curr = bb_mid[0] - InpKeltnerMult * atr_val[0];

   bool was_in_squeeze = (bb_up[1] < keltner_up_prev && bb_low[1] > keltner_low_prev);
   bool is_squeeze_fired = (bb_up[0] > keltner_up_curr || bb_low[0] < keltner_low_curr);

   if(was_in_squeeze && is_squeeze_fired)
   {
      // Bullish Squeeze Fired + Above H1 EMA
      if(rates[0].close > bb_mid[0] && rates[0].close > ema_val[0])
      {
         if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q06_Squeeze_Buy"))
            daily_trades++;
         return;
      }
      // Bearish Squeeze Fired + Below H1 EMA
      if(rates[0].close < bb_mid[0] && rates[0].close < ema_val[0])
      {
         if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q06_Squeeze_Sell"))
            daily_trades++;
         return;
      }
   }
}
"""

# -------------------------------------------------------------
# 7. Quant07_Asian_Mean_Reversion_EA.mq5 (Asian Mean Reversion)
# -------------------------------------------------------------
q07_code = """//+------------------------------------------------------------------+
//|                         Quant07_Asian_Mean_Reversion_EA.mq5      |
//|               Archetype: Mean Reversion & Volatility Compression |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 8.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 14.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 5.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Asian Mean Reversion Parameters ==="
input int      InpBBPeriod             = 20;     // Bollinger Bands Period
input double   InpBBDeviation          = 2.0;    // Bollinger Bands Deviation
input int      InpRSIPeriod            = 14;     // RSI Period
input double   InpRSIOverbought        = 65.0;   // RSI Overbought Level
input double   InpRSIOversold          = 35.0;   // RSI Oversold Level
input int      InpH1TrendEMA           = 100;    // H1 Trend Filter EMA
input int      InpAsianStartHour       = 21;     // Asian Session Start (21:00 UTC)
input int      InpAsianEndHour         = 5;      // Asian Session End (05:00 UTC)
input ulong    InpMagicNumber          = 202607; // Magic Number

CQuantTrade    quant;
int            bb_handle, rsi_handle, h1_ema_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   bb_handle     = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   rsi_handle    = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   h1_ema_handle = iMA(_Symbol, PERIOD_H1, InpH1TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(bb_handle == INVALID_HANDLE || rsi_handle == INVALID_HANDLE || h1_ema_handle == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(bb_handle);
   IndicatorRelease(rsi_handle);
   IndicatorRelease(h1_ema_handle);
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven)
   {
      quant.ManageBreakevenAndTrailing(
         InpBreakevenTriggerPips * pip_mult,
         InpBreakevenLockPips * pip_mult,
         0, 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   if(!CQuantTrade::IsInHourWindow(InpAsianStartHour, InpAsianEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double bb_up[], bb_low[], bb_mid[];
   ArraySetAsSeries(bb_up, true); ArraySetAsSeries(bb_low, true); ArraySetAsSeries(bb_mid, true);
   if(CopyBuffer(bb_handle, 1, 1, 2, bb_up) < 2) return;
   if(CopyBuffer(bb_handle, 2, 1, 2, bb_low) < 2) return;
   if(CopyBuffer(bb_handle, 0, 1, 2, bb_mid) < 2) return;

   double rsi_val[]; ArraySetAsSeries(rsi_val, true);
   if(CopyBuffer(rsi_handle, 0, 1, 2, rsi_val) < 2) return;

   double h1_ema[]; ArraySetAsSeries(h1_ema, true);
   if(CopyBuffer(h1_ema_handle, 0, 1, 2, h1_ema) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 2, rates) < 2) return;

   // Mean Reversion Long
   if(rates[0].low <= bb_low[0] && rsi_val[0] <= InpRSIOversold && rates[0].close > rates[0].open && rates[0].close > h1_ema[0])
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q07_Asian_Reversion_Buy"))
         daily_trades++;
      return;
   }

   // Mean Reversion Short
   if(rates[0].high >= bb_up[0] && rsi_val[0] >= InpRSIOverbought && rates[0].close < rates[0].open && rates[0].close < h1_ema[0])
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q07_Asian_Reversion_Sell"))
         daily_trades++;
      return;
   }
}
"""

# -------------------------------------------------------------
# 8. Quant08_RSI_Divergence_Envelope_EA.mq5 (Divergence Envelope)
# -------------------------------------------------------------
q08_code = """//+------------------------------------------------------------------+
//|                     Quant08_RSI_Divergence_Envelope_EA.mq5       |
//|               Archetype: Mean Reversion & Volatility Compression |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 9.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 20.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 6.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Envelope & Divergence Parameters ==="
input int      InpEnvMAPeriod          = 20;     // Envelope Moving Average Period
input double   InpEnvDeviation         = 0.12;   // Envelope Percentage Deviation
input int      InpRSIPeriod            = 14;     // RSI Oscillator Period
input int      InpDivergenceLookback   = 10;     // Divergence Swing Lookback Bars
input int      InpH1TrendEMA           = 100;    // Trend Filter EMA
input int      InpTradeStartHour       = 7;      // Session Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 17;     // Session End Hour (17:00 UTC)
input ulong    InpMagicNumber          = 202608; // Magic Number

CQuantTrade    quant;
int            env_handle, rsi_handle, ema_handle;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   env_handle = iEnvelopes(_Symbol, _Period, InpEnvMAPeriod, 0, MODE_SMA, PRICE_CLOSE, InpEnvDeviation);
   rsi_handle = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   ema_handle = iMA(_Symbol, PERIOD_H1, InpH1TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(env_handle == INVALID_HANDLE || rsi_handle == INVALID_HANDLE || ema_handle == INVALID_HANDLE) return INIT_FAILED;
   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(env_handle);
   IndicatorRelease(rsi_handle);
   IndicatorRelease(ema_handle);
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven || InpUseTrailing)
   {
      quant.ManageBreakevenAndTrailing(
         InpUseBreakeven ? InpBreakevenTriggerPips * pip_mult : 0,
         InpUseBreakeven ? InpBreakevenLockPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingStepPips * pip_mult : 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double env_up[], env_low[], ema_val[];
   ArraySetAsSeries(env_up, true); ArraySetAsSeries(env_low, true); ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(env_handle, 0, 1, 2, env_up) < 2) return;
   if(CopyBuffer(env_handle, 1, 1, 2, env_low) < 2) return;
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   double rsi_buf[]; ArraySetAsSeries(rsi_buf, true);
   if(CopyBuffer(rsi_handle, 0, 1, InpDivergenceLookback + 2, rsi_buf) < InpDivergenceLookback + 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, InpDivergenceLookback + 2, rates) < InpDivergenceLookback + 2) return;

   // Bullish Divergence at lower envelope in bullish trend
   if(rates[0].low <= env_low[0] && rates[0].close > ema_val[0])
   {
      for(int i = 3; i <= InpDivergenceLookback; i++)
      {
         if(rates[0].low < rates[i].low && rsi_buf[0] > rsi_buf[i] && rsi_buf[i] < 35.0)
         {
            if(rates[0].close > rates[0].open)
            {
               if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q08_RSI_Div_Buy"))
                  daily_trades++;
               return;
            }
         }
      }
   }

   // Bearish Divergence at upper envelope in bearish trend
   if(rates[0].high >= env_up[0] && rates[0].close < ema_val[0])
   {
      for(int i = 3; i <= InpDivergenceLookback; i++)
      {
         if(rates[0].high > rates[i].high && rsi_buf[0] < rsi_buf[i] && rsi_buf[i] > 65.0)
         {
            if(rates[0].close < rates[0].open)
            {
               if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q08_RSI_Div_Sell"))
                  daily_trades++;
               return;
            }
         }
      }
   }
}
"""

# -------------------------------------------------------------
# 9. Quant09_London_Judas_Killzone_EA.mq5 (Judas Killzone)
# -------------------------------------------------------------
q09_code = """//+------------------------------------------------------------------+
//|                        Quant09_London_Judas_Killzone_EA.mq5      |
//|               Archetype: Session Momentum & Killzone Dynamics    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 24.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 7.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== London Judas Swing Parameters ==="
input int      InpAsianStartHour       = 0;      // Asian Session Start Hour
input int      InpAsianEndHour         = 7;      // Asian Session End Hour
input int      InpJudasStartHour       = 7;      // London Judas Open Start (07:00 UTC)
input int      InpJudasEndHour         = 11;     // London Judas Open End (11:00 UTC)
input double   InpMinWickPercent       = 0.35;   // Minimum Rejection Wick Size (% of Candle)
input int      InpTrendEMAPeriod       = 50;     // H1 Regime Filter EMA
input ulong    InpMagicNumber          = 202609; // Magic Number

CQuantTrade    quant;
double         asian_high, asian_low;
datetime       last_asian_day, last_trade_day;
bool           asian_ready;
int            ema_handle;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   ema_handle = iMA(_Symbol, PERIOD_H1, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(ema_handle == INVALID_HANDLE) return INIT_FAILED;
   asian_high = 0; asian_low = 999999; last_asian_day = 0; last_trade_day = 0;
   asian_ready = false; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(ema_handle);
}

void UpdateAsianRange()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_asian_day)
   {
      last_asian_day = cur_day;
      asian_high = 0; asian_low = 999999; asian_ready = false;
   }
   if(dt.hour >= InpAsianStartHour && dt.hour < InpAsianEndHour)
   {
      MqlRates r[]; ArraySetAsSeries(r, true);
      if(CopyRates(_Symbol, _Period, 0, 2, r) >= 2)
      {
         if(r[1].high > asian_high) asian_high = r[1].high;
         if(r[1].low < asian_low)   asian_low  = r[1].low;
      }
   }
   else if(dt.hour >= InpAsianEndHour && asian_high > 0 && asian_low < 999999)
   {
      asian_ready = true;
   }
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven || InpUseTrailing)
   {
      quant.ManageBreakevenAndTrailing(
         InpUseBreakeven ? InpBreakevenTriggerPips * pip_mult : 0,
         InpUseBreakeven ? InpBreakevenLockPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingStepPips * pip_mult : 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   UpdateAsianRange();

   if(!CQuantTrade::IsInHourWindow(InpJudasStartHour, InpJudasEndHour)) return;
   if(!asian_ready || asian_high <= 0 || asian_low >= 999999) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double ema_val[]; ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   double c_high = rates[0].high, c_low = rates[0].low, c_open = rates[0].open, c_close = rates[0].close;
   double c_range = c_high - c_low;
   if(c_range <= 0) return;

   // Bullish Judas Reversal: Swept Asian Low + Closed above + Long Wick + Trend above H1 EMA
   if(c_low < asian_low && c_close > asian_low && c_close > ema_val[0])
   {
      double lower_wick = MathMin(c_open, c_close) - c_low;
      if(lower_wick / c_range >= InpMinWickPercent)
      {
         if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q09_Judas_Buy"))
            daily_trades++;
         return;
      }
   }

   // Bearish Judas Reversal: Swept Asian High + Closed below + Long Wick + Trend below H1 EMA
   if(c_high > asian_high && c_close < asian_high && c_close < ema_val[0])
   {
      double upper_wick = c_high - MathMax(c_open, c_close);
      if(upper_wick / c_range >= InpMinWickPercent)
      {
         if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q09_Judas_Sell"))
            daily_trades++;
         return;
      }
   }
}
"""

# -------------------------------------------------------------
# 10. Quant10_Daily_CPR_Momentum_EA.mq5 (CPR Momentum)
# -------------------------------------------------------------
q10_code = """//+------------------------------------------------------------------+
//|                        Quant10_Daily_CPR_Momentum_EA.mq5         |
//|               Archetype: Session Momentum & Killzone Dynamics    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 24.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 7.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 2;      // Max Trades per Day

input group "=== Daily CPR Compression Parameters ==="
input double   InpMaxCPRPips           = 18.0;   // Max CPR Width (TC-BC in Pips)
input int      InpMACDFast             = 12;     // MACD Fast Period
input int      InpMACDSlow             = 26;     // MACD Slow Period
input int      InpMACDSignal           = 9;      // MACD Signal Period
input int      InpH1TrendEMA           = 100;    // Trend Baseline Filter
input int      InpTradeStartHour       = 7;      // Session Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 16;     // Session End Hour (16:00 UTC)
input ulong    InpMagicNumber          = 202610; // Magic Number

CQuantTrade    quant;
int            macd_handle, ema_handle;
double         cpr_pivot, cpr_bc, cpr_tc, cpr_width_pips;
datetime       last_cpr_day, last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   macd_handle = iMACD(_Symbol, _Period, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   ema_handle  = iMA(_Symbol, PERIOD_H1, InpH1TrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(macd_handle == INVALID_HANDLE || ema_handle == INVALID_HANDLE) return INIT_FAILED;
   last_cpr_day = 0; last_trade_day = 0; daily_trades = 0;
   cpr_pivot = 0; cpr_bc = 0; cpr_tc = 0; cpr_width_pips = 999;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(macd_handle);
   IndicatorRelease(ema_handle);
}

void UpdateCPR()
{
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day == last_cpr_day) return;
   last_cpr_day = cur_day;

   MqlRates d_rates[]; ArraySetAsSeries(d_rates, true);
   if(CopyRates(_Symbol, PERIOD_D1, 1, 1, d_rates) < 1) return;

   double high = d_rates[0].high, low = d_rates[0].low, close = d_rates[0].close;
   cpr_pivot = (high + low + close) / 3.0;
   cpr_bc    = (high + low) / 2.0;
   cpr_tc    = (cpr_pivot - cpr_bc) + cpr_pivot;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;
   cpr_width_pips = MathAbs(cpr_tc - cpr_bc) / (point * pip_mult);
}

void OnTick()
{
   int pip_mult = (_Digits == 3 || _Digits == 5) ? 10 : 1;

   if(InpUseBreakeven || InpUseTrailing)
   {
      quant.ManageBreakevenAndTrailing(
         InpUseBreakeven ? InpBreakevenTriggerPips * pip_mult : 0,
         InpUseBreakeven ? InpBreakevenLockPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingPips * pip_mult : 0,
         InpUseTrailing ? InpTrailingStepPips * pip_mult : 0
      );
   }

   if(!quant.IsNewBar(_Period)) return;

   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   datetime cur_day = StringToTime(StringFormat("%04d.%02d.%02d 00:00", dt.year, dt.mon, dt.day));
   if(cur_day != last_trade_day) { last_trade_day = cur_day; daily_trades = 0; }
   if(daily_trades >= InpMaxDailyTrades) return;

   UpdateCPR();

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;
   if(cpr_width_pips > InpMaxCPRPips || cpr_pivot <= 0) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double macd_main[], macd_sig[], ema_val[];
   ArraySetAsSeries(macd_main, true); ArraySetAsSeries(macd_sig, true); ArraySetAsSeries(ema_val, true);
   if(CopyBuffer(macd_handle, 0, 1, 2, macd_main) < 2) return;
   if(CopyBuffer(macd_handle, 1, 1, 2, macd_sig) < 2) return;
   if(CopyBuffer(ema_handle, 0, 1, 2, ema_val) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 2, rates) < 2) return;

   double upper_cpr = MathMax(cpr_tc, cpr_bc);
   double lower_cpr = MathMin(cpr_tc, cpr_bc);

   // Bullish Expansion
   if(rates[0].close > upper_cpr && macd_main[0] > macd_sig[0] && rates[0].close > ema_val[0])
   {
      if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q10_CPR_Expansion_Buy"))
         daily_trades++;
      return;
   }

   // Bearish Expansion
   if(rates[0].close < lower_cpr && macd_main[0] < macd_sig[0] && rates[0].close < ema_val[0])
   {
      if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q10_CPR_Expansion_Sell"))
         daily_trades++;
      return;
   }
}
"""

strategies = [
    ("Quant01_Asian_Sweep_Sniper_EA", q01_code),
    ("Quant02_FVG_Mitigation_Flow_EA", q02_code),
    ("Quant03_Triple_Supertrend_Donchian_EA", q03_code),
    ("Quant04_EMA_Ribbon_Pullback_EA", q04_code),
    ("Quant05_Turtle_ATR_Breakout_EA", q05_code),
    ("Quant06_Bollinger_Keltner_Squeeze_EA", q06_code),
    ("Quant07_Asian_Mean_Reversion_EA", q07_code),
    ("Quant08_RSI_Divergence_Envelope_EA", q08_code),
    ("Quant09_London_Judas_Killzone_EA", q09_code),
    ("Quant10_Daily_CPR_Momentum_EA", q10_code)
]

print("Deploying & Compiling Calibrated Quant10 Suite...")
for name, code in strategies:
    repo_file = os.path.join(REPO_STRATEGIES, name, f"{name}.mq5")
    with open(repo_file, "w", encoding="utf-8") as f:
        f.write(code)
    mt5_file = os.path.join(MT5_EXPERTS_Q10, f"{name}.mq5")
    with open(mt5_file, "w", encoding="utf-8") as f:
        f.write(code)
    succ, log, ex5 = compile_ea(f"Quant10\\{name}.mq5")
    if succ:
        dst_ex5 = os.path.join(REPO_STRATEGIES, name, f"{name}.ex5")
        shutil.copyfile(ex5, dst_ex5)
        print(f"  [OK] {name} compiled successfully -> .ex5 synced")
    else:
        print(f"  [FAIL] {name} compile failed!")
