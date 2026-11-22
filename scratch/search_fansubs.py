import urllib.request
import urllib.parse
import json

queries = [
    'samehadaku "Solo Leveling"',
    'otakudesu "Solo Leveling"',
    'animepahe "Solo Leveling"',
    'gogoanime "Solo Leveling"',
    'bilibili "Solo Leveling"',
    '"Solo Leveling" "sub indo"',
    '"Solo Leveling" "eng sub"',
    '"Solo Leveling" "english sub"',
    'samehadaku "Ore dake"',
    'otakudesu "Ore dake"',
    'animepahe "Ore dake"',
    '"Ore dake Level Up na Ken"',
    '"Ore dake" "1080p"',
    '"Ore dake" "720p"',
    'Solo Leveling 2024 sub',
    'Solo Leveling 2024 eng',
    'Solo Leveling 2024 indo',
    'Solo Leveling S01 E',
    'Solo Leveling 01 02 03',
]

results = {}
for q in queries:
    url = f"https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads&sort[]=downloads+desc&rows=10&output=json"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            data = json.loads(r.read())
            docs = data.get('response', {}).get('docs', [])
            for d in docs:
                ident = d.get('identifier')
                if ident not in results:
                    results[ident] = (d.get('title'), d.get('downloads'))
    except Exception as e:
        print(f"Error {q}: {e}")

print(f"Found {len(results)} items:")
for k, (t, dls) in sorted(results.items(), key=lambda x: x[1][1] or 0, reverse=True):
    print(f"{k} | {t} | {dls}")

