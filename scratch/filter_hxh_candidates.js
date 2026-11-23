const https = require('https');

function search(q, rows = 1000) {
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
  const docs = await search('(identifier:(*hunter*x*hunter*) OR identifier:(*hxh*) OR title:("Hunter x Hunter")) AND mediatype:(movies)', 1000);
  console.log(`Total movies: ${docs.length}`);
  
  // Filter for docs likely to be 2011 anime series (e.g. size > 5GB or title contains 2011 or 148 or season)
  const seriesDocs = docs.filter(d => {
    const s = ((d.identifier || '') + ' ' + (d.title || '') + ' ' + (d.description || '')).toLowerCase();
    const isLarge = d.item_size && d.item_size > 5000000000; // > 5GB
    const is2011 = s.includes('2011');
    const is148 = s.includes('148');
    const isNot1999 = !s.includes('1999');
    return (isLarge || is2011 || is148) && isNot1999;
  });

  console.log(`Filtered candidates: ${seriesDocs.length}`);
  for (const d of seriesDocs) {
    console.log(`- [${d.identifier}] "${d.title}" (dl: ${d.downloads}, size: ${(d.item_size / 1e9).toFixed(2)} GB)`);
  }
}

run();

