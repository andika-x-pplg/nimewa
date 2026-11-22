import urllib.request
import json

u = "https://archive.org/metadata/solo-leveling-s1_202610"
req = urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
    thumbs = [f.get('name') for f in data.get('files', []) if 'С1Э01' in f.get('name', '') and f.get('name', '').endswith('.jpg')]
    print(f"Total thumbs for Ep1: {len(thumbs)}")
    for t in thumbs:
        print(t)

