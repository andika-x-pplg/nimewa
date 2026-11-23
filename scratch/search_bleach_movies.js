const https = require('https');

function search(query) {
  return new Promise((resolve, reject) => {
    const url = `https://archive.org/advancedsearch.php?q=${encodeURIComponent(query)}&fl[]=identifier,title,downloads,item_size,description&sort[]=downloads+desc&rows=30&output=json`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve(parsed.response.docs);
        } catch(e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

async function run() {
  const docs = await search('title:(Bleach) AND mediatype:(movies)');
  console.log(`Found ${docs.length} items:`);
  for (const d of docs) {
    console.log(`- ${d.identifier}: ${d.title} (downloads: ${d.downloads})`);
  }
}

run();

