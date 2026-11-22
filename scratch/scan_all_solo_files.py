import urllib.request
import urllib.parse
import json
import time

u = 'https://archive.org/advancedsearch.php?q="solo+leveling"&fl[]=identifier,title,downloads,mediatype&sort[]=downloads+desc&rows=300&output=json'
req = urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
    docs = data.get('response', {}).get('docs', [])

print(f"Total docs to inspect: {len(docs)}")

video_items = []
for d in docs:
    ident = d.get('identifier')
    # check metadata
    meta_url = f"https://archive.org/metadata/{ident}/files"
    try:
        r2 = urllib.request.urlopen(urllib.request.Request(meta_url, headers={'User-Agent': 'Mozilla/5.0'}), timeout=5)
        files = json.loads(r2.read()).get('result', [])
        v_files = [f.get('name') for f in files if f.get('name', '').endswith('.mp4') or f.get('name', '').endswith('.mkv')]
        if v_files:
            video_items.append((ident, d.get('title'), len(v_files), v_files[:5]))
            print(f"MATCH: {ident} | {d.get('title')} | {len(v_files)} video files:")
            for vf in v_files[:5]:
                print(f"   -> {vf}")
    except Exception as e:
        pass

print(f"\nDone! Found {len(video_items)} items with videos.")

