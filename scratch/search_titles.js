const { searchArchive } = require('./archive_util');

async function searchTitles() {
  const titles = [
    'title:"Hunter x Hunter"',
    'title:"Death Note" mediatype:movies',
    'title:"Kimetsu no Yaiba" mediatype:movies',
    'title:"Demon Slayer" mediatype:movies',
    'title:"Bleach" mediatype:movies'
  ];

  for (const t of titles) {
    console.log(`\n=== SEARCH: ${t} ===`);
    const docs = await searchArchive(t, 20);
    for (const d of docs) {
      console.log(`${d.identifier} | ${(d.title||'').slice(0, 70)} | ${d.downloads || 0} dl`);
    }
  }
}

searchTitles();

