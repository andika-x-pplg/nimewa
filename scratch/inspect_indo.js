const { fetchJson, searchArchive, getItemMetadata } = require('./archive_util');

async function inspectDeathNoteFiles() {
  console.log('=== DEATH NOTE COMPLETE EPISODES ===');
  const meta = await getItemMetadata('death-note-complete');
  if (meta && meta.files) {
    const eps = meta.files.filter(f => !f.name.startsWith('Extras') && (f.name.endsWith('.mp4') || f.name.endsWith('.mkv')));
    console.log(`Found ${eps.length} non-extra videos:`);
    for (const f of eps.slice(0, 10)) {
      console.log(`  ${f.name} (${f.size} bytes) format=${f.format}`);
    }
  }
}

async function inspectBleachItems() {
  console.log('\n=== BLEACH CANDIDATES ===');
  for (const it of ['bleachseason1', 'kayoanime-bleach-001', 'bleach-001_202210']) {
    const meta = await getItemMetadata(it);
    console.log(`Item: ${it}`);
    if (meta && meta.files) {
      for (const f of meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv')).slice(0, 5)) {
        console.log(`  ${f.name} (${f.size} bytes)`);
      }
    }
  }
}

async function searchSubIndo() {
  console.log('\n=== SEARCHING SUBTITLE INDONESIA ON ARCHIVE ===');
  const queries = [
    '"Hunter x Hunter" "indo"',
    '"Hunter x Hunter" "sub indo"',
    '"Death Note" "sub indo"',
    '"Death Note" "indo"',
    '"Kimetsu" "indo"',
    '"Kimetsu" "sub indo"',
    '"Bleach" "sub indo"',
    '"Bleach" "indo"'
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
  await inspectDeathNoteFiles();
  await inspectBleachItems();
  await searchSubIndo();
}

main();

