const https = require('https');

function search(q, rows = 100) {
  return new Promise((resolve) => {
    const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(q) + '&fl[]=identifier,title,description,downloads,item_size,mediatype,subject&sort[]=downloads+desc&rows=' + rows + '&output=json';
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
    'subject:("hunter x hunter") AND mediatype:(movies)',
    'subject:("hxh") AND mediatype:(movies)',
    'description:("148") AND title:("Hunter")',
    'description:("Chimera Ant") AND mediatype:(movies)',
    'description:("Greed Island") AND description:("2011") AND mediatype:(movies)'
  ];

  for (const q of queries) {
    const docs = await search(q, 30);
    console.log(`=== Query: ${q} (${docs.length}) ===`);
    for (const d of docs) {
      console.log(`- [${d.identifier}] "${d.title}" (${(d.item_size/1e9).toFixed(2)} GB, dl: ${d.downloads})`);
    }
  }
}

run();

