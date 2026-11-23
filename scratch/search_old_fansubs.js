const { searchArchive } = require('./archive_util');

async function searchOldFansubs() {
  const queries = [
    'Death Note (Kuroi OR Kuro-Hana OR Shinsen OR "Anime-Keep" OR Coalgirls OR THORA)',
    'Death Note (Samehadaku OR Oploverz OR Wardhanime OR Animeindo OR Shinokun)',
    'Hunter x Hunter (HorribleSubs OR "Underwater" OR "Chyu")',
    'Hunter x Hunter (Samehadaku OR Oploverz OR Wardhanime OR Animeindo)',
    'Kimetsu (Samehadaku OR Oploverz OR Wardhanime OR Animeindo OR Otakudesu)',
    'Bleach (Dattebayo OR Lunar OR "DB")',
    'Bleach (Samehadaku OR Oploverz OR Animeindo)'
  ];

  for (const q of queries) {
    console.log(`\nQuery: ${q}`);
    const docs = await searchArchive(q, 15);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)} | ${d.downloads||0} dl`);
    }
  }
}

searchOldFansubs();

