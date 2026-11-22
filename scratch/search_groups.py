import urllib.request
import urllib.parse
import json

queries = [
    '"SubsPlease" "Solo Leveling"',
    '"SubsPlease" "Ore dake"',
    '"Erai-raws" "Solo Leveling"',
    '"Erai-raws" "Ore dake"',
    '"Judas" "Solo Leveling"',
    '"HorribleSubs" "Solo Leveling"',
    '"NanDesuKa" "Solo Leveling"',
    '"Samehadaku" "Solo Leveling"',
    '"Otakudesu" "Solo Leveling"',
    '"Bilibili" "Solo Leveling"',
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

