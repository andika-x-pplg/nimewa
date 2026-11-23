const { getItemMetadata, searchArchive } = require('./archive_util');

async function findMoreIndoUploaders() {
  console.log('=== FINDING INDO UPLOADERS ===');
  const items = [
    'musonime-otakudesu-sousnomyji-01-720p',
    'otakudesu-jk-01-360p',
    'otakudesu-boruto-001-720p',
    'otakudesu-op-020-720p-rm',
    'AnimeSubtitleIndonesiaNontonSamehadakuAnime21.co',
    'DRR19MP4HDSAMEHADAKU.TV',
    'oploverz-teis-02-mp-4-480p',
    'oploverz-csw-01-mp-4-480p'
  ];

  const uploaders = new Set();
  for (const it of items) {
    const meta = await getItemMetadata(it);
    if (meta && meta.metadata && meta.metadata.uploader) {
      uploaders.add(meta.metadata.uploader);
    }
  }

  console.log('Uploaders found:', Array.from(uploaders));
  for (const u of uploaders) {
    console.log(`\n--- Uploads by ${u} ---`);
    const docs = await searchArchive(`uploader:${u}`, 30);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 60)}`);
    }
  }
}

findMoreIndoUploaders();

