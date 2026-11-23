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
    'AnimePahe "Hunter x Hunter"',
    'AnimePahe HxH',
    '"Anime Time" "Hunter x Hunter"',
    'Judas "Hunter x Hunter"',
    'Erai-raws "Hunter x Hunter"',
    'HorribleSubs "Hunter x Hunter"',
    'Kayoanime "Hunter x Hunter"',
    'Hunter x Hunter 2011 480p',
    'Hunter x Hunter 2011 720p',
    'Hunter x Hunter 2011 1080p',
    'Hunter x Hunter Crunchyroll',
    'Hunter x Hunter Batch',
    'Hunter x Hunter Complete',
    'Hunter x Hunter Season 1',
    'Hunter x Hunter episode 1',
    'Hunter x Hunter 001'
  ];

  const seen = new Set();
  for (const q of queries) {
    const docs = await search(q);
    console.log(`=== Query: ${q} (${docs.length}) ===`);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`- [${d.identifier}] "${d.title}" (dl: ${d.downloads}, size: ${d.item_size})`);
      }
    }
  }
}

run();

