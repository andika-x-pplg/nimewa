const { getItemMetadata } = require('./archive_util');
const https = require('https');

async function checkOldanimeku() {
  const meta = await getItemMetadata('oldanimeku-hx-h-01-480p');
  console.log('Title:', meta.metadata?.title);
  console.log('Description:', meta.metadata?.description);
  console.log('Files count:', meta.files?.length);
  const mp4s = meta.files?.filter(f => f.name.endsWith('.mp4')) || [];
  console.log('MP4s:', mp4s.length);
  for (const m of mp4s) {
    console.log(' -', m.name, m.size);
  }

  // Also search for all items by uploader or with oldanimeku hxh
  const url = 'https://archive.org/advancedsearch.php?q=oldanimeku+hx-h&fl[]=identifier,title,downloads&rows=50&output=json';
  https.get(url, res => {
    let d = '';
    res.on('data', chunk => d += chunk);
    res.on('end', () => {
      try {
        const json = JSON.parse(d);
        console.log('Related oldanimeku items:');
        for (const it of json.response.docs) {
          console.log(`  [${it.identifier}] ${it.title} (${it.downloads})`);
        }
      } catch (e) {
        console.error(e);
      }
    });
  });
}

checkOldanimeku();

