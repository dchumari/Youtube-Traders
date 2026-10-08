import requests
import json
import re
import xml.etree.ElementTree as ET

def get_transcript(video_id):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept-Language": "en-US,en;q=0.9",
    }
    url = f"https://www.youtube.com/watch?v={video_id}"
    resp = requests.get(url, headers=headers)
    text = resp.text
    
    # Check player captions
    m = re.search(r'"captionTracks":\s*(\[.*?\])', text)
    if not m:
        return None, "No captionTracks in page"
        
    try:
        caption_tracks = json.loads(m.group(1))
    except Exception as e:
        return None, str(e)
        
    if not caption_tracks:
        return None, "Empty captionTracks"
        
    track_url = caption_tracks[0].get("baseUrl")
    if not track_url:
        return None, "No baseUrl in track"
        
    cap_resp = requests.get(track_url, headers=headers)
    # Parse xml or json
    try:
        root = ET.fromstring(cap_resp.text)
        lines = []
        for text_tag in root.findall(".//text"):
            lines.append(text_tag.text or "")
        return " ".join(lines), None
    except Exception as e:
        return cap_resp.text[:500], None

test_vids = [
    "9gy0deRBAm4", # Give Me 10 Minutes...
    "vLdOrMRJ8-4", # FREE Trading Indicator
    "ixZ96xRz4qk", # Made Over $50k on GOLD and NASDAQ
    "o2tyEAXRT88", # Trading Gold Was HARD
]

for vid in test_vids:
    transcript, err = get_transcript(vid)
    if transcript:
        print(f"[{vid}] Transcript length: {len(transcript)} chars")
        print(f"Sample: {transcript[:250]}...\n")
    else:
        print(f"[{vid}] Error: {err}")
