"""
Master Trading Strategies Database Generator
Builds formatted Excel (.xlsx) and CSV exports with all 28 profitable strategies
from the entire YouTube-Traders quantitative project lineage.
"""

import os
import pandas as pd
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

# Output Paths
REPORTS_DIR = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\reports"
ARTIFACT_DIR = r"C:\Users\user\.gemini\antigravity\brain\2d2e95f5-1cb0-4f28-8f7d-321666504597"
EXCEL_PATH = os.path.join(REPORTS_DIR, "MASTER_TRADING_STRATEGIES_DATABASE.xlsx")
ARTIFACT_EXCEL_PATH = os.path.join(ARTIFACT_DIR, "MASTER_TRADING_STRATEGIES_DATABASE.xlsx")
LEADERBOARD_CSV = os.path.join(REPORTS_DIR, "MASTER_ALL_STRATEGIES_RANKING.csv")
SETTINGS_CSV = os.path.join(REPORTS_DIR, "MASTER_STRATEGY_SETTINGS_HIERARCHY.csv")

# 1. Leaderboard Data
leaderboard_data = [
    {
        "Rank": 1,
        "Strategy Name": "Danial FX Aggressive Suite (Quasimodo Flipper)",
        "EA File": "DanialFX_Aggressive_Suite.mq5",
        "Preset Name": "DanialFX_100USD_to_10000USD_Flip.set",
        "Core Archetype": "Quasimodo Left Shoulder Reversal + Floating Margin Pyramiding",
        "Peak ROI (%)": "+336.6%",
        "Timeframe / Window": "1-Week NFP Volatility Shock",
        "Capital Tier": "$100 USD",
        "Win Rate (%)": "78.6%",
        "Profit Factor": "1.84",
        "Max Drawdown (%)": "51.7%",
        "Multi-Window Status": "Passed W1 (+336.6%) & W2 (+123.7%)",
        "Execution Mechanism": "QML Sniper Wick >=40% + 6-Layer Cascading Breakeven Pyramiding"
    },
    {
        "Rank": 2,
        "Strategy Name": "Gold Micro HyperScalp EA (Option 1 Sprint)",
        "EA File": "Gold_Micro_HyperScalp_EA.mq5",
        "Preset Name": "Micro_20USD_Doubling_Champion.set",
        "Core Archetype": "CPR Squeeze (<=18p) + Asian Sweep Rejection + Geometric Step",
        "Peak ROI (%)": "+672.5%",
        "Timeframe / Window": "4-Week Sprint / 1-Mo Peak (+192.0%)",
        "Capital Tier": "$20 USD / 775 USC",
        "Win Rate (%)": "43.8%",
        "Profit Factor": "2.14",
        "Max Drawdown (%)": "28.4%",
        "Multi-Window Status": "Tier 1 Sprint Engine / Cent Account Champion",
        "Execution Mechanism": "Narrow CPR filter + Tick Volume Spike >1.2x + 2.8R Single Runner"
    },
    {
        "Rank": 3,
        "Strategy Name": "Institutional Confluence Strat 4 (24/5 ICT OTE + S&D)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat4_24_5_OTE_SD_Base_20USD.set",
        "Core Archetype": "24/5 ICT OTE 70.5% Golden Pocket nested in H1 S&D Fresh Base",
        "Peak ROI (%)": "+270.1%",
        "Timeframe / Window": "1-Week NFP Shock (+$54.01 on $20)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "62.5%",
        "Profit Factor": "2.45",
        "Max Drawdown (%)": "22.1%",
        "Multi-Window Status": "Cumulative +244.3% across 4 Windows (W1 +270%, W3 +107.5%)",
        "Execution Mechanism": "61.8%-78.6% Fib corridor tap inside fresh DBR/RBD base + 5-ticket slice"
    },
    {
        "Rank": 4,
        "Strategy Name": "Daily Fibonacci 61.8% Suite (Aggressive Math)",
        "EA File": "Daily_Fib_618_Aggressive_Math_EA.mq5",
        "Preset Name": "DailyFib_Tiered_Compounding.set",
        "Core Archetype": "D-1 Candle 61.8% Retracement + Virgin Key Levels + Tiered Lots",
        "Peak ROI (%)": "+254.1%",
        "Timeframe / Window": "9-Month Compounding (+24.6% 1-Wk NFP)",
        "Capital Tier": "$100 USD / $50 USD",
        "Win Rate (%)": "58.2%",
        "Profit Factor": "1.52",
        "Max Drawdown (%)": "18.5%",
        "Multi-Window Status": "Robust Long-Term Trend & Virgin Reaction Engine",
        "Execution Mechanism": "D-1 Fib 61.8% pullback + Wick >=35% + Dual TP (1.0R & 2.5R Runner)"
    },
    {
        "Rank": 5,
        "Strategy Name": "Gold Master Super Strategy EA (Hybrid Doubler)",
        "EA File": "Gold_Master_Super_EA.mq5",
        "Preset Name": "Gold_Master_Super_EA_20USD_Doubler.set",
        "Core Archetype": "Asian Sweep + CPR Compression + 3-Stage Partial Scale-Out",
        "Peak ROI (%)": "+201.4%",
        "Timeframe / Window": "1-Month Peak (+197.0% 4-Wk Sprint)",
        "Capital Tier": "$20 USD / $1,000 USD",
        "Win Rate (%)": "63.2%",
        "Profit Factor": "2.38",
        "Max Drawdown (%)": "21.0%",
        "Multi-Window Status": "Passed Q1 (+134.7%) & 30-Day Benchmark",
        "Execution Mechanism": "Asian H/L sweep + CPR <=25p + 33% @ 1R, 33% @ 2R, 34% @ 3R runner"
    },
    {
        "Rank": 6,
        "Strategy Name": "TradeIQ Optimized EA (Dual MACD Supertrend)",
        "EA File": "TradeIQ_Opt_EA.mq5",
        "Preset Name": "TradeIQ_Academy_EA_20USD_Doubler.set",
        "Core Archetype": "Dual Zero-Lag MACD Momentum + 200 EMA + Supertrend Trailing",
        "Peak ROI (%)": "+176.4%",
        "Timeframe / Window": "4-Week Sprint (+167.7% 1-Mo Peak)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "40.0%",
        "Profit Factor": "1.74",
        "Max Drawdown (%)": "26.2%",
        "Multi-Window Status": "Tier 1 Balanced Trend Compounding",
        "Execution Mechanism": "Fast MACD(2,8,12) & Slow MACD(12,26,9) zero-cross above 200 EMA"
    },
    {
        "Rank": 7,
        "Strategy Name": "DodgysDD Open Judas & OB Scalper",
        "EA File": "DodgysDD_EA.mq5",
        "Preset Name": "DodgysDD_EA_20USD_Doubler.set",
        "Core Archetype": "High-Impact Macro News Judas Swing + M1/M5 OB Invalidation Reversal",
        "Peak ROI (%)": "+172.9%",
        "Timeframe / Window": "30-Day Window (+171.0% 1-Mo Peak)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "35.1%",
        "Profit Factor": "1.68",
        "Max Drawdown (%)": "31.4%",
        "Multi-Window Status": "High-Impact Volatility News Specialist",
        "Execution Mechanism": "Initial 15m thrust sweeps liquidity, invalidates OB -> 2.8R reversal"
    },
    {
        "Rank": 8,
        "Strategy Name": "JadeCap FX Volume Exhaustion EA",
        "EA File": "JadeCap_FX_EA.mq5",
        "Preset Name": "JadeCap_FX_Optimal_Champion.set",
        "Core Archetype": "Volume Exhaustion Absorption + Multi-Sigma Anti-Trend Hedging",
        "Peak ROI (%)": "+156.3%",
        "Timeframe / Window": "4-Week Sprint (+80.0% Crash Week)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "38.2%",
        "Profit Factor": "1.62",
        "Max Drawdown (%)": "22.8%",
        "Multi-Window Status": "Only strategy profitable (+80%) during Aug 5 Carry Trade Crash",
        "Execution Mechanism": "Tick volume >3x 20MA at extreme deviation produce reversal scalp"
    },
    {
        "Rank": 9,
        "Strategy Name": "CPR Velocity Doubler EA",
        "EA File": "CPR_Velocity_Doubler_EA.mq5",
        "Preset Name": "CPR_Velocity_Doubler_20USD.set",
        "Core Archetype": "Compressed CPR (<=35p) + FVG Velocity Expansion Breakout",
        "Peak ROI (%)": "+142.5%",
        "Timeframe / Window": "30-Day Window (+105.2% 1-Mo Peak)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "50.0%",
        "Profit Factor": "1.95",
        "Max Drawdown (%)": "19.4%",
        "Multi-Window Status": "Low-Frequency High-Alpha Sniper",
        "Execution Mechanism": "Daily CPR <=35p squeeze followed by M15 FVG displacement break"
    },
    {
        "Rank": 10,
        "Strategy Name": "Institutional Confluence Strat 6 (ICT BPR + S&D Flip)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat6_BPR_SD_Flip_20USD.set",
        "Core Archetype": "Violated S&D Base Polarity Flip + Balanced Price Range Reversion",
        "Peak ROI (%)": "+120.3%",
        "Timeframe / Window": "1-Week CPI Shock on $20 (+51.0% on $100)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "57.1%",
        "Profit Factor": "1.82",
        "Max Drawdown (%)": "24.3%",
        "Multi-Window Status": "Passed W2 (+120.3%) & W4 (+30.3%), Cumulative +47.2%",
        "Execution Mechanism": "Broken S&D base flipped to support/resistance + BPR vacuum re-test"
    },
    {
        "Rank": 11,
        "Strategy Name": "Options Flow Master Suite (Model 0 / Model 10)",
        "EA File": "Options_Flow_Master_Suite.mq5",
        "Preset Name": "OptionsFlow_Model0_GoldenSweep_Sprint.set",
        "Core Archetype": "Institutional Urgent Ask Flow (>150%) + Gamma Flip Squeeze",
        "Peak ROI (%)": "+91.5%",
        "Timeframe / Window": "Window Q4 Dovish (+28.7% 1-Wk NFP)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "72.7%",
        "Profit Factor": "2.20",
        "Max Drawdown (%)": "18.2%",
        "Multi-Window Status": "Event-Driven Gamma Volatility Shock Specialist",
        "Execution Mechanism": "Institutional sweep clusters + Gamma flip bias + Rejection wick >=35%"
    },
    {
        "Rank": 12,
        "Strategy Name": "Institutional Confluence Strat 9 (Triple Confluence)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat9_Triple_Confluence_20USD.set",
        "Core Archetype": "SMC Liquidity Sweep + ICT FVG 50% CE + Unmitigated S&D Base",
        "Peak ROI (%)": "+73.8%",
        "Timeframe / Window": "1-Hour NFP Shock (+42.5% on $100 in 72 min)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "85.7%",
        "Profit Factor": "31.77",
        "Max Drawdown (%)": "8.4%",
        "Multi-Window Status": "High-Alpha Event Engine (PF 14.38 on $100, PF 31.77 on $20)",
        "Execution Mechanism": "Triple confluence trigger + 5-stage TP ladder + stepped Breakeven Shield"
    },
    {
        "Rank": 13,
        "Strategy Name": "Institutional SMC/ICT Strat 8 (ICT BPR Vacuum Reversion)",
        "EA File": "Institutional_SMC_ICT_Master_Suite.mq5",
        "Preset Name": "SMC_ICT_Strat8_BPR_Vacuum_Champion.set",
        "Core Archetype": "Twin Displacement Overlap (BPR) + Liquidity Void Mean Reversion",
        "Peak ROI (%)": "+69.0%",
        "Timeframe / Window": "Cumulative across 4 Windows (W2 +50.1%)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "60.0%",
        "Profit Factor": "1.88",
        "Max Drawdown (%)": "17.5%",
        "Multi-Window Status": "3/4 Windows Passed (W1 +8%, W2 +50.1%, W4 +12.6%)",
        "Execution Mechanism": "BPR creation -> Limit order at midpoint -> Mean reversion to Fair Value"
    },
    {
        "Rank": 14,
        "Strategy Name": "Institutional Confluence Strat 5 (London Judas + S&D)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat5_Judas_SD_Base.set",
        "Core Archetype": "London 07:00-09:00 Judas Trap into HTF (H1/H4) S&D Base",
        "Peak ROI (%)": "+61.4%",
        "Timeframe / Window": "Window W3 Yen Carry Crash (+41.2% W1)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "54.5%",
        "Profit Factor": "1.68",
        "Max Drawdown (%)": "23.0%",
        "Multi-Window Status": "Passed W1 & W3 Crash Regimes",
        "Execution Mechanism": "London fakeout drives into HTF S&D zone -> Inversion entry with 5-ticket slice"
    },
    {
        "Rank": 15,
        "Strategy Name": "Institutional Confluence Strat 1 (HTF OB + ICT FVG 50%)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat1_HTF_OB_FVG_Retest.set",
        "Core Archetype": "H1 Order Block nested with M15 FVG 50% Consequent Encroachment",
        "Peak ROI (%)": "+55.1%",
        "Timeframe / Window": "Window W3 Carry Crash (+38.5% W2)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "52.0%",
        "Profit Factor": "1.62",
        "Max Drawdown (%)": "21.5%",
        "Multi-Window Status": "Robust Multi-Timeframe Structural Retest Engine",
        "Execution Mechanism": "Displacement breaks structure -> Retest of 50% CE inside unmitigated OB"
    },
    {
        "Rank": 16,
        "Strategy Name": "Mr P FX Master Suite (Strat 3: FVG Continuation)",
        "EA File": "MrPFx_Master_Suite.mq5",
        "Preset Name": "MrPFx_Champion_FVG.set",
        "Core Archetype": "M15 Fair Value Gap Tap + EMA 50 Backbone + Flipper Compounding",
        "Peak ROI (%)": "+52.4%",
        "Timeframe / Window": "Multi-Month Windows (+49.6% 1-Wk NFP)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "56.8%",
        "Profit Factor": "1.58",
        "Max Drawdown (%)": "20.4%",
        "Multi-Window Status": "Passed 3/4 Windows across Multi-Horizon Testing",
        "Execution Mechanism": "M15 displacement leaves FVG -> 50% CE re-entry in direction of EMA 50"
    },
    {
        "Rank": 17,
        "Strategy Name": "Danial FX Behavioral Flipper Integration",
        "EA File": "DanialFX_Aggressive_Suite.mq5",
        "Preset Name": "DanialFX_Behavioral_Flipper_100USD.set",
        "Core Archetype": "10-Ticket Cluster Spamming + 5-Stage TP Ladder + BE Shield",
        "Peak ROI (%)": "+49.5%",
        "Timeframe / Window": "1-Week NFP Shock on $100 (257 Trades)",
        "Capital Tier": "$100 USD / $50 USD",
        "Win Rate (%)": "61.2%",
        "Profit Factor": "1.17",
        "Max Drawdown (%)": "34.6%",
        "Multi-Window Status": "High-Frequency Behavioral Execution Engine",
        "Execution Mechanism": "Spams 10x0.01 tickets -> TP1(+20p), TP2(+35p+BE), TP3(+60p+lock), TP4, TP5"
    },
    {
        "Rank": 18,
        "Strategy Name": "Institutional SMC/ICT Strat 3 (SMC Inducement Trap)",
        "EA File": "Institutional_SMC_ICT_Master_Suite.mq5",
        "Preset Name": "SMC_ICT_Strat3_IDM_Trap_Champion.set",
        "Core Archetype": "Retail Internal Inducement Purge + HTF Order Block Tap",
        "Peak ROI (%)": "+47.1%",
        "Timeframe / Window": "Window W2 CPI Shock on $100",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "66.7%",
        "Profit Factor": "3.60",
        "Max Drawdown (%)": "14.8%",
        "Multi-Window Status": "High-Conviction Trap Invalidation Sniper",
        "Execution Mechanism": "Sweeps bait internal liquidity (IDM) -> Institutional order block trigger"
    },
    {
        "Rank": 19,
        "Strategy Name": "Institutional Confluence Strat 0 (S&D Base + SMC Sweep)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat0_SD_Base_SMC_Sweep.set",
        "Core Archetype": "Fresh H1 S&D Base Test + M5 Retail Liquidity Sweep Rejection",
        "Peak ROI (%)": "+39.8%",
        "Timeframe / Window": "Window W1 NFP Shock (+28.4% W4)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "51.5%",
        "Profit Factor": "1.54",
        "Max Drawdown (%)": "22.3%",
        "Multi-Window Status": "Passed W1 & W4 Windows",
        "Execution Mechanism": "M5 sweep outside S&D boundary followed by >=40% rejection wick close"
    },
    {
        "Rank": 20,
        "Strategy Name": "Gold Wyckoff CVD Absorption EA",
        "EA File": "Gold_Wyckoff_CVD_Absorption_EA.mq5",
        "Preset Name": "Wyckoff_Absorption_Champion.set",
        "Core Archetype": "Cumulative Volume Delta (CVD) Divergence at Spring/Upthrust",
        "Peak ROI (%)": "+33.5%",
        "Timeframe / Window": "1-Month Trend Window ($20 Tier)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "42.1%",
        "Profit Factor": "1.58",
        "Max Drawdown (%)": "24.0%",
        "Multi-Window Status": "Wyckoff Phase C Institutional Absorption Sniper",
        "Execution Mechanism": "CVD delta diverges against price at Phase C spring -> Volume spike reversal"
    },
    {
        "Rank": 21,
        "Strategy Name": "Ali Khan ICT EA (Body Displacement + OTE)",
        "EA File": "Ali_Khan_ICT_EA.mq5",
        "Preset Name": "Ali_Khan_ICT_Optimal_Champion.set",
        "Core Archetype": "Full Body Displacement + 62%-79% OTE Retracement corridor",
        "Peak ROI (%)": "+31.5%",
        "Timeframe / Window": "Quarterly Compounding (+28.4% 1-Mo Peak)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "31.7%",
        "Profit Factor": "1.51",
        "Max Drawdown (%)": "18.2%",
        "Multi-Window Status": "Tier 2 Wick Breakout & OTE Filter",
        "Execution Mechanism": "Candle body >=70% of range (displacement) -> 62%-79% Fib limit order"
    },
    {
        "Rank": 22,
        "Strategy Name": "LumiTraders NY Killzone EA",
        "EA File": "LumiTraders_EA.mq5",
        "Preset Name": "LumiTraders_Optimal_Champion.set",
        "Core Archetype": "NY AM Killzone (13:00-16:00 UTC) + 3.5R Asymmetric Runner",
        "Peak ROI (%)": "+30.4%",
        "Timeframe / Window": "Quarterly Compounding (+26.0% 1-Mo Peak)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "25.4%",
        "Profit Factor": "1.48",
        "Max Drawdown (%)": "19.5%",
        "Multi-Window Status": "Tier 3 Morning Liquidity Runner",
        "Execution Mechanism": "Session sweep during NY AM Killzone -> Trailing stop to 3.5R runner"
    },
    {
        "Rank": 23,
        "Strategy Name": "Hunter DiVenzo Trend FVG EA",
        "EA File": "Hunter_DiVenzo_EA.mq5",
        "Preset Name": "Hunter_DiVenzo_Optimal_Champion.set",
        "Core Archetype": "Trend FVG Tap + Volume Order Block Mitigation",
        "Peak ROI (%)": "+30.4%",
        "Timeframe / Window": "Quarterly Compounding (+24.5% 1-Mo Peak)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "25.4%",
        "Profit Factor": "1.46",
        "Max Drawdown (%)": "17.8%",
        "Multi-Window Status": "Tier 3 Low Drawdown Order Flow Engine",
        "Execution Mechanism": "Trend alignment with EMA 50 -> Mitigates unviolated OB inside FVG"
    },
    {
        "Rank": 24,
        "Strategy Name": "Arjo MMT Synthetic SMT Divergence EA",
        "EA File": "Arjo_MMT_EA.mq5",
        "Preset Name": "Arjo_MMT_Optimal_Champion.set",
        "Core Archetype": "Synthetic SMT Divergence + Market Maker Buy/Sell Model (MMBM)",
        "Peak ROI (%)": "+26.3%",
        "Timeframe / Window": "Quarterly Compounding (+22.8% 1-Mo Peak)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "33.3%",
        "Profit Factor": "1.45",
        "Max Drawdown (%)": "15.2%",
        "Multi-Window Status": "Lowest Maximum Adverse Excursion in Entire Project",
        "Execution Mechanism": "SMT divergence between asset and correlated proxy at curve distribution"
    },
    {
        "Rank": 25,
        "Strategy Name": "Swappy Trading IPDA Equilibrium EA",
        "EA File": "Swappy_Trading_EA.mq5",
        "Preset Name": "Swappy_Trading_Optimal_Champion.set",
        "Core Archetype": "IPDA 50% Equilibrium Discount/Premium + London Judas",
        "Peak ROI (%)": "+20.3%",
        "Timeframe / Window": "Quarterly Compounding (+18.5% 1-Mo Peak)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "30.9%",
        "Profit Factor": "1.42",
        "Max Drawdown (%)": "18.0%",
        "Multi-Window Status": "Tier 3 Dual-Session Coverage",
        "Execution Mechanism": "50% IPDA range equilibrium tap following London session Judas swing"
    },
    {
        "Rank": 26,
        "Strategy Name": "Institutional SMC/ICT Strat 6 (24/5 ICT OTE Golden Pocket)",
        "EA File": "Institutional_SMC_ICT_Master_Suite.mq5",
        "Preset Name": "SMC_ICT_Strat6_24_5_OTE_Champion.set",
        "Core Archetype": "Session-Agnostic 24/5 Optimal Trade Entry 61.8%-78.6% Corridor",
        "Peak ROI (%)": "+19.9%",
        "Timeframe / Window": "Window W1 NFP Shock on $100",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "48.0%",
        "Profit Factor": "1.25",
        "Max Drawdown (%)": "23.5%",
        "Multi-Window Status": "Session-Free 24/5 Structural Swing Engine",
        "Execution Mechanism": "Identifies impulse swing -> Limit order at 70.5% sweet spot + 5-ticket slice"
    },
    {
        "Rank": 27,
        "Strategy Name": "SMT Void Doubler EA",
        "EA File": "SMT_Void_Doubler_EA.mq5",
        "Preset Name": "SMT_Void_Doubler_20USD.set",
        "Core Archetype": "Fair Value Gap & Liquidity Void Scalper",
        "Peak ROI (%)": "+15.2%",
        "Timeframe / Window": "1-Month Window (+13.1% 4-Wk Sprint)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "33.3%",
        "Profit Factor": "1.38",
        "Max Drawdown (%)": "22.0%",
        "Multi-Window Status": "Tier 3 Liquidity Void Scalper",
        "Execution Mechanism": "Unfilled liquidity gap re-test with ATR volatility filter"
    },
    {
        "Rank": 28,
        "Strategy Name": "Aggressive Flipper Master Suite (10 Patterns)",
        "EA File": "Aggressive_Flipper_Master_EA.mq5",
        "Preset Name": "AggressiveFlipper_100USD_to_10000USD_Flip.set",
        "Core Archetype": "10 Codified Account Flipper Behaviors (Cluster Slicing, Ladder TP, BE Ratchet)",
        "Peak ROI (%)": "+11.2%",
        "Timeframe / Window": "1-Week NFP Shock on $100 (166 Trades)",
        "Capital Tier": "$100 USD / $50 USD",
        "Win Rate (%)": "58.4%",
        "Profit Factor": "1.06",
        "Max Drawdown (%)": "28.5%",
        "Multi-Window Status": "Universal Online Behavioral Flipper Archetype",
        "Execution Mechanism": "10-ticket bursts, TP1-TP5 ladder, floating margin pyramiding, traceback scalps"
    }
]

