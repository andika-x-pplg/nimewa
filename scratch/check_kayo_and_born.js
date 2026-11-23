const { searchArchive, getItemMetadata } = require('./archive_util');

async function check() {
  console.log('=== Checking bleach-001-a-shinigami-is-born ===');
  const m1 = await getItemMetadata('bleach-001-a-shinigami-is-born');
  console.log('Title:', m1?.metadata?.title);
  console.log('Description:', m1?.metadata?.description);
  console.log('Files:', (m1?.files || []).filter(f => f.name.endsWith('.mp4')).map(f => f.name));

  console.log('\n=== Checking kayoanime-bleach-001 ===');
  const m2 = await getItemMetadata('kayoanime-bleach-001');
  console.log('Title:', m2?.metadata?.title);
  console.log('Description:', m2?.metadata?.description);
  console.log('Files:', (m2?.files || []).filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv')).map(f => f.name));

  console.log('\n=== Searching kayoanime bleach ===');
  const kayos = await searchArchive('kayoanime bleach', 20);
  kayos.forEach(x => console.log(x.identifier, '|', x.title));
}

check().catch(console.error);

