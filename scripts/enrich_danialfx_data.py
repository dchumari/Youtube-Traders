import json
import os

with open('strategies/Danial_FX/source_data/danial_fx_channel_mining.json', 'r', encoding='utf-8') as f:
    raw = json.load(f)

videos = raw.get('videos', [])

# Categorize and enrich each video
categorized = {
    'quasimodo_qm': [],
    'bbma_rem': [],
    'awesome_oscillator_ao': [],
    'supply_demand_snd': [],
    'full_margin_layering': [],
    'gold_scalping_analysis': [],
    'tutorials': []
}

for v in videos:
    t = v.get('title', '').upper()
    v_id = v.get('videoId')
    
    tags = []
    if 'QM' in t or 'QUASIMODO' in t:
        tags.append('Quasimodo (QM)')
        categorized['quasimodo_qm'].append(v)
    if 'BBMA' in t or 'REM' in t:
        tags.append('BBMA (Bollinger Bands Moving Average)')
        categorized['bbma_rem'].append(v)
    if 'AO' in t:
        tags.append('Awesome Oscillator (AO)')
        categorized['awesome_oscillator_ao'].append(v)
    if 'SND' in t or 'SNR' in t or 'SUPPLY' in t or 'DEMAND' in t:
        tags.append('Supply and Demand (SND / SNR)')
        categorized['supply_demand_snd'].append(v)
    if 'MARGIN' in t or 'FULL MARGIN' in t or 'PROFIT' in t or '300 TO' in t or 'SCALPING' in t:
        tags.append('Aggressive Scalping & Full Margin Layering')
        categorized['full_margin_layering'].append(v)
    if 'GOLD' in t:
        tags.append('Gold (XAUUSD)')
        categorized['gold_scalping_analysis'].append(v)
    if 'TUTORIAL' in t or 'BASIC' in t or 'HOW TO' in t or 'WAY TO' in t:
        tags.append('Educational Tutorial')
        categorized['tutorials'].append(v)
        
    v['strategy_tags'] = tags

enriched_data = {
    'channel': '@Danialfx',
    'creator': 'Ahmad Danial',
    'location': 'Malaysia',
    'focus_assets': ['XAUUSD (Gold)', 'US30 (Dow Jones)'],
    'core_philosophy': 'Aggressive sniper reversals (Quasimodo + SND) and trend re-entries (BBMA REM) with Awesome Oscillator momentum confluence, compounded via aggressive pyramiding (layering positions in profit) to scale small accounts ($20, $50, $100) into massive exponential gains.',
    'total_videos': len(videos),
    'categorized_counts': {k: len(v) for k, v in categorized.items()},
    'videos': videos
}

with open('strategies/Danial_FX/source_data/danial_fx_channel_mining.json', 'w', encoding='utf-8') as f:
    json.dump(enriched_data, f, indent=2, ensure_ascii=False)

print(f"Enriched {len(videos)} videos. Categories:")
for k, v in categorized.items():
    print(f"  {k}: {len(v)} videos")
