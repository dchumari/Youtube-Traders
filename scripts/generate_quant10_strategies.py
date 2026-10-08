import os
import sys
import shutil

sys.path.insert(0, os.path.dirname(__file__))
from tester_runner import DATA_FOLDER, compile_ea

REPO_STRATEGIES = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies"
MT5_EXPERTS_Q10 = os.path.join(DATA_FOLDER, "MQL5", "Experts", "Quant10")
os.makedirs(MT5_EXPERTS_Q10, exist_ok=True)

# ---------------------------------------------------------
# 1. Quant01_Asian_Sweep_Sniper_EA.mq5
# ---------------------------------------------------------
code_q01 = """//+------------------------------------------------------------------+
//|                               Quant01_Asian_Sweep_Sniper_EA.mq5  |
//|               Archetype: Institutional Order Flow / Liquidity    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 8.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 20.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 6.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 10.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.5;    // Trailing Step (Pips)

input group "=== Institutional Liquidity Sweep Parameters ==="
input int      InpAsianStartHour       = 0;      // Asian Start Hour (00:00 UTC)
input int      InpAsianEndHour         = 7;      // Asian End Hour (07:00 UTC)
input int      InpTradeStartHour       = 7;      // London Killzone Start (07:00 UTC)
input int      InpTradeEndHour         = 13;     // London Killzone End (13:00 UTC)
input double   InpSweepMinPips         = 1.2;    // Min Sweep Distance (Pips)
input double   InpSweepMaxPips         = 18.0;   // Max Sweep Distance (Pips)
input int      InpTrendEMAPeriod       = 50;     // H1 Regime Filter EMA
input ulong    InpMagicNumber          = 202601; // Magic Number

CQuantTrade    quant;
double         asian_high;
double         asian_low;
datetime       last_asian_day;
bool           asian_ready;
int            ema_handle;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   ema_handle = iMA(_Symbol, _Period, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(ema_handle == INVALID_HANDLE) return INIT_FAILED;
   asian_high = 0; asian_low = 999999; last_asian_day = 0; asian_ready = false;
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

   // Bearish Sweep of Asian High
   if(c_high > asian_high + sw_min && c_high < asian_high + sw_max)
   {
      if(c_close < asian_high && c_close < ema_val[0])
      {
         double wick = c_high - MathMax(c_open, c_close);
         if(wick / c_range >= 0.35)
         {
            quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q01_Asian_Sweep_Sell");
            return;
         }
      }
   }

   // Bullish Sweep of Asian Low
   if(c_low < asian_low - sw_min && c_low > asian_low - sw_max)
   {
      if(c_close > asian_low && c_close > ema_val[0])
      {
         double wick = MathMin(c_open, c_close) - c_low;
         if(wick / c_range >= 0.35)
         {
            quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q01_Asian_Sweep_Buy");
            return;
         }
      }
   }
}
"""

