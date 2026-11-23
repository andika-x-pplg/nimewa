const { getItemMetadata } = require('./archive_util');
const https = require('https');

function search(q) {
  return new Promise((resolve) => {
    const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(q) + '&fl[]=identifier,title,description,downloads,item_size&sort[]=downloads+desc&rows=30&output=json';
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

async function inspectCandidates() {
  const identifiers = [
    'hxh11',
    'hunter-x-hunter-2011_202605',
    'hunterxhunter_202605',
    'Data-Live_Hunter_X_Hunter_BobMarley',
    'SDHXH'
  ];

  for (const id of identifiers) {
    try {
      const meta = await getItemMetadata(id);
      const files = meta.files || [];
      const mp4s = files.filter(f => f.name.endsWith('.mp4'));
      const mkvs = files.filter(f => f.name.endsWith('.mkv'));
      console.log(`=== ${id} ===`);
      console.log('Title:', meta.metadata?.title);
      console.log(`Total files: ${files.length}, MP4s: ${mp4s.length}, MKVs: ${mkvs.length}`);
      if (mp4s.length > 0) {
        console.log('Sample MP4s:', mp4s.slice(0, 3).map(f => f.name));
        console.log('Last MP4:', mp4s[mp4s.length - 1]?.name);
      } else if (mkvs.length > 0) {
        console.log('Sample MKVs:', mkvs.slice(0, 3).map(f => f.name));
      }
    } catch (e) {
      console.log(`Error fetching ${id}:`, e.message);
    }
  }

  // Indonesian queries
  const indoQueries = [
    'Kusonime Hunter x Hunter',
    'Otakudesu Hunter x Hunter',
    'Samehadaku Hunter x Hunter',
    'AWSubs Hunter x Hunter',
    'Oploverz Hunter x Hunter',
    'Hunter x Hunter Subtitle Indonesia',
    'Hunter x Hunter 2011 Subtitle Indonesia'
  ];

  for (const q of indoQueries) {
    const docs = await search(q);
    if (docs.length > 0) {
      console.log(`=== Query: ${q} ===`);
      for (const d of docs) {
        console.log(`- [${d.identifier}] ${d.title} (${d.downloads})`);
      }
    }
  }
}

inspectCandidates();

