const { searchArchive, getItemMetadata } = require('./archive_util');

async function searchAnime(name, query) {
  console.log(`\n================ SEARCHING FOR: ${name} ================`);
  const docs = await searchArchive(query, 30);
  console.log(`Found ${docs.length} items`);
  for (const d of docs) {
    console.log(`\n--- Item: ${d.identifier} (${d.title}) | downloads: ${d.downloads} ---`);
    const meta = await getItemMetadata(d.identifier);
    if (!meta || !meta.files) {
      console.log('  No metadata files');
      continue;
    }
    const mp4s = meta.files.filter(f => f.name.endsWith('.mp4'));
    const mkvs = meta.files.filter(f => f.name.endsWith('.mkv'));
    console.log(`  MP4 count: ${mp4s.length}, MKV count: ${mkvs.length}`);
    if (mp4s.length > 0) {
      console.log('  Sample MP4s:', mp4s.slice(0, 5).map(f => f.name).join(', '));
      if (mp4s.length > 5) {
        console.log('  Last MP4s:', mp4s.slice(-3).map(f => f.name).join(', '));
      }
    }
  }
}

async function main() {
  await searchAnime('Death Note', 'title:("Death Note") AND mediatype:(movies)');
  await searchAnime('Bleach', 'title:(Bleach) AND mediatype:(movies)');
  await searchAnime('Hunter x Hunter', 'title:("Hunter x Hunter") AND mediatype:(movies)');
}

main().catch(console.error);

