import urllib.request
import urllib.parse
import json

queries = [
    'Solo.Leveling.S01E01',
    'Solo Leveling S01E01',
    'Solo Leveling S01E02',
    'Solo Leveling E01 1080p',
    'Solo Leveling E01 720p',
    'Solo.Leveling.1080p',
    'Solo.Leveling.720p',
    'Ore.dake.Level.Up.S01E01',
    'Ore dake Level Up S01E01',
]

results = {}
for q in queries:
    u = f'https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads,mediatype&sort[]=downloads+desc&rows=20&output=json'
    try:
        r = json.loads(urllib.request.urlopen(urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'}), timeout=10).read())
        for d in r.get('response', {}).get('docs', []):
            ident = d.get('identifier')
            if ident not in results:
                results[ident] = d
    except Exception as e:
        print(f"Error {q}: {e}")

print(f"Total results: {len(results)}")
for k, v in results.items():
    print(k, '|', v.get('title'), '|', v.get('downloads'))

