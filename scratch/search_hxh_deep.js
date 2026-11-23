const https = require('https');

function search(q) {
  return new Promise((resolve) => {
    const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(q) + '&fl[]=identifier,title,description,downloads,item_size,uploader&sort[]=downloads+desc&rows=50&output=json';
    https.get(url, res => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve(json.response.docs);
        } catch (e) {
          resolve([]);
        }
      });
    }).on('error', () => resolve([]));
  });
}

async function run() {
  const queries = [
    'title:("Hunter x Hunter") AND (hardsub OR "eng sub" OR "sub eng" OR "sub indo")',
    'description:("Hunter x Hunter") AND ("hardsub" OR "sub indo")',
    'title:("Hunter x Hunter 2011") AND mediatype:(movies)',
    'title:("HxH 2011") AND mediatype:(movies)',
    'identifier:(hunter-x-hunter-2011*)',
    'identifier:(hunter-x-hunter*complete*)',
    'identifier:(*hxh*2011*)',
    'identifier:(*hunterxhunter*)'
  ];

  const seen = new Set();
  for (const q of queries) {
    const docs = await search(q);
    console.log(`=== Query: ${q} (${docs.length}) ===`);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`- [${d.identifier}] "${d.title}" (dl: ${d.downloads}, size: ${d.item_size}, uploader: ${d.uploader})`);
      }
    }
  }
}

run();

