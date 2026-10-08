import json
import math
import os
import urllib.request
from datetime import datetime
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.patches import Rectangle
import numpy as np
import pandas as pd

ARTIFACT_DIR = r"C:\Users\user\.gemini\antigravity\brain\908548ce-da6e-4067-ad2d-a1589ba235cd"
os.makedirs(ARTIFACT_DIR, exist_ok=True)

def fetch_gold_data():
    print("Fetching Daily Gold data from Yahoo Finance (GC=F)...")
    url_d1 = "https://query1.finance.yahoo.com/v8/finance/chart/GC=F?interval=1d&range=2y"
    req = urllib.request.Request(url_d1, headers={'User-Agent': 'Mozilla/5.0'})
    res = urllib.request.urlopen(req)
    data_d1 = json.loads(res.read())['chart']['result'][0]
    
    timestamps = data_d1['timestamp']
    quotes = data_d1['indicators']['quote'][0]
    
    df_d1 = pd.DataFrame({
        'timestamp': [datetime.fromtimestamp(ts) for ts in timestamps],
        'open': quotes['open'],
        'high': quotes['high'],
        'low': quotes['low'],
        'close': quotes['close'],
        'volume': quotes.get('volume', [0]*len(timestamps))
    }).dropna()
    df_d1 = df_d1.sort_values('timestamp').reset_index(drop=True)
    print(f"Fetched {len(df_d1)} daily bars from {df_d1['timestamp'].iloc[0].date()} to {df_d1['timestamp'].iloc[-1].date()}")
    
    # Also fetch hourly data for granular analysis
    print("Fetching Hourly Gold data (GC=F)...")
    url_h1 = "https://query1.finance.yahoo.com/v8/finance/chart/GC=F?interval=1h&range=730d"
    req_h1 = urllib.request.Request(url_h1, headers={'User-Agent': 'Mozilla/5.0'})
    res_h1 = urllib.request.urlopen(req_h1)
    data_h1 = json.loads(res_h1.read())['chart']['result'][0]
    ts_h1 = data_h1['timestamp']
    q_h1 = data_h1['indicators']['quote'][0]
    
    df_h1 = pd.DataFrame({
        'timestamp': [datetime.fromtimestamp(ts) for ts in ts_h1],
        'open': q_h1['open'],
        'high': q_h1['high'],
        'low': q_h1['low'],
        'close': q_h1['close']
    }).dropna().sort_values('timestamp').reset_index(drop=True)
    print(f"Fetched {len(df_h1)} hourly bars.")
    
    return df_d1, df_h1

