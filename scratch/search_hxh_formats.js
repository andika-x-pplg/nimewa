const https = require('https');

function search(q, rows = 100) {
  return new Promise((resolve) => {
    const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(q) + '&fl[]=identifier,title,description,downloads,item_size&sort[]=downloads+desc&rows=' + rows + '&output=json';
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
  const q = '("Hunter x Hunter" OR "HxH") AND (format:MPEG4 OR format:h.264) AND (2011 OR 148)';
  const docs = await search(q, 100);
  console.log(`Results: ${docs.length}`);
  for (const d of docs) {
    console.log(`- [${d.identifier}] "${d.title}" (dl: ${d.downloads}, size: ${(d.item_size / 1e9).toFixed(2)} GB)`);
  }
}

run();

