import os
import sys
import json
import time
from datetime import datetime

sys.path.insert(0, os.path.dirname(__file__))
from mrpfx_matrix_engine import run_test_instance, STRATEGY_MODELS, TEST_WINDOWS

# Define Matrix Grid Configurations
# We test across all 4 strategy models on XAUUSD (Gold) and EURUSD
MATRIX_CONFIGURATIONS = [
    # --- Strategy 0: Liquidity Grab (Sweep & Rejection) ---
    {
        "strat_id": 0,
        "config_id": "LG-01-Baseline",
        "name": "Liquidity Grab (RR 2.5, Lookback 20, Wick 0.40, BE 1.0R)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.5,
            "InpSweepLookback": 20,
            "InpMinSweepPoints": 30,
            "InpMinWickRatio": 0.40,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "false",
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpRiskPercent": 1.5
        }
    },
    {
        "strat_id": 0,
        "config_id": "LG-02-StrictWick",
        "name": "Liquidity Grab (RR 3.0, Lookback 25, Wick 0.50, BE 1.0R)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 3.0,
            "InpSweepLookback": 25,
            "InpMinSweepPoints": 40,
            "InpMinWickRatio": 0.50,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "false",
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpRiskPercent": 1.5
        }
    },
    {
        "strat_id": 0,
        "config_id": "LG-03-KillzoneOnly",
        "name": "Liquidity Grab (RR 2.0, Lookback 15, Killzone Active, Wick 0.35)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.0,
            "InpSweepLookback": 15,
            "InpMinSweepPoints": 25,
            "InpMinWickRatio": 0.35,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "true",
            "InpUseBreakeven": "true",
            "InpBETriggerR": 0.8,
            "InpRiskPercent": 1.5
        }
    },
    {
        "strat_id": 0,
        "config_id": "LG-04-FX-EURUSD",
        "name": "Liquidity Grab on EURUSD (RR 2.5, Lookback 20, Wick 0.40)",
        "symbol": "EURUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 0,
            "InpRewardRiskRatio": 2.5,
            "InpSweepLookback": 20,
            "InpMinSweepPoints": 30,
            "InpMinWickRatio": 0.40,
            "InpUseTrendFilter": "true",
            "InpUseSessionFilter": "false",
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpRiskPercent": 1.5
        }
    },

    # --- Strategy 1: 15-Minute Trendline Break & Retest ---
    {
        "strat_id": 1,
        "config_id": "TL-01-Baseline",
        "name": "Trendline Retest (RR 2.0, FastEMA 20, SlowEMA 50, BE 1.0R)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 1,
            "InpRewardRiskRatio": 2.0,
            "InpFastEMAPeriod": 20,
            "InpSlowEMAPeriod": 50,
            "InpRetestTolerance": 40,
            "InpUseSessionFilter": "false",
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpRiskPercent": 1.5
        }
    },
    {
        "strat_id": 1,
        "config_id": "TL-02-Runner-3R",
        "name": "Trendline Retest (RR 3.0, FastEMA 20, SlowEMA 50, BE 1.2R)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 1,
            "InpRewardRiskRatio": 3.0,
            "InpFastEMAPeriod": 20,
            "InpSlowEMAPeriod": 50,
            "InpRetestTolerance": 30,
            "InpUseSessionFilter": "false",
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.2,
            "InpRiskPercent": 1.5
        }
    },
    {
        "strat_id": 1,
        "config_id": "TL-03-EURUSD",
        "name": "Trendline Retest on EURUSD (RR 2.0, FastEMA 20, SlowEMA 50)",
        "symbol": "EURUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 1,
            "InpRewardRiskRatio": 2.0,
            "InpFastEMAPeriod": 20,
            "InpSlowEMAPeriod": 50,
            "InpRetestTolerance": 35,
            "InpUseSessionFilter": "false",
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpRiskPercent": 1.5
        }
    },

    # --- Strategy 2: Gold Matrix Volatility Scalper ---
    {
        "strat_id": 2,
        "config_id": "GM-01-Baseline",
        "name": "Gold Matrix (KeltnerMult 1.8, ATR 14, RSI 14, RR 2.5)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 2,
            "InpRewardRiskRatio": 2.5,
            "InpKeltnerMult": 1.8,
            "InpATRPeriod": 14,
            "InpRSIPeriod": 14,
            "InpUseSessionFilter": "false",
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpRiskPercent": 1.5
        }
    },
    {
        "strat_id": 2,
        "config_id": "GM-02-TightBand",
        "name": "Gold Matrix (KeltnerMult 1.5, ATR 10, RR 3.0, BE 1.0R)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 2,
            "InpRewardRiskRatio": 3.0,
            "InpKeltnerMult": 1.5,
            "InpATRPeriod": 10,
            "InpRSIPeriod": 14,
            "InpUseSessionFilter": "false",
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpRiskPercent": 1.5
        }
    },
    {
        "strat_id": 2,
        "config_id": "GM-03-EURUSD",
        "name": "Gold Matrix on EURUSD (KeltnerMult 1.8, ATR 14, RR 2.5)",
        "symbol": "EURUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 2,
            "InpRewardRiskRatio": 2.5,
            "InpKeltnerMult": 1.8,
            "InpATRPeriod": 14,
            "InpRSIPeriod": 14,
            "InpUseSessionFilter": "false",
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpRiskPercent": 1.5
        }
    },

    # --- Strategy 3: Killzone Momentum Doubler ---
    {
        "strat_id": 3,
        "config_id": "KZ-01-Baseline",
        "name": "Killzone Momentum (London+NY, RR 2.5, FastEMA 20, SlowEMA 50)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 3,
            "InpRewardRiskRatio": 2.5,
            "InpFastEMAPeriod": 20,
            "InpSlowEMAPeriod": 50,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpRiskPercent": 1.5
        }
    },
    {
        "strat_id": 3,
        "config_id": "KZ-02-Runner-3R",
        "name": "Killzone Momentum (London+NY, RR 3.0, FastEMA 15, SlowEMA 45)",
        "symbol": "XAUUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 3,
            "InpRewardRiskRatio": 3.0,
            "InpFastEMAPeriod": 15,
            "InpSlowEMAPeriod": 45,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.2,
            "InpRiskPercent": 1.5
        }
    },
    {
        "strat_id": 3,
        "config_id": "KZ-03-EURUSD",
        "name": "Killzone Momentum on EURUSD (London+NY, RR 2.5, FastEMA 20, SlowEMA 50)",
        "symbol": "EURUSD",
        "period": "M15",
        "inputs": {
            "InpStrategy": 3,
            "InpRewardRiskRatio": 2.5,
            "InpFastEMAPeriod": 20,
            "InpSlowEMAPeriod": 50,
            "InpUseSessionFilter": "true",
            "InpSessionStartH1": 7,
            "InpSessionEndH1": 11,
            "InpSessionStartH2": 13,
            "InpSessionEndH2": 17,
            "InpUseBreakeven": "true",
            "InpBETriggerR": 1.0,
            "InpRiskPercent": 1.5
        }
    }
]

