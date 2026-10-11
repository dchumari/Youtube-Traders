"""
Scrapes metadata, full descriptions, guests, timestamps, and strategy overviews
for all videos from Chart Fanatics YouTube channel.
"""

import json
import os
import re
import sys
import time
import urllib.request

sys.stdout.reconfigure(encoding='utf-8')

SOURCE_DATA_DIR = r"d:\Projects\AUTOMATIONS\TRADING\Youtube-Traders\strategies\Chart_Fanatics\source_data"
VIDEOS_JSON = os.path.join(SOURCE_DATA_DIR, "videos.json")
ALL_METADATA_PATH = os.path.join(SOURCE_DATA_DIR, "all_videos_metadata.json")

os.makedirs(SOURCE_DATA_DIR, exist_ok=True)

with open(VIDEOS_JSON, "r", encoding="utf-8") as f:
    videos = json.load(f)

print(f"Total videos to scrape: {len(videos)}")

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept-Language': 'en-US,en;q=0.9'
}

all_metadata = []

for idx, v in enumerate(videos, 1):
    vid = v['id']
    url = f"https://www.youtube.com/watch?v={vid}"
    out_file = os.path.join(SOURCE_DATA_DIR, f"{vid}.json")
    
    if os.path.exists(out_file):
        print(f"[{idx}/{len(videos)}] Already scraped: {v['title'][:40]}...")
        with open(out_file, "r", encoding="utf-8") as f:
            all_metadata.append(json.load(f))
        continue
        
    print(f"[{idx}/{len(videos)}] Scraping: {v['title'][:40]}... ({url})")
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode('utf-8')
            
        m = re.search(r'ytInitialPlayerResponse = ({.*?});', html)
        if not m:
            print(f"  Warning: ytInitialPlayerResponse not found for {vid}")
            continue
            
        player_data = json.loads(m.group(1))
        vd = player_data.get('videoDetails', {})
        
        title = vd.get('title', v['title'])
        author = vd.get('author', 'Chart Fanatics')
        length_seconds = vd.get('lengthSeconds', '0')
        views = vd.get('viewCount', '0')
        desc = vd.get('shortDescription', '')
        
        # Parse timestamps / chapters from description
        timestamps = []
        for line in desc.splitlines():
            line_str = line.strip()
            # match pattern like 00:00 - Intro or 1:21:37 - Strategy
            ts_match = re.search(r'(\b\d{1,2}:\d{2}(?::\d{2})?\b)\s*[-:]\s*(.+)', line_str)
            if ts_match:
                timestamps.append({
                    'time': ts_match.group(1),
                    'topic': ts_match.group(2).strip()
                })
                
        # Look for guest in description
        guest = ""
        guest_match = re.search(r'Guest:\s*(.+)', desc, re.IGNORECASE)
        if guest_match:
            guest = guest_match.group(1).strip()
            
        meta_entry = {
            'id': vid,
            'title': title,
            'author': author,
            'length_seconds': int(length_seconds) if length_seconds.isdigit() else 0,
            'length_formatted': f"{int(length_seconds)//3600}h {(int(length_seconds)%3600)//60}m" if length_seconds.isdigit() else v.get('duration', ''),
            'view_count': int(views) if views.isdigit() else 0,
            'subtitles_snippet': v.get('subtitles', ''),
            'url': url,
            'guest': guest,
            'timestamps': timestamps,
            'description': desc
        }
        
        with open(out_file, "w", encoding="utf-8") as f:
            json.dump(meta_entry, f, indent=2)
            
        all_metadata.append(meta_entry)
        print(f"  -> Extracted {len(timestamps)} timestamps, length: {meta_entry['length_formatted']}")
        time.sleep(1) # polite delay
    except Exception as e:
        print(f"  Error scraping {vid}: {e}")
        time.sleep(2)

with open(ALL_METADATA_PATH, "w", encoding="utf-8") as f:
    json.dump(all_metadata, f, indent=2)

print(f"\nCompleted! Saved all metadata to {ALL_METADATA_PATH}")