# ---------------------------------------------------------
# 2. Quant02_FVG_Mitigation_Flow_EA.mq5
# ---------------------------------------------------------
code_q02 = """//+------------------------------------------------------------------+
//|                               Quant02_FVG_Mitigation_Flow_EA.mq5 |
//|               Archetype: Institutional Order Flow / Imbalance    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 24.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 7.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 12.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 3.0;    // Trailing Step (Pips)

input group "=== Fair Value Gap & Displacement Parameters ==="
input int      InpATRPeriod            = 14;     // ATR Volatility Period
input double   InpDisplacementATRMult  = 1.4;    // Displacement Candle Body ATR Multiplier
input int      InpRSIFilterPeriod      = 14;     // RSI Momentum Period
input int      InpTradeStartHour       = 8;      // Active Killzone Start (08:00 UTC)
input int      InpTradeEndHour         = 17;     // Active Killzone End (17:00 UTC)
input ulong    InpMagicNumber          = 202602; // Magic Number

CQuantTrade    quant;
int            atr_handle;
int            rsi_handle;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   atr_handle = iATR(_Symbol, _Period, InpATRPeriod);
   rsi_handle = iRSI(_Symbol, _Period, InpRSIFilterPeriod, PRICE_CLOSE);
   if(atr_handle == INVALID_HANDLE || rsi_handle == INVALID_HANDLE) return INIT_FAILED;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(atr_handle);
   IndicatorRelease(rsi_handle);
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
   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 4, rates) < 4) return;

   double atr_val[]; ArraySetAsSeries(atr_val, true);
   if(CopyBuffer(atr_handle, 0, 1, 2, atr_val) < 2) return;

   double rsi_val[]; ArraySetAsSeries(rsi_val, true);
   if(CopyBuffer(rsi_handle, 0, 1, 2, rsi_val) < 2) return;

   // 3-Bar FVG structure check:
   // Bar 2 (index 1) is displacement bar, Bar 3 (index 2) is pre-displacement, Bar 1 (index 0) is test bar
   double bar2_body = MathAbs(rates[1].close - rates[1].open);
   if(bar2_body < InpDisplacementATRMult * atr_val[0]) return;

   // Bullish FVG: Low of Bar 1 > High of Bar 3
   if(rates[1].close > rates[1].open && rates[0].low > rates[2].high)
   {
      // Consequent Encroachment (50% gap level)
      double fvg_ce = (rates[0].low + rates[2].high) / 2.0;
      if(rates[0].close > fvg_ce && rsi_val[0] > 52.0)
      {
         quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q02_FVG_Mitigation_Buy");
         return;
      }
   }

   // Bearish FVG: High of Bar 1 < Low of Bar 3
   if(rates[1].close < rates[1].open && rates[0].high < rates[2].low)
   {
      double fvg_ce = (rates[0].high + rates[2].low) / 2.0;
      if(rates[0].close < fvg_ce && rsi_val[0] < 48.0)
      {
         quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q02_FVG_Mitigation_Sell");
         return;
      }
   }
}
"""

# ---------------------------------------------------------
# 3. Quant03_Triple_Supertrend_Donchian_EA.mq5
# ---------------------------------------------------------
code_q03 = """//+------------------------------------------------------------------+
//|                     Quant03_Triple_Supertrend_Donchian_EA.mq5    |
//|               Archetype: Multi-Timeframe Trend Continuation      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 22.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 7.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 11.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.5;    // Trailing Step (Pips)

input group "=== MTF Trend & Donchian Breakout Parameters ==="
input int      InpMacroEMAPeriod       = 200;    // Macro Regime Filter EMA
input int      InpDonchianPeriod       = 20;     // Donchian Breakout Period
input int      InpADXPeriod            = 14;     // ADX Trend Filter Period
input double   InpMinADX               = 20.0;   // Minimum ADX Threshold
input int      InpTradeStartHour       = 7;      // Trade Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 18;     // Trade End Hour (18:00 UTC)
input ulong    InpMagicNumber          = 202603; // Magic Number

CQuantTrade    quant;
int            ema_handle;
int            adx_handle;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   ema_handle = iMA(_Symbol, _Period, InpMacroEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   adx_handle = iADX(_Symbol, _Period, InpADXPeriod);
   if(ema_handle == INVALID_HANDLE || adx_handle == INVALID_HANDLE) return INIT_FAILED;
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

   // Find Highest High and Lowest Low over previous InpDonchianPeriod bars (excluding bar 1)
   double donchian_high = rates[1].high;
   double donchian_low  = rates[1].low;
   for(int i = 2; i <= InpDonchianPeriod; i++)
   {
      if(rates[i].high > donchian_high) donchian_high = rates[i].high;
      if(rates[i].low < donchian_low)   donchian_low  = rates[i].low;
   }

   // Bullish Breakout
   if(rates[0].close > donchian_high && rates[0].close > ema_val[0])
   {
      quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q03_Donchian_Breakout_Buy");
      return;
   }

   // Bearish Breakdown
   if(rates[0].close < donchian_low && rates[0].close < ema_val[0])
   {
      quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q03_Donchian_Breakout_Sell");
      return;
   }
}
"""

