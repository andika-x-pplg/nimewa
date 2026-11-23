const https = require('https');

function search(q) {
  return new Promise((resolve) => {
    const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(q) + '&fl[]=identifier,title,description,downloads,item_size,mediatype&sort[]=downloads+desc&rows=20&output=json';
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
  const fansubs = [
    'Underwater "Hunter"',
    'DameDesuYo "Hunter"',
    'Chyuu "Hunter"',
    'GotWoot "Hunter"',
    'BakedFish "Hunter"',
    'Cleo "Hunter"',
    'Coalgirls "Hunter"',
    'Erai "Hunter x Hunter"',
    'Judas "Hunter x Hunter 2011"'
  ];

  for (const q of fansubs) {
    const docs = await search(q);
    if (docs.length > 0) {
      console.log(`=== Query: ${q} (${docs.length}) ===`);
      for (const d of docs) {
        console.log(`- [${d.identifier}] "${d.title}" (${(d.item_size/1e9).toFixed(2)} GB, dl: ${d.downloads})`);
      }
    }
  }
}

run();