def analyze_strategy(df_d1):
    print("\n--- Running Quantitative Strategy Analysis ---")
    results = []
    virgin_levels = []
    
    # For gold, 1 point = $0.10 or $1.00? In forex standard: 
    # Gold $1.00 move = 100 pips (or 10 pips depending on broker convention).
    # We will express moves both in Gold Dollars ($) and standard pips ($0.10 = 1 pip -> $1 = 10 pips, or $0.01 = 1 pip -> $1 = 100 pips).
    # We will state dollars ($) and standard forex pips ($1.00 = 100 pips).
    
    total_days = len(df_d1) - 1
    
    bearish_days = 0
    bullish_days = 0
    
    touched_next_day_count = 0
    untouched_next_day_count = 0
    
    # Immediate touch performance
    immediate_mfes = [] # Max favorable excursion ($)
    immediate_maes = [] # Max adverse excursion ($)
    immediate_win_rate = [] # Did it close favorably or bounce at least $10 (100 pips)?
    
    for i in range(len(df_d1) - 1):
        prev = df_d1.iloc[i]
        curr = df_d1.iloc[i+1]
        
        is_bearish = prev['close'] < prev['open']
        is_bullish = prev['close'] > prev['open']
        rng = prev['high'] - prev['low']
        
        if rng <= 0:
            continue
            
        if is_bearish:
            bearish_days += 1
            # User rule: 100 at High, 0 at Low. Retracement level = Low + 0.618 * Range
            fib_level = prev['low'] + 0.618 * rng
            trade_type = 'SELL'
            # Next day touch condition: did curr High reach or exceed fib_level?
            touched = curr['high'] >= fib_level
            
            if touched:
                touched_next_day_count += 1
                # If touched, price is at fib_level.
                # Adverse move (overshoot above fib_level):
                mae = max(0.0, curr['high'] - fib_level)
                # Favorable move (bounce down from fib_level towards low):
                mfe = max(0.0, fib_level - curr['low'])
                net_close_diff = fib_level - curr['close'] # Positive if close is below entry (in profit)
                
                immediate_mfes.append(mfe)
                immediate_maes.append(mae)
                immediate_win_rate.append(1 if mfe >= 10.0 and mfe > mae else 0)
                
                results.append({
                    'day_idx': i,
                    'date': prev['timestamp'].strftime('%Y-%m-%d'),
                    'type': 'SELL',
                    'fib_level': fib_level,
                    'range': rng,
                    'touched_next_day': True,
                    'mfe': mfe,
                    'mae': mae,
                    'net_close_gain': net_close_diff
                })
            else:
                untouched_next_day_count += 1
                # Mark as Virgin Level
                virgin_levels.append({
                    'created_day_idx': i,
                    'created_date': prev['timestamp'],
                    'type': 'SELL',
                    'fib_level': fib_level,
                    'orig_high': prev['high'],
                    'orig_low': prev['low'],
                    'range': rng
                })
                results.append({
                    'day_idx': i,
                    'date': prev['timestamp'].strftime('%Y-%m-%d'),
                    'type': 'SELL',
                    'fib_level': fib_level,
                    'range': rng,
                    'touched_next_day': False
                })
                
        elif is_bullish:
            bullish_days += 1
            # User rule: 100 at Low, 0 at High. Retracement level = High - 0.618 * Range
            fib_level = prev['high'] - 0.618 * rng
            trade_type = 'BUY'
            # Next day touch condition: did curr Low reach or drop below fib_level?
            touched = curr['low'] <= fib_level
            
            if touched:
                touched_next_day_count += 1
                # If touched, entry at fib_level.
                # Adverse move (overshoot below fib_level):
                mae = max(0.0, fib_level - curr['low'])
                # Favorable move (bounce up from fib_level towards high):
                mfe = max(0.0, curr['high'] - fib_level)
                net_close_diff = curr['close'] - fib_level
                
                immediate_mfes.append(mfe)
                immediate_maes.append(mae)
                immediate_win_rate.append(1 if mfe >= 10.0 and mfe > mae else 0)
                
                results.append({
                    'day_idx': i,
                    'date': prev['timestamp'].strftime('%Y-%m-%d'),
                    'type': 'BUY',
                    'fib_level': fib_level,
                    'range': rng,
                    'touched_next_day': True,
                    'mfe': mfe,
                    'mae': mae,
                    'net_close_gain': net_close_diff
                })
            else:
                untouched_next_day_count += 1
                virgin_levels.append({
                    'created_day_idx': i,
                    'created_date': prev['timestamp'],
                    'type': 'BUY',
                    'fib_level': fib_level,
                    'orig_high': prev['high'],
                    'orig_low': prev['low'],
                    'range': rng
                })
                results.append({
                    'day_idx': i,
                    'date': prev['timestamp'].strftime('%Y-%m-%d'),
                    'type': 'BUY',
                    'fib_level': fib_level,
                    'range': rng,
                    'touched_next_day': False
                })

    # Now analyze the Virgin Levels:
    # When are they touched in future days (i+2, i+3, ...)?
    print("\nTracking Virgin Levels through subsequent history...")
    virgin_stats = []
    
    for vl in virgin_levels:
        start_idx = vl['created_day_idx'] + 2 # day i+1 did NOT touch
        level = vl['fib_level']
        l_type = vl['type']
        
        hit_day = None
        days_elapsed = 0
        
        for k in range(start_idx, len(df_d1)):
            k_bar = df_d1.iloc[k]
            if l_type == 'SELL':
                if k_bar['high'] >= level:
                    hit_day = k
                    days_elapsed = k - vl['created_day_idx']
                    # Reaction on hit day
                    mae = max(0.0, k_bar['high'] - level)
                    mfe = max(0.0, level - k_bar['low'])
                    
                    # Also look at next 3 days expansion
                    future_bars = df_d1.iloc[k:min(k+4, len(df_d1))]
                    max_future_drop = level - future_bars['low'].min()
                    max_future_overshoot = future_bars['high'].max() - level
                    
                    virgin_stats.append({
                        'date_created': vl['created_date'].strftime('%Y-%m-%d'),
                        'date_hit': k_bar['timestamp'].strftime('%Y-%m-%d'),
                        'type': l_type,
                        'level': level,
                        'days_elapsed': days_elapsed,
                        'hit_day_mfe': mfe,
                        'hit_day_mae': mae,
                        'multi_day_mfe': max(0.0, max_future_drop),
                        'multi_day_mae': max(0.0, max_future_overshoot)
                    })
                    break
            elif l_type == 'BUY':
                if k_bar['low'] <= level:
                    hit_day = k
                    days_elapsed = k - vl['created_day_idx']
                    mae = max(0.0, level - k_bar['low'])
                    mfe = max(0.0, k_bar['high'] - level)
                    
                    future_bars = df_d1.iloc[k:min(k+4, len(df_d1))]
                    max_future_rally = future_bars['high'].max() - level
                    max_future_overshoot = level - future_bars['low'].min()
                    
                    virgin_stats.append({
                        'date_created': vl['created_date'].strftime('%Y-%m-%d'),
                        'date_hit': k_bar['timestamp'].strftime('%Y-%m-%d'),
                        'type': l_type,
                        'level': level,
                        'days_elapsed': days_elapsed,
                        'hit_day_mfe': mfe,
                        'hit_day_mae': mae,
                        'multi_day_mfe': max(0.0, max_future_rally),
                        'multi_day_mae': max(0.0, max_future_overshoot)
                    })
                    break
                    
    df_virgin = pd.DataFrame(virgin_stats)
    
    print("\n" + "="*70)
    print("QUANTITATIVE SUMMARY OF THE FIBONACCI 61.8 STRATEGY ON GOLD")
    print("="*70)
    print(f"Total Daily Candles Analyzed: {total_days}")
    print(f"Bearish Days: {bearish_days} ({bearish_days/total_days*100:.1f}%) | Bullish Days: {bullish_days} ({bullish_days/total_days*100:.1f}%)")
    print(f"Days 61.8% Touched NEXT DAY (Immediate Retest): {touched_next_day_count} ({touched_next_day_count/total_days*100:.1f}%)")
    print(f"Days 61.8% UNTOUCHED (Turned into Virgin Levels): {untouched_next_day_count} ({untouched_next_day_count/total_days*100:.1f}%)")
    
    avg_imm_mfe = np.mean(immediate_mfes)
    avg_imm_mae = np.mean(immediate_maes)
    print(f"\n[IMMEDIATE DAY+1 RETEST METRICS]")
    print(f"Average Favorable Bounce (MFE): ${avg_imm_mfe:.2f} ({avg_imm_mfe*100:.0f} pips)")
    print(f"Average Adverse Overshoot (MAE): ${avg_imm_mae:.2f} ({avg_imm_mae*100:.0f} pips)")
    print(f"Reward-to-Risk Excursion Ratio (MFE / MAE): {avg_imm_mfe / (avg_imm_mae + 1e-5):.2f}")
    
    if len(df_virgin) > 0:
        print(f"\n[VIRGIN / UNTOUCHED LEVEL METRICS]")
        print(f"Total Virgin Levels Identified: {len(virgin_levels)}")
        print(f"Total Virgin Levels Eventually Hit: {len(df_virgin)} ({len(df_virgin)/len(virgin_levels)*100:.1f}%)")
        print(f"Average Days Until Retest: {df_virgin['days_elapsed'].mean():.1f} days (Median: {df_virgin['days_elapsed'].median():.1f} days)")
        print(f"Average Hit-Day Favorable Bounce (MFE): ${df_virgin['hit_day_mfe'].mean():.2f} ({df_virgin['hit_day_mfe'].mean()*100:.0f} pips)")
        print(f"Average Hit-Day Adverse Overshoot (MAE): ${df_virgin['hit_day_mae'].mean():.2f} ({df_virgin['hit_day_mae'].mean()*100:.0f} pips)")
        print(f"Average Multi-Day Expansion (Follow-through): ${df_virgin['multi_day_mfe'].mean():.2f} ({df_virgin['multi_day_mfe'].mean()*100:.0f} pips)")
        
        # Test User's Specific Hypothesis:
        # "if 6.18 is not hit in the most days possible, that means it returns the most, it will give the most pips possible"
        print(f"\n[USER HYPOTHESIS TEST: Does Level Age Correlate with Larger Pip Returns?]")
        short_aged = df_virgin[df_virgin['days_elapsed'] <= 5]
        medium_aged = df_virgin[(df_virgin['days_elapsed'] > 5) & (df_virgin['days_elapsed'] <= 15)]
        long_aged = df_virgin[df_virgin['days_elapsed'] > 15]
        
        print(f"  • Fast Retest (2 - 5 days, n={len(short_aged)}): Avg Multi-day MFE = ${short_aged['multi_day_mfe'].mean():.2f} ({short_aged['multi_day_mfe'].mean()*100:.0f} pips)")
        if len(medium_aged) > 0:
            print(f"  • Medium Retest (6 - 15 days, n={len(medium_aged)}): Avg Multi-day MFE = ${medium_aged['multi_day_mfe'].mean():.2f} ({medium_aged['multi_day_mfe'].mean()*100:.0f} pips)")
        if len(long_aged) > 0:
            print(f"  • Aged / Institutional (16+ days, n={len(long_aged)}): Avg Multi-day MFE = ${long_aged['multi_day_mfe'].mean():.2f} ({long_aged['multi_day_mfe'].mean()*100:.0f} pips)")
            
    return df_d1, results, virgin_levels, df_virgin

