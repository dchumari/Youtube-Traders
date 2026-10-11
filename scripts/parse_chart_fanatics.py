import json
import os

with open('reports/chart_fanatics_raw.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

def find_all(obj, key):
    res = []
    if isinstance(obj, dict):
        if key in obj:
            res.append(obj[key])
        for v in obj.values():
            res.extend(find_all(v, key))
    elif isinstance(obj, list):
        for item in obj:
            res.extend(find_all(item, key))
    return res

lockups = find_all(data, 'lockupViewModel')

videos = []
seen = set()

for lum in lockups:
    vid = lum.get('contentId')
    if not vid or vid in seen:
        continue
    seen.add(vid)
    
    # Extract title and duration from accessibilityContext or metadata
    label = lum.get('accessibilityContext', {}).get('label', '')
    
    # Metadata ViewModel
    meta = lum.get('metadata', {}).get('lockupMetadataViewModel', {})
    title = meta.get('title', {}).get('content', '')
    if not title and label:
        title = label
        
    meta_rows = meta.get('metadata', {}).get('contentMetadataViewModel', {}).get('metadataRows', [])
    subtitle_parts = []
    for row in meta_rows:
        for part in row.get('metadataParts', []):
            text = part.get('text', {}).get('content', '')
            if text:
                subtitle_parts.append(text)
    
    # Image badge (often contains video length)
    content_img = lum.get('contentImage', {}).get('thumbnailViewModel', {})
    overlays = content_img.get('overlays', [])
    duration = ''
    for ov in overlays:
        tb = ov.get('thumbnailOverlayTimeStatusRenderer', {}).get('text', {}).get('content', '')
        if tb:
            duration = tb
            break
        # Or in other structures
        if 'thumbnailOverlayBadgeViewModel' in ov:
            # check badge
            badge_text = ov.get('thumbnailOverlayBadgeViewModel', {}).get('badge', {}).get('text', '')
            if badge_text:
                duration = badge_text
                
    videos.append({
        'id': vid,
        'title': title,
        'duration': duration,
        'label': label,
        'subtitles': ' • '.join(subtitle_parts),
        'url': f'https://www.youtube.com/watch?v={vid}'
    })

print(f"Total unique videos extracted: {len(videos)}")
for i, v in enumerate(videos):
    print(f"{i+1}. [{v['duration'] or 'N/A'}] {v['title']} ({v['url']})")
    if v['subtitles']:
        print(f"    Subtitles: {v['subtitles']}")

os.makedirs('reports', exist_ok=True)
with open('reports/chart_fanatics_videos.json', 'w', encoding='utf-8') as out:
    json.dump(videos, out, indent=2)

print("\nSaved videos to reports/chart_fanatics_videos.json")
