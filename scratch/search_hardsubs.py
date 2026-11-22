import urllib.request
import urllib.parse
import json

queries = [
    'Solo Leveling 720p',
    'Solo Leveling 1080p',
    'Solo Leveling Pahe',
    'Solo Leveling SubsPlease',
    'Solo Leveling Erai',
    'Solo Leveling Sub Indo',
    'Solo Leveling Indonesia',
    'Solo Leveling Episode 1',
    'Solo Leveling Ep 01',
    'Ore dake Level Up 720p',
    'Ore dake Level Up 1080p',
    'Ore dake Level Up Pahe',
    'Ore dake Level Up Sub',
    'Solo Leveling English Sub',
    'Solo Leveling Eng Sub'
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

print(f"Found {len(results)} unique items:")
for k, (t, dls) in sorted(results.items(), key=lambda x: x[1][1] or 0, reverse=True)[:40]:
    print(f"{k} | {t} | {dls}")

