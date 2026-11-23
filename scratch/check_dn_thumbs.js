const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');

async function checkDn2006Thumbs() {
  const meta = await getItemMetadata('death-note_2006');
  if (meta && meta.files) {
    const thumbs = meta.files.filter(f => f.name.includes('.thumbs') && f.name.includes('E1-') && f.name.endsWith('.jpg'));
    console.log('death-note_2006 E1 thumbs:');
    for (const t of thumbs) {
      console.log(`  ${t.name}`);
    }
    if (thumbs.length > 2) {
      const targetThumb = thumbs[Math.floor(thumbs.length / 2)].name;
      const url = `https://archive.org/download/death-note_2006/${encodeURIComponent(targetThumb)}`;
      console.log('Downloading thumb:', url);
      await download(url, 'scratch/dn_2006_thumb.jpg');
      console.log('Downloaded scratch/dn_2006_thumb.jpg');
    }
  }

  const meta2 = await getItemMetadata('death-note-01x-26-renewal');
  if (meta2 && meta2.files) {
    const thumbs2 = meta2.files.filter(f => f.name.includes('.thumbs') && f.name.includes('01x01') && f.name.endsWith('.jpg'));
    console.log('\ndeath-note-01x-26-renewal 01x01 thumbs:');
    for (const t of thumbs2) {
      console.log(`  ${t.name}`);
    }
    if (thumbs2.length > 2) {
      const targetThumb2 = thumbs2[Math.floor(thumbs2.length / 2)].name;
      const url2 = `https://archive.org/download/death-note-01x-26-renewal/${encodeURIComponent(targetThumb2)}`;
      console.log('Downloading thumb 2:', url2);
      await download(url2, 'scratch/dn_renewal_thumb.jpg');
      console.log('Downloaded scratch/dn_renewal_thumb.jpg');
    }
  }
}

checkDn2006Thumbs();

