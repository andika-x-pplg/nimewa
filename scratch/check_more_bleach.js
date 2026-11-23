const { getItemMetadata, searchArchive } = require('./archive_util');

async function main() {
  console.log('Checking bl35ch-s35s0ns-1...');
  try {
    const meta = await getItemMetadata('bl35ch-s35s0ns-1');
    console.log('Title:', meta?.metadata?.title);
    console.log('Description:', meta?.metadata?.description);
    const files = meta?.files || [];
    console.log('Files count:', files.length);
    const vids = files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv') || f.name.endsWith('.avi'));
    console.log('Video count:', vids.length);
    for (const v of vids.slice(0, 15)) {
      console.log('  ', v.name, (v.size/1024/1024).toFixed(1), 'MB');
    }
  } catch(e) {
    console.error('Error bl35ch:', e.message);
  }

  console.log('\nSearching for bleach fansubs / episodes...');
  const queries = [
    'Bleach [DVD]',
    'Bleach uncensored',
    'Bleach episode 01 720p',
    'Bleach 01 sub',
    'Bleach flv',
    'Bleach s01e01',
    'Bleach Japanese audio'
  ];

  for (const q of queries) {
    const res = await searchArchive(q, 5);
    console.log(`\nQuery: ${q} (${res.length} results)`);
    for (const r of res) {
      console.log(`  ${r.identifier} | ${r.title}`);
    }
  }
}

main();

