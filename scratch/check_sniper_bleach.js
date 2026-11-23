const { getItemMetadata, searchArchive } = require('./archive_util');
const { download } = require('./downloader');

async function inspectDarkSniper() {
  console.log('=== SEARCHING DARK SNIPER ===');
  const docs = await searchArchive('DarkSniper Hunter X Hunter', 20);
  for (const d of docs) {
    console.log(`  ${d.identifier} | ${d.title}`);
  }
}

async function inspectBleachTemporada1() {
  console.log('\n=== INSPECTING bleach-temporada-1 ===');
  const meta = await getItemMetadata('bleach-temporada-1');
  if (meta && meta.files) {
    const vids = meta.files.filter(f => f.name.endsWith('.mp4'));
    console.log(`Video count: ${vids.length}`);
    for (const v of vids.slice(0, 10)) {
      console.log(`  ${v.name} (${v.size} bytes)`);
    }
    const thumbs = meta.files.filter(f => f.name.includes('.thumbs') || f.name.endsWith('.jpg'));
    console.log(`Thumbs count: ${thumbs.length}`);
    if (thumbs.length > 0) {
      console.log('Sample thumb:', thumbs[0].name);
    }
  }
}

async function inspectTomen() {
  console.log('\n=== UPLOADS BY tomen4052020@gmail.com ===');
  const docs = await searchArchive('uploader:tomen4052020@gmail.com', 50);
  for (const d of docs) {
    console.log(`  ${d.identifier} | ${d.title}`);
  }
}

async function main() {
  await inspectDarkSniper();
  await inspectBleachTemporada1();
  await inspectTomen();
}

main();

