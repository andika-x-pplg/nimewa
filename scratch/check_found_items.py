import urllib.request
import urllib.parse
import json

def get_meta(item):
    url = f"https://archive.org/metadata/{item}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read())
            files = data.get('files', [])
            print(f"=== METADATA FOR {item} ===")
            for f in files:
                name = f.get('name', '')
                if any(name.endswith(ext) for ext in ['.mp4', '.mkv', '.srt', '.vtt', '.ass']):
                    print(f"  {name} | size: {f.get('size')} | fmt: {f.get('format')}")
    except Exception as e:
        print(f"Error {item}: {e}")

get_meta('koe-no-katachi-1080p')
get_meta('a-silent-voice-subbed')
get_meta('sl-01-720p')
get_meta('solo-leveling_202511')
