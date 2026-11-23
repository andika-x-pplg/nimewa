const { getItemMetadata, searchArchive } = require('./archive_util');

async function inspectDn1080p() {
  console.log('=== INSPECTING death-note_1080p_2007 ===');
  const meta = await getItemMetadata('death-note_1080p_2007');
  if (meta && meta.files) {
    const vids = meta.files.filter(f => f.name.endsWith('.mp4') || f.name.endsWith('.mkv'));
    console.log(`Video count: ${vids.length}`);
    for (const v of vids.slice(0, 10)) {
      console.log(`  ${v.name} (${v.size} bytes) format=${v.format}`);
    }
  }
}

inspectDn1080p();

