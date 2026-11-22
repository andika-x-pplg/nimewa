import urllib.request
import urllib.parse
import json

queries = [
    'identifier:solo-leveling*',
    'identifier:sololeveling*',
    'identifier:*solo-leveling*',
    'identifier:ore-dake*',
    'identifier:oredake*',
    'title:"Solo Leveling" AND (format:h.264 OR format:MPEG4 OR format:Matroska)',
    'description:"Solo Leveling" AND (format:h.264 OR format:MPEG4 OR format:Matroska)',
]

all_items = {}
for q in queries:
    url = f"https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads,mediatype,publicdate&sort[]=downloads+desc&rows=50&output=json"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read())
            docs = data.get('response', {}).get('docs', [])
            for d in docs:
                i = d.get('identifier')
                if i not in all_items:
                    all_items[i] = d
    except Exception as e:
        print(f"Error {q}: {e}")

print(f"Total unique identifiers: {len(all_items)}")
# Print items with movies or with downloads
for k, v in sorted(all_items.items(), key=lambda x: x[1].get('downloads') or 0, reverse=True):
    if v.get('mediatype') == 'movies' or (v.get('downloads') or 0) > 100:
        print(f"{k} | mediatype: {v.get('mediatype')} | {v.get('title')} | {v.get('downloads')} dls")