# ---------------------------------------------------------
# 4. Quant04_EMA_Ribbon_Pullback_EA.mq5
# ---------------------------------------------------------
code_q04 = """//+------------------------------------------------------------------+
//|                         Quant04_EMA_Ribbon_Pullback_EA.mq5       |
//|               Archetype: Multi-Timeframe Trend Continuation      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 12.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 26.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 8.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 2.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 12.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 3.0;    // Trailing Step (Pips)

input group "=== EMA Ribbon & Oscillator Pullback Parameters ==="
input int      InpFastEMA              = 8;      // Fast Ribbon EMA
input int      InpMedEMA               = 21;     // Medium Ribbon EMA
input int      InpSlowEMA              = 55;     // Slow Ribbon EMA
input int      InpStochK               = 5;      // Stochastic %K
input int      InpStochD               = 3;      // Stochastic %D
input int      InpStochSlowing         = 3;      // Stochastic Slowing
input int      InpTradeStartHour       = 6;      // Session Start Hour (06:00 UTC)
input int      InpTradeEndHour         = 18;     // Session End Hour (18:00 UTC)
input ulong    InpMagicNumber          = 202604; // Magic Number

CQuantTrade    quant;
int            fast_ema_h;
int            med_ema_h;
int            slow_ema_h;
int            stoch_h;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   fast_ema_h = iMA(_Symbol, _Period, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   med_ema_h  = iMA(_Symbol, _Period, InpMedEMA,  0, MODE_EMA, PRICE_CLOSE);
   slow_ema_h = iMA(_Symbol, _Period, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   stoch_h    = iStochastic(_Symbol, _Period, InpStochK, InpStochD, InpStochSlowing, MODE_SMA, STO_LOWHIGH);
   
   if(fast_ema_h == INVALID_HANDLE || med_ema_h == INVALID_HANDLE || slow_ema_h == INVALID_HANDLE || stoch_h == INVALID_HANDLE)
      return INIT_FAILED;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(fast_ema_h);
   IndicatorRelease(med_ema_h);
   IndicatorRelease(slow_ema_h);
   IndicatorRelease(stoch_h);
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
   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double f_ema[], m_ema[], s_ema[];
   ArraySetAsSeries(f_ema, true); ArraySetAsSeries(m_ema, true); ArraySetAsSeries(s_ema, true);
   if(CopyBuffer(fast_ema_h, 0, 1, 2, f_ema) < 2) return;
   if(CopyBuffer(med_ema_h, 0, 1, 2, m_ema) < 2) return;
   if(CopyBuffer(slow_ema_h, 0, 1, 2, s_ema) < 2) return;

   double stoch_k[], stoch_d[];
   ArraySetAsSeries(stoch_k, true); ArraySetAsSeries(stoch_d, true);
   if(CopyBuffer(stoch_h, 0, 1, 3, stoch_k) < 3) return;
   if(CopyBuffer(stoch_h, 1, 1, 3, stoch_d) < 3) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   // Bullish Ribbon: EMA8 > EMA21 > EMA55
   bool ribbon_bull = (f_ema[0] > m_ema[0] && m_ema[0] > s_ema[0]);
   // Bearish Ribbon: EMA8 < EMA21 < EMA55
   bool ribbon_bear = (f_ema[0] < m_ema[0] && m_ema[0] < s_ema[0]);

   // Bullish Pullback Trigger: touched EMA21, closed above EMA8, Stoch cross out of oversold (<25)
   if(ribbon_bull && rates[0].low <= m_ema[0] && rates[0].close > f_ema[0])
   {
      if(stoch_k[1] < 25.0 && stoch_k[0] > stoch_d[0])
      {
         quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q04_Ribbon_Pullback_Buy");
         return;
      }
   }

   // Bearish Pullback Trigger: touched EMA21, closed below EMA8, Stoch cross out of overbought (>75)
   if(ribbon_bear && rates[0].high >= m_ema[0] && rates[0].close < f_ema[0])
   {
      if(stoch_k[1] > 75.0 && stoch_k[0] < stoch_d[0])
      {
         quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q04_Ribbon_Pullback_Sell");
         return;
      }
   }
}
"""

