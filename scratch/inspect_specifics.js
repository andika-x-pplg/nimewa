const { getItemMetadata, searchArchive } = require('./archive_util');

async function inspectHxH() {
  console.log('=== INSPECTING HXH ITEMS ===');
  for (const id of ['U.U.THunterXHunter2011Ep01-50_720pUPByDarkSniper', 'monk3y25_gmail_007_201509', 'hunter-x-hunter-2011_202203']) {
    const meta = await getItemMetadata(id);
    if (!meta) { console.log(id, 'not found'); continue; }
    console.log(`\n--- ${id} ---`);
    console.log('Description:', (meta.metadata && meta.metadata.description || '').slice(0, 200));
    const vids = (meta.files || []).filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log(`Video files count: ${vids.length}`);
    for (const f of vids.slice(0, 5)) {
      console.log(`  ${f.name} (${f.size} bytes) format=${f.format}`);
    }
  }
}

async function inspectJeovanne() {
  console.log('\n=== INSPECTING JEOVANNE SOUZA (DEMON SLAYER S2) ===');
  const meta = await getItemMetadata('demon-slayer-kimetsu-no-yaiba-s02-jeovanne-souza');
  if (meta && meta.files) {
    const vids = meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log(`Video files count: ${vids.length}`);
    for (const f of vids) {
      console.log(`  ${f.name} (${f.size} bytes) format=${f.format}`);
    }
  }
}

async function main() {
  await inspectHxH();
  await inspectJeovanne();
}

main();