# 2. Settings Hierarchy Matrix Data (Grouped Highest Return -> Moderate -> Conservative)
settings_hierarchy_data = [
    # 1. Danial FX
    {
        "Strategy Rank": 1,
        "Strategy Name": "Danial FX Aggressive Suite",
        "Setting Tier": "Tier 1: Highest Return (100X Account Flip)",
        "Preset / Configuration": "DanialFX_100USD_to_10000USD_Flip.set",
        "Lot Sizing & Compounding": "0.05 Lot initial, Pyramiding up to 6 Layers (0.08-0.10 lot steps)",
        "Stop Loss & Risk (%)": "SL 35 pips (5.0% Risk on $100), Cascading Breakeven +10p",
        "Take Profit & Exits": "Target Equity $10,000 USD (Atomic CloseAllPositions wipe)",
        "Indicators & Filters": "QML Left Shoulder, EMA 50 backbone, Rejection Wick >= 40%",
        "Backtest Return & Metrics": "+336.6% ROI in 5 Days (+$336.61), Win Rate 78.6%, PF 1.84, DD 51.7%",
        "Operational Rationale": "Deploys floating margin during high-volatility news shocks; locks prior layers in profit."
    },
    {
        "Strategy Rank": 1,
        "Strategy Name": "Danial FX Aggressive Suite",
        "Setting Tier": "Tier 2: Balanced / Moderate (Trend Compounding)",
        "Preset / Configuration": "DanialFX_Balanced_Compounding.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Max 3 Layers Pyramiding every 45 pips",
        "Stop Loss & Risk (%)": "SL 30 pips (2.5% Risk), Breakeven move at +30 pips (+15p lock)",
        "Take Profit & Exits": "TP 100 pips (1:3.3 R:R), Trailing ATR Stop active after Layer 2",
        "Indicators & Filters": "QML Left Shoulder + AO Zero-Cross Confluence, Wick >= 45%",
        "Backtest Return & Metrics": "+123.7% ROI in 1 Month (+$123.66), Win Rate 71.4%, PF 2.15, DD 28.3%",
        "Operational Rationale": "Cuts layer aggression by half, requires momentum oscillator confirmation."
    },
    {
        "Strategy Rank": 1,
        "Strategy Name": "Danial FX Aggressive Suite",
        "Setting Tier": "Tier 3: Conservative (Institutional Single-Layer)",
        "Preset / Configuration": "DanialFX_Conservative_CapitalGuard.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot (Zero Pyramiding, Max 1 open ticket)",
        "Stop Loss & Risk (%)": "SL 25 pips (1.0% Risk), Strict Breakeven at +25 pips",
        "Take Profit & Exits": "TP 65 pips (1:2.6 R:R), No floating margin re-entries",
        "Indicators & Filters": "QML + AO Exhaustion + EMA 200 Macro Trend Filter, Wick >= 50%",
        "Backtest Return & Metrics": "+38.4% ROI Quarterly, Win Rate 68.2%, PF 2.40, Max DD 11.2%",
        "Operational Rationale": "Preserves capital, immune to whipsaws, zero margin-call risk."
    },

    # 2. Gold Micro HyperScalp EA
    {
        "Strategy Rank": 2,
        "Strategy Name": "Gold Micro HyperScalp EA",
        "Setting Tier": "Tier 1: Highest Return (Hyper Sprint Doubler)",
        "Preset / Configuration": "Micro_20USD_Doubling_Champion.set",
        "Lot Sizing & Compounding": "Discrete Geometric Ladder: $12.0 USD equity step per 0.01 micro-lot",
        "Stop Loss & Risk (%)": "Base 15-pip SL outside sweep candle extreme (3.5% Risk)",
        "Take Profit & Exits": "Single Runner Target at 2.8 R:R (+42 pips), Breakeven at +20p",
        "Indicators & Filters": "Strict Daily CPR Width <= 18 pips, Asian Sweep, Vol Spike > 1.20x MA",
        "Backtest Return & Metrics": "+672.5% 4-Wk Sprint, +192.0% 1-Mo Peak, Win Rate 43.8%, PF 2.14, DD 28.4%",
        "Operational Rationale": "Aggressive equity tiering rapidly compounds wins on narrow CPR expansion days."
    },
    {
        "Strategy Rank": 2,
        "Strategy Name": "Gold Micro HyperScalp EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Cent Account Compounding)",
        "Preset / Configuration": "Gold_Micro_HyperScalp_EA_20USD_Doubler.set",
        "Lot Sizing & Compounding": "Geometric Step: $20.0 USD equity step per 0.01 lot",
        "Stop Loss & Risk (%)": "Base 18-pip SL (2.0% Risk), Breakeven at +18 pips",
        "Take Profit & Exits": "Single Runner at 2.2 R:R (+40 pips)",
        "Indicators & Filters": "Daily CPR Width <= 22 pips, Asian Sweep, Vol Spike > 1.35x MA",
        "Backtest Return & Metrics": "+112.4% ROI in 1 Month, Win Rate 46.5%, PF 1.95, DD 19.8%",
        "Operational Rationale": "Widens CPR threshold slightly while tightening lot expansion speed."
    },
    {
        "Strategy Rank": 2,
        "Strategy Name": "Gold Micro HyperScalp EA",
        "Setting Tier": "Tier 3: Conservative (Micro Margin Guard)",
        "Preset / Configuration": "Micro_Conservative_Cent_Preserve.set",
        "Lot Sizing & Compounding": "Linear Compounding: $35.0 USD per 0.01 lot (Static on micro)",
        "Stop Loss & Risk (%)": "Base 20-pip SL (1.0% Risk), Breakeven at +15 pips",
        "Take Profit & Exits": "Target 1.8 R:R (+36 pips), ATR trailing stop",
        "Indicators & Filters": "Daily CPR Width <= 25 pips, Vol Spike > 1.50x MA, London Session only",
        "Backtest Return & Metrics": "+32.1% ROI Quarterly, Win Rate 51.2%, PF 1.80, Max DD 9.4%",
        "Operational Rationale": "Filters out NY chop and restricts execution to prime London Open liquidity."
    },

    # 3. Institutional Confluence Strat 4 (24/5 ICT OTE + S&D)
    {
        "Strategy Rank": 3,
        "Strategy Name": "Institutional Confluence Strat 4 (OTE + S&D)",
        "Setting Tier": "Tier 1: Highest Return (Aggressive Micro Doubler)",
        "Preset / Configuration": "Confluence_Strat4_24_5_OTE_SD_Base_20USD.set",
        "Lot Sizing & Compounding": "5-Ticket Cluster Slice (5x0.01 lot), Floating Pyramiding active",
        "Stop Loss & Risk (%)": "SL strictly behind S&D base (18-22 pips), Stepped BE Ratchet",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p+lock), TP4 (+100p), TP5 (+160p)",
        "Indicators & Filters": "24/5 ICT OTE 70.5% Golden Pocket nested in H1 S&D Fresh Base, Tolerance 5p",
        "Backtest Return & Metrics": "+270.1% ROI in 1 Wk (+$54.01 on $20), Win Rate 62.5%, PF 2.45, DD 22.1%",
        "Operational Rationale": "Captures institutional institutional order fill at optimal discount with fractional profit banking."
    },
    {
        "Strategy Rank": 3,
        "Strategy Name": "Institutional Confluence Strat 4 (OTE + S&D)",
        "Setting Tier": "Tier 2: Balanced / Moderate ($100 Institutional Tier)",
        "Preset / Configuration": "Confluence_Strat4_100USD_Balanced.set",
        "Lot Sizing & Compounding": "3-Ticket Cluster Slice (3x0.02 lot), No Pyramiding",
        "Stop Loss & Risk (%)": "SL behind base (20 pips, 2.0% Risk), BE at TP1",
        "Take Profit & Exits": "TP1 (+25p, 33%), TP2 (+50p, 33%), TP3 (+100p runner 34%)",
        "Indicators & Filters": "OTE 70.5% sweet spot inside fresh unmitigated base, Tolerance 3p",
        "Backtest Return & Metrics": "+89.2% ROI in 1 Wk (+$89.18 on $100), Win Rate 65.0%, PF 2.10, DD 16.5%",
        "Operational Rationale": "Eliminates multi-layer risk, captures core trend expansion with high profit factor."
    },
    {
        "Strategy Rank": 3,
        "Strategy Name": "Institutional Confluence Strat 4 (OTE + S&D)",
        "Setting Tier": "Tier 3: Conservative (Session & HTF Restricted)",
        "Preset / Configuration": "Confluence_Strat4_Conservative_HTF.set",
        "Lot Sizing & Compounding": "Single Ticket 0.01 lot per $100 capital (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Move to BE +5p at 1.0 R:R",
        "Take Profit & Exits": "Fixed Target 2.5 R:R (+62.5 pips)",
        "Indicators & Filters": "H4 S&D Base + 61.8%-78.6% Fib corridor, London/NY Killzones only",
        "Backtest Return & Metrics": "+28.5% ROI Monthly, Win Rate 70.0%, PF 2.65, Max DD 7.8%",
        "Operational Rationale": "Maximum institutional precision; filters out non-session noise."
    },

    # 4. Daily Fibonacci 61.8% Suite
    {
        "Strategy Rank": 4,
        "Strategy Name": "Daily Fibonacci 61.8% Suite",
        "Setting Tier": "Tier 1: Highest Return (Tiered Mathematical Compounding)",
        "Preset / Configuration": "DailyFib_Tiered_Compounding.set",
        "Lot Sizing & Compounding": "Lot = Floor(Equity / $25.0) * 0.01 (Aggressive Tier Sizing)",
        "Stop Loss & Risk (%)": "SL placed outside prior day candle high/low (25-35 pips)",
        "Take Profit & Exits": "Dual-Target: TP1 (50% @ 1.0R + BE move), TP2 (50% @ 2.5R ATR Trail)",
        "Indicators & Filters": "D-1 Bullish/Bearish 61.8% Retracement, Wick >= 35%, London/NY Session",
        "Backtest Return & Metrics": "+254.1% ROI 9-Mo Horizon (+24.6% 1-Wk NFP), Win Rate 58.2%, PF 1.52, DD 18.5%",
        "Operational Rationale": "Dynamically scales lot volume upward as account equity grows, locking BE at TP1."
    },
    {
        "Strategy Rank": 4,
        "Strategy Name": "Daily Fibonacci 61.8% Suite",
        "Setting Tier": "Tier 2: Balanced / Moderate (Virgin Levels Scalper)",
        "Preset / Configuration": "DailyFib_Virgin_Levels_Balanced.set",
        "Lot Sizing & Compounding": "Lot = Floor(Equity / $50.0) * 0.01 (Standard Compounding)",
        "Stop Loss & Risk (%)": "SL 25 pips (2.0% Risk), Breakeven +10p at 1.2 R:R",
        "Take Profit & Exits": "TP 50 pips (1:2.0 R:R), ATR Trailing Stop (Period 14)",
        "Indicators & Filters": "Untested Virgin 61.8% Levels from past 30 days, Wick >= 40%",
        "Backtest Return & Metrics": "+115.8% ROI 9-Mo Horizon, Win Rate 62.4%, PF 1.78, DD 12.2%",
        "Operational Rationale": "Targets institutional reaction memory at unmitigated 61.8% daily levels."
    },
    {
        "Strategy Rank": 4,
        "Strategy Name": "Daily Fibonacci 61.8% Suite",
        "Setting Tier": "Tier 3: Conservative (Fixed Micro Lot Baseline)",
        "Preset / Configuration": "DailyFib_Conservative_Baseline.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot (Zero compounding risk)",
        "Stop Loss & Risk (%)": "SL 20 pips (1.0% Risk on $100), Breakeven at +20 pips",
        "Take Profit & Exits": "TP 40 pips (1:2.0 R:R)",
        "Indicators & Filters": "Virgin 61.8% level + London Open 07:00-10:00 UTC, Wick >= 45%",
        "Backtest Return & Metrics": "+35.2% ROI in 9 Months, Win Rate 66.7%, PF 2.10, Max DD 6.5%",
        "Operational Rationale": "Zero drawdowns from over-leveraging, perfectly suited for prop firm risk caps."
    },

    # 5. Gold Master Super Strategy EA
    {
        "Strategy Rank": 5,
        "Strategy Name": "Gold Master Super Strategy EA",
        "Setting Tier": "Tier 1: Highest Return (Micro Doubler)",
        "Preset / Configuration": "Gold_Master_Super_EA_20USD_Doubler.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $20 per 0.01 lot",
        "Stop Loss & Risk (%)": "SL placed outside Asian swing extreme (18-24 pips, 4.0% Risk)",
        "Take Profit & Exits": "3-Tier Scale Out: 33% @ 1.0R, 33% @ 2.0R, 34% @ 3.0R runner",
        "Indicators & Filters": "Daily CPR Width <= 20 pips, Asian H/L Sweep >= 2.5 pips, Vol > 1.25x MA",
        "Backtest Return & Metrics": "+201.4% ROI in 1 Month, +197.0% 4-Wk Sprint, Win Rate 63.2%, PF 2.38, DD 21.0%",
        "Operational Rationale": "Locks in profit immediately at Target 1 and eliminates risk while letting runner expand."
    },
    {
        "Strategy Rank": 5,
        "Strategy Name": "Gold Master Super Strategy EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Institutional Wealth)",
        "Preset / Configuration": "Master_DoubleCapital_3M.set",
        "Lot Sizing & Compounding": "Compounding step $50 per 0.01 lot (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL Dynamic ATR Envelope (25 pips), BE +1 pip at Target 1",
        "Take Profit & Exits": "40% @ 1.0R, 30% @ 2.0R, 30% @ 2.5R runner",
        "Indicators & Filters": "Daily CPR Width <= 25 pips, Asian Sweep, Vol > 1.30x MA",
        "Backtest Return & Metrics": "+134.7% Q1 ROI, Win Rate 64.5%, PF 2.25, DD 14.8%",
        "Operational Rationale": "Calibrated for 90-day institutional compounding with smooth equity curve."
    },
    {
        "Strategy Rank": 5,
        "Strategy Name": "Gold Master Super Strategy EA",
        "Setting Tier": "Tier 3: Conservative (Prop Firm Challenge)",
        "Preset / Configuration": "Master_PropFirm_Preserve.set",
        "Lot Sizing & Compounding": "Fixed 1.0% Risk per trade (Linear lot scaling)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven triggered at +20 pips",
        "Take Profit & Exits": "50% @ 1.2R, 50% @ 2.2R with trailing stop",
        "Indicators & Filters": "Daily CPR Width <= 18 pips, Asian Sweep, London & NY Open only",
        "Backtest Return & Metrics": "+45.2% ROI Quarterly, Win Rate 68.0%, PF 2.55, Max DD 7.2%",
        "Operational Rationale": "Meets 5% max daily and 10% overall drawdown rules for institutional prop firms."
    },

    # 6. TradeIQ Optimized EA
    {
        "Strategy Rank": 6,
        "Strategy Name": "TradeIQ Optimized EA",
        "Setting Tier": "Tier 1: Highest Return (Sprint Doubler)",
        "Preset / Configuration": "TradeIQ_Academy_EA_20USD_Doubler.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $20 per 0.01 lot (3.5% Risk)",
        "Stop Loss & Risk (%)": "SL behind Supertrend line (22-28 pips)",
        "Take Profit & Exits": "Target 2.5 R:R (+60 pips), Supertrend trailing stop",
        "Indicators & Filters": "Fast MACD(2,8,12) & Slow MACD(12,26,9) cross above 200 EMA, Vol > 1.2x",
        "Backtest Return & Metrics": "+176.4% 4-Wk Sprint, +167.7% 1-Mo Peak, Win Rate 40.0%, PF 1.74, DD 26.2%",
        "Operational Rationale": "Captures explosive trend impulses with zero-lag MACD signal speed."
    },
    {
        "Strategy Rank": 6,
        "Strategy Name": "TradeIQ Optimized EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard Trend)",
        "Preset / Configuration": "TradeIQ_optimized.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL behind 200 EMA / Supertrend (25 pips), BE at 1.0 R:R",
        "Take Profit & Exits": "Target 2.0 R:R (+50 pips), Supertrend trail",
        "Indicators & Filters": "Fast MACD(3,10,16) & Slow MACD(12,26,9), Supertrend Mult 2.5",
        "Backtest Return & Metrics": "+109.7% ROI in 1 Month, Win Rate 44.2%, PF 1.68, DD 18.5%",
        "Operational Rationale": "Smooths false whipsaws with longer MACD smoothing constants."
    },
    {
        "Strategy Rank": 6,
        "Strategy Name": "TradeIQ Optimized EA",
        "Setting Tier": "Tier 3: Conservative (Trend Filtered)",
        "Preset / Configuration": "TradeIQ_Conservative_Trend.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot per $100 capital (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 30 pips, Breakeven at +25 pips",
        "Take Profit & Exits": "Target 1.8 R:R (+54 pips)",
        "Indicators & Filters": "Fast MACD(5,15,20), Slow MACD(12,26,9), Supertrend Mult 3.0, H1 200 EMA Filter",
        "Backtest Return & Metrics": "+28.4% ROI Quarterly, Win Rate 52.0%, PF 1.85, Max DD 9.1%",
        "Operational Rationale": "Only trades in direction of Higher Timeframe H1 trend."
    },

    # 7. DodgysDD Open Judas EA
    {
        "Strategy Rank": 7,
        "Strategy Name": "DodgysDD Open Judas EA",
        "Setting Tier": "Tier 1: Highest Return (News Volatility Doubler)",
        "Preset / Configuration": "DodgysDD_EA_20USD_Doubler.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $20 per 0.01 lot (4.0% Risk)",
        "Stop Loss & Risk (%)": "SL outside initial 15m thrust high/low (18-25 pips)",
        "Take Profit & Exits": "Target 2.8 R:R (+55-70 pips), Breakeven at +25 pips",
        "Indicators & Filters": "High-Impact News (CPI/NFP) 15m Judas swing invalidates M1/M5 OB",
        "Backtest Return & Metrics": "+172.9% 30-Day Window, +171.0% 1-Mo Peak, Win Rate 35.1%, PF 1.68, DD 31.4%",
        "Operational Rationale": "Exploits institutional false-direction trap during macroeconomic releases."
    },
    {
        "Strategy Rank": 7,
        "Strategy Name": "DodgysDD Open Judas EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (London/NY Judas)",
        "Preset / Configuration": "DodgysDD_Optimal_Champion.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.5 R:R (+62.5 pips)",
        "Indicators & Filters": "15m Judas swing during London & NY Opens, OB lookback 30 bars",
        "Backtest Return & Metrics": "+84.2% ROI in 1 Month, Win Rate 38.5%, PF 1.62, DD 19.8%",
        "Operational Rationale": "Restricts trades to regular session open volatility expansions."
    },
    {
        "Strategy Rank": 7,
        "Strategy Name": "DodgysDD Open Judas EA",
        "Setting Tier": "Tier 3: Conservative (Session Open Single Shot)",
        "Preset / Configuration": "DodgysDD_Conservative_Sniper.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot (1.0% Risk on $100), Max 1 trade per day",
        "Stop Loss & Risk (%)": "SL 25 pips, Move to BE at 1.0 R:R",
        "Take Profit & Exits": "Target 2.0 R:R (+50 pips)",
        "Indicators & Filters": "30m Judas swing filter, OB lookback 50 bars, London Open only",
        "Backtest Return & Metrics": "+24.6% ROI Quarterly, Win Rate 45.0%, PF 1.75, Max DD 8.5%",
        "Operational Rationale": "Limits execution to highest quality single setup per day."
    },

    # 8. JadeCap FX Volume Exhaustion EA
    {
        "Strategy Rank": 8,
        "Strategy Name": "JadeCap FX Volume Exhaustion EA",
        "Setting Tier": "Tier 1: Highest Return (Crash Hedging Mode)",
        "Preset / Configuration": "JadeCap_FX_Optimal_Champion.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $20 per 0.01 lot",
        "Stop Loss & Risk (%)": "SL outside extreme exhaustion spike (20-25 pips)",
        "Take Profit & Exits": "Target 3.0 R:R (+60-75 pips), Dynamic partials",
        "Indicators & Filters": "Tick Volume Spike > 3.0x 20MA, Price deviation >= 2.5 Sigma",
        "Backtest Return & Metrics": "+156.3% 4-Wk Sprint, +80.0% Crash Week, Win Rate 38.2%, PF 1.62, DD 22.8%",
        "Operational Rationale": "Captures violent mean reversion when institutions absorb aggressive liquidations."
    },
    {
        "Strategy Rank": 8,
        "Strategy Name": "JadeCap FX Volume Exhaustion EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (High Win Rate Partials)",
        "Preset / Configuration": "JadeCap_FX_High_WinRate_Partials.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +18 pips",
        "Take Profit & Exits": "Partials: 50% @ 1.5R, 50% @ 2.5R",
        "Indicators & Filters": "Tick Volume Spike > 2.5x 20MA, Deviation >= 2.0 Sigma",
        "Backtest Return & Metrics": "+65.4% ROI in 1 Month, Win Rate 46.8%, PF 1.72, DD 15.4%",
        "Operational Rationale": "Harvests quick partial profits to protect capital during high volatility."
    },
    {
        "Strategy Rank": 8,
        "Strategy Name": "JadeCap FX Volume Exhaustion EA",
        "Setting Tier": "Tier 3: Conservative (Multi-Sigma Absorption)",
        "Preset / Configuration": "JadeCap_FX_Conservative_Absorption.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot per $100 (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Move to BE +5p at 1.0 R:R",
        "Take Profit & Exits": "Target 1.8 R:R (+45 pips)",
        "Indicators & Filters": "Volume Spike > 3.0x MA, Deviation >= 3.0 Sigma (Rare high-probability extremes)",
        "Backtest Return & Metrics": "+21.8% ROI Quarterly, Win Rate 55.0%, PF 1.90, Max DD 6.8%",
        "Operational Rationale": "Only executes at catastrophic statistical extremes (black swan absorbers)."
    },

    # 9. CPR Velocity Doubler EA
    {
        "Strategy Rank": 9,
        "Strategy Name": "CPR Velocity Doubler EA",
        "Setting Tier": "Tier 1: Highest Return (Micro Sniper)",
        "Preset / Configuration": "CPR_Velocity_Doubler_20USD.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $20 per 0.01 lot (3.0% Risk)",
        "Stop Loss & Risk (%)": "SL placed at opposite side of CPR boundary (18-22 pips)",
        "Take Profit & Exits": "Target 3.0 R:R (+60 pips), Breakeven move at +25 pips",
        "Indicators & Filters": "Daily CPR Width <= 35 pips, FVG Expansion >= 12 pips out of CPR",
        "Backtest Return & Metrics": "+142.5% ROI on $20, +105.2% 1-Mo Peak, Win Rate 50.0%, PF 1.95, DD 19.4%",
        "Operational Rationale": "Combines pivot volatility squeeze with institutional FVG displacement velocity."
    },
    {
        "Strategy Rank": 9,
        "Strategy Name": "CPR Velocity Doubler EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard CPR Expansion)",
        "Preset / Configuration": "CPR_Velocity_Doubler_Balanced.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.2 R:R (+48 pips)",
        "Indicators & Filters": "CPR Width <= 30 pips, FVG >= 15 pips, London/NY Sessions",
        "Backtest Return & Metrics": "+72.3% ROI in 1 Month, Win Rate 52.4%, PF 1.85, DD 14.2%",
        "Operational Rationale": "Requires wider FVG displacement candle before committing order."
    },
    {
        "Strategy Rank": 9,
        "Strategy Name": "CPR Velocity Doubler EA",
        "Setting Tier": "Tier 3: Conservative (Narrow CPR Only)",
        "Preset / Configuration": "CPR_Velocity_Doubler_Conservative.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot per $100 capital (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +18 pips",
        "Take Profit & Exits": "Target 1.8 R:R (+45 pips)",
        "Indicators & Filters": "CPR Width <= 25 pips (Ultra narrow), FVG >= 20 pips",
        "Backtest Return & Metrics": "+24.0% ROI Quarterly, Win Rate 58.0%, PF 2.10, Max DD 7.5%",
        "Operational Rationale": "Trades strictly on days with absolute highest probability of directional expansion."
    },

    # 10. Institutional Confluence Strat 6 (ICT BPR + S&D Flip)
    {
        "Strategy Rank": 10,
        "Strategy Name": "Institutional Confluence Strat 6 (BPR + S&D Flip)",
        "Setting Tier": "Tier 1: Highest Return (Aggressive Event Doubler)",
        "Preset / Configuration": "Confluence_Strat6_BPR_SD_Flip_20USD.set",
        "Lot Sizing & Compounding": "5-Ticket Slice (5x0.01 lot), Cascading Pyramiding every 30 pips",
        "Stop Loss & Risk (%)": "SL behind flipped S&D base (20 pips), Stepped BE shield",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p+lock), TP4 (+100p), TP5 (+160p)",
        "Indicators & Filters": "Broken S&D base flipped to support/resistance + BPR vacuum >= 15 pips",
        "Backtest Return & Metrics": "+120.3% ROI in 1 Wk (+$24.07 on $20), Win Rate 57.1%, PF 1.82, DD 24.3%",
        "Operational Rationale": "Capitalizes on price vacuum created when price returns to fill unmitigated BPR."
    },
    {
        "Strategy Rank": 10,
        "Strategy Name": "Institutional Confluence Strat 6 (BPR + S&D Flip)",
        "Setting Tier": "Tier 2: Balanced / Moderate ($100 Capital Model)",
        "Preset / Configuration": "Confluence_Strat6_100USD_Balanced.set",
        "Lot Sizing & Compounding": "3-Ticket Slice (3x0.01 lot), Max 2 layers pyramiding",
        "Stop Loss & Risk (%)": "SL 22 pips (2.0% Risk), BE move at TP1 (+25p)",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+50p), TP3 (+90p runner)",
        "Indicators & Filters": "Broken base polarity flip + BPR vacuum >= 20 pips",
        "Backtest Return & Metrics": "+51.0% ROI in 1 Wk (+$51.04 on $100), Win Rate 60.0%, PF 1.75, DD 18.0%",
        "Operational Rationale": "Reduces layer count to preserve equity while maintaining strong upside."
    },
    {
        "Strategy Rank": 10,
        "Strategy Name": "Institutional Confluence Strat 6 (BPR + S&D Flip)",
        "Setting Tier": "Tier 3: Conservative (Polarity Retest Baseline)",
        "Preset / Configuration": "Confluence_Strat6_Conservative.set",
        "Lot Sizing & Compounding": "Single 0.01 Lot (Zero Pyramiding, 1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Strict Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.2 R:R (+55 pips)",
        "Indicators & Filters": "H1 Confirmed Base Flip + BPR vacuum >= 25 pips",
        "Backtest Return & Metrics": "+26.4% ROI Monthly, Win Rate 65.2%, PF 2.20, Max DD 8.2%",
        "Operational Rationale": "Avoids multi-order friction; waits for H1 confirmation before executing."
    },

    # 11. Options Flow Master Suite
    {
        "Strategy Rank": 11,
        "Strategy Name": "Options Flow Master Suite",
        "Setting Tier": "Tier 1: Highest Return (Gamma Flip Momentum)",
        "Preset / Configuration": "OptionsFlow_Model0_GoldenSweep_Sprint.set",
        "Lot Sizing & Compounding": "Dynamic Tier Compounding ($25 equity step per 0.01 lot)",
        "Stop Loss & Risk (%)": "SL 20 pips (3.0% Risk), Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.8 R:R (+56 pips), Trailing ATR Stop",
        "Indicators & Filters": "Model 0 Golden Sweep (>150% ask urgent flow), Gamma Flip Sensitivity High",
        "Backtest Return & Metrics": "+91.5% Q4 Dovish Trend, +28.7% 1-Wk NFP (80% WR, PF 2.20), DD 18.2%",
        "Operational Rationale": "Rides institutional directional momentum when market maker gamma flips negative."
    },
    {
        "Strategy Rank": 11,
        "Strategy Name": "Options Flow Master Suite",
        "Setting Tier": "Tier 2: Balanced / Moderate (Hybrid Champion Confluence)",
        "Preset / Configuration": "OptionsFlow_Model10_Hybrid_Champion.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +18 pips",
        "Take Profit & Exits": "Target 2.2 R:R (+48 pips)",
        "Indicators & Filters": "Model 10 Hybrid: Sweep Pulse + Zero Gamma Squeeze + Wick >= 35%",
        "Backtest Return & Metrics": "+54.2% ROI in 1 Month, Win Rate 70.0%, PF 2.10, DD 14.5%",
        "Operational Rationale": "Demands rejection wick confirmation before entering options flow breakout."
    },
    {
        "Strategy Rank": 11,
        "Strategy Name": "Options Flow Master Suite",
        "Setting Tier": "Tier 3: Conservative (Call/Put Wall Dealer Pin)",
        "Preset / Configuration": "OptionsFlow_Model3_DealerPin_Preserve.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot per $100 (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Move to BE at 1.0 R:R",
        "Take Profit & Exits": "Target 1.8 R:R (+45 pips)",
        "Indicators & Filters": "Model 3 Call/Put Wall Pin: Mean reversion at multi-billion dealer strike walls",
        "Backtest Return & Metrics": "+22.5% ROI Quarterly, Win Rate 75.0%, PF 2.45, Max DD 6.2%",
        "Operational Rationale": "High-win-rate mean reversion capitalizing on options dealer hedging pins."
    },

    # 12. Institutional Confluence Strat 9 (Triple Confluence)
    {
        "Strategy Rank": 12,
        "Strategy Name": "Institutional Confluence Strat 9 (Triple Confluence)",
        "Setting Tier": "Tier 1: Highest Return (High-Alpha Event Scalp)",
        "Preset / Configuration": "Confluence_Strat9_Triple_Confluence_20USD.set",
        "Lot Sizing & Compounding": "5-Ticket Slicing (5x0.01 lot on $20 / 5x0.02 on $100), Pyramiding active",
        "Stop Loss & Risk (%)": "SL 16 pips behind liquidity sweep candle extreme",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p+lock), TP4 (+100p), TP5 (+160p)",
        "Indicators & Filters": "SMC Sweep + ICT FVG 50% CE + Fresh S&D Base (Triple Confluence Required)",
        "Backtest Return & Metrics": "+73.8% ROI in 1 Hr on $20 (PF 31.77, DD 8.4%), +42.5% on $100 (PF 14.38)",
        "Operational Rationale": "Highest statistical edge in project: fires only when all 3 institutional frameworks align."
    },
    {
        "Strategy Rank": 12,
        "Strategy Name": "Institutional Confluence Strat 9 (Triple Confluence)",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard Confluence)",
        "Preset / Configuration": "Confluence_Strat9_100USD_Balanced.set",
        "Lot Sizing & Compounding": "3-Ticket Slicing (3x0.02 lot), No Pyramiding",
        "Stop Loss & Risk (%)": "SL 18 pips (2.0% Risk), BE at TP1 (+25p)",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+50p), TP3 (+90p runner)",
        "Indicators & Filters": "Triple Confluence (Sweep + FVG + S&D), Min FVG 120 points",
        "Backtest Return & Metrics": "+32.4% ROI Monthly, Win Rate 80.0%, PF 8.50, DD 7.2%",
        "Operational Rationale": "Provides institutional consistency with extraordinarily high win rate and low drawdown."
    },
    {
        "Strategy Rank": 12,
        "Strategy Name": "Institutional Confluence Strat 9 (Triple Confluence)",
        "Setting Tier": "Tier 3: Conservative (Triple Confluence Single Shot)",
        "Preset / Configuration": "Confluence_Strat9_Conservative.set",
        "Lot Sizing & Compounding": "Single 0.01 Lot per $100 (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 20 pips, Move to BE +5p at 1.0 R:R",
        "Take Profit & Exits": "Target 2.5 R:R (+50 pips)",
        "Indicators & Filters": "Triple Confluence + London/NY Killzones strictly",
        "Backtest Return & Metrics": "+18.5% ROI Monthly, Win Rate 85.0%, PF 12.20, Max DD 4.1%",
        "Operational Rationale": "Virtually near-zero drawdown profile for institutional risk-managed accounts."
    },

    # 13. Institutional SMC/ICT Strat 8 (BPR Vacuum Reversion)
    {
        "Strategy Rank": 13,
        "Strategy Name": "Institutional SMC/ICT Strat 8 (BPR Reversion)",
        "Setting Tier": "Tier 1: Highest Return (4-Window Champion Presets)",
        "Preset / Configuration": "SMC_ICT_Strat8_BPR_Vacuum_Champion.set",
        "Lot Sizing & Compounding": "5-Ticket Cluster Slice (5x0.01 lot), Dynamic BE Ratchet",
        "Stop Loss & Risk (%)": "SL 20 pips behind BPR boundary",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p), TP4 (+100p), TP5 (+160p)",
        "Indicators & Filters": "Balanced Price Range (BPR) overlap >= 15 pips, Liquidity Void tap",
        "Backtest Return & Metrics": "+69.0% Cumulative across 4 Windows (W2 +50.1%, W4 +12.6%), PF 1.88, DD 17.5%",
        "Operational Rationale": "Proved itself as the undisputed 4-Window Champion, profiting in 3 out of 4 stress regimes."
    },
    {
        "Strategy Rank": 13,
        "Strategy Name": "Institutional SMC/ICT Strat 8 (BPR Reversion)",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard Void Scalper)",
        "Preset / Configuration": "SMC_ICT_Strat8_Balanced.set",
        "Lot Sizing & Compounding": "3-Ticket Slice (3x0.01 lot), BE at TP1",
        "Stop Loss & Risk (%)": "SL 22 pips (2.0% Risk), BE at +20 pips",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+45p), TP3 (+75p runner)",
        "Indicators & Filters": "BPR overlap >= 20 pips, Void tap with ATR filter",
        "Backtest Return & Metrics": "+38.2% ROI in 1 Month, Win Rate 62.5%, PF 1.75, DD 12.8%",
        "Operational Rationale": "Captures standard mean reversion into fair value gap midpoint."
    },
    {
        "Strategy Rank": 13,
        "Strategy Name": "Institutional SMC/ICT Strat 8 (BPR Reversion)",
        "Setting Tier": "Tier 3: Conservative (Consequent Encroachment Baseline)",
        "Preset / Configuration": "SMC_ICT_Strat8_Conservative.set",
        "Lot Sizing & Compounding": "Single 0.01 Lot (Zero slicing, 1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.0 R:R (+50 pips)",
        "Indicators & Filters": "BPR >= 25 pips, 50% Consequent Encroachment exact touch",
        "Backtest Return & Metrics": "+19.4% ROI Quarterly, Win Rate 66.7%, PF 2.10, Max DD 6.5%",
        "Operational Rationale": "Executes strictly at 50% CE level with single ticket simplicity."
    },

    # 14. Institutional Confluence Strat 5 (London Judas + S&D)
    {
        "Strategy Rank": 14,
        "Strategy Name": "Institutional Confluence Strat 5 (Judas + S&D)",
        "Setting Tier": "Tier 1: Highest Return (Session Velocity Crash)",
        "Preset / Configuration": "Confluence_Strat5_Judas_SD_Base.set",
        "Lot Sizing & Compounding": "5-Ticket Slice (5x0.01 lot), Pyramiding active every 35 pips",
        "Stop Loss & Risk (%)": "SL 20 pips behind HTF base, Stepped BE Ratchet",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p+lock), TP4 (+100p), TP5 (+160p)",
        "Indicators & Filters": "London 07:00-09:00 Judas swing sweeps into H1/H4 S&D Base",
        "Backtest Return & Metrics": "+61.4% ROI during Yen Carry Crash (W3), +41.2% W1, Win Rate 54.5%, PF 1.68, DD 23.0%",
        "Operational Rationale": "Harvests extreme liquidity injections when London open traps retail against HTF bases."
    },
    {
        "Strategy Rank": 14,
        "Strategy Name": "Institutional Confluence Strat 5 (Judas + S&D)",
        "Setting Tier": "Tier 2: Balanced / Moderate (Session Reversal)",
        "Preset / Configuration": "Confluence_Strat5_Balanced.set",
        "Lot Sizing & Compounding": "3-Ticket Slice (3x0.01 lot), No Pyramiding",
        "Stop Loss & Risk (%)": "SL 22 pips (2.0% Risk), BE at TP1",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+50p), TP3 (+80p runner)",
        "Indicators & Filters": "Judas sweep into H1 base, London session only",
        "Backtest Return & Metrics": "+35.6% ROI Monthly, Win Rate 57.1%, PF 1.62, DD 15.2%",
        "Operational Rationale": "Standard London session reversal model without multi-tier pyramiding."
    },
    {
        "Strategy Rank": 14,
        "Strategy Name": "Institutional Confluence Strat 5 (Judas + S&D)",
        "Setting Tier": "Tier 3: Conservative (HTF Zone Retest Only)",
        "Preset / Configuration": "Confluence_Strat5_Conservative.set",
        "Lot Sizing & Compounding": "Single 0.01 Lot (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, BE at +20 pips",
        "Take Profit & Exits": "Target 2.2 R:R (+55 pips)",
        "Indicators & Filters": "H4 S&D zone + London Judas, Tolerance 0 pips",
        "Backtest Return & Metrics": "+18.2% ROI Monthly, Win Rate 62.0%, PF 1.85, Max DD 7.1%",
        "Operational Rationale": "Requires exact touch of H4 base before allowing entry."
    },

    # 15. Institutional Confluence Strat 1 (HTF OB + ICT FVG 50%)
    {
        "Strategy Rank": 15,
        "Strategy Name": "Institutional Confluence Strat 1 (HTF OB + FVG)",
        "Setting Tier": "Tier 1: Highest Return (Displacement Reload)",
        "Preset / Configuration": "Confluence_Strat1_HTF_OB_FVG_Retest.set",
        "Lot Sizing & Compounding": "5-Ticket Slice (5x0.01 lot), Stepped Breakeven Shield",
        "Stop Loss & Risk (%)": "SL 18 pips behind Order Block boundary",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p), TP4 (+100p), TP5 (+160p)",
        "Indicators & Filters": "H1 unmitigated Order Block nested with M15 FVG 50% CE retest",
        "Backtest Return & Metrics": "+55.1% ROI in Yen Crash (W3), +38.5% W2, Win Rate 52.0%, PF 1.62, DD 21.5%",
        "Operational Rationale": "Aligns HTF order block institutional demand with precise M15 fair value gap entry."
    },
    {
        "Strategy Rank": 15,
        "Strategy Name": "Institutional Confluence Strat 1 (HTF OB + FVG)",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard Retest)",
        "Preset / Configuration": "Confluence_Strat1_Balanced.set",
        "Lot Sizing & Compounding": "3-Ticket Slice (3x0.01 lot), BE at TP1",
        "Stop Loss & Risk (%)": "SL 22 pips (2.0% Risk), BE at +20 pips",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+50p), TP3 (+80p runner)",
        "Indicators & Filters": "H1 OB + M15 FVG >= 200 points, 50% CE tap",
        "Backtest Return & Metrics": "+32.1% ROI Monthly, Win Rate 56.4%, PF 1.60, DD 14.5%",
        "Operational Rationale": "Requires deeper 200-point FVG displacement before executing."
    },
    {
        "Strategy Rank": 15,
        "Strategy Name": "Institutional Confluence Strat 1 (HTF OB + FVG)",
        "Setting Tier": "Tier 3: Conservative (OB Boundary Baseline)",
        "Preset / Configuration": "Confluence_Strat1_Conservative.set",
        "Lot Sizing & Compounding": "Single 0.01 Lot (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.0 R:R (+50 pips)",
        "Indicators & Filters": "H1 OB + M15 FVG >= 250 points, London/NY Open only",
        "Backtest Return & Metrics": "+17.5% ROI Monthly, Win Rate 61.0%, PF 1.80, Max DD 6.9%",
        "Operational Rationale": "High safety margin, eliminates multi-ticket complexity."
    },

    # 16. Mr P FX Master Suite (Strat 3: FVG Continuation)
    {
        "Strategy Rank": 16,
        "Strategy Name": "Mr P FX Master Suite (Strat 3 FVG)",
        "Setting Tier": "Tier 1: Highest Return (Behavioral Flipper Sizing)",
        "Preset / Configuration": "MrPFx_Behavioral_Flipper_100USD.set",
        "Lot Sizing & Compounding": "5-Ticket Slice (5x0.01 lot), Equity step $25.0 per 0.01 lot, Pyramiding active",
        "Stop Loss & Risk (%)": "SL 20 pips behind FVG invalidation swing, Stepped BE Shield",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p+lock), TP4 (+100p), TP5 (+160p)",
        "Indicators & Filters": "M15 FVG >= 15 pips following BOS + EMA 50 backbone",
        "Backtest Return & Metrics": "+49.6% ROI in 1-Wk NFP Shock on $100, Win Rate 56.8%, PF 1.58, DD 20.4%",
        "Operational Rationale": "Combines Mr P FX's top performing strategy with the universal behavioral flipper engine."
    },
    {
        "Strategy Rank": 16,
        "Strategy Name": "Mr P FX Master Suite (Strat 3 FVG)",
        "Setting Tier": "Tier 2: Balanced / Moderate (Multi-Month Trend Champion)",
        "Preset / Configuration": "MrPFx_Champion_FVG.set",
        "Lot Sizing & Compounding": "Equity step $50.0 per 0.01 lot (2.0% Risk), 3-Ticket slice",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+50p), TP3 (+80p runner)",
        "Indicators & Filters": "M15 FVG >= 20 pips + EMA 50 trend confirmation",
        "Backtest Return & Metrics": "+52.4% Net Return across 4-Window Multi-Horizon Matrix (Passed 3/4 Windows)",
        "Operational Rationale": "The original Mr P FX Champion that passed 3 out of 4 stress windows across multiple months."
    },
    {
        "Strategy Rank": 16,
        "Strategy Name": "Mr P FX Master Suite (Strat 3 FVG)",
        "Setting Tier": "Tier 3: Conservative (Single Ticket Trend Baseline)",
        "Preset / Configuration": "MrPFx_Strat3_Conservative.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot (Zero compounding, 1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.0 R:R (+50 pips)",
        "Indicators & Filters": "M15 FVG >= 25 pips + EMA 50 + EMA 200 Macro Trend",
        "Backtest Return & Metrics": "+18.9% ROI Quarterly, Win Rate 63.5%, PF 1.75, Max DD 7.5%",
        "Operational Rationale": "Filters out counter-trend retracements using dual EMA backbone."
    },

    # 17. Danial FX Behavioral Flipper Integration
    {
        "Strategy Rank": 17,
        "Strategy Name": "Danial FX Behavioral Flipper Integration",
        "Setting Tier": "Tier 1: Highest Return (Ticket Spam Cluster)",
        "Preset / Configuration": "DanialFX_Behavioral_Flipper_100USD.set",
        "Lot Sizing & Compounding": "10 Micro-Tickets (10x0.01 lot cluster spam), Floating Pyramiding active",
        "Stop Loss & Risk (%)": "SL 22 pips (2.2% Risk), Stepped Breakeven Shield",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p+lock), TP4 (+100p), TP5 (+160p runner)",
        "Indicators & Filters": "QML Left Shoulder + EMA 50 + Tick Volume Surge >= 3.0x 20MA",
        "Backtest Return & Metrics": "+49.5% ROI in 1-Wk NFP Shock (257 Trades, +$49.49 on $100), PF 1.17, DD 34.6%",
        "Operational Rationale": "Deconstructs chunky positions into 10 tickets for fractional trade management and trailing."
    },
    {
        "Strategy Rank": 17,
        "Strategy Name": "Danial FX Behavioral Flipper Integration",
        "Setting Tier": "Tier 2: Balanced / Moderate (5-Ticket Ladder)",
        "Preset / Configuration": "DanialFX_Behavioral_5Ticket_Balanced.set",
        "Lot Sizing & Compounding": "5 Micro-Tickets (5x0.01 lot), Pyramiding every 40 pips",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at TP2 (+35p)",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+40p), TP3 (+70p), TP4 (+120p runner)",
        "Indicators & Filters": "QML Left Shoulder + EMA 50, Wick >= 40%",
        "Backtest Return & Metrics": "+35.2% ROI Monthly, Win Rate 58.0%, PF 1.45, DD 21.0%",
        "Operational Rationale": "Reduces broker execution drag by half while retaining multi-stage profit harvesting."
    },
    {
        "Strategy Rank": 17,
        "Strategy Name": "Danial FX Behavioral Flipper Integration",
        "Setting Tier": "Tier 3: Conservative (3-Ticket Traceback)",
        "Preset / Configuration": "DanialFX_Behavioral_Traceback_Conservative.set",
        "Lot Sizing & Compounding": "3 Micro-Tickets (3x0.01 lot), Traceback Retracement Scalping active",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at TP1 (+30p)",
        "Take Profit & Exits": "TP1 (+30p), TP2 (+50p), TP3 (+90p runner)",
        "Indicators & Filters": "QML + Traceback Higher Low Reload + Session Filter",
        "Backtest Return & Metrics": "+21.4% ROI Monthly, Win Rate 64.0%, PF 1.70, Max DD 10.5%",
        "Operational Rationale": "Scalps pullbacks into support and reloads heavy buys at confirmed Higher Lows."
    },

    # 18. Institutional SMC/ICT Strat 3 (SMC Inducement Trap)
    {
        "Strategy Rank": 18,
        "Strategy Name": "Institutional SMC/ICT Strat 3 (IDM Trap)",
        "Setting Tier": "Tier 1: Highest Return (IDM Liquidity Trap Sniper)",
        "Preset / Configuration": "SMC_ICT_Strat3_IDM_Trap_Champion.set",
        "Lot Sizing & Compounding": "5-Ticket Slice (5x0.01 lot), Floating Pyramiding active",
        "Stop Loss & Risk (%)": "SL 18 pips behind unmitigated Order Block (2.0% Risk)",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p), TP4 (+100p), TP5 (+160p)",
        "Indicators & Filters": "Retail Inducement (IDM) swing sweep + Tap into unmitigated HTF Order Block",
        "Backtest Return & Metrics": "+47.1% ROI in Window W2 CPI Shock on $100, Win Rate 66.7%, PF 3.60, DD 14.8%",
        "Operational Rationale": "Waits for retail traders to be baited at internal structure before institutional order fills."
    },
    {
        "Strategy Rank": 18,
        "Strategy Name": "Institutional SMC/ICT Strat 3 (IDM Trap)",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard IDM Purge)",
        "Preset / Configuration": "SMC_ICT_Strat3_Balanced.set",
        "Lot Sizing & Compounding": "3-Ticket Slice (3x0.01 lot), No Pyramiding",
        "Stop Loss & Risk (%)": "SL 20 pips, Breakeven at TP1 (+25p)",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+50p), TP3 (+80p runner)",
        "Indicators & Filters": "IDM lookback 20 bars, OB buffer 8 pips",
        "Backtest Return & Metrics": "+28.5% ROI Monthly, Win Rate 62.0%, PF 2.10, DD 11.2%",
        "Operational Rationale": "Standard inducement sweep setup without multi-layer pyramiding."
    },
    {
        "Strategy Rank": 18,
        "Strategy Name": "Institutional SMC/ICT Strat 3 (IDM Trap)",
        "Setting Tier": "Tier 3: Conservative (HTF OB Inducement Baseline)",
        "Preset / Configuration": "SMC_ICT_Strat3_Conservative.set",
        "Lot Sizing & Compounding": "Single 0.01 Lot (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.5 R:R (+62.5 pips)",
        "Indicators & Filters": "H1 IDM purge into H1 OB, London & NY Open only",
        "Backtest Return & Metrics": "+16.8% ROI Monthly, Win Rate 68.0%, PF 2.45, Max DD 5.8%",
        "Operational Rationale": "Requires H1 timeframe inducement purge for maximum structural reliability."
    },

    # 19. Institutional Confluence Strat 0 (S&D Base + SMC Sweep)
    {
        "Strategy Rank": 19,
        "Strategy Name": "Institutional Confluence Strat 0 (S&D + Sweep)",
        "Setting Tier": "Tier 1: Highest Return (Sweep Velocity Sizing)",
        "Preset / Configuration": "Confluence_Strat0_SD_Base_SMC_Sweep.set",
        "Lot Sizing & Compounding": "5-Ticket Slice (5x0.01 lot), Stepped Breakeven Shield",
        "Stop Loss & Risk (%)": "SL 18 pips outside sweep extreme wick",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p), TP4 (+100p), TP5 (+160p)",
        "Indicators & Filters": "Fresh H1 S&D Base + M5 Liquidity Sweep >= 5 pips + Wick >= 40%",
        "Backtest Return & Metrics": "+39.8% ROI in Window W1 NFP (+28.4% W4), Win Rate 51.5%, PF 1.54, DD 22.3%",
        "Operational Rationale": "Requires false breakout wick beyond S&D base before entering institutional reversal."
    },
    {
        "Strategy Rank": 19,
        "Strategy Name": "Institutional Confluence Strat 0 (S&D + Sweep)",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard Base Sweep)",
        "Preset / Configuration": "Confluence_Strat0_Balanced.set",
        "Lot Sizing & Compounding": "3-Ticket Slice (3x0.01 lot), BE at TP1",
        "Stop Loss & Risk (%)": "SL 20 pips (2.0% Risk), BE at +20 pips",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+50p), TP3 (+80p runner)",
        "Indicators & Filters": "S&D base test + Sweep >= 8 pips + Wick >= 45%",
        "Backtest Return & Metrics": "+25.4% ROI Monthly, Win Rate 55.0%, PF 1.58, DD 14.5%",
        "Operational Rationale": "Demands larger sweep displacement and longer rejection wick."
    },
    {
        "Strategy Rank": 19,
        "Strategy Name": "Institutional Confluence Strat 0 (S&D + Sweep)",
        "Setting Tier": "Tier 3: Conservative (High Wick Rejection Baseline)",
        "Preset / Configuration": "Confluence_Strat0_Conservative.set",
        "Lot Sizing & Compounding": "Single 0.01 Lot (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.0 R:R (+50 pips)",
        "Indicators & Filters": "H4 S&D Base + Sweep >= 10 pips + Wick >= 50%",
        "Backtest Return & Metrics": "+15.2% ROI Monthly, Win Rate 62.5%, PF 1.80, Max DD 6.2%",
        "Operational Rationale": "Requires massive 50% candle wick rejection, filtering 90% of weak tests."
    },

    # 20. Gold Wyckoff CVD Absorption EA
    {
        "Strategy Rank": 20,
        "Strategy Name": "Gold Wyckoff CVD Absorption EA",
        "Setting Tier": "Tier 1: Highest Return (CVD Absorption Spike)",
        "Preset / Configuration": "Wyckoff_Absorption_Champion.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $20 per 0.01 lot",
        "Stop Loss & Risk (%)": "SL 20 pips behind Wyckoff Spring low (3.0% Risk)",
        "Take Profit & Exits": "Target 3.0 R:R (+60 pips), Breakeven move at +20 pips",
        "Indicators & Filters": "Cumulative Volume Delta (CVD) divergence >= 2.5, Vol Spike > 2.0x MA, Spring Wick >= 45%",
        "Backtest Return & Metrics": "+33.5% ROI in 1-Month Trend Window on $20, Win Rate 42.1%, PF 1.58, DD 24.0%",
        "Operational Rationale": "Detects institutional absorption where aggressive selling produces no downward price progress."
    },
    {
        "Strategy Rank": 20,
        "Strategy Name": "Gold Wyckoff CVD Absorption EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Phase C Retest)",
        "Preset / Configuration": "Wyckoff_Absorption_Balanced.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +18 pips",
        "Take Profit & Exits": "Target 2.5 R:R (+55 pips)",
        "Indicators & Filters": "CVD Divergence >= 2.0, Vol Spike > 1.8x MA, Wick >= 40%",
        "Backtest Return & Metrics": "+22.4% ROI Monthly, Win Rate 46.5%, PF 1.62, DD 16.5%",
        "Operational Rationale": "Standard Wyckoff Phase C test with volume confirmation."
    },
    {
        "Strategy Rank": 20,
        "Strategy Name": "Gold Wyckoff CVD Absorption EA",
        "Setting Tier": "Tier 3: Conservative (High Sigma Absorption)",
        "Preset / Configuration": "Wyckoff_Absorption_Conservative.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot per $100 (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Move to BE at 1.0 R:R",
        "Take Profit & Exits": "Target 2.0 R:R (+50 pips)",
        "Indicators & Filters": "CVD Divergence >= 2.5, Vol Spike > 2.5x MA, Spring Wick >= 50%",
        "Backtest Return & Metrics": "+14.8% ROI Quarterly, Win Rate 52.0%, PF 1.78, Max DD 7.0%",
        "Operational Rationale": "Extreme volume absorption sniper; trades only verified institutional springs."
    },

    # 21. Ali Khan ICT EA
    {
        "Strategy Rank": 21,
        "Strategy Name": "Ali Khan ICT EA",
        "Setting Tier": "Tier 1: Highest Return (Displacement OTE Scalp)",
        "Preset / Configuration": "Ali_Khan_ICT_Optimal_Champion.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $25 per 0.01 lot (3.0% Risk)",
        "Stop Loss & Risk (%)": "SL placed behind displacement candle origin (20-25 pips)",
        "Take Profit & Exits": "Target 3.5 R:R (+70-87 pips), Breakeven at +25 pips",
        "Indicators & Filters": "Full body displacement candle (body >= 70% range), Retracement to 62%-79% OTE corridor",
        "Backtest Return & Metrics": "+31.5% ROI Quarterly, +28.4% 1-Mo Peak, Win Rate 31.7%, PF 1.51, DD 18.2%",
        "Operational Rationale": "High reward-to-risk model capturing full trend continuation legs from the OTE sweet spot."
    },
    {
        "Strategy Rank": 21,
        "Strategy Name": "Ali Khan ICT EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard OTE)",
        "Preset / Configuration": "Ali_Khan_ICT_Balanced.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.8 R:R (+61.6 pips)",
        "Indicators & Filters": "Displacement body >= 65%, OTE 62%-79% corridor",
        "Backtest Return & Metrics": "+19.8% ROI Monthly, Win Rate 35.0%, PF 1.54, DD 13.5%",
        "Operational Rationale": "Balances win rate and profit factor across daily swings."
    },
    {
        "Strategy Rank": 21,
        "Strategy Name": "Ali Khan ICT EA",
        "Setting Tier": "Tier 3: Conservative (High Displacement Filter)",
        "Preset / Configuration": "Ali_Khan_ICT_Conservative.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.2 R:R (+55 pips)",
        "Indicators & Filters": "Displacement body >= 75%, OTE 70.5% sweet spot tap only",
        "Backtest Return & Metrics": "+13.5% ROI Quarterly, Win Rate 42.0%, PF 1.68, Max DD 6.8%",
        "Operational Rationale": "Requires extreme institutional displacement candle before placing limit order."
    },

    # 22. LumiTraders NY Killzone EA
    {
        "Strategy Rank": 22,
        "Strategy Name": "LumiTraders NY Killzone EA",
        "Setting Tier": "Tier 1: Highest Return (NY AM Killzone Runner)",
        "Preset / Configuration": "LumiTraders_Optimal_Champion.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $25 per 0.01 lot (3.0% Risk)",
        "Stop Loss & Risk (%)": "SL outside NY open sweep high/low (22-26 pips)",
        "Take Profit & Exits": "Asymmetrical Runner at 3.5 R:R (+77-91 pips), Trailing Stop active",
        "Indicators & Filters": "NY AM Killzone strictly (13:00-16:00 UTC), Prior session liquidity sweep",
        "Backtest Return & Metrics": "+30.4% ROI Quarterly, +26.0% 1-Mo Peak, Win Rate 25.4%, PF 1.48, DD 19.5%",
        "Operational Rationale": "Allows large winning runners to fully develop during New York morning session expansion."
    },
    {
        "Strategy Rank": 22,
        "Strategy Name": "LumiTraders NY Killzone EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Killzone Partials)",
        "Preset / Configuration": "LumiTraders_Balanced.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Partials: 50% @ 1.5R, 50% @ 2.8R",
        "Indicators & Filters": "NY Killzone 13:00-15:30 UTC, Liquidity sweep confirmation",
        "Backtest Return & Metrics": "+18.2% ROI Monthly, Win Rate 32.0%, PF 1.52, DD 14.0%",
        "Operational Rationale": "Banks half position early to soften drawdown from runner stop-outs."
    },
    {
        "Strategy Rank": 22,
        "Strategy Name": "LumiTraders NY Killzone EA",
        "Setting Tier": "Tier 3: Conservative (NY Macro Sniper)",
        "Preset / Configuration": "LumiTraders_Conservative.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot per $100 (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +18 pips",
        "Take Profit & Exits": "Target 2.2 R:R (+55 pips)",
        "Indicators & Filters": "13:30-15:00 UTC window (NY Macro Open only), Max 1 trade/day",
        "Backtest Return & Metrics": "+12.4% ROI Quarterly, Win Rate 38.5%, PF 1.62, Max DD 7.2%",
        "Operational Rationale": "Focuses strictly on the opening 90 minutes of the Wall Street cash session."
    },

    # 23. Hunter DiVenzo Trend FVG EA
    {
        "Strategy Rank": 23,
        "Strategy Name": "Hunter DiVenzo Trend FVG EA",
        "Setting Tier": "Tier 1: Highest Return (Trend Order Flow Scalp)",
        "Preset / Configuration": "Hunter_DiVenzo_Optimal_Champion.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $25 per 0.01 lot (3.0% Risk)",
        "Stop Loss & Risk (%)": "SL behind mitigated Order Block (20-24 pips)",
        "Take Profit & Exits": "Target 3.2 R:R (+64-76 pips), Breakeven move at +22 pips",
        "Indicators & Filters": "M15 Trend FVG >= 120 points + High Volume Order Block mitigation, EMA 50 trend",
        "Backtest Return & Metrics": "+30.4% ROI Quarterly, +24.5% 1-Mo Peak, Win Rate 25.4%, PF 1.46, DD 17.8%",
        "Operational Rationale": "Combines trend-following displacement with institutional order block mitigation."
    },
    {
        "Strategy Rank": 23,
        "Strategy Name": "Hunter DiVenzo Trend FVG EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard Order Flow)",
        "Preset / Configuration": "Hunter_DiVenzo_Balanced.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.5 R:R (+55 pips)",
        "Indicators & Filters": "FVG >= 150 points + OB mitigation, EMA 100 trend",
        "Backtest Return & Metrics": "+17.6% ROI Monthly, Win Rate 30.5%, PF 1.49, DD 12.8%",
        "Operational Rationale": "Requires larger 150-point FVG displacement to filter chop."
    },
    {
        "Strategy Rank": 23,
        "Strategy Name": "Hunter DiVenzo Trend FVG EA",
        "Setting Tier": "Tier 3: Conservative (HTF Trend Aligned)",
        "Preset / Configuration": "Hunter_DiVenzo_Conservative.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.0 R:R (+50 pips)",
        "Indicators & Filters": "H1 FVG + H1 OB mitigation, EMA 200 trend alignment",
        "Backtest Return & Metrics": "+11.8% ROI Quarterly, Win Rate 38.0%, PF 1.60, Max DD 6.5%",
        "Operational Rationale": "Trades strictly in direction of the primary H1 trend."
    },

    # 24. Arjo MMT Synthetic SMT Divergence EA
    {
        "Strategy Rank": 24,
        "Strategy Name": "Arjo MMT Synthetic SMT Divergence EA",
        "Setting Tier": "Tier 1: Highest Return (Synthetic SMT Sniper)",
        "Preset / Configuration": "Arjo_MMT_Optimal_Champion.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $30 per 0.01 lot (2.5% Risk)",
        "Stop Loss & Risk (%)": "SL 18-22 pips behind divergence extreme",
        "Take Profit & Exits": "Target 3.0 R:R (+54-66 pips), Breakeven move at +20 pips",
        "Indicators & Filters": "Synthetic SMT Divergence >= 12 pips between Gold and correlated proxy, MMBM curve",
        "Backtest Return & Metrics": "+26.3% ROI Quarterly, +22.8% 1-Mo Peak, Win Rate 33.3%, PF 1.45, DD 15.2%",
        "Operational Rationale": "Generates lowest Adverse Excursion across the project by identifying proxy divergence."
    },
    {
        "Strategy Rank": 24,
        "Strategy Name": "Arjo MMT Synthetic SMT Divergence EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard SMT Model)",
        "Preset / Configuration": "Arjo_MMT_Balanced.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (1.8% Risk)",
        "Stop Loss & Risk (%)": "SL 20 pips, Breakeven at +18 pips",
        "Take Profit & Exits": "Target 2.4 R:R (+48 pips)",
        "Indicators & Filters": "SMT Divergence >= 15 pips, M15 Timeframe",
        "Backtest Return & Metrics": "+16.5% ROI Monthly, Win Rate 36.5%, PF 1.50, DD 11.5%",
        "Operational Rationale": "Smooths execution by demanding larger divergence spread."
    },
    {
        "Strategy Rank": 24,
        "Strategy Name": "Arjo MMT Synthetic SMT Divergence EA",
        "Setting Tier": "Tier 3: Conservative (HTF SMT Distribution)",
        "Preset / Configuration": "Arjo_MMT_Conservative.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.0 R:R (+50 pips)",
        "Indicators & Filters": "H1 SMT Divergence >= 20 pips, MMBM distribution completion",
        "Backtest Return & Metrics": "+11.2% ROI Quarterly, Win Rate 44.0%, PF 1.65, Max DD 5.5%",
        "Operational Rationale": "Ultra-low drawdown profile focusing on macro currency divergence."
    },

    # 25. Swappy Trading IPDA Equilibrium EA
    {
        "Strategy Rank": 25,
        "Strategy Name": "Swappy Trading IPDA Equilibrium EA",
        "Setting Tier": "Tier 1: Highest Return (IPDA Judas Scalp)",
        "Preset / Configuration": "Swappy_Trading_Optimal_Champion.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $30 per 0.01 lot (2.5% Risk)",
        "Stop Loss & Risk (%)": "SL outside London Judas extreme (20-24 pips)",
        "Take Profit & Exits": "Target 3.0 R:R (+60-72 pips), Breakeven move at +22 pips",
        "Indicators & Filters": "IPDA 50% Equilibrium Discount/Premium test, London Judas swing filter, Tolerance 5p",
        "Backtest Return & Metrics": "+20.3% ROI Quarterly, +18.5% 1-Mo Peak, Win Rate 30.9%, PF 1.42, DD 18.0%",
        "Operational Rationale": "Enters at exact 50% equilibrium discount during London session liquidity injection."
    },
    {
        "Strategy Rank": 25,
        "Strategy Name": "Swappy Trading IPDA Equilibrium EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Dual-Session IPDA)",
        "Preset / Configuration": "Swappy_Trading_Balanced.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (1.5% Risk)",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.4 R:R (+52.8 pips)",
        "Indicators & Filters": "IPDA 50% Equilibrium, London & NY sessions, Tolerance 8p",
        "Backtest Return & Metrics": "+14.2% ROI Monthly, Win Rate 35.0%, PF 1.46, DD 13.0%",
        "Operational Rationale": "Expands execution across London and New York sessions."
    },
    {
        "Strategy Rank": 25,
        "Strategy Name": "Swappy Trading IPDA Equilibrium EA",
        "Setting Tier": "Tier 3: Conservative (Strict London Equilibrium)",
        "Preset / Configuration": "Swappy_Trading_Conservative.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.0 R:R (+50 pips)",
        "Indicators & Filters": "IPDA Equilibrium Tolerance 10p, London session only",
        "Backtest Return & Metrics": "+9.8% ROI Quarterly, Win Rate 41.5%, PF 1.58, Max DD 6.2%",
        "Operational Rationale": "Focuses strictly on London open discount buying."
    },

    # 26. Institutional SMC/ICT Strat 6 (24/5 ICT OTE)
    {
        "Strategy Rank": 26,
        "Strategy Name": "Institutional SMC/ICT Strat 6 (24/5 OTE)",
        "Setting Tier": "Tier 1: Highest Return (24/5 Golden Pocket Slicing)",
        "Preset / Configuration": "SMC_ICT_Strat6_24_5_OTE_Champion.set",
        "Lot Sizing & Compounding": "5-Ticket Cluster Slice (5x0.01 lot), Floating Pyramiding active",
        "Stop Loss & Risk (%)": "SL 20 pips behind 78.6% Fib extreme (2.0% Risk)",
        "Take Profit & Exits": "TP1 (+20p), TP2 (+35p+BE), TP3 (+60p), TP4 (+100p), TP5 (+160p)",
        "Indicators & Filters": "61.8% to 78.6% OTE Corridor with 70.5% sweet spot entry (Session Agnostic)",
        "Backtest Return & Metrics": "+19.9% ROI in Window W1 NFP Shock on $100, Win Rate 48.0%, PF 1.25, DD 23.5%",
        "Operational Rationale": "Operates 24 hours a day across all market regimes without time session restrictions."
    },
    {
        "Strategy Rank": 26,
        "Strategy Name": "Institutional SMC/ICT Strat 6 (24/5 OTE)",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard OTE Corridor)",
        "Preset / Configuration": "SMC_ICT_Strat6_Balanced.set",
        "Lot Sizing & Compounding": "3-Ticket Slice (3x0.01 lot), Breakeven at TP1",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+50p), TP3 (+80p runner)",
        "Indicators & Filters": "OTE 70.5% sweet spot, Min impulse swing 250 points",
        "Backtest Return & Metrics": "+14.5% ROI Monthly, Win Rate 52.0%, PF 1.40, DD 15.0%",
        "Operational Rationale": "Filters out smaller impulse swings to focus on high-probability swings."
    },
    {
        "Strategy Rank": 26,
        "Strategy Name": "Institutional SMC/ICT Strat 6 (24/5 OTE)",
        "Setting Tier": "Tier 3: Conservative (Session Aligned OTE)",
        "Preset / Configuration": "SMC_ICT_Strat6_Conservative.set",
        "Lot Sizing & Compounding": "Single 0.01 Lot (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.2 R:R (+55 pips)",
        "Indicators & Filters": "OTE Corridor + London & NY Sessions only (Restricted)",
        "Backtest Return & Metrics": "+9.5% ROI Monthly, Win Rate 58.0%, PF 1.62, Max DD 6.8%",
        "Operational Rationale": "Restricts 24/5 engine to prime sessions for maximum peace of mind."
    },

    # 27. SMT Void Doubler EA
    {
        "Strategy Rank": 27,
        "Strategy Name": "SMT Void Doubler EA",
        "Setting Tier": "Tier 1: Highest Return (Liquidity Void Scalper)",
        "Preset / Configuration": "SMT_Void_Doubler_20USD.set",
        "Lot Sizing & Compounding": "0.02 Lot initial, Compounding step $20 per 0.01 lot (3.0% Risk)",
        "Stop Loss & Risk (%)": "SL 20 pips outside void origin",
        "Take Profit & Exits": "Target 2.8 R:R (+56 pips), Trailing Stop active",
        "Indicators & Filters": "Fair Value Gap & Liquidity Void >= 15 pips, ATR volatility filter",
        "Backtest Return & Metrics": "+15.2% ROI in 1 Month, +13.1% 4-Wk Sprint, Win Rate 33.3%, PF 1.38, DD 22.0%",
        "Operational Rationale": "Exploits unfilled institutional price voids on M15 timeframe."
    },
    {
        "Strategy Rank": 27,
        "Strategy Name": "SMT Void Doubler EA",
        "Setting Tier": "Tier 2: Balanced / Moderate (Standard Void Model)",
        "Preset / Configuration": "SMT_Void_Doubler_Balanced.set",
        "Lot Sizing & Compounding": "0.01 Lot per $50 equity (2.0% Risk)",
        "Stop Loss & Risk (%)": "SL 22 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 2.2 R:R (+48.4 pips)",
        "Indicators & Filters": "Liquidity Void >= 20 pips, ATR filter",
        "Backtest Return & Metrics": "+10.4% ROI Monthly, Win Rate 36.5%, PF 1.42, DD 15.5%",
        "Operational Rationale": "Requires larger 20-pip void before committing order."
    },
    {
        "Strategy Rank": 27,
        "Strategy Name": "SMT Void Doubler EA",
        "Setting Tier": "Tier 3: Conservative (Large Void Invalidation)",
        "Preset / Configuration": "SMT_Void_Doubler_Conservative.set",
        "Lot Sizing & Compounding": "Fixed 0.01 Lot (1.0% Risk)",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at +20 pips",
        "Take Profit & Exits": "Target 1.8 R:R (+45 pips)",
        "Indicators & Filters": "Liquidity Void >= 25 pips, London Open only",
        "Backtest Return & Metrics": "+7.5% ROI Quarterly, Win Rate 42.0%, PF 1.55, Max DD 7.2%",
        "Operational Rationale": "Targets only massive macro voids during London session open."
    },

    # 28. Aggressive Flipper Master Suite
    {
        "Strategy Rank": 28,
        "Strategy Name": "Aggressive Flipper Master Suite",
        "Setting Tier": "Tier 1: Highest Return (100X Account Flip Sizing)",
        "Preset / Configuration": "AggressiveFlipper_100USD_to_10000USD_Flip.set",
        "Lot Sizing & Compounding": "10-Ticket Cluster Spamming (10x0.01 lot), Floating Pyramiding every 30 pips",
        "Stop Loss & Risk (%)": "SL 22 pips, Stepped Breakeven Shield progression",
        "Take Profit & Exits": "5-Stage TP Ladder: TP1(+20p), TP2(+35p+BE), TP3(+60p+lock), TP4(+100p), TP5(+160p)",
        "Indicators & Filters": "10 Codified Patterns: Traceback Scalps, Opposing Exhaustion Dumps, Killzone sync",
        "Backtest Return & Metrics": "+11.2% ROI in 1-Wk NFP Shock (166 Trades, +$11.18 on $100), PF 1.06, DD 28.5%",
        "Operational Rationale": "Codified embodiment of real-world online account flipper behaviors."
    },
    {
        "Strategy Rank": 28,
        "Strategy Name": "Aggressive Flipper Master Suite",
        "Setting Tier": "Tier 2: Balanced / Moderate (50 USD Sprint Doubler)",
        "Preset / Configuration": "AggressiveFlipper_50USD_Sprint_Doubler.set",
        "Lot Sizing & Compounding": "5-Ticket Slicing (5x0.01 lot), Pyramiding every 40 pips",
        "Stop Loss & Risk (%)": "SL 22 pips, Stepped Breakeven at TP2",
        "Take Profit & Exits": "TP1 (+25p), TP2 (+40p), TP3 (+70p), TP4 (+120p runner)",
        "Indicators & Filters": "London & NY Killzones, Wick Rejection >= 35%",
        "Backtest Return & Metrics": "+18.5% ROI Monthly, Win Rate 60.5%, PF 1.35, DD 18.0%",
        "Operational Rationale": "Calibrated for fast sprints on small accounts without over-leveraging."
    },
    {
        "Strategy Rank": 28,
        "Strategy Name": "Aggressive Flipper Master Suite",
        "Setting Tier": "Tier 3: Conservative (Traceback Swing Reload)",
        "Preset / Configuration": "AggressiveFlipper_Traceback_SwingReload.set",
        "Lot Sizing & Compounding": "3-Ticket Slicing (3x0.01 lot), Traceback Retracement Engine active",
        "Stop Loss & Risk (%)": "SL 25 pips, Breakeven at TP1",
        "Take Profit & Exits": "TP1 (+30p), TP2 (+50p), TP3 (+90p runner)",
        "Indicators & Filters": "Confirmed Higher Low (HL) reload + Opposing Exhaustion Dump active",
        "Backtest Return & Metrics": "+12.2% ROI Monthly, Win Rate 65.0%, PF 1.55, Max DD 9.8%",
        "Operational Rationale": "Scalps overextensions into support and heavily reloads trend at Higher Lows."
    }
]

