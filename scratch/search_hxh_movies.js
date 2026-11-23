const https = require('https');

function search(q) {
  return new Promise((resolve) => {
    const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(q) + '&fl[]=identifier,title,description,downloads,item_size&sort[]=downloads+desc&rows=50&output=json';
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
    'title:("Hunter x Hunter") AND mediatype:(movies)',
    'title:("Hunter Hunter") AND mediatype:(movies)',
    'description:("Hunter x Hunter") AND mediatype:(movies)',
    'identifier:(*hunter*x*hunter*) AND mediatype:(movies)',
    'identifier:(*hxh*) AND mediatype:(movies)'
  ];

  const seen = new Set();
  for (const q of queries) {
    const docs = await search(q);
    console.log(`=== Query: ${q} (${docs.length}) ===`);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`- [${d.identifier}] ${d.title} (downloads: ${d.downloads}, size: ${d.item_size})`);
      }
    }
  }
}

run();

