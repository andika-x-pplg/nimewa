const { getItemMetadata, searchArchive } = require('./archive_util');
const https = require('https');
const fs = require('fs');

function downloadFile(url, dest) {
  return new Promise((resolve) => {
    https.get(encodeURI(url), (res) => {
      if (res.statusCode !== 200) return resolve({ success: false, status: res.statusCode });
      const f = fs.createWriteStream(dest);
      res.pipe(f);
      f.on('finish', () => resolve({ success: true, size: fs.statSync(dest).size }));
    }).on('error', (e) => resolve({ success: false, error: e.message }));
  });
}

async function testDnThumbs() {
  console.log('=== DOWNLOADING DN THUMBS ===');
  await downloadFile('https://archive.org/download/death-note-complete/death-note-complete.thumbs/Series/Death Note - 01_001081.jpg', 'scratch/dn_comp_1081.jpg');
  await downloadFile('https://archive.org/download/death-note-complete/death-note-complete.thumbs/Series/Death Note - 01_001351.jpg', 'scratch/dn_comp_1351.jpg');
  console.log('1081 size:', fs.existsSync('scratch/dn_comp_1081.jpg') ? fs.statSync('scratch/dn_comp_1081.jpg').size : 0);
  console.log('1351 size:', fs.existsSync('scratch/dn_comp_1351.jpg') ? fs.statSync('scratch/dn_comp_1351.jpg').size : 0);
}

async function inspectYkHxh() {
  console.log('\n=== INSPECTING yk-hunter-x-hunter-2011 ===');
  const meta = await getItemMetadata('yk-hunter-x-hunter-2011');
  if (meta && meta.files) {
    const vids = meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log(`yk-hunter-x-hunter-2011 has ${vids.length} videos:`);
    for (const v of vids.slice(0, 10)) {
      console.log(`  ${v.name} (${v.size} bytes)`);
    }
  }
}

async function searchBleachBatches() {
  console.log('\n=== SEARCHING BLEACH BATCHES ===');
  const docs = await searchArchive('Bleach (01-20 OR "001-020" OR "Season 1" OR "Season 01" OR "Substitute Shinigami Arc") mediatype:movies', 15);
  for (const d of docs) {
    console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
  }
}

async function searchKnyS2Clean() {
  console.log('\n=== SEARCHING KNY S2 CLEAN ===');
  const queries = [
    '("Demon Slayer" OR "Kimetsu") ("Season 2" OR "Yuukaku" OR "Entertainment District") mediatype:movies'
  ];
  for (const q of queries) {
    const docs = await searchArchive(q, 20);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
    }
  }
}

async function main() {
  await testDnThumbs();
  await inspectYkHxh();
  await searchBleachBatches();
  await searchKnyS2Clean();
}

main();

