const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');
const fs = require('fs');

async function testDialogueThumbs(identifier, filterStr, outName) {
  const meta = await getItemMetadata(identifier);
  if (!meta || !meta.files) return;
  const thumbs = meta.files.filter(f => f.name.includes('.thumbs') && f.name.includes(filterStr) && f.name.endsWith('.jpg'));
  console.log(`\n=== ${identifier} (${filterStr}) thumbs ===`);
  for (const t of thumbs) {
    console.log(`  ${t.name}`);
  }
  // pick one in the middle (e.g. index 2 or 3)
  if (thumbs.length > 2) {
    const chosen = thumbs[Math.floor(thumbs.length / 2)];
    const url = `https://archive.org/download/${identifier}/${encodeURIComponent(chosen.name)}`;
    console.log(`Downloading ${chosen.name} -> scratch/${outName}`);
    await download(url, `scratch/${outName}`);
  }
}

async function run() {
  await testDialogueThumbs('horrible-subs-hunter-x-hunter-135-480p', '01 [480p]', 'hxh_dialogue.jpg');
  await testDialogueThumbs('death-note-22-guidance', '01 - Rebirth', 'dn_dialogue.jpg');
  await testDialogueThumbs('bleach-127-c-p', '001', 'bleach_dialogue.jpg');
  await testDialogueThumbs('bleach-complete', 'S01E01', 'bleach_comp_dialogue.jpg');
}

run().catch(console.error);

