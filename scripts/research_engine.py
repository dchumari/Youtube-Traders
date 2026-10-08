import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from tester_runner import run_tester, compile_ea, DATA_FOLDER, WINDOWS

code_trend = """//+------------------------------------------------------------------+
//|                               Quant_TrendMomentum_Bench.mq5      |
//|                                  Copyright 2026, Quant Research  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Quant Research"
#property link      "https://github.com/quant-research"
#property version   "2.00"

#include <QuantCore.mqh>

input group "=== Risk Management ==="
input double   InpRiskPercent          = 2.0;    // Risk per trade (% of Equity)
input double   InpStopLossPips         = 8.0;    // Stop Loss (Pips)
input double   InpTakeProfitPips       = 18.0;   // Take Profit (Pips)
input bool     InpUseBreakeven         = true;   // Enable Breakeven Protection
input double   InpBreakevenTriggerPips = 5.0;    // Breakeven Trigger (Pips)
input double   InpBreakevenLockPips    = 1.0;    // Breakeven Lock (Pips)
input bool     InpUseTrailing          = true;   // Enable Trailing Stop
input double   InpTrailingPips         = 8.0;    // Trailing Distance (Pips)
input double   InpTrailingStepPips     = 2.0;    // Trailing Step (Pips)
input int      InpMaxDailyTrades       = 3;      // Max Trades per Day

input group "=== Trend & Momentum Parameters ==="
input int      InpFastEMAPeriod        = 9;      // Fast EMA
input int      InpSlowEMAPeriod        = 21;     // Slow EMA
input int      InpTrendEMAPeriod       = 100;    // H1 Trend Filter EMA
input int      InpRSIPeriod            = 14;     // RSI Period
input int      InpTradeStartHour       = 7;      // Killzone Start (07:00 UTC)
input int      InpTradeEndHour         = 18;     // Killzone End (18:00 UTC)
input ulong    InpMagicNumber          = 202699; // Magic Number

CQuantTrade    quant;
int            fast_ema_h, slow_ema_h, trend_ema_h, rsi_h;
datetime       last_trade_day;
int            daily_trades;

int OnInit()
{
   if(!quant.Init(InpMagicNumber, _Symbol)) return INIT_FAILED;
   fast_ema_h  = iMA(_Symbol, _Period, InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   slow_ema_h  = iMA(_Symbol, _Period, InpSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   trend_ema_h = iMA(_Symbol, PERIOD_H1, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   rsi_h       = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);

   if(fast_ema_h == INVALID_HANDLE || slow_ema_h == INVALID_HANDLE || trend_ema_h == INVALID_HANDLE || rsi_h == INVALID_HANDLE)
      return INIT_FAILED;

   last_trade_day = 0; daily_trades = 0;
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(fast_ema_h);
   IndicatorRelease(slow_ema_h);
   IndicatorRelease(trend_ema_h);
   IndicatorRelease(rsi_h);
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

   double f_ema[2], s_ema[2], t_ema[2], rsi[2];
   ArraySetAsSeries(f_ema, true); ArraySetAsSeries(s_ema, true);
   ArraySetAsSeries(t_ema, true); ArraySetAsSeries(rsi, true);

   if(CopyBuffer(fast_ema_h, 0, 1, 2, f_ema) < 2) return;
   if(CopyBuffer(slow_ema_h, 0, 1, 2, s_ema) < 2) return;
   if(CopyBuffer(trend_ema_h, 0, 1, 2, t_ema) < 2) return;
   if(CopyBuffer(rsi_h, 0, 1, 2, rsi) < 2) return;

   MqlRates rates[]; ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 1, 3, rates) < 3) return;

   // Bullish Trend Continuation:
   // 1. Macro H1 Trend: Close > H1 100 EMA
   // 2. M15 Fast EMA > Slow EMA
   // 3. Pullback trigger: Bar 2 touched Slow EMA or Bar 1 closed above Fast EMA
   // 4. RSI between 50 and 68 (positive momentum, not overbought)
   if(rates[0].close > t_ema[0] && f_ema[0] > s_ema[0])
   {
      if(rates[1].low <= s_ema[1] && rates[0].close > f_ema[0] && rsi[0] > 50.0 && rsi[0] < 68.0)
      {
         if(quant.OpenBuy(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Trend_Buy"))
            daily_trades++;
         return;
      }
   }

   // Bearish Trend Continuation:
   if(rates[0].close < t_ema[0] && f_ema[0] < s_ema[0])
   {
      if(rates[1].high >= s_ema[1] && rates[0].close < f_ema[0] && rsi[0] < 50.0 && rsi[0] > 32.0)
      {
         if(quant.OpenSell(InpStopLossPips * pip_mult, InpTakeProfitPips * pip_mult, InpRiskPercent, "Trend_Sell"))
            daily_trades++;
         return;
      }
   }
}
"""

target = os.path.join(DATA_FOLDER, "MQL5", "Experts", "Quant10", "Quant_TrendMomentum_Bench.mq5")
with open(target, "w", encoding="utf-8") as f:
    f.write(code_trend)

ok, log, ex5 = compile_ea("Quant10\\Quant_TrendMomentum_Bench.mq5")
print(f"Compilation: {ok}")

windows = ["M1", "M2", "M3", "M4", "Q1", "Q2", "Q3", "Q4", "Y2", "Y3"]
for wid in windows:
    w = WINDOWS[wid]
    res = run_tester("Quant10\\Quant_TrendMomentum_Bench", "EURUSD", "M15", w["from"], w["to"], deposit=100.0)
    print(f"[{wid}] Trades={res.get('total_trades', 0):<3} | Net=${res.get('net_profit', 0.0):<6.2f} | PF={res.get('profit_factor', 0.0):<4.2f} | DD={res.get('drawdown_pct', 0.0):<4.2f}%")
