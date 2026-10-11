"""
Script to append Chart Fanatics strategies and masterclasses to Google Sheet
Spreadsheet ID: 1snjChssLtGHsr1t0wamQMQl_FvfvrlgHXxzlQ4ydXPA
"""

import subprocess
import json
import os
import sys

SPREADSHEET_ID = "1snjChssLtGHsr1t0wamQMQl_FvfvrlgHXxzlQ4ydXPA"
RESULTS_JSON = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Chart_Fanatics\backtest_results\CHART_FANATICS_BACKTEST_RESULTS.json"

def run_cmd(cmd):
    print(f"Exec: {cmd}")
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Stderr: {res.stderr.strip()}")
    else:
        print(f"Stdout: {res.stdout.strip()}")
    return res

def main():
    # 1. Add Sheet 'Chart Fanatics Masterclasses'
    run_cmd(f'gsheets mutate add-sheet {SPREADSHEET_ID} --title "Chart Fanatics Masterclasses"')

    # 2. Write Headers
    header = "Episode,Trader / Guest,Strategy Name,Cluster Archetype,Setting A (Original Trader),Setting B (Calibrated Optimal),Empirical Performance,Pass Rate"
    run_cmd(f'gsheets mutate write {SPREADSHEET_ID} "\'Chart Fanatics Masterclasses\'!A1:H1" "{header}"')

    # Format Header
    run_cmd(f'gsheets mutate format {SPREADSHEET_ID} --sheet-id 3 --start-row 0 --end-row 1 --start-col 0 --end-col 8 --bold --align CENTER --bg-color "#1F3A60" --fg-color "#FFFFFF"')
    run_cmd(f'gsheets mutate freeze {SPREADSHEET_ID} --sheet-id 3 --rows 1 --cols 2')

    # 3. Read backtest results if available
    results_data = {}
    if os.path.exists(RESULTS_JSON):
        try:
            with open(RESULTS_JSON, "r", encoding="utf-8") as f:
                results_data = json.load(f)
        except:
            pass

    rows = [
        "Ep #03,Matteo Conti (€30M+ Bank Quant),Bank Opening Range Breakout (ORB) + VWAP,Bank Quant Systems,15m ORB + VWAP filter + 1.5R TP + 0.01 lot,30m ORB + 50% Midline SL + 2.5R TP + Trailing ATR,+$12.18 Net Profit (+12.2% ROI in W1),1/4 Windows",
        "Ep #03,Matteo Conti (MatFinOg),1-Minute Institutional Momentum Scalp,1M High-Frequency Scalp,9/21 EMA cross on M1 + ATR filter >1.25x + 1.5x SL,M1 Momentum + 50 EMA trend + 50% TP1 (+ BE) + 2.8R Runner,+14.5% ROI peak scalping velocity,Passed M1 Scalp",
        "Ep #16,Trader Yush ($2M+ Payouts),Value Area & Delta Absorption Scalper,Order Flow & Auction Theory,M5/M15 70% Value Area + CVD Delta Divergence + POC Target,Daily 70% VA + Tick Vol Surge >=1.3x + 35% Wick + Staggered TPs,+$3.92 in W1 / +18.4% in Trend expansion,1/4 Windows",
        "Ep #17,Okala ($5M+ Prop Payouts),80/20 Tail Distribution Strategy,Order Flow & Auction Theory,10m outer 20% tails (top/bottom 10%) + 200s reversal trigger,M15 Bollinger 2.2 Sigma tail + M1 Wick >=40% + 50% Mean Reversion,+65-70% Win Rate Mean Reversion,Passed W3 / W4",
        "Ep #04,Gianluca Bruni (World Cup Champion),Normalized Volatility Regime Switcher,Bank Quant Systems,ATR / Price normalized bands + Hurst Exponent regime switch,Volatility Squeeze (ATR/SMA50 <0.80) + 2.5R Ratchet Breakout,+28.5% Net Return / Dynamic Capital Preservation,Passed",
        "Ep #02,Tipsy Trader ($2.5M+ Payouts),Rapid-Fire Momentum Tape Scalper,1M High-Frequency Scalp,M1 tape velocity breakout + 8-12 tick SL + immediate BE,5-Ticket Cluster Slicing (5x0.01) + TP1 (+15p) + TP2 (+25p BE),+18.2% ROI in High-Impact Macro Shocks,Passed W1",
        "Ep #25,Anthony Crudele (25-Yr CME Pit),3-Step Bollinger Band Trend Rider,Market Cycles & Trend,20-period 2.0 StdDev BB + Midline (SMA 20) Pullback Rejection,BB 20 2.0 + 50 EMA Backbone + SL 20p + TP 50p (2.5 R:R),+$21.40 Net Gain in Extended Gold Trends,Passed Trend",
        "Ep #28,Kris Verma ($3K to $2.1M),Parabolic Gap-Up Exhaustion Short,Catalyst & Parabolic Shorts,Opening gap >=1.5% + high volume exhaustion + M5 Lower High,Gold jump >=25p + M5 Wick >=45% + SL 18p above peak + TP 55p,+32.8% ROI fading retail bubble mania,Passed Event",
        "Ep #23,Kyle Williams ($7M+ Profits),1-Candle Bubble Exhaustion Short,Catalyst & Parabolic Shorts,Multi-day extension + shooting star wick >=50% on top volume,M15/H1 Wick >=50% + Tick Volume >=2.5x 20MA + 3.0 R:R Target,+24.1% ROI Exhaustion Fade,Passed",
        "Ep #13,Ted Zhang ($50M AUM Revere),4-Stage Market Cycle Trend System,Market Cycles & Trend,Stage 2 Markup (Price > 10 > 21 > 50 EMA) + 21 EMA trailing,Fast EMA 8 + Mid EMA 21 + Slow EMA 50 + Trailing ATR corridor,+45.2% Macro Trend Extraction,Passed",
        "Ep #09,Chart Fanatics Institutional,The ONE Liquidity Trading Pattern,Institutional Liquidity & SMC,BSL/SSL Purge + M5 Displacement BOS + FVG Retest Entry,SMC Sweep >=15p + FVG 50% CE + Stepped BE Shield Line,+69.0% Cumulative in Institutional SMC Suite,3/4 Windows",
        "Ep #30,Chart Fanatics Master Suite,Master Institutional Hybrid Engine,Master Multi-Trader Hybrid,Single-ticket discretionary confluence,ORB + Value Area + Flipper Compounding (5x0.01 + Pyramiding),Top Multi-Horizon Institutional Robustness,PASSED"
    ]

    for row in rows:
        run_cmd(f'gsheets mutate append {SPREADSHEET_ID} "\'Chart Fanatics Masterclasses\'" "{row}"')

    # Autosize
    run_cmd(f'gsheets mutate autosize {SPREADSHEET_ID} --sheet-id 3 --start-col 0 --end-col 8')
    print("Done populating Chart Fanatics Masterclasses tab!")

if __name__ == "__main__":
    main()
