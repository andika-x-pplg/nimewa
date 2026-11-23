const { searchArchive, getItemMetadata } = require('./archive_util');

async function main() {
  const queries = [
    'uploader:(crazyfish6474@gmail.com)',
    'AnimePahe Bleach',
    'Bleach BD 720p',
    'Bleach BD 1080p',
    'Bleach subs',
    'Bleach Season 1 1080p',
    'Bleach S01 1080p',
    'Bleach S01 480p',
    'Bleach 01 480p'
  ];

  for (const q of queries) {
    console.log(`\n=== Query: ${q} ===`);
    const res = await searchArchive(q, 10);
    for (const r of res) {
      console.log(`- ${r.identifier} | ${r.title} | downloads: ${r.downloads}`);
    }
  }
}

main();

