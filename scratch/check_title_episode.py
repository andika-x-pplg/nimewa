import urllib.request
import urllib.parse
import json

u = 'https://archive.org/advancedsearch.php?q=title:("Solo+Leveling"+AND+Episode)&fl[]=identifier,title,downloads&output=json'
req = urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
    for d in data.get('response', {}).get('docs', []):
        print(d.get('identifier'), '|', d.get('title'), '|', d.get('downloads'))