# ---------------------------------------------------------
# 5. Quant05_Turtle_ATR_Breakout_EA.mq5
# ---------------------------------------------------------
code_q05 = """//+------------------------------------------------------------------+
//|                          Quant05_Turtle_ATR_Breakout_EA.mq5      |
//|               Archetype: Multi-Timeframe Trend Continuation      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 12.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 30.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 9.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 2.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 14.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 3.5;    // Trailing Step (Pips)

input group "=== Turtle Breakout & ATR Regime Parameters ==="
input int      InpChannelPeriod        = 20;     // Donchian Breakout Channel Length
input int      InpATRPeriod            = 14;     // ATR Volatility Period
input int      InpATRMAPeriod          = 50;     // ATR Moving Average Baseline
input int      InpTradeStartHour       = 6;      // Session Start Hour (06:00 UTC)
input int      InpTradeEndHour         = 19;     // Session End Hour (19:00 UTC)
input ulong    InpMagicNumber          = 202605; // Magic Number

CQuantTrade    quant;
int            atr_handle;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   atr_handle = iATR(_Symbol, _Period, InpATRPeriod);
   if(atr_handle == INVALID_HANDLE) return INIT_FAILED;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(atr_handle);
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
   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double atr_buf[]; ArraySetAsSeries(atr_buf, true);
   int atr_copied = CopyBuffer(atr_handle, 0, 1, InpATRMAPeriod + 5, atr_buf);
   if(atr_copied < InpATRMAPeriod + 5) return;

   // Check if ATR is expanding relative to its 50-period average
   double atr_sum = 0;
   for(int i = 0; i < InpATRMAPeriod; i++) atr_sum += atr_buf[i];
   double atr_avg = atr_sum / InpATRMAPeriod;
   if(atr_buf[0] < atr_avg * 0.95) return; // Skip low volatility regime

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

   // Turtle Long Breakout
   if(rates[0].close > ch_high)
   {
      quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q05_Turtle_Breakout_Buy");
      return;
   }

   // Turtle Short Breakdown
   if(rates[0].close < ch_low)
   {
      quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q05_Turtle_Breakout_Sell");
      return;
   }
}
"""

# ---------------------------------------------------------
# 6. Quant06_Bollinger_Keltner_Squeeze_EA.mq5
# ---------------------------------------------------------
code_q06 = """//+------------------------------------------------------------------+
//|                     Quant06_Bollinger_Keltner_Squeeze_EA.mq5     |
//|               Archetype: Mean Reversion & Volatility Compression |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 22.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 7.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 11.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.5;    // Trailing Step (Pips)

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
int            bb_handle;
int            atr_handle;
int            ema_handle;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   bb_handle  = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   atr_handle = iATR(_Symbol, _Period, InpKeltnerATRPeriod);
   ema_handle = iMA(_Symbol, _Period, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(bb_handle == INVALID_HANDLE || atr_handle == INVALID_HANDLE || ema_handle == INVALID_HANDLE)
      return INIT_FAILED;
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

   // Keltner Channels: Mid +/- InpKeltnerMult * ATR
   double keltner_up_prev  = bb_mid[1] + InpKeltnerMult * atr_val[1];
   double keltner_low_prev = bb_mid[1] - InpKeltnerMult * atr_val[1];
   double keltner_up_curr  = bb_mid[0] + InpKeltnerMult * atr_val[0];
   double keltner_low_curr = bb_mid[0] - InpKeltnerMult * atr_val[0];

   // Squeeze on previous bar: Bollinger completely inside Keltner
   bool was_in_squeeze = (bb_up[1] < keltner_up_prev && bb_low[1] > keltner_low_prev);
   // Squeeze release on current completed bar: Bollinger expanding outside Keltner
   bool is_squeeze_fired = (bb_up[0] > keltner_up_curr || bb_low[0] < keltner_low_curr);

   if(was_in_squeeze && is_squeeze_fired)
   {
      // Bullish Squeeze Fired
      if(rates[0].close > bb_mid[0] && rates[0].close > ema_val[0])
      {
         quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q06_Squeeze_Buy");
         return;
      }
      // Bearish Squeeze Fired
      if(rates[0].close < bb_mid[0] && rates[0].close < ema_val[0])
      {
         quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q06_Squeeze_Sell");
         return;
      }
   }
}
"""

