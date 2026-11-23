const { fetchJson, searchArchive, getItemMetadata } = require('./archive_util');

async function testCandidateIdentifiers() {
  const candidates = [
    // Demon Slayer S2
    'knys2', 'kny-s2', 'kny-s02', 'knys02', 'kny-yuukaku', 'kimetsu-s2', 'kimetsu-s02', 'kimetsu-no-yaiba-s2', 
    'kimetsu-yuukaku', 'demon-slayer-s2', 'demon-slayer-s02', 'demon-slayer-season-2', 'demon-slayer-yuukaku',
    'kny-season-2', 'kny-entertainment-district', 'kimetsu-no-yaiba-yuukaku-hen',
    // Death Note
    'death-note-s1', 'death-note-bd', 'death-note-1080p', 'death-note-720p', 'death-note-sub', 'death-note-subbed',
    'death-note-japanese', 'death-note-eng-sub', 'death-note-remastered', 'death-note-anime', 'death-note-series',
    'death-note-kametsu', 'death-note-complete',
    // Hunter x Hunter 2011
    'hxh2011', 'hxh-2011', 'hxh-s1', 'hunter-x-hunter-2011', 'hunter-hunter-2011', 'hxh-bd', 'hunter-x-hunter-bd',
    'hxh-subbed', 'hunter-x-hunter-subbed', 'hxh-1080p', 'hxh-720p', 'hunter-x-hunter-1080p',
    // Bleach
    'bleach-s1', 'bleach-s01', 'bleach-bd', 'bleach-1080p', 'bleach-720p', 'bleach-sub', 'bleach-subbed',
    'bleach-season-1', 'bleach-season-01', 'bleach-episodes-1-20', 'bleach-001-020'
  ];

  console.log('Testing identifier direct lookup:');
  for (const c of candidates) {
    const meta = await getItemMetadata(c);
    if (meta && meta.metadata) {
      const title = meta.metadata.title || meta.metadata.identifier;
      const vids = (meta.files || []).filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
      console.log(`[FOUND] ${c} -> "${title}" (${vids.length} videos)`);
    }
  }
}

testCandidateIdentifiers();

