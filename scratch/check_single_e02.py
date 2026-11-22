import urllib.request
import json

u = "https://archive.org/metadata/solo.-leveling.-s-01-e-02.-if.-i.-had.-one.-more.-chance.-1080p.-cr.-web-dl.-mul"
req = urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
    meta = data.get('metadata', {})
    print("Uploader:", meta.get('uploader'))
    print("Files:")
    for f in data.get('files', []):
        print(f.get('name'), f.get('size'), f.get('format'))