# ---------------------------------------------------------
# 7. Quant07_Asian_Mean_Reversion_EA.mq5
# ---------------------------------------------------------
code_q07 = """//+------------------------------------------------------------------+
//|                         Quant07_Asian_Mean_Reversion_EA.mq5      |
//|               Archetype: Mean Reversion & Volatility Compression |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 8.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 10.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 5.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)

input group "=== Asian Mean Reversion Parameters ==="
input int      InpBBPeriod             = 20;     // Bollinger Bands Period
input double   InpBBDeviation          = 2.2;    // Bollinger Bands Deviation
input int      InpRSIPeriod            = 14;     // RSI Period
input double   InpRSIOverbought        = 68.0;   // RSI Overbought Level
input double   InpRSIOversold          = 32.0;   // RSI Oversold Level
input int      InpAsianStartHour       = 22;     // Asian Session Start (22:00 UTC)
input int      InpAsianEndHour         = 5;      // Asian Session End (05:00 UTC)
input ulong    InpMagicNumber          = 202607; // Magic Number

CQuantTrade    quant;
int            bb_handle;
int            rsi_handle;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   bb_handle  = iBands(_Symbol, _Period, InpBBPeriod, 0, InpBBDeviation, PRICE_CLOSE);
   rsi_handle = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   if(bb_handle == INVALID_HANDLE || rsi_handle == INVALID_HANDLE) return INIT_FAILED;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(bb_handle);
   IndicatorRelease(rsi_handle);
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

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 2, rates) < 2) return;

   // Mean Reversion Long: Pierced lower Bollinger Band, RSI < Oversold, candle closed bullish
   if(rates[0].low <= bb_low[0] && rsi_val[0] <= InpRSIOversold && rates[0].close > rates[0].open)
   {
      quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q07_Asian_Reversion_Buy");
      return;
   }

   // Mean Reversion Short: Pierced upper Bollinger Band, RSI > Overbought, candle closed bearish
   if(rates[0].high >= bb_up[0] && rsi_val[0] >= InpRSIOverbought && rates[0].close < rates[0].open)
   {
      quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q07_Asian_Reversion_Sell");
      return;
   }
}
"""

# ---------------------------------------------------------
# 8. Quant08_RSI_Divergence_Envelope_EA.mq5
# ---------------------------------------------------------
code_q08 = """//+------------------------------------------------------------------+
//|                     Quant08_RSI_Divergence_Envelope_EA.mq5       |
//|               Archetype: Mean Reversion & Volatility Compression |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 22.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 7.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.5;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 11.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.5;    // Trailing Step (Pips)

input group "=== Envelope & Divergence Parameters ==="
input int      InpEnvMAPeriod          = 20;     // Envelope Moving Average Period
input double   InpEnvDeviation         = 0.12;   // Envelope Percentage Deviation
input int      InpRSIPeriod            = 14;     // RSI Oscillator Period
input int      InpDivergenceLookback   = 10;     // Divergence Swing Lookback Bars
input int      InpTradeStartHour       = 7;      // Session Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 17;     // Session End Hour (17:00 UTC)
input ulong    InpMagicNumber          = 202608; // Magic Number

CQuantTrade    quant;
int            env_handle;
int            rsi_handle;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   env_handle = iEnvelopes(_Symbol, _Period, InpEnvMAPeriod, 0, MODE_SMA, PRICE_CLOSE, InpEnvDeviation);
   rsi_handle = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   if(env_handle == INVALID_HANDLE || rsi_handle == INVALID_HANDLE) return INIT_FAILED;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(env_handle);
   IndicatorRelease(rsi_handle);
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
   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double env_up[], env_low[];
   ArraySetAsSeries(env_up, true); ArraySetAsSeries(env_low, true);
   if(CopyBuffer(env_handle, 0, 1, 2, env_up) < 2) return;
   if(CopyBuffer(env_handle, 1, 1, 2, env_low) < 2) return;

   double rsi_buf[]; ArraySetAsSeries(rsi_buf, true);
   int rsi_copied = CopyBuffer(rsi_handle, 0, 1, InpDivergenceLookback + 2, rsi_buf);
   if(rsi_copied < InpDivergenceLookback + 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   int rates_copied = CopyRates(_Symbol, _Period, 1, InpDivergenceLookback + 2, rates);
   if(rates_copied < InpDivergenceLookback + 2) return;

   // Bullish Divergence at lower envelope: Price made Lower Low, but RSI made Higher Low
   if(rates[0].low <= env_low[0])
   {
      for(int i = 3; i <= InpDivergenceLookback; i++)
      {
         if(rates[0].low < rates[i].low && rsi_buf[0] > rsi_buf[i] && rsi_buf[i] < 35.0)
         {
            if(rates[0].close > rates[0].open) // Reversal candle confirmation
            {
               quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q08_RSI_Div_Buy");
               return;
            }
         }
      }
   }

   // Bearish Divergence at upper envelope: Price made Higher High, but RSI made Lower High
   if(rates[0].high >= env_up[0])
   {
      for(int i = 3; i <= InpDivergenceLookback; i++)
      {
         if(rates[0].high > rates[i].high && rsi_buf[0] < rsi_buf[i] && rsi_buf[i] > 65.0)
         {
            if(rates[0].close < rates[0].open) // Reversal candle confirmation
            {
               quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q08_RSI_Div_Sell");
               return;
            }
         }
      }
   }
}
"""

