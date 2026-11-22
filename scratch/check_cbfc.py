import urllib.request
import json

u = "https://archive.org/metadata/cbfc-ecinepramaan-100010292300010302"
req = urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
    print("Files:")
    for f in data.get('files', []):
        print(f.get('name'), f.get('size'), f.get('format'))

