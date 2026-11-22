import urllib.request
import json

url = "https://archive.org/metadata/sololevelinggggg"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
    print("Files in sololevelinggggg:")
    for f in data.get('files', []):
        print(f.get('name'), f.get('size'), f.get('format'))

