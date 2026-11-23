const https = require('https');

function search(q) {
  return new Promise((resolve) => {
    const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(q) + '&fl[]=identifier,title,description,downloads,item_size,mediatype&sort[]=downloads+desc&rows=100&output=json';
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
    'identifier:(*hunter*148*)',
    'identifier:(*hxh*148*)',
    'identifier:(*hunter*2011*)',
    'identifier:(*hunter*complete*)',
    'identifier:(*hxh*complete*)'
  ];

  for (const q of queries) {
    const docs = await search(q);
    console.log(`=== Query: ${q} (${docs.length}) ===`);
    for (const d of docs) {
      console.log(`- [${d.identifier}] "${d.title}" (${(d.item_size/1e9).toFixed(2)} GB, dl: ${d.downloads})`);
    }
  }
}

run();

