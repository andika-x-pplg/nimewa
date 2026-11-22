import urllib.request
import json

url = "https://archive.org/metadata/SololevelingKAJ1325"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
    meta = data.get('metadata', {})
    print("Uploader:", meta.get('uploader'))
    print("Creator:", meta.get('creator'))
    print("Addeddate:", meta.get('addeddate'))
    print("Publicdate:", meta.get('publicdate'))

