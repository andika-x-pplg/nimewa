const https = require('https');

function searchArchive(query) {
  return new Promise((resolve, reject) => {
    const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(query) + '&fl[]=identifier,title,description,downloads,item_size&sort[]=-downloads&rows=25&output=json';
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data).response.docs);
        } catch(e) {
          console.error('Parse error:', e.message, data.slice(0, 100));
          resolve([]);
        }
      });
    }).on('error', reject);
  });
}

async function run() {
  const queries = {
    'Demon Slayer S2': '("demon slayer" OR kimetsu) (yuukaku OR "entertainment district" OR "season 2" OR s02) mediatype:movies',
    'Death Note': '("death note" OR deathnote) (animepahe OR horriblesubs OR subbed OR "sub indo" OR "sub ita" OR "judas" OR "coalgirls") mediatype:movies',
    'Hunter x Hunter': '("hunter x hunter" OR hxh) 2011 (animepahe OR horriblesubs OR subbed OR "sub indo") mediatype:movies',
    'Bleach': 'bleach (animepahe OR horriblesubs OR judas OR "sub indo" OR subbed) mediatype:movies'
  };

  for (const [name, q] of Object.entries(queries)) {
    console.log('\n=== ' + name + ' ===');
    const docs = await searchArchive(q);
    for (const d of docs) {
      console.log(`${d.identifier} | ${(d.title || '').substring(0, 60)} | ${d.downloads || 0} dl`);
    }
  }
}

run();

