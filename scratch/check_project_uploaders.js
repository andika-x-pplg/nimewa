const { getItemMetadata, searchArchive } = require('./archive_util');

async function checkProjectUploaders() {
  const items = [
    'knys1',
    'opm-s1',
    'sl-bd-s1',
    'aot-s-1',
    'tokyo-ghoul-s01-sm',
    'jjk-s01CBT',
    'dan-da-dan-seasons-1-2',
    'ag_yosuga-no-sora'
  ];

  const uploaders = new Set();
  for (const it of items) {
    const meta = await getItemMetadata(it);
    if (meta && meta.metadata) {
      console.log(`${it} -> uploader: ${meta.metadata.uploader}, publicdate: ${meta.metadata.publicdate}`);
      if (meta.metadata.uploader) uploaders.add(meta.metadata.uploader);
    }
  }

  for (const u of uploaders) {
    console.log(`\n=== ALL UPLOADS BY ${u} ===`);
    const docs = await searchArchive(`uploader:${u}`, 100);
    for (const d of docs) {
      console.log(`  ${d.identifier} | ${d.title}`);
    }
  }
}

checkProjectUploaders();