# ---------------------------------------------------------
# 9. Quant09_London_Judas_Killzone_EA.mq5
# ---------------------------------------------------------
code_q09 = """//+------------------------------------------------------------------+
//|                        Quant09_London_Judas_Killzone_EA.mq5      |
//|               Archetype: Session Momentum & Killzone Dynamics    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 24.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 8.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 2.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 12.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 3.0;    // Trailing Step (Pips)

input group "=== London Judas Swing Parameters ==="
input int      InpAsianStartHour       = 0;      // Asian Session Start Hour
input int      InpAsianEndHour         = 7;      // Asian Session End Hour
input int      InpJudasStartHour       = 7;      // London Judas Open Start (07:00 UTC)
input int      InpJudasEndHour         = 10;     // London Judas Open End (10:00 UTC)
input double   InpMinWickPercent       = 0.40;   // Minimum Rejection Wick Size (% of Candle)
input ulong    InpMagicNumber          = 202609; // Magic Number

CQuantTrade    quant;
double         asian_high;
double         asian_low;
datetime       last_asian_day;
bool           asian_ready;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   asian_high = 0; asian_low = 999999; last_asian_day = 0; asian_ready = false;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
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
   UpdateAsianRange();

   if(!CQuantTrade::IsInHourWindow(InpJudasStartHour, InpJudasEndHour)) return;
   if(!asian_ready || asian_high <= 0 || asian_low >= 999999) return;

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   double c_high = rates[0].high, c_low = rates[0].low, c_open = rates[0].open, c_close = rates[0].close;
   double c_range = c_high - c_low;
   if(c_range <= 0) return;

   // Bullish Judas: Pierced Asian Low, wicked out, closed back above Asian Low
   if(c_low < asian_low && c_close > asian_low)
   {
      double lower_wick = MathMin(c_open, c_close) - c_low;
      if(lower_wick / c_range >= InpMinWickPercent)
      {
         quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q09_London_Judas_Buy");
         return;
      }
   }

   // Bearish Judas: Pierced Asian High, wicked out, closed back below Asian High
   if(c_high > asian_high && c_close < asian_high)
   {
      double upper_wick = c_high - MathMax(c_open, c_close);
      if(upper_wick / c_range >= InpMinWickPercent)
      {
         quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q09_London_Judas_Sell");
         return;
      }
   }
}
"""

