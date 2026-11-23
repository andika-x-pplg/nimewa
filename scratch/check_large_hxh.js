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
  const docs = await search('title:("Hunter x Hunter") AND mediatype:(movies)', 200);
  console.log(`Total docs: ${docs.length}`);
  const large = docs.filter(d => d.item_size && d.item_size > 5000000000); // > 5GB
  console.log(`Large docs (>5GB): ${large.length}`);
  for (const d of large) {
    console.log(`- [${d.identifier}] "${d.title}" (${(d.item_size/1e9).toFixed(2)} GB, dl: ${d.downloads})`);
  }
}

run();

