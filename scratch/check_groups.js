const { getItemMetadata, searchArchive } = require('./archive_util');
const https = require('https');
const fs = require('fs');

async function checkYkHxhThumbs() {
  console.log('=== YK HXH 2011 METADATA & THUMBS ===');
  const meta = await getItemMetadata('yk-hunter-x-hunter-2011');
  if (meta && meta.files) {
    const thumbs = meta.files.filter(f => f.name.includes('.thumbs') || f.name.endsWith('.jpg'));
    console.log(`Found ${thumbs.length} thumbs in yk-hunter-x-hunter-2011:`);
    for (const t of thumbs.slice(0, 10)) {
      console.log(`  ${t.name}`);
    }
  }
}

async function checkBleachSeasons1() {
  console.log('\n=== BLEACH bl35ch-s35s0ns-1 ===');
  const meta = await getItemMetadata('bl35ch-s35s0ns-1');
  if (meta && meta.files) {
    const vids = meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log(`Found ${vids.length} videos in bl35ch-s35s0ns-1:`);
    for (const v of vids.slice(0, 10)) {
      console.log(`  ${v.name} (${v.size} bytes) format=${v.format}`);
    }
  }
}

async function searchSubsPleaseAndErai() {
  console.log('\n=== SEARCHING SUBSPLEASE / ERAI-RAWS / SHINSEN / DATTEBAYO ===');
  const queries = [
    '("SubsPlease" OR "Erai-raws") ("Demon Slayer" OR "Kimetsu" OR "Yuukaku")',
    '("SubsPlease" OR "Erai-raws") ("Hunter x Hunter" OR "HxH")',
    '("Shinsen" OR "Shinsen-Subs") "Death Note"',
    '("Dattebayo" OR "[DB]") "Bleach"',
    'title:"SubsPlease" (Demon OR Kimetsu OR Bleach OR Death OR Hunter)',
    'title:"Erai-raws" (Demon OR Kimetsu OR Bleach OR Death OR Hunter)'
  ];

  for (const q of queries) {
    console.log(`\nQuery: ${q}`);
    const docs = await searchArchive(q, 10);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
    }
  }
}

async function main() {
  await checkYkHxhThumbs();
  await checkBleachSeasons1();
  await searchSubsPleaseAndErai();
}

main();

