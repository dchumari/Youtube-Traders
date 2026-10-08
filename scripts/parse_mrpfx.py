import json
import re

html_path = r"C:\Users\user\.gemini\antigravity\brain\3bdb51a7-be68-4872-a687-720f237a28e3\.system_generated\steps\12\content.md"

with open(html_path, "r", encoding="utf-8") as f:
    text = f.read()

m = re.search(r"var ytInitialData = ({.*?});</script>", text)
if not m:
    m = re.search(r"ytInitialData\s*=\s*({.*?});", text)

if m:
    data = json.loads(m.group(1))
    print("Found ytInitialData!")
    
    # Let's find all richItemRenderer / videoRenderer
    videos = []
    
    def find_videos(obj):
        if isinstance(obj, dict):
            if "videoRenderer" in obj:
                vr = obj["videoRenderer"]
                vid = vr.get("videoId")
                title = vr.get("title", {}).get("runs", [{}])[0].get("text", "")
                if not title:
                    title = vr.get("title", {}).get("simpleText", "")
                desc = ""
                if "descriptionSnippet" in vr:
                    desc = "".join([r.get("text", "") for r in vr["descriptionSnippet"].get("runs", [])])
                views = vr.get("viewCountText", {}).get("simpleText", "")
                published = vr.get("publishedTimeText", {}).get("simpleText", "")
                length = vr.get("lengthText", {}).get("simpleText", "")
                videos.append({
                    "id": vid,
                    "title": title,
                    "published": published,
                    "length": length,
                    "views": views,
                    "desc": desc,
                    "url": f"https://www.youtube.com/watch?v={vid}"
                })
            for v in obj.values():
                find_videos(v)
        elif isinstance(obj, list):
            for item in obj:
                find_videos(item)

    find_videos(data)
    print(f"Total videos parsed: {len(videos)}")
    
    with open("mrpfx_scraped_videos.json", "w", encoding="utf-8") as out:
        json.dump(videos, out, indent=2)
        
    for i, v in enumerate(videos):
        print(f"{i+1}. [{v['length']}] {v['title']} ({v['published']}) -> {v['url']}")
else:
    print("ytInitialData pattern not matched.")
