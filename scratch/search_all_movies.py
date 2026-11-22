import urllib.request
import urllib.parse
import json

q = '(title:"Solo Leveling" OR description:"Solo Leveling" OR "Solo Leveling" OR "Ore dake Level Up") AND mediatype:movies'
url = f"https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads&sort[]=downloads+desc&rows=100&output=json"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
    docs = data.get('response', {}).get('docs', [])
    print(f"Total found: {len(docs)}")
    for d in docs:
        print(d.get('identifier'), '|', d.get('title'))

