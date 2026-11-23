const { searchArchive } = require('./archive_util');

async function main() {
  const queries = [
    'Bleach Dattebayo',
    'Bleach Lunar',
    'Bleach "Sub Indo"',
    'Bleach Otakudesu',
    'Bleach Samehadaku',
    'Bleach 01-20',
    'Bleach S01 720p',
    'Bleach 001 mp4'
  ];

  for (const q of queries) {
    console.log(`\n=== Query: ${q} ===`);
    try {
      const results = await searchArchive(q, 8);
      for (const item of results) {
        console.log(`- ${item.identifier} | ${item.title} | ${item.mediatype} | downloads: ${item.downloads}`);
      }
    } catch (e) {
      console.error(e.message);
    }
  }
}

main();

