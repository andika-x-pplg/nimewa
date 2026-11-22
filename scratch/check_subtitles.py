import urllib.request
import urllib.parse
import json

def search(q):
    url = f"https://archive.org/advancedsearch.php?q={urllib.parse.quote(q)}&fl[]=identifier,title,description,downloads&sort[]=downloads+desc&rows=20&page=1&output=json"
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            res = json.loads(r.read())
            docs = res.get('response', {}).get('docs', [])
            print(f"=== SEARCH: {q} ===")
            for d in docs:
                print(d.get('identifier'), '|', d.get('title'))
    except Exception as e:
        print('Error:', e)

search('mediatype:(movies) AND "solo leveling"')
search('mediatype:(movies) AND "koe no katachi"')
search('mediatype:(movies) AND "silent voice"')