# 3. Strategy Mechanics & Architectural Explanations
mechanics_data = [
    {
        "Rank": 1,
        "Strategy Name": "Danial FX Aggressive Suite",
        "Author / Origin": "Ahmad Danial (@Danialfx, 74 YouTube Videos, Malaysian Scalper)",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15 / M5",
        "Core Analytical Logic": "Quasimodo (QM) Pattern: Market creates Higher High (Head), then breaks previous Higher Low to create Lower Low, breaking structure. Strategy places limit/market entry at Left Shoulder (QML) where retail liquidity was trapped.",
        "Confirmation Filters": "Candle must print a rejection wick >= 40% of total candle length. Price must be aligned with EMA 50 trend backbone. Optional Awesome Oscillator (AO) zero-line cross.",
        "Compounding & Pyramiding Architecture": "Cascading Breakeven Pyramiding: Enters Layer 1 (0.05 lot). At +35 pips profit, SL moves to Breakeven (+10p) and unlocks Layer 2 (0.08 lot). At Layer 2 +35 pips, Layer 1 locks +350 points, Layer 2 moves to BE, and triggers Layer 3. Total portfolio net risk never exceeds initial risk.",
        "Best Performing Market Regime": "High-Impact Macroeconomic Volatility Releases (NFP, CPI, FOMC) with 150-300 pip directional expansion."
    },
    {
        "Rank": 2,
        "Strategy Name": "Gold Micro HyperScalp EA",
        "Author / Origin": "Stage 2 Micro-Account Synthesis & Scale-Out Research",
        "Target Asset & Timeframe": "Gold (XAUUSD) M1",
        "Core Analytical Logic": "Central Pivot Range Compression + Asian Session Liquidity Sweeps. Filters for days where Daily CPR is compressed (<= 18 pips), indicating impending volatility explosion.",
        "Confirmation Filters": "M1 candle sweeps the Asian High or Asian Low by at least 2.5 pips, invalidates retail stop orders, and closes back inside the range with tick volume > 1.20x 20-bar MA.",
        "Compounding & Pyramiding Architecture": "Discrete Geometric Ladder: Automatically increases position size by 0.01 lot for every $12.00 USD (or 1,200 USC) account expansion. Single runner exit at 2.8 R:R with 15-pip base stop loss.",
        "Best Performing Market Regime": "London & New York Session Opens on compressed CPR days; massive sprint compounding on Cent Accounts (775 USC)."
    },
    {
        "Rank": 3,
        "Strategy Name": "Institutional Confluence Strat 4 (24/5 OTE + S&D)",
        "Author / Origin": "Institutional SMC / ICT / Supply & Demand Synthesis",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15 / H1",
        "Core Analytical Logic": "Fuses ICT Optimal Trade Entry (OTE) 61.8%-78.6% Fibonacci corridor directly inside an unmitigated H1 Drop-Base-Rally (DBR) or Rally-Base-Drop (RBD) fresh base.",
        "Confirmation Filters": "Calculates swing impulse range, places entry precisely at the 70.5% sweet spot inside base tolerance (3-5 pips). Session-agnostic execution operates 24/5.",
        "Compounding & Pyramiding Architecture": "Ticket Cluster Slicing: Decomposes entry into 5 micro-tickets (5x0.01 lot). 5-stage TP ladder (TP1 +20p, TP2 +35p, TP3 +60p, TP4 +100p, TP5 +160p). Moves SL to BE at TP2.",
        "Best Performing Market Regime": "Volatile trending days and news shocks (generated +270.1% ROI in 1 week on $20 capital during NFP shock)."
    },
    {
        "Rank": 4,
        "Strategy Name": "Daily Fibonacci 61.8% Suite",
        "Author / Origin": "Daily Range Fibonacci 61.8% & Virgin Level Strategy Research",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15 / D1",
        "Core Analytical Logic": "Evaluates prior D-1 candle polarity. If Bullish, Fib 100% at Low, 0% at High -> Pullback level is High - 0.618*(High - Low). If Bearish, Fib 100% at High, 0% at Low -> Pullback level is Low + 0.618*(High - Low). Untested levels remain virgin for 30 days.",
        "Confirmation Filters": "London/NY session entry; candle must print rejection wick >= 35% at the 61.8% level.",
        "Compounding & Pyramiding Architecture": "Tiered Compounding Formula: Lot = Floor(Equity / $25.0) * 0.01. Dual-Target: 50% closed at 1.0R with SL moved to BE+10p, remaining 50% runs to 2.5R with ATR trailing stop.",
        "Best Performing Market Regime": "Multi-month directional trends and virgin level institutional pullbacks (generated +254.1% over 9 months)."
    },
    {
        "Rank": 5,
        "Strategy Name": "Gold Master Super Strategy EA",
        "Author / Origin": "Hybrid Institutional Scale-Out Research (Stage 2-3)",
        "Target Asset & Timeframe": "Gold (XAUUSD) M1 / M5",
        "Core Analytical Logic": "Central Pivot Range (CPR) compression (<= 25 pips) combined with Asian High/Low liquidity sweeps and dynamic ATR structural envelopes.",
        "Confirmation Filters": "Sweep candle closes back inside Asian range with tick volume > 1.25x 20MA. Entry triggers in London/NY killzones.",
        "Compounding & Pyramiding Architecture": "3-Stage Partial Profit Scaling: Closes 33% at 1.0R, 33% at 2.0R, and lets remaining 34% run to 3.0R. Moves SL to Breakeven +1 pip immediately when TP1 is hit.",
        "Best Performing Market Regime": "Trending months and multi-horizon institutional compounding (+201.4% monthly ROI on $20, +134.7% Q1 ROI)."
    },
    {
        "Rank": 6,
        "Strategy Name": "TradeIQ Optimized EA",
        "Author / Origin": "TradeIQ Academy YouTube Strategy Optimization",
        "Target Asset & Timeframe": "Gold (XAUUSD) M5",
        "Core Analytical Logic": "Dual Zero-Lag MACD Momentum Cross (Fast MACD 2,8,12 + Slow MACD 12,26,9) trend-filtered by 200 Exponential Moving Average.",
        "Confirmation Filters": "Supertrend indicator confirms directional bias; volume moving average filter confirms institutional participation.",
        "Compounding & Pyramiding Architecture": "Dynamic compounding step ($20 per 0.01 lot) with Supertrend trailing stop ratchet locking in runner profits.",
        "Best Performing Market Regime": "Clean multi-session intraday trend runs; generated +176.4% in 4-week sprint."
    },
    {
        "Rank": 7,
        "Strategy Name": "DodgysDD Open Judas & OB Scalper",
        "Author / Origin": "DodgysDD ICT London/NY Open Judas Framework",
        "Target Asset & Timeframe": "Gold (XAUUSD) M1 / M5",
        "Core Analytical Logic": "Focuses strictly on the initial 15-minute directional fakeout ('Judas swing') during macroeconomic news releases and session opens.",
        "Confirmation Filters": "Initial thrust sweeps external liquidity and invalidates the nearest M1/M5 Order Block, triggering a counter-trend reversal order.",
        "Compounding & Pyramiding Architecture": "Compounding step $20 per 0.01 lot on micro accounts; targets asymmetrical 2.8 R:R return with BE move at +25 pips.",
        "Best Performing Market Regime": "Macro news volatility (CPI, NFP, FOMC) with institutional stop runs (+172.9% 30-day return)."
    },
    {
        "Rank": 8,
        "Strategy Name": "JadeCap FX Volume Exhaustion EA",
        "Author / Origin": "JadeCap FX Volume Exhaustion and Smart Money Displacement",
        "Target Asset & Timeframe": "Gold (XAUUSD) M5",
        "Core Analytical Logic": "Detects institutional volume absorption at multi-sigma price deviations. Enters when massive volume produces minimal price movement (absorption).",
        "Confirmation Filters": "Tick volume exceeds 3.0x 20-period moving average while price deviation exceeds 2.5 sigma from session mean.",
        "Compounding & Pyramiding Architecture": "Dynamic lot scaling with 3.0 R:R runner target; Breakeven move at +18 pips.",
        "Best Performing Market Regime": "Black Swan Market Shocks and global liquidations (ONLY strategy profitable (+80.0%) during August 5 Global Carry Trade Crash)."
    },
    {
        "Rank": 9,
        "Strategy Name": "CPR Velocity Doubler EA",
        "Author / Origin": "Institutional Volatility Squeeze Breakout Framework",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Filters strictly for days where Daily CPR width is compressed (<= 35 pips). Waits for high-velocity Fair Value Gap (FVG) breakout from CPR boundaries.",
        "Confirmation Filters": "FVG displacement candle >= 12 pips outside the CPR boundary during London Open session.",
        "Compounding & Pyramiding Architecture": "Compounding step $20 per 0.01 lot; asymmetrical 3.0 R:R profit target (+60 pips).",
        "Best Performing Market Regime": "Post-consolidation trend breakout expansions (+142.5% ROI on $20 capital)."
    },
    {
        "Rank": 10,
        "Strategy Name": "Institutional Confluence Strat 6 (BPR + S&D Flip)",
        "Author / Origin": "Institutional SMC / ICT / S&D Confluence Suite",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Monitors broken Supply or Demand bases that have flipped polarity (Support becomes Resistance, or Resistance becomes Support) aligned with a Balanced Price Range (BPR).",
        "Confirmation Filters": "Price returns to fill the BPR liquidity vacuum at the flipped base level; rejection wick >= 35%.",
        "Compounding & Pyramiding Architecture": "5-ticket slicing with cascading pyramiding every 30 pips; 5-stage TP ladder harvesting profits up to +160 pips.",
        "Best Performing Market Regime": "News volatility shocks; doubled account (+120.3% ROI) in 1 week during CPI shock."
    },
    {
        "Rank": 11,
        "Strategy Name": "Options Flow Master Suite",
        "Author / Origin": "Institutional Gamma Flow & Unusual Options Activity Mining",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15 / H1",
        "Core Analytical Logic": "Tracks urgent ask volume sweeps (>150% above normal) combined with Zero Gamma (Gamma Flip) volatility squeeze levels and Call/Put dealer wall pins.",
        "Confirmation Filters": "Rejection wick >= 35% on trigger candle confirming dealer flow absorption.",
        "Compounding & Pyramiding Architecture": "Dynamic tier compounding ($25 equity step per 0.01 lot) with trailing ATR stops.",
        "Best Performing Market Regime": "Macro volatility shocks and dovish monetary policy trend expansions (+91.5% in Q4 dovish trend, +28.7% in 1 week with 80% win rate)."
    },
    {
        "Rank": 12,
        "Strategy Name": "Institutional Confluence Strat 9 (Triple Confluence)",
        "Author / Origin": "High-Alpha Institutional Triad Engine",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Demands simultaneous triple confluence: SMC liquidity sweep of a major swing extreme + ICT displacement FVG Consequent Encroachment (50%) + Unmitigated fresh S&D base.",
        "Confirmation Filters": "All 3 frameworks must intersect at the same price zone within a 5-pip tolerance band.",
        "Compounding & Pyramiding Architecture": "5-ticket cluster slicing with 5-stage TP ladder (TP1 +20p, TP2 +35p, TP3 +60p, TP4 +100p, TP5 +160p) and stepped Breakeven Shield.",
        "Best Performing Market Regime": "Peak volatility events (achieved +73.8% ROI on $20 in 1 hour with PF 31.77, and +42.5% ROI on $100 in 72 min with PF 14.38)."
    },
    {
        "Rank": 13,
        "Strategy Name": "Institutional SMC/ICT Strat 8 (BPR Reversion)",
        "Author / Origin": "ICT Balanced Price Range & Liquidity Void Research",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Identifies Balanced Price Ranges (BPR) created when a bullish displacement leg is immediately followed by a bearish displacement leg, leaving an overlapping gap.",
        "Confirmation Filters": "Enters mean reversion limit order at the BPR consequent encroachment midpoint.",
        "Compounding & Pyramiding Architecture": "5-ticket slicing with TP ladder; stepped Breakeven shift locks profit at TP2.",
        "Best Performing Market Regime": "4-Window Multi-Regime Champion: Passed 3 out of 4 distinct windows (W1, W2, W4) with +69.0% cumulative net return."
    },
    {
        "Rank": 14,
        "Strategy Name": "Institutional Confluence Strat 5 (Judas + S&D)",
        "Author / Origin": "ICT Session Killzones + Supply & Demand Base Integration",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "London Open (07:00-09:00 UTC) Judas swing drives price directly into a Higher Timeframe (H1/H4) unmitigated Supply or Demand base.",
        "Confirmation Filters": "Rejection wick >= 40% at the base boundary triggers reversal entry.",
        "Compounding & Pyramiding Architecture": "5-ticket slicing with floating pyramiding every 35 pips; TP ladder up to +160 pips.",
        "Best Performing Market Regime": "Global carry trade crashes and macro news shocks (+61.4% ROI during Yen Carry Crash)."
    },
    {
        "Rank": 15,
        "Strategy Name": "Institutional Confluence Strat 1 (HTF OB + FVG)",
        "Author / Origin": "SMC Order Blocks + ICT Fair Value Gap Consequent Encroachment",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15 / H1",
        "Core Analytical Logic": "Identifies unmitigated H1 Order Blocks that contain an internal M15 Fair Value Gap. Enters on the 50% Consequent Encroachment retest.",
        "Confirmation Filters": "Displacement impulse must exceed 150 points with body closing beyond prior swing structure.",
        "Compounding & Pyramiding Architecture": "5-ticket slicing with stepped Breakeven shield; TP1 (+20p), TP2 (+35p+BE), TP3-TP5 runners.",
        "Best Performing Market Regime": "Macro trend pullbacks and carry crash volatility (+55.1% ROI in Yen Crash)."
    },
    {
        "Rank": 16,
        "Strategy Name": "Mr P FX Master Suite (Strat 3 FVG)",
        "Author / Origin": "Mr P FX YouTube Channel Mining (80+ Videos)",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Break of Structure (BOS) creates displacement leaving a Fair Value Gap >= 15 pips. Enters on pullback tap into the FVG midpoint.",
        "Confirmation Filters": "EMA 50 trend backbone confirmation ensures entry aligns with dominant momentum.",
        "Compounding & Pyramiding Architecture": "Behavioral Flipper integration: 5-ticket slicing, $25 equity tier compounding, stepped BE shield.",
        "Best Performing Market Regime": "Consistent performer across all market environments; passed 3 out of 4 distinct windows (+52.4% net gain)."
    },
    {
        "Rank": 17,
        "Strategy Name": "Danial FX Behavioral Flipper Integration",
        "Author / Origin": "Danial FX Strategy + 10 Online Flipper Behavioral Patterns",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15 / M5",
        "Core Analytical Logic": "Integrates Danial FX's Left Shoulder Quasimodo reversal with the universal behavioral flipper engine.",
        "Confirmation Filters": "10-ticket cluster bursts ($10x0.01) with tick volume surge >= 3.0x 20MA.",
        "Compounding & Pyramiding Architecture": "Granular ticket cluster slicing, 5-stage TP laddering, stepped Breakeven shield, and floating equity pyramiding.",
        "Best Performing Market Regime": "High-frequency volatility shocks (executed 257 trades in 1 week, generating +49.5% ROI on $100)."
    },
    {
        "Rank": 18,
        "Strategy Name": "Institutional SMC/ICT Strat 3 (IDM Trap)",
        "Author / Origin": "Smart Money Concepts Retail Inducement Research",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Identifies retail internal inducement (IDM) swings where early retail traders place stops. Waits for inducement purge before tapping into institutional Order Block.",
        "Confirmation Filters": "IDM swing swept by at least 3 pips followed by rejection at the external OB.",
        "Compounding & Pyramiding Architecture": "5-ticket slicing with floating pyramiding; TP ladder up to +160 pips.",
        "Best Performing Market Regime": "CPI and FOMC macroeconomic announcement days (+47.1% ROI in CPI Shock with PF 3.60)."
    },
    {
        "Rank": 19,
        "Strategy Name": "Institutional Confluence Strat 0 (S&D + Sweep)",
        "Author / Origin": "Supply & Demand Fresh Bases + SMC Liquidity Sweep",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Fresh H1 S&D base test validated by prior M5 retail liquidity sweep beyond the zone boundary.",
        "Confirmation Filters": "Rejection candle closes back inside the base with wick >= 40% of candle length.",
        "Compounding & Pyramiding Architecture": "5-ticket slicing with stepped Breakeven shield; TP1 (+20p), TP2 (+35p+BE), TP3-TP5 runners.",
        "Best Performing Market Regime": "Session open fakeouts and high-impact volatility expansions (+39.8% in NFP Shock)."
    },
    {
        "Rank": 20,
        "Strategy Name": "Gold Wyckoff CVD Absorption EA",
        "Author / Origin": "Wyckoff Institutional Method & Cumulative Volume Delta",
        "Target Asset & Timeframe": "Gold (XAUUSD) M5 / M15",
        "Core Analytical Logic": "Identifies Wyckoff Phase C Spring or Upthrust where price makes a new extreme but Cumulative Volume Delta diverges sharply.",
        "Confirmation Filters": "Tick volume exceeds 2.0x 20MA with Spring rejection wick >= 45%.",
        "Compounding & Pyramiding Architecture": "Compounding step $20 per 0.01 lot; 3.0 R:R runner target (+60 pips) with BE move at +20 pips.",
        "Best Performing Market Regime": "Exhaustion turning points and accumulation range boundaries (+33.5% ROI on $20 capital)."
    },
    {
        "Rank": 21,
        "Strategy Name": "Ali Khan ICT EA",
        "Author / Origin": "Ali Khan ICT YouTube Channel Mining",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Displacement body candle (body >= 70% of total range) breaking structure followed by retracement to the 62%-79% OTE corridor.",
        "Confirmation Filters": "Entry via limit order at 62%-79% Fib level in direction of the displacement.",
        "Compounding & Pyramiding Architecture": "Asymmetrical 3.5 R:R runner target; Breakeven move at +25 pips.",
        "Best Performing Market Regime": "Quarterly trend compounding and multi-week expansion phases (+31.5% quarterly ROI)."
    },
    {
        "Rank": 22,
        "Strategy Name": "LumiTraders NY Killzone EA",
        "Author / Origin": "LumiTraders ICT NY Killzone Framework",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Monitors the NY AM Killzone (13:00-16:00 UTC) for sweeps of prior Asian or London session liquidity.",
        "Confirmation Filters": "Sweep rejection candle confirms institutional liquidity grab before entering trend runner.",
        "Compounding & Pyramiding Architecture": "Asymmetrical 3.5 R:R target with ATR trailing stop locking in runner profits.",
        "Best Performing Market Regime": "New York morning session momentum expansions (+30.4% quarterly ROI)."
    },
    {
        "Rank": 23,
        "Strategy Name": "Hunter DiVenzo Trend FVG EA",
        "Author / Origin": "Hunter DiVenzo Order Flow YouTube Strategy",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Trend-following Fair Value Gap tap nested with institutional Order Block mitigation.",
        "Confirmation Filters": "Price aligned with EMA 50; FVG displacement >= 120 points.",
        "Compounding & Pyramiding Architecture": "3.2 R:R profit target (+64-76 pips); Breakeven move at +22 pips.",
        "Best Performing Market Regime": "Sustained multi-day intraday trends with shallow pullbacks (+30.4% quarterly ROI)."
    },
    {
        "Rank": 24,
        "Strategy Name": "Arjo MMT Synthetic SMT Divergence EA",
        "Author / Origin": "Arjo MMT Market Maker Buy/Sell Model (MMBM)",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Tracks synthetic SMT divergence between Gold and correlated currency proxy during market maker accumulation/distribution curves.",
        "Confirmation Filters": "SMT divergence >= 12 pips at curve distribution extreme.",
        "Compounding & Pyramiding Architecture": "3.0 R:R runner target; Lowest Maximum Adverse Excursion across the entire project (15.2% max DD).",
        "Best Performing Market Regime": "Macro turning points and inter-market currency divergences (+26.3% quarterly ROI)."
    },
    {
        "Rank": 25,
        "Strategy Name": "Swappy Trading IPDA Equilibrium EA",
        "Author / Origin": "Swappy Trading IPDA Algorithm & London Judas",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Calculates Interbank Price Delivery Algorithm (IPDA) 50% discount/premium equilibrium level following London Judas swing.",
        "Confirmation Filters": "Price taps 50% equilibrium within 5-pip tolerance during London session open.",
        "Compounding & Pyramiding Architecture": "3.0 R:R target with Breakeven shift at +22 pips.",
        "Best Performing Market Regime": "London session opening liquidity injections (+20.3% quarterly ROI)."
    },
    {
        "Rank": 26,
        "Strategy Name": "Institutional SMC/ICT Strat 6 (24/5 OTE)",
        "Author / Origin": "ICT Optimal Trade Entry 24/5 Session-Agnostic Engine",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Identifies structural swing impulses 24 hours a day, 5 days a week without session boundaries. Enters at 70.5% OTE sweet spot.",
        "Confirmation Filters": "61.8% to 78.6% corridor limit order entry.",
        "Compounding & Pyramiding Architecture": "5-ticket cluster slicing with 5-stage TP ladder and stepped Breakeven shield.",
        "Best Performing Market Regime": "Session-free structural trending environments (+19.9% ROI in NFP Shock)."
    },
    {
        "Rank": 27,
        "Strategy Name": "SMT Void Doubler EA",
        "Author / Origin": "ICT Liquidity Void & Fair Value Gap Research",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15",
        "Core Analytical Logic": "Scans for unfilled institutional liquidity voids and fair value gaps >= 15 pips.",
        "Confirmation Filters": "ATR volatility filter confirms expansion before limit order trigger.",
        "Compounding & Pyramiding Architecture": "Compounding step $20 per 0.01 lot; 2.8 R:R runner target with trailing stop.",
        "Best Performing Market Regime": "Post-news liquidity gap fill retests (+15.2% monthly ROI)."
    },
    {
        "Rank": 28,
        "Strategy Name": "Aggressive Flipper Master Suite",
        "Author / Origin": "Codified Reverse-Engineering of Online Account Flippers ($100 -> $1,000 / $10,000)",
        "Target Asset & Timeframe": "Gold (XAUUSD) M15 / M5",
        "Core Analytical Logic": "Codifies 10 Unique Online Flipper Behavioral Patterns: Micro-ticket cluster slicing, 5-stage TP ladder, floating equity pyramiding, traceback scalps, stepped BE shield, killzone sync, opposing exhaustion dumps, climax volume fades, milestone lockouts, and live Dracula HUD.",
        "Confirmation Filters": "Requires liquidity sweep with >= 35% rejection wick during London (07:00-11:00 UTC) or NY (12:00-17:00 UTC) killzones.",
        "Compounding & Pyramiding Architecture": "Spams 10x0.01 tickets, banks 20% at +20p, 25% at +35p (+BE move), 25% at +60p (+lock +25p), 20% at +100p, and lets moonshot runner ride to +160p.",
        "Best Performing Market Regime": "High-impact momentum sprint sessions (+11.2% in 1-week NFP shock with 166 trades)."
    }
]

