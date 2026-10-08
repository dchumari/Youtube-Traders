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
    s = json.dumps(data)
    print("ytInitialData size:", len(s))
    
    # search for watch?v= or videoId
    vids = re.findall(r'/watch\?v=([a-zA-Z0-9_-]{11})', s)
    vids2 = re.findall(r'"videoId":\s*"([a-zA-Z0-9_-]{11})"', s)
    all_vids = list(dict.fromkeys(vids + vids2))
    print("Found video IDs:", len(all_vids), all_vids[:10])
    
    # Let's inspect some of the structure around video IDs
    sample = s[s.find(all_vids[0])-200:s.find(all_vids[0])+600] if all_vids else "None"
    print("Sample around first vid:\n", sample)
