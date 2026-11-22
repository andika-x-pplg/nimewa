import urllib.request
import urllib.parse
import json

queries = [
    'Solo Leveling batch',
    'Solo Leveling 01 1080p',
    'Solo Leveling 01 720p',
    'Solo Leveling sub english',
    'Solo Leveling english subbed',
    'Solo Leveling eng subbed',
    'Solo Leveling anime episode 1',
    'Solo Leveling s01e01 1080p',
    'Solo Leveling s01e01 720p',
    'Solo Leveling Crunchyroll sub',
    'Ore dake Level Up na Ken 01',
    'Ore dake Level Up na Ken episode',
    'Ore dake Level Up na Ken sub',
    'Ore dake Level Up sub indo',
    'Ore dake Level Up eng sub',
]

results = {}
for q in queries:
    url = f"https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads,mediatype&sort[]=downloads+desc&rows=15&output=json"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read())
            docs = data.get('response', {}).get('docs', [])
            for d in docs:
                ident = d.get('identifier')
                if ident not in results:
                    results[ident] = d
    except Exception as e:
        print(f"Error {q}: {e}")

print(f"Found {len(results)} items:")
for k, v in sorted(results.items(), key=lambda x: x[1].get('downloads') or 0, reverse=True):
    if v.get('mediatype') == 'movies' or (v.get('downloads') or 0) > 100:
        print(f"{k} | {v.get('mediatype')} | {v.get('title')} | {v.get('downloads')} dls")

