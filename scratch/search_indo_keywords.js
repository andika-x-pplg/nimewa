const { searchArchive } = require('./archive_util');

async function searchIndoKeywords() {
  const keywords = ['otakudesu', 'samehadaku', 'meownime', 'kusonime', 'oploverz', 'anoboy', 'animeindo', 'kuramanime', 'animasu'];
  for (const kw of keywords) {
    const res = await searchArchive(kw, 25);
    console.log(`=== Keyword: ${kw} (${res.length}) ===`);
    for (const r of res) {
      console.log(`  ${r.identifier} | ${r.title}`);
    }
  }
}

searchIndoKeywords();

