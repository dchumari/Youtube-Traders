"""
Script to update Master Quantitative Strategies Database with:
- Chart Fanatics Masterclasses (Master Hybrid, Kris Verma, Matteo Conti ORB, Crudele, Trader Yush)
- Grand Master Hybrid Suite (Multi-Horizon benchmarks across $100 and $20 tiers)
- Re-rank all 34 strategies from #1 to #34
- Re-generate Excel and CSV files
- Update MASTER_QUANTITATIVE_STRATEGIES_DATABASE.md
"""

import os
import json
import pandas as pd
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

REPORTS_DIR = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\reports"
ARTIFACT_DIR = r"C:\Users\user\.gemini\antigravity\brain\2d2e95f5-1cb0-4f28-8f7d-321666504597"
EXCEL_PATH = os.path.join(REPORTS_DIR, "MASTER_TRADING_STRATEGIES_DATABASE.xlsx")
ARTIFACT_EXCEL_PATH = os.path.join(ARTIFACT_DIR, "MASTER_TRADING_STRATEGIES_DATABASE.xlsx")
LEADERBOARD_CSV = os.path.join(REPORTS_DIR, "MASTER_ALL_STRATEGIES_RANKING.csv")
SETTINGS_CSV = os.path.join(REPORTS_DIR, "MASTER_STRATEGY_SETTINGS_HIERARCHY.csv")
MD_DATABASE_PATH = os.path.join(ARTIFACT_DIR, "MASTER_QUANTITATIVE_STRATEGIES_DATABASE.md")

os.makedirs(REPORTS_DIR, exist_ok=True)
os.makedirs(ARTIFACT_DIR, exist_ok=True)

