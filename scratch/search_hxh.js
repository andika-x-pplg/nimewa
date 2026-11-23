const https = require('https');

function search(q) {
  return new Promise((resolve) => {
    const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(q) + '&fl[]=identifier,title,description,downloads&sort[]=downloads+desc&rows=30&output=json';
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
    'hunter x hunter sub indo',
    'hunter x hunter 2011 sub indo',
    'hunter x hunter indonesia',
    'hxh sub indo',
    'hunter x hunter 2011 hardsub',
    'hunter x hunter 2011 720p',
    'hunter x hunter 2011 complete',
    'hunter x hunter 1-148',
    'hunter x hunter 148',
    'hunter x hunter otakudesu',
    'hunter x hunter samehadaku',
    'hunter x hunter animeindo'
  ];

  const seen = new Set();
  for (const q of queries) {
    const docs = await search(q);
    console.log('=== Query:', q, `(${docs.length} results) ===`);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`- [${d.identifier}] ${d.title} (downloads: ${d.downloads})`);
      }
    }
  }
}

run();

