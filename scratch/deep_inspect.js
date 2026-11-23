const { getItemMetadata, searchArchive } = require('./archive_util');
const https = require('https');
const fs = require('fs');

function downloadFile(url, dest) {
  return new Promise((resolve, reject) => {
    https.get(encodeURI(url), (res) => {
      if (res.statusCode !== 200) {
        return resolve({ success: false, status: res.statusCode });
      }
      const file = fs.createWriteStream(dest);
      res.pipe(file);
      file.on('finish', () => resolve({ success: true, size: fs.statSync(dest).size }));
    }).on('error', reject);
  });
}

async function inspectBleachSeason1() {
  console.log('=== BLEACH SEASON 1 FILES ===');
  const meta = await getItemMetadata('bleachseason1');
  if (meta && meta.files) {
    const vids = meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log(`bleachseason1 has ${vids.length} video files:`);
    for (const v of vids) {
      console.log(`  ${v.name} (${v.size} bytes) format=${v.format}`);
    }
  }
}

async function inspectDeathNoteComplete() {
  console.log('\n=== DEATH NOTE COMPLETE SERIES FILES ===');
  const meta = await getItemMetadata('death-note-complete');
  if (meta && meta.files) {
    const eps = meta.files.filter(f => f.name.startsWith('Series/Death Note - ') && f.name.endsWith('.mp4'));
    console.log(`death-note-complete has ${eps.length} MP4 series files:`);
    for (const e of eps) {
      console.log(`  ${e.name} (${e.size} bytes)`);
    }
  }
}

async function inspectJeovanneKny() {
  console.log('\n=== JEOVANNE KNY S2 FILES ===');
  const meta = await getItemMetadata('demon-slayer-kimetsu-no-yaiba-s02-jeovanne-souza');
  if (meta && meta.files) {
    const vids = meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log(`Jeovanne has ${vids.length} files:`);
    for (const v of vids) {
      console.log(`  ${v.name} (${v.size} bytes) format=${v.format}`);
    }
  }
}

async function searchMoreKnyS2() {
  console.log('\n=== SEARCH MORE KNY S2 ===');
  const docs = await searchArchive('identifier:(*yuukaku*) OR identifier:(*district*) OR title:(*yuukaku*)', 20);
  for (const d of docs) {
    console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
  }
}

async function searchMoreHxH() {
  console.log('\n=== SEARCH MORE HXH 2011 ===');
  const docs = await searchArchive('title:"Hunter X Hunter" AND 2011 mediatype:movies', 20);
  for (const d of docs) {
    console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
  }
}

async function main() {
  await inspectBleachSeason1();
  await inspectDeathNoteComplete();
  await inspectJeovanneKny();
  await searchMoreKnyS2();
  await searchMoreHxH();
}

main();

