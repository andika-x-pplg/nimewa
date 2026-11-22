import urllib.request
import urllib.parse
import json

queries = [
    'identifier:*ore*dake*',
    'identifier:*level*up*',
    'identifier:*solo*level*',
    'identifier:*jin*woo*',
]

results = {}
for q in queries:
    u = f'https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads&sort[]=downloads+desc&rows=50&output=json'
    try:
        r = json.loads(urllib.request.urlopen(urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'}), timeout=10).read())
        for d in r.get('response', {}).get('docs', []):
            ident = d.get('identifier')
            if ident not in results:
                results[ident] = (d.get('title'), d.get('downloads'))
    except Exception as e:
        print(f"Error {q}: {e}")

print(f"Total found: {len(results)}")
for k, (t, dls) in sorted(results.items(), key=lambda x: x[1][1] or 0, reverse=True)[:50]:
    print(k, '|', t, '|', dls)