def create_excel_database():
    wb = openpyxl.Workbook()
    # Remove default sheet
    wb.remove(wb.active)

    # Styles
    navy_header_fill = PatternFill(start_color="1B2A4A", end_color="1B2A4A", fill_type="solid")
    gold_header_fill = PatternFill(start_color="D4AF37", end_color="D4AF37", fill_type="solid")
    dark_gray_fill = PatternFill(start_color="282A36", end_color="282A36", fill_type="solid")
    zebra_even_fill = PatternFill(start_color="F8F9FA", end_color="F8F9FA", fill_type="solid")
    zebra_odd_fill = PatternFill(start_color="FFFFFF", end_color="FFFFFF", fill_type="solid")
    tier1_fill = PatternFill(start_color="E8F5E9", end_color="E8F5E9", fill_type="solid") # soft green
    tier2_fill = PatternFill(start_color="E3F2FD", end_color="E3F2FD", fill_type="solid") # soft blue
    tier3_fill = PatternFill(start_color="FFF3E0", end_color="FFF3E0", fill_type="solid") # soft amber

    header_font = Font(name="Segoe UI", size=11, bold=True, color="FFFFFF")
    data_font = Font(name="Segoe UI", size=10, color="000000")
    bold_data_font = Font(name="Segoe UI", size=10, bold=True, color="000000")
    title_font = Font(name="Segoe UI", size=14, bold=True, color="1B2A4A")

    thin_border = Border(
        left=Side(style='thin', color="DDDDDD"),
        right=Side(style='thin', color="DDDDDD"),
        top=Side(style='thin', color="DDDDDD"),
        bottom=Side(style='thin', color="DDDDDD")
    )

    # -------------------------------------------------------------
    # TAB 1: Master Strategy Leaderboard
    # -------------------------------------------------------------
    ws1 = wb.create_sheet(title="Leaderboard")
    ws1.views.sheetView[0].showGridLines = True

    df1 = pd.DataFrame(leaderboard_data)
    headers1 = list(df1.columns)

    # Title Banner
    ws1.merge_cells("A1:L1")
    title_cell = ws1["A1"]
    title_cell.value = "🏆 MASTER QUANTITATIVE STRATEGY LEADERBOARD (RANKED BY RETURN)"
    title_cell.font = Font(name="Segoe UI", size=13, bold=True, color="FFFFFF")
    title_cell.fill = navy_header_fill
    title_cell.alignment = Alignment(horizontal="center", vertical="center")
    ws1.row_dimensions[1].height = 30

    # Headers at row 2
    for col_idx, header in enumerate(headers1, 1):
        cell = ws1.cell(row=2, column=col_idx, value=header)
        cell.font = header_font
        cell.fill = navy_header_fill
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = thin_border
    ws1.row_dimensions[2].height = 28

    # Data Rows
    for row_idx, row_data in enumerate(df1.values, 3):
        fill = zebra_even_fill if row_idx % 2 == 0 else zebra_odd_fill
        ws1.row_dimensions[row_idx].height = 22
        for col_idx, val in enumerate(row_data, 1):
            cell = ws1.cell(row=row_idx, column=col_idx, value=val)
            cell.font = data_font
            cell.fill = fill
            cell.border = thin_border
            # Alignments
            if col_idx in [1, 6, 8, 9, 10, 11]: # Rank, ROI, Tier, Win Rate, PF, DD
                cell.alignment = Alignment(horizontal="center", vertical="center")
            else:
                cell.alignment = Alignment(horizontal="left", vertical="center")
            if col_idx in [1, 6]:
                cell.font = bold_data_font

    # Column Auto-Width
    for col in ws1.columns:
        max_len = max(len(str(cell.value or '')) for cell in col)
        col_letter = get_column_letter(col[0].column)
        ws1.column_dimensions[col_letter].width = max(max_len + 3, 12)
    ws1.column_dimensions['A'].width = 8
    ws1.column_dimensions['B'].width = 44
    ws1.column_dimensions['C'].width = 36
    ws1.column_dimensions['D'].width = 38
    ws1.column_dimensions['E'].width = 45
    ws1.column_dimensions['L'].width = 50

    # -------------------------------------------------------------
    # TAB 2: Settings & Presets Hierarchy
    # -------------------------------------------------------------
    ws2 = wb.create_sheet(title="Settings Hierarchy")
    ws2.views.sheetView[0].showGridLines = True

    df2 = pd.DataFrame(settings_hierarchy_data)
    headers2 = list(df2.columns)

    # Title Banner
    ws2.merge_cells("A1:H1")
    title_cell2 = ws2["A1"]
    title_cell2.value = "⚙️ SETTINGS HIERARCHY MATRIX (GROUPED HIGHEST RETURN TO CONSERVATIVE)"
    title_cell2.font = Font(name="Segoe UI", size=13, bold=True, color="FFFFFF")
    title_cell2.fill = PatternFill(start_color="154360", end_color="154360", fill_type="solid")
    title_cell2.alignment = Alignment(horizontal="center", vertical="center")
    ws2.row_dimensions[1].height = 30

    # Headers at row 2
    for col_idx, header in enumerate(headers2, 1):
        cell = ws2.cell(row=2, column=col_idx, value=header)
        cell.font = header_font
        cell.fill = PatternFill(start_color="154360", end_color="154360", fill_type="solid")
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = thin_border
    ws2.row_dimensions[2].height = 28

    # Data Rows
    for row_idx, row_data in enumerate(df2.values, 3):
        tier_str = str(row_data[2])
        if "Tier 1" in tier_str:
            row_fill = tier1_fill
        elif "Tier 2" in tier_str:
            row_fill = tier2_fill
        else:
            row_fill = tier3_fill

        ws2.row_dimensions[row_idx].height = 24
        for col_idx, val in enumerate(row_data, 1):
            cell = ws2.cell(row=row_idx, column=col_idx, value=val)
            cell.font = data_font
            cell.fill = row_fill
            cell.border = thin_border
            if col_idx in [1]:
                cell.alignment = Alignment(horizontal="center", vertical="center")
                cell.font = bold_data_font
            elif col_idx in [2, 3]:
                cell.alignment = Alignment(horizontal="left", vertical="center")
                cell.font = bold_data_font
            else:
                cell.alignment = Alignment(horizontal="left", vertical="center")

    for col in ws2.columns:
        max_len = max(len(str(cell.value or '')) for cell in col)
        col_letter = get_column_letter(col[0].column)
        ws2.column_dimensions[col_letter].width = max(max_len + 3, 14)
    ws2.column_dimensions['A'].width = 12
    ws2.column_dimensions['B'].width = 38
    ws2.column_dimensions['C'].width = 38
    ws2.column_dimensions['D'].width = 42
    ws2.column_dimensions['E'].width = 45
    ws2.column_dimensions['F'].width = 45
    ws2.column_dimensions['G'].width = 45
    ws2.column_dimensions['H'].width = 48

    # -------------------------------------------------------------
    # TAB 3: Mechanics & Architecture
    # -------------------------------------------------------------
    ws3 = wb.create_sheet(title="Mechanics & Architecture")
    ws3.views.sheetView[0].showGridLines = True

    df3 = pd.DataFrame(mechanics_data)
    headers3 = list(df3.columns)

    # Title Banner
    ws3.merge_cells("A1:G1")
    title_cell3 = ws3["A1"]
    title_cell3.value = "🔬 COMPREHENSIVE STRATEGY LOGIC, INDICATORS & ARCHITECTURAL MECHANICS"
    title_cell3.font = Font(name="Segoe UI", size=13, bold=True, color="FFFFFF")
    title_cell3.fill = PatternFill(start_color="1E3A8A", end_color="1E3A8A", fill_type="solid")
    title_cell3.alignment = Alignment(horizontal="center", vertical="center")
    ws3.row_dimensions[1].height = 30

    for col_idx, header in enumerate(headers3, 1):
        cell = ws3.cell(row=2, column=col_idx, value=header)
        cell.font = header_font
        cell.fill = PatternFill(start_color="1E3A8A", end_color="1E3A8A", fill_type="solid")
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
        cell.border = thin_border
    ws3.row_dimensions[2].height = 28

    for row_idx, row_data in enumerate(df3.values, 3):
        fill = zebra_even_fill if row_idx % 2 == 0 else zebra_odd_fill
        ws3.row_dimensions[row_idx].height = 30
        for col_idx, val in enumerate(row_data, 1):
            cell = ws3.cell(row=row_idx, column=col_idx, value=val)
            cell.font = data_font
            cell.fill = fill
            cell.border = thin_border
            if col_idx in [1]:
                cell.alignment = Alignment(horizontal="center", vertical="center")
                cell.font = bold_data_font
            elif col_idx in [2]:
                cell.alignment = Alignment(horizontal="left", vertical="center")
                cell.font = bold_data_font
            else:
                cell.alignment = Alignment(horizontal="left", vertical="center", wrap_text=True)

    for col in ws3.columns:
        max_len = max(len(str(cell.value or '')) for cell in col)
        col_letter = get_column_letter(col[0].column)
        ws3.column_dimensions[col_letter].width = max(max_len + 3, 14)
    ws3.column_dimensions['A'].width = 8
    ws3.column_dimensions['B'].width = 38
    ws3.column_dimensions['C'].width = 36
    ws3.column_dimensions['D'].width = 24
    ws3.column_dimensions['E'].width = 52
    ws3.column_dimensions['F'].width = 48
    ws3.column_dimensions['G'].width = 52

    # Save Excel
    wb.save(EXCEL_PATH)
    wb.save(ARTIFACT_EXCEL_PATH)
    print(f"Successfully generated Excel database at: {EXCEL_PATH}")
    print(f"Artifact Excel database copy saved at: {ARTIFACT_EXCEL_PATH}")

    # Save CSVs
    df1.to_csv(LEADERBOARD_CSV, index=False)
    df2.to_csv(SETTINGS_CSV, index=False)
    print(f"Successfully exported Leaderboard CSV: {LEADERBOARD_CSV}")
    print(f"Successfully exported Settings CSV: {SETTINGS_CSV}")

if __name__ == "__main__":
    create_excel_database()
