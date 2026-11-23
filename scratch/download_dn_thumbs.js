const { download } = require('./downloader');
const fs = require('fs');

async function downloadMoreThumbs() {
  for (const s of ['000420', '000600', '000960', '001200']) {
    const thumbName = `death-note-relight-1.thumbs/Death Note Episode 1 Rebirth_${s}.jpg`;
    const url = `https://archive.org/download/death-note-relight-1/${encodeURIComponent(thumbName)}`;
    await download(url, `scratch/dn_relight_${s}.jpg`);
    console.log(`Downloaded ${s}:`, fs.statSync(`scratch/dn_relight_${s}.jpg`).size);
  }
}

downloadMoreThumbs();

