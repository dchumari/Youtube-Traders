import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open("d:\\Projects\\AUTOMATIONS\\TRADING\\Youtube-Traders\\mrpfx_detailed_videos.json", "r", encoding="utf-8") as f:
    videos = json.load(f)

print(f"Total videos: {len(videos)}")
for i, v in enumerate(videos):
    desc = v.get("short_description", "").replace("\n", " ")
    print(f"{i+1:02d}. Title: {v['title']}")
    print(f"    Keywords: {', '.join(v.get('keywords', []))}")
    print(f"    Desc: {desc[:200]}...")
    print("-" * 60)
