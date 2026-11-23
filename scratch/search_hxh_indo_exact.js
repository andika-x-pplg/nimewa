const https = require('https');

function search(q, rows = 100) {
  return new Promise((resolve) => {
    const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(q) + '&fl[]=identifier,title,description,downloads,item_size,mediatype&sort[]=downloads+desc&rows=' + rows + '&output=json';
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
    '("Hunter" OR "HxH") AND ("sub indo" OR "subtitle indonesia" OR "sub-indo" OR "tamat" OR "lengkap")',
    '"Hunter x Hunter" AND ("Indonesia" OR "Indo")',
    '"Hunter x Hunter (2011)" AND ("Indonesia" OR "Indo")'
  ];

  for (const q of queries) {
    const docs = await search(q, 50);
    console.log(`=== Query: ${q} (${docs.length}) ===`);
    for (const d of docs) {
      console.log(`- [${d.identifier}] "${d.title}" (${(d.item_size/1e9).toFixed(2)} GB, mediatype: ${d.mediatype})`);
    }
  }
}

run();