# 34 Complete Ranked Strategies
strategies = [
    {
        "Rank": 1,
        "Strategy Name": "Gold Micro HyperScalp EA (Sprint Champion)",
        "EA File": "Gold_Micro_HyperScalp_EA.mq5",
        "Preset Name": "Micro_20USD_Doubling_Champion.set",
        "Core Archetype": "CPR Squeeze (<=18p) + Asian Sweep Rejection + Geometric Step",
        "Peak ROI (%)": "+672.5%",
        "Horizon / Regime Window": "4-Week Sprint / 1-Mo Peak (+192.0%)",
        "Capital Tier": "$20 USD / 775 USC",
        "Win Rate (%)": "43.8%",
        "Profit Factor": "2.14",
        "Max Drawdown (%)": "28.4%",
        "Multi-Window Status": "Tier 1 Sprint Engine / Cent Account Champion",
        "Execution Mechanism": "Narrow CPR filter + Tick Volume Spike >1.2x + 2.8R Single Runner"
    },
    {
        "Rank": 2,
        "Strategy Name": "Danial FX Aggressive Suite (Quasimodo Flipper)",
        "EA File": "DanialFX_Aggressive_Suite.mq5",
        "Preset Name": "DanialFX_100USD_to_10000USD_Flip.set",
        "Core Archetype": "Quasimodo Left Shoulder Reversal + Floating Margin Pyramiding",
        "Peak ROI (%)": "+336.6%",
        "Horizon / Regime Window": "1-Week NFP Volatility Shock",
        "Capital Tier": "$100 USD",
        "Win Rate (%)": "78.6%",
        "Profit Factor": "1.84",
        "Max Drawdown (%)": "51.7%",
        "Multi-Window Status": "Passed W1 (+336.6%) & W2 (+123.7%)",
        "Execution Mechanism": "QML Sniper Wick >=40% + 6-Layer Cascading Breakeven Pyramiding"
    },
    {
        "Rank": 3,
        "Strategy Name": "Institutional Confluence Strat 4 (24/5 ICT OTE + S&D)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat4_24_5_OTE_SD_Base_20USD.set",
        "Core Archetype": "24/5 ICT OTE 70.5% Golden Pocket nested in H1 S&D Fresh Base",
        "Peak ROI (%)": "+270.1%",
        "Horizon / Regime Window": "1-Week NFP Shock (+$54.01 on $20)",
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
        "Horizon / Regime Window": "9-Month Compounding (+24.6% 1-Wk NFP)",
        "Capital Tier": "$100 USD / $50 USD",
        "Win Rate (%)": "58.2%",
        "Profit Factor": "1.52",
        "Max Drawdown (%)": "18.5%",
        "Multi-Window Status": "Robust Long-Term Trend & Virgin Reaction Engine",
        "Execution Mechanism": "D-1 Fib 61.8% pullback + Wick >=35% + Dual TP (1.0R & 2.5R Runner)"
    },
    {
        "Rank": 5,
        "Strategy Name": "Grand Master Hybrid EA (Weekly $20 Doubler)",
        "EA File": "Grand_Master_Hybrid_EA.mq5",
        "Preset Name": "GMH_Weekly_Sprint_Doubler_20USD.set",
        "Core Archetype": "Bank ORB + ICT OTE 70.5% + Danial QM + Verma Parabolic Fade",
        "Peak ROI (%)": "+201.6%",
        "Horizon / Regime Window": "1-Week NFP Shock (+$40.31 on $20 / +137.4% W3)",
        "Capital Tier": "$20 USD / 775 USC",
        "Win Rate (%)": "55.0%",
        "Profit Factor": "1.63",
        "Max Drawdown (%)": "28.7%",
        "Multi-Window Status": "Passed 3/4 Event Windows (Cumulative +$69.74 / +348.7%)",
        "Execution Mechanism": "Autonomous Multi-Regime Fusion + Stepped BE Shield + 5-Stage TP Ladder"
    },
    {
        "Rank": 6,
        "Strategy Name": "Gold Master Super Strategy EA (Hybrid Doubler)",
        "EA File": "Gold_Master_Super_EA.mq5",
        "Preset Name": "Gold_Master_Super_EA_20USD_Doubler.set",
        "Core Archetype": "Asian Sweep + CPR Compression + 3-Stage Partial Scale-Out",
        "Peak ROI (%)": "+201.4%",
        "Horizon / Regime Window": "1-Month Peak (+197.0% 4-Wk Sprint)",
        "Capital Tier": "$20 USD / $1,000 USD",
        "Win Rate (%)": "63.2%",
        "Profit Factor": "2.38",
        "Max Drawdown (%)": "21.0%",
        "Multi-Window Status": "Passed Q1 (+134.7%) & 30-Day Benchmark",
        "Execution Mechanism": "Asian H/L sweep + CPR <=25p + 33% @ 1R, 33% @ 2R, 34% @ 3R runner"
    },
    {
        "Rank": 7,
        "Strategy Name": "TradeIQ Optimized EA (Dual MACD Supertrend)",
        "EA File": "TradeIQ_Opt_EA.mq5",
        "Preset Name": "TradeIQ_Academy_EA_20USD_Doubler.set",
        "Core Archetype": "Dual Zero-Lag MACD Momentum + 200 EMA + Supertrend Trailing",
        "Peak ROI (%)": "+176.4%",
        "Horizon / Regime Window": "4-Week Sprint (+167.7% 1-Mo Peak)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "40.0%",
        "Profit Factor": "1.74",
        "Max Drawdown (%)": "26.2%",
        "Multi-Window Status": "Tier 1 Balanced Trend Compounding",
        "Execution Mechanism": "Fast MACD(2,8,12) & Slow MACD(12,26,9) zero-cross above 200 EMA"
    },
    {
        "Rank": 8,
        "Strategy Name": "DodgysDD Open Judas & OB Scalper",
        "EA File": "DodgysDD_EA.mq5",
        "Preset Name": "DodgysDD_EA_20USD_Doubler.set",
        "Core Archetype": "High-Impact Macro News Judas Swing + M1/M5 OB Invalidation Reversal",
        "Peak ROI (%)": "+172.9%",
        "Horizon / Regime Window": "30-Day Window (+171.0% 1-Mo Peak)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "35.1%",
        "Profit Factor": "1.68",
        "Max Drawdown (%)": "31.4%",
        "Multi-Window Status": "High-Impact Volatility News Specialist",
        "Execution Mechanism": "Initial 15m thrust sweeps liquidity, invalidates OB -> 2.8R reversal"
    },
    {
        "Rank": 9,
        "Strategy Name": "Chart Fanatics Master Institutional Hybrid",
        "EA File": "ChartFanatics_Master_Suite.mq5",
        "Preset Name": "CF_Master_Hybrid_Optimal.set",
        "Core Archetype": "Matteo ORB + Value Area Absorption + Flipper Compounding",
        "Peak ROI (%)": "+171.3%",
        "Horizon / Regime Window": "4 Random Weeks Total (+83.4% Single Week W_Rand4)",
        "Capital Tier": "$100 USD",
        "Win Rate (%)": "52.4%",
        "Profit Factor": "2.19",
        "Max Drawdown (%)": "26.4%",
        "Multi-Window Status": "Passed 4/4 Random Weeks (100% Pass) & +30.6% 1-Year Unassisted",
        "Execution Mechanism": "15m ORB + Session VWAP + 70% VA Retest + 5-Stage TP Laddering"
    },
    {
        "Rank": 10,
        "Strategy Name": "JadeCap FX Volume Exhaustion EA",
        "EA File": "JadeCap_FX_EA.mq5",
        "Preset Name": "JadeCap_FX_Optimal_Champion.set",
        "Core Archetype": "Volume Exhaustion Absorption + Multi-Sigma Anti-Trend Hedging",
        "Peak ROI (%)": "+156.3%",
        "Horizon / Regime Window": "4-Week Sprint (+80.0% Crash Week)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "38.2%",
        "Profit Factor": "1.62",
        "Max Drawdown (%)": "22.8%",
        "Multi-Window Status": "Only strategy profitable (+80%) during Aug 5 Carry Trade Crash",
        "Execution Mechanism": "Tick volume >3x 20MA at extreme deviation produce reversal scalp"
    },
    {
        "Rank": 11,
        "Strategy Name": "CPR Velocity Doubler EA",
        "EA File": "CPR_Velocity_Doubler_EA.mq5",
        "Preset Name": "CPR_Velocity_Doubler_20USD.set",
        "Core Archetype": "Compressed CPR (<=35p) + FVG Velocity Expansion Breakout",
        "Peak ROI (%)": "+142.5%",
        "Horizon / Regime Window": "30-Day Window (+105.2% 1-Mo Peak)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "50.0%",
        "Profit Factor": "1.95",
        "Max Drawdown (%)": "19.4%",
        "Multi-Window Status": "Low-Frequency High-Alpha Sniper",
        "Execution Mechanism": "CPR width <=35p + FVG displacement breakout + trailing runner"
    },
    {
        "Rank": 12,
        "Strategy Name": "Institutional Confluence Strat 6 (BPR + S&D Flip)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat6_BPR_SD_Flip_20USD.set",
        "Core Archetype": "Violated S&D Base Polarity Flip + Balanced Price Range Reversion",
        "Peak ROI (%)": "+120.3%",
        "Horizon / Regime Window": "1-Week CPI Shock on $20 (+51.0% on $100)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "57.1%",
        "Profit Factor": "1.82",
        "Max Drawdown (%)": "24.3%",
        "Multi-Window Status": "Passed W2 (+120.3%) & W4 (+30.3%)",
        "Execution Mechanism": "S&D broken base becomes polarity flip + BPR twin displacement vacuum"
    },
    {
        "Rank": 13,
        "Strategy Name": "Kris Verma Parabolic Gap Exhaustion Short",
        "EA File": "ChartFanatics_Master_Suite.mq5",
        "Preset Name": "CF_KrisVerma_GapShort_Optimal.set",
        "Core Archetype": "Parabolic Extension Fade + Multi-Sigma Overextension Reversal",
        "Peak ROI (%)": "+110.7%",
        "Horizon / Regime Window": "1-Week Carry Crash (+103.7% in W_Rand4)",
        "Capital Tier": "$100 USD",
        "Win Rate (%)": "66.7%",
        "Profit Factor": "3.59",
        "Max Drawdown (%)": "43.3%",
        "Multi-Window Status": "Doubled Account in 1 Week (+$110.69 W3 / +$103.66 W_Rand4)",
        "Execution Mechanism": "Gold surge >=25p from EMA + shooting star wick >=45% + volume surge >=2.0x"
    },
    {
        "Rank": 14,
        "Strategy Name": "Grand Master Hybrid EA (Monthly $100 Expansion)",
        "EA File": "Grand_Master_Hybrid_EA.mq5",
        "Preset Name": "GMH_Monthly_Expansion_100USD.set",
        "Core Archetype": "Bank ORB + ICT OTE 70.5% + Danial QM + 3-Stage Monthly Ladder",
        "Peak ROI (%)": "+98.3%",
        "Horizon / Regime Window": "1-Month Continuous May 2024 (+$98.26 on $100)",
        "Capital Tier": "$100 USD",
        "Win Rate (%)": "56.4%",
        "Profit Factor": "1.92",
        "Max Drawdown (%)": "24.8%",
        "Multi-Window Status": "Passed May (+98.3%) & Oct (+11.1%) Monthly Horizons",
        "Execution Mechanism": "London/NY ORB + 3-ticket cluster + TP1 (+25p), TP2 (+40p BE), TP3 (+180p runner)"
    },
    {
        "Rank": 15,
        "Strategy Name": "Matteo Conti Bank Opening Range Breakout (ORB)",
        "EA File": "ChartFanatics_Master_Suite.mq5",
        "Preset Name": "CF_MatteoConti_ORB_Optimal.set",
        "Core Archetype": "15m/30m Initial Balance Breakout + Session VWAP Filter",
        "Peak ROI (%)": "+92.4%",
        "Horizon / Regime Window": "4 Random Weeks Total (+54.2% May Month / +31.8% W3)",
        "Capital Tier": "$100 USD",
        "Win Rate (%)": "62.5%",
        "Profit Factor": "2.90",
        "Max Drawdown (%)": "15.8%",
        "Multi-Window Status": "Passed 4/4 Random Weeks (100% Pass) & 3/4 Months (+$30.27)",
        "Execution Mechanism": "15m opening range breakout confirmed by VWAP + 50 EMA + stepped BE shield"
    },
    {
        "Rank": 16,
        "Strategy Name": "Options Flow Master Suite",
        "EA File": "Options_Flow_Master_Suite.mq5",
        "Preset Name": "OptionsFlow_Model0_GoldenSweep_Sprint.set",
        "Core Archetype": "Institutional Urgent Ask Flow (>150%) + Gamma Flip Squeeze",
        "Peak ROI (%)": "+91.5%",
        "Horizon / Regime Window": "Window Q4 Dovish (+28.7% 1-Wk NFP)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "72.7%",
        "Profit Factor": "2.20",
        "Max Drawdown (%)": "18.2%",
        "Multi-Window Status": "Event-Driven Gamma Volatility Shock",
        "Execution Mechanism": "Gamma flip level breakout + urgent call sweep pulse (>150% volume)"
    },
    {
        "Rank": 17,
        "Strategy Name": "Institutional Confluence Strat 9 (Triple Confluence)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat9_Triple_Confluence_20USD.set",
        "Core Archetype": "SMC Liquidity Sweep + ICT FVG 50% CE + Unmitigated S&D Base",
        "Peak ROI (%)": "+73.8%",
        "Horizon / Regime Window": "1-Hour NFP Shock (+42.5% on $100 in 72 min)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "85.7%",
        "Profit Factor": "31.77",
        "Max Drawdown (%)": "8.4%",
        "Multi-Window Status": "High-Alpha Triad Engine (PF 14.38-31.77)",
        "Execution Mechanism": "Simultaneous confluence of retail sweep, FVG 50% CE, and fresh S&D base"
    },
    {
        "Rank": 18,
        "Strategy Name": "Anthony Crudele 3-Step Bollinger Trend",
        "EA File": "ChartFanatics_Master_Suite.mq5",
        "Preset Name": "CF_Crudele_Bollinger_Optimal.set",
        "Core Archetype": "20-Period Bollinger Midline Pullback + 50 EMA Trend Backbone",
        "Peak ROI (%)": "+68.3%",
        "Horizon / Regime Window": "1-Week NFP Shock (+31.5% in W_Rand3)",
        "Capital Tier": "$100 USD",
        "Win Rate (%)": "54.2%",
        "Profit Factor": "1.39",
        "Max Drawdown (%)": "47.2%",
        "Multi-Window Status": "Passed W1 (+68.3%) & W_Rand3 (+31.5%) Trend Expansions",
        "Execution Mechanism": "Midline (SMA 20) rejection wick >=35% in direction of 50 EMA + 2.5R TP"
    },
    {
        "Rank": 19,
        "Strategy Name": "Institutional SMC/ICT Strat 8 (BPR Vacuum)",
        "EA File": "Institutional_SMC_ICT_Master_Suite.mq5",
        "Preset Name": "SMC_ICT_Strat8_BPR_Vacuum_Champion.set",
        "Core Archetype": "Twin Displacement Overlap (BPR) + Liquidity Void Mean Reversion",
        "Peak ROI (%)": "+69.0%",
        "Horizon / Regime Window": "Cumulative across 4 Windows (W2 +50.1%)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "60.0%",
        "Profit Factor": "1.88",
        "Max Drawdown (%)": "17.5%",
        "Multi-Window Status": "3/4 Windows Passed (W1, W2, W4)",
        "Execution Mechanism": "Consecutive opposing FVGs form Balanced Price Range vacuum reversion"
    },
    {
        "Rank": 20,
        "Strategy Name": "Institutional Confluence Strat 5 (Judas + S&D)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat5_Judas_SD_Base.set",
        "Core Archetype": "London 07:00-09:00 Judas Trap into HTF (H1/H4) S&D Base",
        "Peak ROI (%)": "+61.4%",
        "Horizon / Regime Window": "Window W3 Carry Crash (+41.2% W1)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "54.5%",
        "Profit Factor": "1.68",
        "Max Drawdown (%)": "23.0%",
        "Multi-Window Status": "Passed W1 & W3 Crash Regimes",
        "Execution Mechanism": "London opening false breakout sweeps into unmitigated HTF base -> reversal"
    },
    {
        "Rank": 21,
        "Strategy Name": "Institutional Confluence Strat 1 (HTF OB + FVG CE)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat1_HTF_OB_FVG_Retest.set",
        "Core Archetype": "H1 Order Block nested with M15 FVG 50% Consequent Encroachment",
        "Peak ROI (%)": "+55.1%",
        "Horizon / Regime Window": "Window W3 Carry Crash (+38.5% W2)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "52.0%",
        "Profit Factor": "1.62",
        "Max Drawdown (%)": "21.5%",
        "Multi-Window Status": "Multi-Timeframe Structural Retest Engine",
        "Execution Mechanism": "M15 displacement pulls back to 50% CE of FVG aligned with H1 Order Block"
    },
    {
        "Rank": 22,
        "Strategy Name": "Mr P FX Master Suite (Strat 3 FVG)",
        "EA File": "MrPFx_Master_Suite.mq5",
        "Preset Name": "MrPFx_Champion_FVG.set",
        "Core Archetype": "M15 Fair Value Gap Tap + EMA 50 Backbone + Flipper Compounding",
        "Peak ROI (%)": "+52.4%",
        "Horizon / Regime Window": "Multi-Month Windows (+49.6% 1-Wk NFP)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "56.8%",
        "Profit Factor": "1.58",
        "Max Drawdown (%)": "20.4%",
        "Multi-Window Status": "Passed 3/4 Windows across Multi-Horizon",
        "Execution Mechanism": "FVG pullback tap in trend direction + 5-ticket cluster partial harvesting"
    },
    {
        "Rank": 23,
        "Strategy Name": "Danial FX Behavioral Flipper",
        "EA File": "DanialFX_Aggressive_Suite.mq5",
        "Preset Name": "DanialFX_Behavioral_Flipper_100USD.set",
        "Core Archetype": "10-Ticket Cluster Spamming + 5-Stage TP Ladder + BE Shield",
        "Peak ROI (%)": "+49.5%",
        "Horizon / Regime Window": "1-Week NFP Shock on $100 (257 Trades)",
        "Capital Tier": "$100 USD / $50 USD",
        "Win Rate (%)": "61.2%",
        "Profit Factor": "1.17",
        "Max Drawdown (%)": "34.6%",
        "Multi-Window Status": "High-Frequency Behavioral Execution Engine",
        "Execution Mechanism": "Quasimodo entry sliced into 10 tickets + stepped BE shield progression"
    },
    {
        "Rank": 24,
        "Strategy Name": "Institutional SMC/ICT Strat 3 (IDM Trap)",
        "EA File": "Institutional_SMC_ICT_Master_Suite.mq5",
        "Preset Name": "SMC_ICT_Strat3_IDM_Trap_Champion.set",
        "Core Archetype": "Retail Internal Inducement Purge + HTF Order Block Tap",
        "Peak ROI (%)": "+47.1%",
        "Horizon / Regime Window": "Window W2 CPI Shock on $100",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "66.7%",
        "Profit Factor": "3.60",
        "Max Drawdown (%)": "14.8%",
        "Multi-Window Status": "High-Conviction Trap Invalidation Sniper",
        "Execution Mechanism": "Retail inducement level purged, price taps institutional OB -> entry"
    },
    {
        "Rank": 25,
        "Strategy Name": "Institutional Confluence Strat 0 (S&D + SMC Sweep)",
        "EA File": "Institutional_Confluence_Master_EA.mq5",
        "Preset Name": "Confluence_Strat0_SD_Base_SMC_Sweep.set",
        "Core Archetype": "Fresh H1 S&D Base Test + M5 Retail Liquidity Sweep Rejection",
        "Peak ROI (%)": "+39.8%",
        "Horizon / Regime Window": "Window W1 NFP Shock (+28.4% W4)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "51.5%",
        "Profit Factor": "1.54",
        "Max Drawdown (%)": "22.3%",
        "Multi-Window Status": "Passed W1 & W4 Windows",
        "Execution Mechanism": "Fresh S&D base test coincides with M5 liquidity purge -> sniper entry"
    },
    {
        "Rank": 26,
        "Strategy Name": "Trader Yush Value Area & Delta Absorption",
        "EA File": "ChartFanatics_Master_Suite.mq5",
        "Preset Name": "CF_TraderYush_ValueArea_Original.set",
        "Core Archetype": "70% Value Area + CVD Delta Absorption Wick + POC Mean Reversion",
        "Peak ROI (%)": "+36.0%",
        "Horizon / Regime Window": "4-Month Total (+$35.99 / 3/4 Pass) & PF 8.17 in W4",
        "Capital Tier": "$100 USD",
        "Win Rate (%)": "58.3%",
        "Profit Factor": "8.17",
        "Max Drawdown (%)": "4.2%",
        "Multi-Window Status": "Passed 3/4 Months & Ultra-Low Drawdown (4.2% Oct DD)",
        "Execution Mechanism": "Test of VAH/VAL with >=35% wick closing back inside VA -> target POC"
    },
    {
        "Rank": 27,
        "Strategy Name": "Gold Wyckoff CVD Absorption EA",
        "EA File": "Gold_Wyckoff_CVD_Absorption_EA.mq5",
        "Preset Name": "Wyckoff_Absorption_Champion.set",
        "Core Archetype": "Cumulative Volume Delta Divergence at Spring/Upthrust",
        "Peak ROI (%)": "+33.5%",
        "Horizon / Regime Window": "1-Month Trend Window ($20 Tier)",
        "Capital Tier": "$20 USD / $100 USD",
        "Win Rate (%)": "42.1%",
        "Profit Factor": "1.58",
        "Max Drawdown (%)": "24.0%",
        "Multi-Window Status": "Wyckoff Phase C Institutional Sniper",
        "Execution Mechanism": "CVD delta divergence at Spring or Upthrust extreme confirms absorption"
    },
    {
        "Rank": 28,
        "Strategy Name": "Ali Khan ICT EA",
        "EA File": "Ali_Khan_ICT_EA.mq5",
        "Preset Name": "Ali_Khan_ICT_Optimal_Champion.set",
        "Core Archetype": "Full Body Displacement + 62%-79% OTE Retracement corridor",
        "Peak ROI (%)": "+31.5%",
        "Horizon / Regime Window": "Quarterly Compounding (+28.4% 1-Mo Peak)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "31.7%",
        "Profit Factor": "1.51",
        "Max Drawdown (%)": "18.2%",
        "Multi-Window Status": "Tier 2 Wick Breakout & OTE Filter",
        "Execution Mechanism": "Displacement body breakout + 62%-79% Fib corridor retest entry"
    },
    {
        "Rank": 29,
        "Strategy Name": "LumiTraders NY Killzone EA",
        "EA File": "LumiTraders_EA.mq5",
        "Preset Name": "LumiTraders_Optimal_Champion.set",
        "Core Archetype": "NY AM Killzone (13:00-16:00 UTC) + 3.5R Asymmetric Runner",
        "Peak ROI (%)": "+30.4%",
        "Horizon / Regime Window": "Quarterly Compounding (+26.0% 1-Mo Peak)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "25.4%",
        "Profit Factor": "1.48",
        "Max Drawdown (%)": "19.5%",
        "Multi-Window Status": "Tier 3 Morning Liquidity Runner",
        "Execution Mechanism": "13:00-16:00 UTC killzone high/low sweep + 3.5R trailing runner"
    },
    {
        "Rank": 30,
        "Strategy Name": "Hunter DiVenzo Trend FVG EA",
        "EA File": "Hunter_DiVenzo_EA.mq5",
        "Preset Name": "Hunter_DiVenzo_Optimal_Champion.set",
        "Core Archetype": "Trend FVG Tap + Volume Order Block Mitigation",
        "Peak ROI (%)": "+30.4%",
        "Horizon / Regime Window": "Quarterly Compounding (+24.5% 1-Mo Peak)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "25.4%",
        "Profit Factor": "1.46",
        "Max Drawdown (%)": "17.8%",
        "Multi-Window Status": "Tier 3 Low Drawdown Order Flow Engine",
        "Execution Mechanism": "M15 Trend FVG tap aligned with Volume Order Block mitigation"
    },
    {
        "Rank": 31,
        "Strategy Name": "Arjo MMT Synthetic SMT EA",
        "EA File": "Arjo_MMT_EA.mq5",
        "Preset Name": "Arjo_MMT_Optimal_Champion.set",
        "Core Archetype": "Synthetic SMT Divergence + Market Maker Buy/Sell Model (MMBM)",
        "Peak ROI (%)": "+26.3%",
        "Horizon / Regime Window": "Quarterly Compounding (+22.8% 1-Mo Peak)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "33.3%",
        "Profit Factor": "1.45",
        "Max Drawdown (%)": "15.2%",
        "Multi-Window Status": "Lowest Max Adverse Excursion (15.2%)",
        "Execution Mechanism": "Synthetic SMT non-confirmation divergence + MMBM curve entry"
    },
    {
        "Rank": 32,
        "Strategy Name": "Okala 80/20 Tail Distribution",
        "EA File": "ChartFanatics_Master_Suite.mq5",
        "Preset Name": "CF_Okala_8020_Original.set",
        "Core Archetype": "Outer 20% Distribution Tail Reversal + 50% Median Mean Reversion",
        "Peak ROI (%)": "+20.0%",
        "Horizon / Regime Window": "Passed W3 Carry Crash & W4 Election Shock",
        "Capital Tier": "$100 USD",
        "Win Rate (%)": "65.0%",
        "Profit Factor": "1.33",
        "Max Drawdown (%)": "8.4%",
        "Multi-Window Status": "Passed 2/4 Windows with DD Under 14%",
        "Execution Mechanism": "Price enters top 10% / bottom 10% tail + 200s structural reversal trigger"
    },
    {
        "Rank": 33,
        "Strategy Name": "Swappy Trading IPDA EA",
        "EA File": "Swappy_Trading_EA.mq5",
        "Preset Name": "Swappy_Trading_Optimal_Champion.set",
        "Core Archetype": "IPDA 50% Equilibrium Discount/Premium + London Judas",
        "Peak ROI (%)": "+20.3%",
        "Horizon / Regime Window": "Quarterly Compounding (+18.5% 1-Mo Peak)",
        "Capital Tier": "$100 USD / $20 USD",
        "Win Rate (%)": "30.9%",
        "Profit Factor": "1.42",
        "Max Drawdown (%)": "18.0%",
        "Multi-Window Status": "Tier 3 Dual-Session Coverage",
        "Execution Mechanism": "IPDA 50% equilibrium discount/premium pricing + London opening Judas"
    },
    {
        "Rank": 34,
        "Strategy Name": "Aggressive Flipper Master EA",
        "EA File": "Aggressive_Flipper_Master_EA.mq5",
        "Preset Name": "AggressiveFlipper_100USD_to_10000USD_Flip.set",
        "Core Archetype": "10 Codified Account Flipper Behaviors (Spam Slicing, TP Ladder)",
        "Peak ROI (%)": "+11.2%",
        "Horizon / Regime Window": "1-Week NFP Shock on $100 (166 Trades)",
        "Capital Tier": "$100 USD / $50 USD",
        "Win Rate (%)": "58.4%",
        "Profit Factor": "1.06",
        "Max Drawdown (%)": "28.5%",
        "Multi-Window Status": "Universal Online Flipper Archetype",
        "Execution Mechanism": "Ticket cluster slicing + 5-stage TP laddering + stepped breakeven shield"
    }
]

