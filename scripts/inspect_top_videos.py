import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

with open(r'strategies\Chart_Fanatics\source_data\all_videos_metadata.json', 'r', encoding='utf-8') as f:
    vids = json.load(f)

print(f"Loaded {len(vids)} videos.")
for i, v in enumerate(vids):
    print("=" * 80)
    print(f"#{i+1}: [{v['id']}] {v['title']} (Length: {v['length_formatted']})")
    if v.get('guest'):
        print(f"  Guest: {v['guest']}")
    if v.get('timestamps'):
        print(f"  Timestamps ({len(v['timestamps'])}):")
        for ts in v['timestamps']:
            print(f"    {ts['time']} - {ts['topic']}")
    else:
        # print first 5 lines of description
        lines = [l.strip() for l in v['description'].splitlines() if l.strip() and not l.startswith('http') and not l.startswith('90%') and not l.startswith('30%') and not l.startswith('20%')][:5]
        print("  Description Summary:")
        for l in lines:
            print(f"    {l}")