# ---------------------------------------------------------
# 10. Quant10_Daily_CPR_Momentum_EA.mq5
# ---------------------------------------------------------
code_q10 = """//+------------------------------------------------------------------+
//|                        Quant10_Daily_CPR_Momentum_EA.mq5         |
//|               Archetype: Session Momentum & Killzone Dynamics    |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "1.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 10.0;   // Stop Loss (Pips)
input double   InpTakeProfitPips       = 24.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 8.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 2.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 12.0;   // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 3.0;    // Trailing Step (Pips)

input group "=== Daily CPR Compression Parameters ==="
input double   InpMaxCPRPips           = 16.0;   // Max CPR Width (TC-BC in Pips)
input int      InpMACDFast             = 12;     // MACD Fast Period
input int      InpMACDSlow             = 26;     // MACD Slow Period
input int      InpMACDSignal           = 9;      // MACD Signal Period
input int      InpTradeStartHour       = 7;      // Session Start Hour (07:00 UTC)
input int      InpTradeEndHour         = 16;     // Session End Hour (16:00 UTC)
input ulong    InpMagicNumber          = 202610; // Magic Number

CQuantTrade    quant;
int            macd_handle;
double         cpr_pivot;
double         cpr_bc;
double         cpr_tc;
double         cpr_width_pips;
datetime       last_cpr_day;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   macd_handle = iMACD(_Symbol, _Period, InpMACDFast, InpMACDSlow, InpMACDSignal, PRICE_CLOSE);
   if(macd_handle == INVALID_HANDLE) return INIT_FAILED;
   last_cpr_day = 0; cpr_pivot = 0; cpr_bc = 0; cpr_tc = 0; cpr_width_pips = 999;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(macd_handle);
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
   UpdateCPR();

   if(!CQuantTrade::IsInHourWindow(InpTradeStartHour, InpTradeEndHour)) return;
   if(cpr_width_pips > InpMaxCPRPips || cpr_pivot <= 0) return; // Only trade compressed CPR days

   long ptype; double popen, psl, ptp; ulong pticket;
   if(quant.HasOpenPosition(ptype, popen, psl, ptp, pticket)) return;

   double macd_main[], macd_sig[];
   ArraySetAsSeries(macd_main, true); ArraySetAsSeries(macd_sig, true);
   if(CopyBuffer(macd_handle, 0, 1, 2, macd_main) < 2) return;
   if(CopyBuffer(macd_handle, 1, 1, 2, macd_sig) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 2, rates) < 2) return;

   double upper_cpr = MathMax(cpr_tc, cpr_bc);
   double lower_cpr = MathMin(cpr_tc, cpr_bc);

   // Bullish Expansion: Closed above upper CPR boundary + MACD Main > Signal
   if(rates[0].close > upper_cpr && macd_main[0] > macd_sig[0])
   {
      quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q10_CPR_Expansion_Buy");
      return;
   }

   // Bearish Expansion: Closed below lower CPR boundary + MACD Main < Signal
   if(rates[0].close < lower_cpr && macd_main[0] < macd_sig[0])
   {
      quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Q10_CPR_Expansion_Sell");
      return;
   }
}
"""

strategies = [
    ("Quant01_Asian_Sweep_Sniper_EA", code_q01),
    ("Quant02_FVG_Mitigation_Flow_EA", code_q02),
    ("Quant03_Triple_Supertrend_Donchian_EA", code_q03),
    ("Quant04_EMA_Ribbon_Pullback_EA", code_q04),
    ("Quant05_Turtle_ATR_Breakout_EA", code_q05),
    ("Quant06_Bollinger_Keltner_Squeeze_EA", code_q06),
    ("Quant07_Asian_Mean_Reversion_EA", code_q07),
    ("Quant08_RSI_Divergence_Envelope_EA", code_q08),
    ("Quant09_London_Judas_Killzone_EA", code_q09),
    ("Quant10_Daily_CPR_Momentum_EA", code_q10)
]

print("Writing and compiling all 10 institutional strategies...")
for name, code in strategies:
    repo_dir = os.path.join(REPO_STRATEGIES, name)
    os.makedirs(repo_dir, exist_ok=True)
    repo_file = os.path.join(repo_dir, f"{name}.mq5")
    with open(repo_file, "w", encoding="utf-8") as f:
        f.write(code)
        
    mt5_file = os.path.join(MT5_EXPERTS_Q10, f"{name}.mq5")
    with open(mt5_file, "w", encoding="utf-8") as f:
        f.write(code)
        
    succ, log, ex5 = compile_ea(f"Quant10\\{name}.mq5")
    status = "[OK]" if succ else "[FAIL]"
    print(f"  {status} {name}: Compiled={succ}")
    if not succ:
        print(f"       Log: {log[:200]}")

print("\nGeneration and compilation complete.")