df = pd.DataFrame(strategies)
df.to_csv(LEADERBOARD_CSV, index=False)
print(f"Saved Leaderboard CSV: {LEADERBOARD_CSV}")

# Export to Excel
wb = openpyxl.Workbook()
ws = wb.active
ws.title = "Leaderboard"

# Header styles
header_fill = PatternFill(start_color="1F3A60", end_color="1F3A60", fill_type="solid")
header_font = Font(name="Segoe UI", size=11, bold=True, color="FFFFFF")
border = Border(
    left=Side(style='thin', color='DDDDDD'),
    right=Side(style='thin', color='DDDDDD'),
    top=Side(style='thin', color='DDDDDD'),
    bottom=Side(style='thin', color='DDDDDD')
)

headers = list(strategies[0].keys())
for col_idx, h in enumerate(headers, 1):
    cell = ws.cell(row=1, column=col_idx, value=h)
    cell.fill = header_fill
    cell.font = header_font
    cell.alignment = Alignment(horizontal="center", vertical="center")

for row_idx, strat in enumerate(strategies, 2):
    for col_idx, h in enumerate(headers, 1):
        cell = ws.cell(row=row_idx, column=col_idx, value=strat[h])
        cell.font = Font(name="Segoe UI", size=10)
        cell.border = border
        if h in ["Rank", "Peak ROI (%)", "Win Rate (%)", "Profit Factor", "Max Drawdown (%)"]:
            cell.alignment = Alignment(horizontal="center", vertical="center")
        else:
            cell.alignment = Alignment(horizontal="left", vertical="center")

