import json
import urllib.request
import re
import sys
import os

sys.stdout.reconfigure(encoding='utf-8')

# Dynamic resolution of channel ID and public Innertube web key
def resolve_youtube_client(channel_handle="@Danialfx"):
    channel_id = "UCgIWdb21hr1bJxwKLHn1vkQ"
    api_key = os.getenv("YOUTUBE_API_KEY", "")
    try:
        url = f"https://www.youtube.com/{channel_handle}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'})
        with urllib.request.urlopen(req) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
        
        m_cid = re.search(r'itemprop="identifier" content="(UC[a-zA-Z0-9_-]+)"', html)
        if m_cid:
            channel_id = m_cid.group(1)
            
        m_key = re.search(r'"INNERTUBE_API_KEY":"([^"]+)"', html)
        if m_key:
            api_key = m_key.group(1)
    except Exception:
        pass
    return channel_id, api_key

channel_id, api_key = resolve_youtube_client("@Danialfx")

def make_req(url, payload):
    req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers={
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0'
    })
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode('utf-8'))

browse_url = f"https://www.youtube.com/youtubei/v1/browse?key={api_key}"
base_payload = {
    "context": {
        "client": {
            "clientName": "WEB",
            "clientVersion": "2.20240101.00.00",
            "hl": "en",
            "gl": "US"
        }
    },
    "browseId": channel_id,
    "params": "EgZ2aWRlb3PyBgQKAjoA"
}

res = make_req(browse_url, base_payload)
tabs = res.get('contents', {}).get('twoColumnBrowseResultsRenderer', {}).get('tabs', [])
videos = []
continuation_token = None

for t in tabs:
    tr = t.get('tabRenderer', {})
    if tr.get('selected'):
        content = tr.get('content', {})
        rich_grid = content.get('richGridRenderer', {})
        contents = rich_grid.get('contents', [])
        for item in contents:
            rir = item.get('richItemRenderer', {})
            lvm = rir.get('content', {}).get('lockupViewModel', {})
            if lvm:
                content_id = lvm.get('contentId')
                metadata = lvm.get('metadata', {}).get('lockupMetadataViewModel', {})
                title = metadata.get('title', {}).get('content', '')
                videos.append({
                    'videoId': content_id,
                    'title': title,
                    'url': f"https://www.youtube.com/watch?v={content_id}"
                })
            cir = item.get('continuationItemRenderer', {})
            if cir:
                continuation_token = cir.get('continuationEndpoint', {}).get('continuationCommand', {}).get('token')

print(f"Page 1: {len(videos)} videos. Next token: {bool(continuation_token)}")

# Paginate to get more videos
page = 1
while continuation_token and page < 10:
    page += 1
    cont_payload = {
        "context": {
            "client": {
                "clientName": "WEB",
                "clientVersion": "2.20240101.00.00",
                "hl": "en",
                "gl": "US"
            }
        },
        "continuation": continuation_token
    }
    cont_res = make_req(browse_url, cont_payload)
    continuation_token = None
    actions = cont_res.get('onResponseReceivedActions', [])
    for act in actions:
        items = act.get('appendContinuationItemsAction', {}).get('continuationItems', [])
        for item in items:
            rir = item.get('richItemRenderer', {})
            lvm = rir.get('content', {}).get('lockupViewModel', {})
            if lvm:
                content_id = lvm.get('contentId')
                metadata = lvm.get('metadata', {}).get('lockupMetadataViewModel', {})
                title = metadata.get('title', {}).get('content', '')
                videos.append({
                    'videoId': content_id,
                    'title': title,
                    'url': f"https://www.youtube.com/watch?v={content_id}"
                })
            cir = item.get('continuationItemRenderer', {})
            if cir:
                continuation_token = cir.get('continuationEndpoint', {}).get('continuationCommand', {}).get('token')
    print(f"Page {page}: total {len(videos)} videos.")

print(f"\nTOTAL ALL VIDEOS MINED FROM @Danialfx: {len(videos)}")
for i, v in enumerate(videos):
    print(f"{i+1}. [{v['videoId']}] {v['title']}")

os.makedirs('strategies/Danial_FX/source_data', exist_ok=True)
with open('strategies/Danial_FX/source_data/danial_fx_channel_mining.json', 'w', encoding='utf-8') as f:
    json.dump({
        'channel': '@Danialfx',
        'channel_name': 'Ahmad Danial',
        'channel_id': channel_id,
        'total_videos': len(videos),
        'videos': videos
    }, f, indent=2, ensure_ascii=False)
