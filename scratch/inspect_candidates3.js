const { getItemMetadata } = require('./archive_util');

async function inspectCandidates() {
  const items = [
    'death-note-22-guidance',
    'death-note_2006',
    'death-note-01x-26-renewal',
    'vodes-hunter-x-hunter-2011-v-2',
    'hunter-x-hunter-2011_202203',
    'hunter-x-hunter-2011_202203_202204',
    'HxH2011ACB'
  ];

  for (const it of items) {
    console.log(`\n=================== ${it} ===================`);
    const meta = await getItemMetadata(it);
    if (!meta) { console.log('Not found'); continue; }
    console.log('Title:', meta.metadata && meta.metadata.title);
    console.log('Uploader:', meta.metadata && meta.metadata.uploader);
    console.log('Description:', (meta.metadata && meta.metadata.description || '').slice(0, 150));
    const vids = (meta.files || []).filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log(`Video count: ${vids.length}`);
    for (const v of vids.slice(0, 5)) {
      console.log(`  ${v.name} (${v.size} bytes) format=${v.format}`);
    }
    const thumbs = (meta.files || []).filter(f => f.name.includes('.thumbs') || f.name.endsWith('.jpg'));
    console.log(`Thumb count: ${thumbs.length}`);
    if (thumbs.length > 1) {
      console.log(`  Sample thumb: ${thumbs[1].name}`);
    }
  }
}

inspectCandidates();

