import urllib.request
import json

items = [
    'solo-leveling-2024-1x-1-pelispedia',
    'SoloLevelingThangCapMotMinhATF',
    'solo-leveling-lvl-1',
    'solo-leveling-s1-gambar',
]

for item in items:
    url = f"https://archive.org/metadata/{item}"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read())
            print(f"=== {item} : {data.get('metadata', {}).get('title')} ===")
            for f in data.get('files', []):
                name = f.get('name', '')
                if any(name.endswith(ext) for ext in ['.mp4', '.mkv']):
                    print(f"  {name} | size: {f.get('size')} | format: {f.get('format')}")
    except Exception as e:
        print(f"Error {item}: {e}")

