import urllib.request
import urllib.parse
import json

queries = [
    'Solo Leveling English Sub',
    'Solo Leveling Eng Sub',
    'Solo Leveling EngSub',
    'Solo Leveling Subbed',
    'Solo Leveling Hardsub',
    'Solo Leveling Sub Indo',
    'Solo Leveling Bahasa Indonesia',
    'Ore dake Level Up na Ken English Sub',
    'Ore dake Level Up na Ken Eng Sub',
    'Ore dake Level Up na Ken Sub Indo',
    'Solo Leveling Pahe',
    'Solo Leveling Gogoanime',
    'Solo Leveling Zoro',
    'Solo Leveling AnimePahe',
    'Solo Leveling 1080p Sub',
    'Solo Leveling 720p Sub',
    'Solo Leveling S1 Sub',
    'Solo Leveling S01 Sub',
]

found_items = {}
for q in queries:
    u = f'https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads,mediatype&sort[]=downloads+desc&rows=20&output=json'
    try:
        r = json.loads(urllib.request.urlopen(urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'}), timeout=10).read())
        for doc in r.get('response', {}).get('docs', []):
            ident = doc.get('identifier')
            if ident not in found_items:
                found_items[ident] = doc
    except Exception as e:
        print(f"Error {q}: {e}")

print(f"Total unique found: {len(found_items)}")
for k, v in sorted(found_items.items(), key=lambda x: x[1].get('downloads') or 0, reverse=True):
    print(f"{k} | {v.get('mediatype')} | {v.get('title')} | {v.get('downloads')} dls")

