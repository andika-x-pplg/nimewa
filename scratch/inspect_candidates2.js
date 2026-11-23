const { fetchJson, searchArchive, getItemMetadata } = require('./archive_util');

async function inspectDeathNoteComplete() {
  console.log('=== INSPECTING death-note-complete ===');
  const meta = await getItemMetadata('death-note-complete');
  if (meta && meta.files) {
    const vids = meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log(`Found ${vids.length} videos:`);
    for (const f of vids.slice(0, 15)) {
      console.log(`  ${f.name} (${f.size} bytes) format=${f.format}`);
    }
  }
}

async function searchByIdentifierPatterns() {
  const patterns = [
    { name: 'KNY S2', q: '(identifier:(*kimetsu*) OR identifier:(*demon*slayer*)) AND (yuukaku OR "district" OR s2 OR s02 OR season)' },
    { name: 'HxH 2011', q: '(identifier:(*hunter*hunter*) OR identifier:(*hxh*)) AND (2011 OR sub OR 720p OR 1080p)' },
    { name: 'Bleach S1', q: 'identifier:(*bleach*) AND (001 OR "ep 01" OR "season 1" OR s01 OR "episode 1")' }
  ];

  for (const p of patterns) {
    console.log(`\n=== SEARCH PATTERN: ${p.name} ===`);
    const docs = await searchArchive(p.q, 25);
    for (const d of docs) {
      console.log(`${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
    }
  }
}

async function main() {
  await inspectDeathNoteComplete();
  await searchByIdentifierPatterns();
}

main();

