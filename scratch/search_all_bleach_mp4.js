const https = require('https');

function search(q) {
  return new Promise((resolve) => {
    const url = `https://archive.org/advancedsearch.php?q=${encodeURIComponent(q)}&fl[]=identifier,title,description,downloads&sort[]=-downloads&rows=50&output=json`;
    https.get(url, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        try {
          resolve(JSON.parse(d).response.docs);
        } catch(e) {
          resolve([]);
        }
      });
    }).on('error', () => resolve([]));
  });
}

async function main() {
  const docs = await search('mediatype:(movies) AND (bleach OR BLEACH)');
  console.log(`Found ${docs.length} bleach movie items:`);
  for (const d of docs) {
    console.log(`- ${d.identifier} | ${d.title} | ${d.downloads}`);
  }
}

main();

