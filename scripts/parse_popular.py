import json
import re

def parse_html_videos(html_path):
    with open(html_path, "r", encoding="utf-8") as f:
        text = f.read()

    m = re.search(r"var ytInitialData = ({.*?});</script>", text)
    if not m:
        m = re.search(r"ytInitialData\s*=\s*({.*?});", text)

    if not m:
        return []
        
    data = json.loads(m.group(1))
    videos = []

    def find_lockups(obj):
        if isinstance(obj, dict):
            if "lockupViewModel" in obj:
                lvm = obj["lockupViewModel"]
                vid = lvm.get("contentId")
                
                metadata = lvm.get("metadata", {})
                title_obj = metadata.get("lockupMetadataViewModel", {}).get("title", {})
                title = title_obj.get("content", "")
                
                duration = ""
                overlays = lvm.get("contentImage", {}).get("thumbnailViewModel", {}).get("overlays", [])
                for ov in overlays:
                    badges = ov.get("thumbnailBottomOverlayViewModel", {}).get("badges", [])
                    for b in badges:
                        txt = b.get("thumbnailBadgeViewModel", {}).get("text")
                        if txt:
                            duration = txt

                meta_snippets = []
                rows = metadata.get("lockupMetadataViewModel", {}).get("metadata", {}).get("contentMetadataViewModel", {}).get("metadataRows", [])
                for r in rows:
                    parts = r.get("metadataParts", [])
                    for p in parts:
                        t = p.get("text", {}).get("content", "")
                        if t:
                            meta_snippets.append(t)
                
                if vid and title:
                    videos.append({
                        "id": vid,
                        "title": title,
                        "duration": duration,
                        "metadata": meta_snippets,
                        "url": f"https://www.youtube.com/watch?v={vid}"
                    })
            for v in obj.values():
                find_lockups(v)
        elif isinstance(obj, list):
            for item in obj:
                find_lockups(item)

    find_lockups(data)
    return videos

p1 = r"C:\Users\user\.gemini\antigravity\brain\3bdb51a7-be68-4872-a687-720f237a28e3\.system_generated\steps\12\content.md"
p2 = r"C:\Users\user\.gemini\antigravity\brain\3bdb51a7-be68-4872-a687-720f237a28e3\.system_generated\steps\34\content.md"

v1 = parse_html_videos(p1)
v2 = parse_html_videos(p2)

all_dict = {}
for v in v1 + v2:
    if v['id'] not in all_dict:
        all_dict[v['id']] = v

combined = list(all_dict.values())
print(f"Total combined unique videos: {len(combined)}")

with open("d:\\Projects\\AUTOMATIONS\\TRADING\\Youtube-Traders\\mrpfx_all_videos.json", "w", encoding="utf-8") as out:
    json.dump(combined, out, indent=2, ensure_ascii=False)

for i, v in enumerate(combined):
    clean_title = v['title'].encode('ascii', 'replace').decode('ascii')
    clean_meta = ' | '.join(v['metadata']).encode('ascii', 'replace').decode('ascii')
    print(f"{i+1:02d}. [{v['duration']}] {clean_title} | {clean_meta}")