# Auto fit columns
for col in ws.columns:
    max_len = max(len(str(cell.value or '')) for cell in col)
    col_letter = get_column_letter(col[0].column)
    ws.column_dimensions[col_letter].width = min(max(max_len + 3, 12), 45)

wb.save(EXCEL_PATH)
wb.save(ARTIFACT_EXCEL_PATH)
print(f"Saved Excel Database to {EXCEL_PATH} and {ARTIFACT_EXCEL_PATH}")

# Update Markdown Database File
md_content = f"""# 🏆 Master Quantitative Trading Strategies Database: Leaderboard, Settings Hierarchy & Architectural Mechanics

**Repository**: `d:\\Projects\\AUTOMATIONS\\TRADING\\Youtube-Traders`  
**Generated Files**:  
- **Master Excel Database**: [`MASTER_TRADING_STRATEGIES_DATABASE.xlsx`](file:///{EXCEL_PATH.replace('\\', '/')}) (Also saved in Artifact Directory)  
- **Leaderboard CSV**: [`MASTER_ALL_STRATEGIES_RANKING.csv`](file:///{LEADERBOARD_CSV.replace('\\', '/')})  
- **Target Asset**: Gold (`XAUUSD`) & Major FX (`EURUSD`)  
- **Broker / Leverage Profiles**: Exness Standard / Cent Profiles (`1:400` Leverage) & Kenyan Shilling Benchmark (`1,000 KES` / `775 USC`)  

---

## 🥇 Complete Ranked Leaderboard (Top 34 Strategies Ranked by Peak Profitability)

| Rank | Strategy Name | EA File | Calibrated Preset | Core Archetype | Peak ROI (%) | Horizon / Regime Window | Capital Tier | Win Rate | Profit Factor | Max DD |
| :---: | :--- | :--- | :--- | :--- | :---: | :--- | :---: | :---: | :---: | :---: |
"""

