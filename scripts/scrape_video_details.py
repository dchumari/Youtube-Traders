import requests
import json
import re

with open("d:\\Projects\\AUTOMATIONS\\TRADING\\Youtube-Traders\\mrpfx_all_videos.json", "r", encoding="utf-8") as f:
    videos = json.load(f)

print(f"Total videos to fetch metadata for: {len(videos)}")

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept-Language": "en-US,en;q=0.9",
}

detailed_videos = []

for idx, v in enumerate(videos):
    vid = v["id"]
    try:
        r = requests.get(f"https://www.youtube.com/watch?v={vid}", headers=headers, timeout=10)
        text = r.text
        
        # Look for shortDescription
        short_desc = ""
        m_desc = re.search(r'"shortDescription":"(.*?)"', text)
        if m_desc:
            short_desc = m_desc.group(1).encode('utf-8').decode('unicode_escape', 'ignore')
            
        # Look for keywords/tags
        keywords = []
        m_keys = re.search(r'"keywords":(\[.*?\])', text)
        if m_keys:
            try:
                keywords = json.loads(m_keys.group(1))
            except:
                pass
                
        # Look for title in player response
        m_title = re.search(r'"title":"(.*?)"', text)
        title = v["title"]
        if m_title:
            try:
                t = m_title.group(1).encode('utf-8').decode('unicode_escape', 'ignore')
                if t: title = t
            except:
                pass

        detailed_videos.append({
            "id": vid,
            "title": title,
            "duration": v.get("duration", ""),
            "url": v["url"],
            "short_description": short_desc[:1000],
            "keywords": keywords[:10]
        })
        print(f"[{idx+1}/{len(videos)}] Scraped: {title[:60]}")
    except Exception as e:
        print(f"[{idx+1}/{len(videos)}] Error for {vid}: {e}")
        detailed_videos.append(v)

with open("d:\\Projects\\AUTOMATIONS\\TRADING\\Youtube-Traders\\mrpfx_detailed_videos.json", "w", encoding="utf-8") as out:
    json.dump(detailed_videos, out, indent=2, ensure_ascii=False)

print("Saved mrpfx_detailed_videos.json successfully!")
