const { searchArchive } = require('./archive_util');

async function searchClassicFansubs() {
  const queries = [
    // Bleach
    'title:(Bleach) AND (Dattebayo OR Lunar OR "Anime-Keep")',
    'Dattebayo Bleach',
    '[DB] Bleach',
    'Bleach Season 1 1080p',
    'Bleach Season 1 720p',
    'Bleach S01 720p',
    'Bleach S01 1080p',
    'Bleach E01 720p',
    'Bleach "001" 720p',
    // Death Note
    'Death Note 720p sub',
    'Death Note 1080p sub',
    'Death Note "Episode 01" sub',
    'Death Note "E01" sub',
    'Death Note "Episode 1" 720p'
  ];

  const seen = new Set();
  for (const q of queries) {
    console.log(`\n=== QUERY: ${q} ===`);
    const docs = await searchArchive(q, 15);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 65)} | ${d.downloads||0} dl`);
      }
    }
  }
}

searchClassicFansubs().catch(console.error);

