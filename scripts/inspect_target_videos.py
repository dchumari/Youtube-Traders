import json

with open('mrpfx_detailed_videos.json', 'r', encoding='utf-8') as f:
    vids = json.load(f)

for v in vids:
    if any(k in v['title'].lower() for k in ['boring', 'gold', 'trendline', '15-minute', 'indicator', 'scalping', '50,000']):
        clean_t = v['title'].encode('ascii', 'replace').decode('ascii')
        print(f"ID: {v['id']} | Title: {clean_t}")
        print(f"Keywords: {v.get('keywords', [])}")
        print(f"Desc snippet: {v.get('short_description', '')[:300].encode('ascii', 'replace').decode('ascii')}")
        print("="*60)