for s in strategies:
    md_content += f"| **#{s['Rank']}** | **{s['Strategy Name']}** | `{s['EA File']}` | `{s['Preset Name']}` | {s['Core Archetype']} | **{s['Peak ROI (%)']}** | {s['Horizon / Regime Window']} | {s['Capital Tier']} | {s['Win Rate (%)']} | {s['Profit Factor']} | {s['Max Drawdown (%)']} |\n"

md_content += """
---

## 🎯 Horizon-Specific Strategic Classification

### 1. Weekly Sprints (Target >= 100% ROI in 1 Week / Account Doubling)
- **#1 Danial FX Quasimodo Flipper**: **+336.6% ROI in 5 days** on $100 capital (1-Week NFP Volatility Shock).
- **#3 Institutional Confluence Strat 4 (OTE 70.5% + S&D Base)**: **+270.1% ROI in 1 week** (+$54.01 on $20 capital).
- **#5 Grand Master Hybrid EA**: **+201.6% ROI in 1 week** (+$40.31 on $20 capital) in NFP shock and **+137.4% ROI in 1 week** in Carry Crash! Cumulative +348.7% across 4 weeks!
- **#9 Chart Fanatics Master Institutional Hybrid**: **+171.3% ROI across 4 random weeks** (100% pass rate, +83.4% peak week).
- **#12 Institutional Confluence Strat 6 (BPR + S&D Flip)**: **+120.3% ROI in 1 week** (+$24.07 on $20 capital).
- **#13 Kris Verma Parabolic Gap Short**: **+110.7% ROI in 1 week** (Carry Crash) and **+103.7% in 1 week** (W_Rand4)!
- **#15 Matteo Conti Bank ORB**: **+92.4% ROI across 4 random weeks** (100% pass rate, max DD 15.8%).

### 2. Monthly Horizons (Target >= 100% ROI in 1 Month / Account Doubling)
- **#1 Gold Micro HyperScalp EA**: **+672.5% 4-week sprint / +192.0% 1-month peak** on $20 / 775 USC.
- **#6 Gold Master Super Strategy EA**: **+201.4% 1-month peak** (+197.0% 4-week sprint).
- **#7 TradeIQ Optimized EA**: **+176.4% 4-week sprint / +167.7% 1-month peak**.
- **#8 DodgysDD Open Judas EA**: **+172.9% 30-day window / +171.0% 1-month peak**.
- **#10 JadeCap FX Volume Exhaustion EA**: **+156.3% 4-week sprint**.
- **#11 CPR Velocity Doubler EA**: **+142.5% 30-day window / +105.2% 1-month peak**.
- **#2 Danial FX Balanced Compounding**: **+123.7% ROI in 1 month** on $100 capital.
- **#14 Grand Master Hybrid EA (Monthly Expansion)**: **+98.3% ROI in 1 month** (May 2024: +$98.26 on $100, PF 1.92, DD 24.8%).
- **#16 Options Flow Master Suite**: **+91.5% ROI** (Window Q4 Dovish trend).
- **#15 Matteo Conti Bank ORB**: **+54.2% ROI in May 2024 month** and **+30.3% across 4 months**!

### 3. Annual Horizons (Target Long-Horizon Geometric Compounding & Maximum Return)
- **#4 Daily Fibonacci 61.8% Suite (Aggressive Math)**: **+254.1% 9-month compounding** with tiered equity sizing ($50/0.01 lot) and dual TP targets (1.0R and 2.5R runner), max DD only 18.5%.
- **#9 Chart Fanatics Master Hybrid (Setting A - Original)**: Completed the **entire 365 calendar days of 2024 in profit unassisted (+30.6% ROI)** across 557 trades on Gold!
- **#26 Trader Yush Value Area (Setting A - Original)**: Passed 3 out of 4 months with **+36.0% net gain**, **PF 8.17**, and October drawdown of only **4.2%**!
"""

with open(MD_DATABASE_PATH, "w", encoding="utf-8") as f:
    f.write(md_content)

print(f"Saved Markdown Database: {MD_DATABASE_PATH}")
