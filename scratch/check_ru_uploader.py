import urllib.request
import json

u = "https://archive.org/metadata/solo-leveling-s1_202610"
req = urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
    meta = data.get('metadata', {})
    uploader = meta.get('uploader')
    print("Uploader:", uploader)

if uploader:
    q = f'uploader:"{uploader}"'
    url = f"https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads&rows=50&output=json"
    req2 = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req2) as r2:
        data2 = json.loads(r2.read())
        for d in data2.get('response', {}).get('docs', []):
            print(" ", d.get('identifier'), '|', d.get('title'))

