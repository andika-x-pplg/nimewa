import urllib.request
import urllib.parse
import json

queries = [
    'Solo Leveling episode 1 mp4',
    'Solo Leveling episode 01 mp4',
    'Solo Leveling ep 1 mp4',
    'Solo Leveling ep 01 mp4',
    'Solo Leveling 01 mp4',
    'Solo Leveling 02 mp4',
    'Solo Leveling S1E1',
    'Solo Leveling S01E01 mp4',
    'Ore dake Level Up na Ken 01 mp4',
    'Ore dake Level Up na Ken E01',
    'Ore dake Level Up 01 mp4',
]

results = {}
for q in queries:
    url = f"https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads&sort[]=downloads+desc&rows=20&output=json"
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

