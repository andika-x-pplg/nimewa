import urllib.request
import urllib.parse
import json

q = 'uploader:"gtwenty0729matt@protonmail.ch"'
url = f"https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads&rows=50&output=json"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req) as r:
    data = json.loads(r.read())
    for d in data.get('response', {}).get('docs', []):
        print(d.get('identifier'), '|', d.get('title'))