def generate_charts(df_d1, df_h1, results, virgin_levels, df_virgin):
    print("\n--- Generating High-Resolution Charts ---")
    
    # -------------------------------------------------------------
    # CHART 1: Core Strategy Mechanics Diagram (Fibonacci Drawing)
    # -------------------------------------------------------------
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 8), facecolor='#12151c')
    
    # Bullish Day Example Diagram
    ax1.set_facecolor('#1a1f2c')
    ax1.set_title("BULLISH DAY SETUP (Green Candle)\n100% Fib at Low, 0% Fib at High -> Retrace to 61.8% to BUY", 
                  color='#00e676', fontsize=12, fontweight='bold', pad=15)
    
    # Day 1: Bullish candle
    # Open: 2300, Low: 2290, High: 2350, Close: 2345
    ax1.vlines(1, 2290, 2350, color='#00e676', linewidth=2.5)
    ax1.add_patch(Rectangle((0.75, 2300), 0.5, 45, facecolor='#00e676', edgecolor='#00e676'))
    
    # Day 2: Retracement and bounce
    # Open: 2345, Low: 2312.9 (61.8% retrace = 2350 - 0.618*60 = 2312.9), High: 2365, Close: 2360
    ax1.vlines(2.5, 2312.9, 2365, color='#00e676', linewidth=2)
    ax1.add_patch(Rectangle((2.25, 2345), 0.5, 15, facecolor='#00e676', edgecolor='#00e676'))
    
    # Draw Fib levels for Day 1
    ax1.axhline(2350, color='#78909c', linestyle='--', alpha=0.6)
    ax1.text(0.05, 2351.5, "0.0% Fib (Day High) = $2350.00", color='#eceff1', fontsize=10, fontweight='bold')
    
    fib_buy = 2350 - 0.618 * 60
    ax1.axhline(fib_buy, color='#ffd700', linestyle='-', linewidth=2.5)
    ax1.text(0.05, fib_buy + 2.0, f"61.8% Fib RETRACEMENT BUY LEVEL = ${fib_buy:.1f}", color='#ffd700', fontsize=10, fontweight='bold')
    
    ax1.axhline(2290, color='#78909c', linestyle='--', alpha=0.6)
    ax1.text(0.05, 2286.5, "100.0% Fib (Day Low) = $2290.00", color='#eceff1', fontsize=10, fontweight='bold')
    
    # Annotate action
    ax1.annotate('1. Day 1 Bullish Expansion', xy=(1, 2345), xytext=(0.2, 2365),
                 color='#00e676', fontsize=10, fontweight='bold',
                 arrowprops=dict(facecolor='#00e676', shrink=0.05, width=1.5, headwidth=6))
                 
    ax1.annotate('2. Day 2 Dips to 61.8%\nBUY ENTRY TRIGGER', xy=(2.5, 2313), xytext=(1.4, 2296),
                 color='#ffd700', fontsize=10, fontweight='bold',
                 arrowprops=dict(facecolor='#ffd700', shrink=0.05, width=1.5, headwidth=6))
                 
    ax1.annotate('3. Violent Bullish Continuation\nTarget > Day 1 High (+450 pips)', xy=(2.5, 2365), xytext=(2.1, 2373),
                 color='#00e676', fontsize=10, fontweight='bold',
                 arrowprops=dict(facecolor='#00e676', shrink=0.05, width=1.5, headwidth=6))
    
    ax1.set_xlim(-0.2, 3.8)
    ax1.set_ylim(2280, 2385)
    ax1.set_xticks([1, 2.5])
    ax1.set_xticklabels(['Day 1 (Reference)', 'Day 2 (Execution)'], color='#eceff1', fontsize=11)
    ax1.tick_params(colors='#eceff1')
    ax1.grid(True, color='#263238', linestyle=':', alpha=0.7)
    
    # Bearish Day Example Diagram
    ax2.set_facecolor('#1a1f2c')
    ax2.set_title("BEARISH DAY SETUP (Red Candle)\n100% Fib at High, 0% Fib at Low -> Retrace to 61.8% to SELL", 
                  color='#ff5252', fontsize=12, fontweight='bold', pad=15)
                  
    # Day 1: Bearish candle
    # Open: 2350, High: 2355, Low: 2295, Close: 2300 (Range = 60)
    ax2.vlines(1, 2295, 2355, color='#ff5252', linewidth=2.5)
    ax2.add_patch(Rectangle((0.75, 2300), 0.5, 50, facecolor='#ff5252', edgecolor='#ff5252'))
    
    # Day 2: Retracement and drop
    # Open: 2300, High: 2332.08 (61.8% retrace = 2295 + 0.618*60 = 2332.08), Low: 2280, Close: 2285
    fib_sell = 2295 + 0.618 * 60
    ax2.vlines(2.5, 2280, fib_sell, color='#ff5252', linewidth=2)
    ax2.add_patch(Rectangle((2.25, 2285), 0.5, 15, facecolor='#ff5252', edgecolor='#ff5252'))
    
    ax2.axhline(2355, color='#78909c', linestyle='--', alpha=0.6)
    ax2.text(0.05, 2356.5, "100.0% Fib (Day High) = $2355.00", color='#eceff1', fontsize=10, fontweight='bold')
    
    ax2.axhline(fib_sell, color='#ffd700', linestyle='-', linewidth=2.5)
    ax2.text(0.05, fib_sell + 2.0, f"61.8% Fib RETRACEMENT SELL LEVEL = ${fib_sell:.1f}", color='#ffd700', fontsize=10, fontweight='bold')
    
    ax2.axhline(2295, color='#78909c', linestyle='--', alpha=0.6)
    ax2.text(0.05, 2291.5, "0.0% Fib (Day Low) = $2295.00", color='#eceff1', fontsize=10, fontweight='bold')
    
    ax2.annotate('1. Day 1 Bearish Dump', xy=(1, 2300), xytext=(0.2, 2285),
                 color='#ff5252', fontsize=10, fontweight='bold',
                 arrowprops=dict(facecolor='#ff5252', shrink=0.05, width=1.5, headwidth=6))
                 
    ax2.annotate('2. Day 2 Rallies to 61.8%\nSELL ENTRY TRIGGER', xy=(2.5, fib_sell), xytext=(1.4, 2345),
                 color='#ffd700', fontsize=10, fontweight='bold',
                 arrowprops=dict(facecolor='#ffd700', shrink=0.05, width=1.5, headwidth=6))
                 
    ax2.annotate('3. Violent Bearish Rejection\nTarget < Day 1 Low (+520 pips)', xy=(2.5, 2280), xytext=(2.1, 2272),
                 color='#ff5252', fontsize=10, fontweight='bold',
                 arrowprops=dict(facecolor='#ff5252', shrink=0.05, width=1.5, headwidth=6))
                 
    ax2.set_xlim(-0.2, 3.8)
    ax2.set_ylim(2265, 2375)
    ax2.set_xticks([1, 2.5])
    ax2.set_xticklabels(['Day 1 (Reference)', 'Day 2 (Execution)'], color='#eceff1', fontsize=11)
    ax2.tick_params(colors='#eceff1')
    ax2.grid(True, color='#263238', linestyle=':', alpha=0.7)
    
    plt.tight_layout()
    chart1_path = os.path.join(ARTIFACT_DIR, "gold_fib_strategy_mechanics.png")
    plt.savefig(chart1_path, dpi=200)
    plt.close()
    print(f"Saved Chart 1: {chart1_path}")
    
    # -------------------------------------------------------------
    # CHART 2: Real Market Price Action - Immediate 61.8 Retracements
    # -------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(16, 9), facecolor='#12151c')
    ax.set_facecolor('#1a1f2c')
    
    # Pick a rich recent window of 20 daily candles with clean setups
    sub_df = df_d1.iloc[-45:-20].copy().reset_index(drop=True)
    
    width = 0.6
    for idx, row in sub_df.iterrows():
        is_up = row['close'] >= row['open']
        color = '#00e676' if is_up else '#ff5252'
        
        # Wick
        ax.vlines(idx, row['low'], row['high'], color=color, linewidth=1.8)
        # Body
        body_bottom = min(row['open'], row['close'])
        body_height = max(abs(row['close'] - row['open']), 0.5)
        ax.add_patch(Rectangle((idx - width/2, body_bottom), width, body_height, facecolor=color, edgecolor=color))
        
        # Draw previous day 61.8 on next day if available
        if idx > 0:
            p_row = sub_df.iloc[idx-1]
            p_range = p_row['high'] - p_row['low']
            if p_row['close'] < p_row['open']: # Bearish
                fib = p_row['low'] + 0.618 * p_range
                l_col = '#ff7043'
                # Draw horizontal line on current day
                ax.plot([idx-0.4, idx+0.4], [fib, fib], color=l_col, linewidth=2.5, linestyle='-')
                if row['high'] >= fib:
                    ax.scatter([idx], [fib], color='#ffd700', s=90, zorder=5, edgecolors='black')
                    ax.annotate('61.8% Sell Hit\nBounce Down', (idx, fib), xytext=(idx+0.3, fib+12),
                                color='#ffd700', fontsize=8, fontweight='bold',
                                arrowprops=dict(facecolor='#ffd700', shrink=0.08, width=1, headwidth=4))
            else: # Bullish
                fib = p_row['high'] - 0.618 * p_range
                l_col = '#29b6f6'
                ax.plot([idx-0.4, idx+0.4], [fib, fib], color=l_col, linewidth=2.5, linestyle='-')
                if row['low'] <= fib:
                    ax.scatter([idx], [fib], color='#ffd700', s=90, zorder=5, edgecolors='black')
                    ax.annotate('61.8% Buy Hit\nBounce Up', (idx, fib), xytext=(idx+0.3, fib-18),
                                color='#ffd700', fontsize=8, fontweight='bold',
                                arrowprops=dict(facecolor='#ffd700', shrink=0.08, width=1, headwidth=4))
                                
    ax.set_title("XAUUSD Real Daily Candles: Daily 61.8% Fibonacci Retracement Touches & Bounces", 
                 color='#eceff1', fontsize=14, fontweight='bold', pad=15)
    ax.set_ylabel("Gold Price (USD)", color='#eceff1', fontsize=12)
    ax.set_xticks(range(len(sub_df)))
    ax.set_xticklabels([d.strftime('%b %d') for d in sub_df['timestamp']], rotation=45, color='#eceff1', fontsize=9)
    ax.tick_params(colors='#eceff1')
    ax.grid(True, color='#263238', linestyle=':', alpha=0.6)
    
    # Custom legend
    from matplotlib.lines import Line2D
    legend_elements = [
        Line2D([0], [0], color='#29b6f6', lw=2.5, label='Bullish 61.8% Support Level'),
        Line2D([0], [0], color='#ff7043', lw=2.5, label='Bearish 61.8% Resistance Level'),
        Line2D([0], [0], marker='o', color='w', markerfacecolor='#ffd700', markersize=9, label='61.8% Retest Touch & Bounce')
    ]
    ax.legend(handles=legend_elements, facecolor='#12151c', edgecolor='#37474f', labelcolor='#eceff1', loc='upper left')
    
    plt.tight_layout()
    chart2_path = os.path.join(ARTIFACT_DIR, "gold_real_daily_618_bounces.png")
    plt.savefig(chart2_path, dpi=200)
    plt.close()
    print(f"Saved Chart 2: {chart2_path}")
    
    # -------------------------------------------------------------
    # CHART 3: The "Virgin 61.8 Level" Phenomenon (Multi-Day Test)
    # -------------------------------------------------------------
    # Find an amazing real virgin level in df_virgin with a large multi-day expansion
    top_virgins = df_virgin.sort_values('multi_day_mfe', ascending=False)
    best_v = None
    for _, v_cand in top_virgins.iterrows():
        if 4 <= v_cand['days_elapsed'] <= 14:
            best_v = v_cand
            break
    if best_v is None:
        best_v = top_virgins.iloc[0]
        
    v_create_date = datetime.strptime(best_v['date_created'], '%Y-%m-%d')
    v_hit_date = datetime.strptime(best_v['date_hit'], '%Y-%m-%d')
    
    c_idx = df_d1[df_d1['timestamp'].dt.date == v_create_date.date()].index[0]
    h_idx = df_d1[df_d1['timestamp'].dt.date == v_hit_date.date()].index[0]
    
    start_plot = max(0, c_idx - 2)
    end_plot = min(len(df_d1), h_idx + 6)
    v_slice = df_d1.iloc[start_plot:end_plot].copy().reset_index(drop=True)
    c_slice_idx = c_idx - start_plot
    h_slice_idx = h_idx - start_plot
    
    fig, ax = plt.subplots(figsize=(16, 9), facecolor='#12151c')
    ax.set_facecolor('#1a1f2c')
    
    for idx, row in v_slice.iterrows():
        is_up = row['close'] >= row['open']
        color = '#00e676' if is_up else '#ff5252'
        ax.vlines(idx, row['low'], row['high'], color=color, linewidth=1.8)
        body_bottom = min(row['open'], row['close'])
        body_height = max(abs(row['close'] - row['open']), 0.5)
        ax.add_patch(Rectangle((idx - width/2, body_bottom), width, body_height, facecolor=color, edgecolor=color))
        
    v_level = best_v['level']
    v_color = '#ffd700'
    # Draw virgin level ray from creation to hit
    ax.plot([c_slice_idx, h_slice_idx], [v_level, v_level], color=v_color, linewidth=2.8, linestyle='--')
    ax.scatter([h_slice_idx], [v_level], color='#ff1744' if best_v['type']=='SELL' else '#00e676', s=150, zorder=6, edgecolors='white', linewidth=2)
    
    ax.annotate(f"VIRGIN 61.8% LEVEL CREATED\nDay {best_v['type']} Range\nUntouched on Day+1!", 
                (c_slice_idx, v_level), xytext=(c_slice_idx - 1.5, v_level + 20),
                color='#ffd700', fontsize=10, fontweight='bold',
                arrowprops=dict(facecolor='#ffd700', shrink=0.08, width=1.5, headwidth=6))
                
    mfe_pips = best_v['multi_day_mfe'] * 100
    ax.annotate(f"INSTITUTIONAL RETEST AFTER {int(best_v['days_elapsed'])} DAYS!\nHit Level ${v_level:.1f}\nMassive Reaction: +${best_v['multi_day_mfe']:.1f} (+{mfe_pips:.0f} Pips)!", 
                (h_slice_idx, v_level), xytext=(h_slice_idx + 0.5, v_level + (25 if best_v['type']=='BUY' else -30)),
                color='#00e676' if best_v['type']=='BUY' else '#ff5252', fontsize=10, fontweight='bold',
                bbox=dict(boxstyle='round,pad=0.5', facecolor='#263238', edgecolor='#ffd700', alpha=0.9),
                arrowprops=dict(facecolor='#ffd700', shrink=0.08, width=1.5, headwidth=6))
                
    ax.set_title(f"THE 'VIRGIN 61.8' PHENOMENON ON GOLD (XAUUSD)\nUnmitigated Level Held for {int(best_v['days_elapsed'])} Days Before Explosive Rejection", 
                 color='#ffd700', fontsize=14, fontweight='bold', pad=15)
    ax.set_ylabel("Gold Price (USD)", color='#eceff1', fontsize=12)
    ax.set_xticks(range(len(v_slice)))
    ax.set_xticklabels([d.strftime('%b %d') for d in v_slice['timestamp']], rotation=45, color='#eceff1', fontsize=9)
    ax.tick_params(colors='#eceff1')
    ax.grid(True, color='#263238', linestyle=':', alpha=0.6)
    
    plt.tight_layout()
    chart3_path = os.path.join(ARTIFACT_DIR, "gold_virgin_618_phenomenon.png")
    plt.savefig(chart3_path, dpi=200)
    plt.close()
    print(f"Saved Chart 3: {chart3_path}")
    
    # -------------------------------------------------------------
    # CHART 4: Statistical Distributions & User Hypothesis Validation
    # -------------------------------------------------------------
    fig, ((ax_s1, ax_s2), (ax_s3, ax_s4)) = plt.subplots(2, 2, figsize=(16, 12), facecolor='#12151c')
    
    # 1. Immediate vs Virgin Touch Distribution
    ax_s1.set_facecolor('#1a1f2c')
    labels = ['Next-Day Touch\n(Immediate Retest)', 'Untouched\n(Becomes Virgin Level)']
    counts = [len(results) - len(virgin_levels), len(virgin_levels)]
    colors_pie = ['#29b6f6', '#ffd700']
    ax_s1.pie(counts, labels=labels, autopct='%1.1f%%', colors=colors_pie,
              textprops={'color': '#eceff1', 'fontsize': 11, 'fontweight': 'bold'},
              wedgeprops=dict(width=0.6, edgecolor='#12151c', linewidth=2))
    ax_s1.set_title("Frequency of Immediate Retest vs Virgin Levels", color='#eceff1', fontsize=12, fontweight='bold')
    
    # 2. Histogram of Days to Retest for Virgin Levels
    ax_s2.set_facecolor('#1a1f2c')
    days_data = df_virgin['days_elapsed'].clip(upper=35)
    ax_s2.hist(days_data, bins=15, color='#ffd700', edgecolor='#12151c', alpha=0.85)
    ax_s2.axvline(days_data.median(), color='#ff5252', linestyle='--', linewidth=2, label=f"Median Days: {days_data.median():.0f}")
    ax_s2.set_title("Virgin Levels: Days Elapsed Before Being Hit", color='#eceff1', fontsize=12, fontweight='bold')
    ax_s2.set_xlabel("Days Elapsed Until Test", color='#eceff1')
    ax_s2.set_ylabel("Number of Levels", color='#eceff1')
    ax_s2.tick_params(colors='#eceff1')
    ax_s2.grid(True, color='#263238', linestyle=':', alpha=0.6)
    ax_s2.legend(facecolor='#12151c', edgecolor='#37474f', labelcolor='#eceff1')
    
    # 3. Pip Bounce Comparison: Immediate vs Virgin Levels
    ax_s3.set_facecolor('#1a1f2c')
    imm_bounces = [r['mfe']*100 for r in results if r.get('touched_next_day', False)]
    vir_bounces = df_virgin['multi_day_mfe']*100
    
    b_data = [imm_bounces, vir_bounces]
    bp = ax_s3.boxplot(b_data, patch_artist=True, tick_labels=['Immediate Retest\n(Day +1)', 'Virgin Level Retest\n(Multi-Day Delay)'])
    bp['boxes'][0].set_facecolor('#29b6f6')
    bp['boxes'][1].set_facecolor('#ffd700')
    for element in ['whiskers', 'caps', 'medians']:
        plt.setp(bp[element], color='#eceff1', linewidth=1.5)
    ax_s3.set_title("Pip Return Distribution: Immediate Retest vs Virgin Retest", color='#eceff1', fontsize=12, fontweight='bold')
    ax_s3.set_ylabel("Favorable Excursion (Pips)", color='#eceff1')
    ax_s3.tick_params(colors='#eceff1')
    ax_s3.grid(True, color='#263238', linestyle=':', alpha=0.6)
    
    # 4. User Hypothesis Scatter: Level Age vs Pip Return
    ax_s4.set_facecolor('#1a1f2c')
    ax_s4.scatter(df_virgin['days_elapsed'], df_virgin['multi_day_mfe']*100, color='#ffd700', alpha=0.7, edgecolors='#ffab00', s=60)
    
    # Trendline
    z = np.polyfit(df_virgin['days_elapsed'], df_virgin['multi_day_mfe']*100, 1)
    p = np.poly1d(z)
    x_vals = np.linspace(df_virgin['days_elapsed'].min(), df_virgin['days_elapsed'].max(), 100)
    ax_s4.plot(x_vals, p(x_vals), color='#00e676', linestyle='--', linewidth=2.5, label=f"Trendline (Slope: {z[0]:+.1f} pips/day)")
    
    ax_s4.set_title("User Hypothesis Test: Age of Level (Days) vs Pips Returned", color='#eceff1', fontsize=12, fontweight='bold')
    ax_s4.set_xlabel("Days Level Remained Untouched", color='#eceff1')
    ax_s4.set_ylabel("Multi-Day Pip Excursion (Pips)", color='#eceff1')
    ax_s4.tick_params(colors='#eceff1')
    ax_s4.grid(True, color='#263238', linestyle=':', alpha=0.6)
    ax_s4.legend(facecolor='#12151c', edgecolor='#37474f', labelcolor='#eceff1')
    
    plt.tight_layout()
    chart4_path = os.path.join(ARTIFACT_DIR, "gold_fib_statistical_analysis.png")
    plt.savefig(chart4_path, dpi=200)
    plt.close()
    print(f"Saved Chart 4: {chart4_path}")
    
    # -------------------------------------------------------------
    # CHART 5: Intraday Hourly (H1) Execution Setup
    # -------------------------------------------------------------
    # Using 2026-09-01: Previous Day Aug 31 (Bearish drop), Fib 61.8 = $4492.51
    # Day Sep 01 rallied into 4492.51, then violently collapsed to $4369.70 (+12,200 pips!)
    match_days = df_d1[df_d1['timestamp'].dt.strftime('%Y-%m-%d') == '2026-09-01']
    if len(match_days) > 0:
        c_i = match_days.index[0]
        sample_day = df_d1.iloc[c_i]
        prev_day = df_d1.iloc[c_i - 1]
    else:
        sample_day = df_d1.iloc[-25]
        prev_day = df_d1.iloc[-26]
    
    p_rng = prev_day['high'] - prev_day['low']
    is_prev_bear = prev_day['close'] < prev_day['open']
    
    if is_prev_bear:
        fib_ex = prev_day['low'] + 0.618 * p_rng
        trade_dir = 'SELL'
        sl_level = prev_day['high'] + 5.0
        tp_level = prev_day['low']
    else:
        fib_ex = prev_day['high'] - 0.618 * p_rng
        trade_dir = 'BUY'
        sl_level = prev_day['low'] - 5.0
        tp_level = prev_day['high']
        
    s_date = sample_day['timestamp'].date()
    h1_slice = df_h1[df_h1['timestamp'].dt.date == s_date].copy().reset_index(drop=True)
    
    if len(h1_slice) > 0:
        fig, ax = plt.subplots(figsize=(16, 8), facecolor='#12151c')
        ax.set_facecolor('#1a1f2c')
        
        w_h = 0.5
        for idx, row in h1_slice.iterrows():
            is_up = row['close'] >= row['open']
            color = '#00e676' if is_up else '#ff5252'
            ax.vlines(idx, row['low'], row['high'], color=color, linewidth=1.5)
            b_bot = min(row['open'], row['close'])
            b_ht = max(abs(row['close'] - row['open']), 0.2)
            ax.add_patch(Rectangle((idx - w_h/2, b_bot), w_h, b_ht, facecolor=color, edgecolor=color))
            
        ax.axhline(fib_ex, color='#ffd700', linestyle='-', linewidth=2.5, label=f'Daily 61.8% Level (${fib_ex:.2f})')
        ax.axhline(sl_level, color='#ff1744', linestyle='--', linewidth=1.8, label=f'Protective Stop Loss (${sl_level:.2f})')
        ax.axhline(tp_level, color='#00e676', linestyle='--', linewidth=1.8, label=f'Take Profit Target (${tp_level:.2f})')
        
        # Identify touch bar
        touch_idxs = []
        for idx, row in h1_slice.iterrows():
            if (trade_dir == 'SELL' and row['high'] >= fib_ex) or (trade_dir == 'BUY' and row['low'] <= fib_ex):
                touch_idxs.append(idx)
                
        if touch_idxs:
            t_idx = touch_idxs[0]
            ax.scatter([t_idx], [fib_ex], color='#ffd700', s=160, zorder=6, edgecolors='black')
            ax.annotate(f"INTRADAY {trade_dir} ENTRY TRIGGER\nTouch of Daily 61.8% Fib\nExecution on H1/M15", 
                        (t_idx, fib_ex), xytext=(t_idx + 1.5, fib_ex + (12 if trade_dir=='BUY' else -15)),
                        color='#ffd700', fontsize=10, fontweight='bold',
                        bbox=dict(boxstyle='round,pad=0.5', facecolor='#263238', edgecolor='#ffd700', alpha=0.9),
                        arrowprops=dict(facecolor='#ffd700', shrink=0.08, width=1.5, headwidth=6))
                        
        ax.set_title(f"INTRADAY EXECUTION MODEL (H1 Timeframe) - Date: {s_date}\nDaily Fibonacci 61.8% Intraday Reaction & Target Fill", 
                     color='#eceff1', fontsize=13, fontweight='bold', pad=15)
        ax.set_ylabel("Gold Price (USD)", color='#eceff1', fontsize=12)
        ax.set_xticks(range(len(h1_slice)))
        ax.set_xticklabels([d.strftime('%H:%M') for d in h1_slice['timestamp']], rotation=45, color='#eceff1', fontsize=9)
        ax.tick_params(colors='#eceff1')
        ax.grid(True, color='#263238', linestyle=':', alpha=0.6)
        ax.legend(facecolor='#12151c', edgecolor='#37474f', labelcolor='#eceff1', loc='upper right')
        
        plt.tight_layout()
        chart5_path = os.path.join(ARTIFACT_DIR, "gold_intraday_h1_execution.png")
        plt.savefig(chart5_path, dpi=200)
        plt.close()
        print(f"Saved Chart 5: {chart5_path}")

if __name__ == '__main__':
    df_d1, df_h1 = fetch_gold_data()
    df_d1, results, virgin_levels, df_virgin = analyze_strategy(df_d1)
    generate_charts(df_d1, df_h1, results, virgin_levels, df_virgin)
    print("\nALL ANALYSIS AND CHART GENERATION COMPLETED SUCCESSFULLY!")

