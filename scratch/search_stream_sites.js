const { searchArchive, getItemMetadata } = require('./archive_util');

async function searchStreamSiteUploads() {
  const sites = ['gogoanime', 'kissanime', '9anime', 'animesuge', 'animixplay', 'zoro.to'];
  const animes = ['Hunter x Hunter', 'Death Note', 'Bleach'];

  for (const a of animes) {
    console.log(`\n=== ANIME: ${a} ===`);
    for (const s of sites) {
      const q = `"${a}" "${s}" mediatype:movies`;
      const docs = await searchArchive(q, 5);
      if (docs.length > 0) {
        console.log(`Site [${s}]:`);
        for (const d of docs) {
          console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 50)} | ${d.downloads||0} dl`);
        }
      }
    }
  }
}

searchStreamSiteUploads();