def main():
    print("=" * 80)
    print(f"MR P FX STRATEGY SUITE: MASTER MATRIX OPTIMIZATION & VALIDATION")
    print(f"Total Configurations to Evaluate: {len(MATRIX_CONFIGURATIONS)}")
    print(f"Test Horizons: 4 Distinct Market Regimes (Trend, Expansion, Chop, Acceleration)")
    print(f"Deposit: $100.00 | Leverage: 1:100")
    print("=" * 80)

    results_data = []

    for idx, cfg in enumerate(MATRIX_CONFIGURATIONS):
        strat_info = STRATEGY_MODELS[cfg["strat_id"]]
        print(f"\n[{idx+1}/{len(MATRIX_CONFIGURATIONS)}] Testing Config: {cfg['config_id']} | {cfg['name']}")
        print(f"      Strategy: {strat_info['name']} on {cfg['symbol']} {cfg['period']}")

        window_results = {}
        total_net = 0.0
        total_gp = 0.0
        total_gl = 0.0
        total_trades = 0
        max_dd_pct = 0.0
        max_dd_money = 0.0
        profitable_windows = 0

        for win in TEST_WINDOWS:
            r = run_test_instance(
                symbol=cfg["symbol"],
                period=cfg["period"],
                from_date=win["from"],
                to_date=win["to"],
                deposit=100.0,
                inputs_dict=cfg["inputs"]
            )
            window_results[win["id"]] = r
            if r["success"]:
                total_net += r["net_profit"]
                total_gp += r["gross_profit"]
                total_gl += abs(r["gross_loss"])
                total_trades += r["total_trades"]
                if r["drawdown_pct"] > max_dd_pct:
                    max_dd_pct = r["drawdown_pct"]
                if r["drawdown_money"] > max_dd_money:
                    max_dd_money = r["drawdown_money"]
                if r["net_profit"] > 0:
                    profitable_windows += 1
                print(f"      {win['id']}: Net=${r['net_profit']:+.2f} | PF={r['profit_factor']:.2f} | DD={r['drawdown_pct']:.2f}% | Trades={r['total_trades']}")
            else:
                print(f"      {win['id']}: FAILED ({r.get('error', 'unknown')})")
            time.sleep(0.3)

        combined_pf = round(total_gp / total_gl, 2) if total_gl > 0 else (99.0 if total_gp > 0 else 0.0)
        calmar = round(total_net / max_dd_money, 2) if max_dd_money > 0 else 0.0

        summary = {
            "config_id": cfg["config_id"],
            "strat_id": cfg["strat_id"],
            "strat_name": strat_info["name"],
            "config_name": cfg["name"],
            "symbol": cfg["symbol"],
            "period": cfg["period"],
            "total_net": round(total_net, 2),
            "total_gp": round(total_gp, 2),
            "total_gl": round(total_gl, 2),
            "combined_pf": combined_pf,
            "max_dd_pct": round(max_dd_pct, 2),
            "max_dd_money": round(max_dd_money, 2),
            "calmar_ratio": calmar,
            "total_trades": total_trades,
            "profitable_windows": profitable_windows,
            "total_windows": len(TEST_WINDOWS),
            "inputs": cfg["inputs"],
            "windows": window_results
        }
        results_data.append(summary)
        print(f"   => COMBINED: Net=${total_net:+.2f} | Combined PF={combined_pf} | Max DD={max_dd_pct:.2f}% | Calmar={calmar} | Profitable Windows: {profitable_windows}/{len(TEST_WINDOWS)}")

    # Sort results by Net Profit and Calmar Ratio
    ranked_results = sorted(results_data, key=lambda x: (x["total_net"], x["calmar_ratio"]), reverse=True)

    output_path = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\MRPFX_MATRIX_OPTIMIZATION_RESULTS.json"
    with open(output_path, "w", encoding="utf-8") as out:
        json.dump(ranked_results, out, indent=2)

    print("\n" + "=" * 80)
    print("TOP RANKED MRPFX STRATEGY CONFIGURATIONS:")
    print("=" * 80)
    for rank, item in enumerate(ranked_results[:5], 1):
        print(f"#{rank} [{item['config_id']}] {item['strat_name']} ({item['symbol']} {item['period']})")
        print(f"    Net Profit: ${item['total_net']:+.2f} | PF: {item['combined_pf']} | Max DD: {item['max_dd_pct']:.2f}% | Calmar: {item['calmar_ratio']} | Wins: {item['profitable_windows']}/4")

    print(f"\nMaster optimization results successfully saved to: {output_path}")

if __name__ == "__main__":
    main()
