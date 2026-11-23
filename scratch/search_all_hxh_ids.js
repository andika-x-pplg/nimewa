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
  const docs = await search('identifier:(*hunter*x*hunter*) OR identifier:(*hxh*)', 500);
  console.log(`Total docs: ${docs.length}`);
  const movieDocs = docs.filter(d => d.mediatype === 'movies' || (d.item_size && d.item_size > 1000000000));
  console.log(`Movie / Large docs: ${movieDocs.length}`);
  for (const d of movieDocs) {
    console.log(`- [${d.identifier}] "${d.title}" (dl: ${d.downloads}, size: ${(d.item_size / 1e9).toFixed(2)} GB)`);
  }
}

run();

