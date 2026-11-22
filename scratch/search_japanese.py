import urllib.request
import urllib.parse
import json

queries = [
    '俺だけレベルアップな件',
    '俺だけレベルアップ',
    'Ore dake Level Up',
    'Oredake',
    'Ore dake',
    'Ore_dake',
]

results = {}
for q in queries:
    u = f'https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,downloads,mediatype&sort[]=downloads+desc&rows=30&output=json'
    try:
        r = json.loads(urllib.request.urlopen(urllib.request.Request(u, headers={'User-Agent': 'Mozilla/5.0'}), timeout=10).read())
        for d in r.get('response', {}).get('docs', []):
            ident = d.get('identifier')
            if ident not in results:
                results[ident] = d
    except Exception as e:
        print(f"Error {q}: {e}")

print(f"Total results: {len(results)}")
for k, v in sorted(results.items(), key=lambda x: x[1].get('downloads') or 0, reverse=True):
    if v.get('mediatype') == 'movies' or 'level' in (v.get('title') or '').lower() or 'solo' in (v.get('title') or '').lower():
        print(k, '|', v.get('title'), '|', v.get('downloads'))

