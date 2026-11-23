const { getItemMetadata } = require('./archive_util');
const { download } = require('./downloader');
const ffmpeg = require('ffmpeg-static');
const { spawnSync } = require('child_process');
const fs = require('fs');

async function inspectCollections() {
  // 1. Check SDHXH
  console.log('--- Inspecting SDHXH ---');
  const metaSD = await getItemMetadata('SDHXH');
  const sdhxhMp4s = metaSD.files.filter(f => f.name.endsWith('.mp4') && !f.name.endsWith('.ia.mp4'));
  console.log(`SDHXH original MP4s: ${sdhxhMp4s.length}`);
  console.log('First 5:', sdhxhMp4s.slice(0, 5).map(f => f.name));
  console.log('Last 5:', sdhxhMp4s.slice(-5).map(f => f.name));

  // Check thumbnails for SDHXH
  const sdhxhThumbs = metaSD.files.filter(f => f.name.includes('.thumbs') && f.name.endsWith('.jpg'));
  console.log(`SDHXH thumbs: ${sdhxhThumbs.length}`);
  if (sdhxhThumbs.length > 0) {
    const thumbUrl = `https://archive.org/download/SDHXH/${encodeURIComponent(sdhxhThumbs[0].name)}`;
    console.log('Downloading SDHXH thumb:', sdhxhThumbs[0].name);
    await download(thumbUrl, 'scratch/sdhxh_thumb.jpg');
    console.log('Downloaded scratch/sdhxh_thumb.jpg');
  }

  // 2. Check hxh11
  console.log('\n--- Inspecting hxh11 ---');
  const meta11 = await getItemMetadata('hxh11');
  const hxh11Mp4s = meta11.files.filter(f => f.name.endsWith('.mp4') && !f.name.endsWith('.ia.mp4'));
  console.log(`hxh11 original MP4s: ${hxh11Mp4s.length}`);
  console.log('First 5:', hxh11Mp4s.slice(0, 5).map(f => f.name));
  console.log('Last 5:', hxh11Mp4s.slice(-5).map(f => f.name));

  const hxh11Thumbs = meta11.files.filter(f => f.name.includes('.thumbs') && f.name.endsWith('.jpg'));
  console.log(`hxh11 thumbs: ${hxh11Thumbs.length}`);
  if (hxh11Thumbs.length > 0) {
    const thumbUrl = `https://archive.org/download/hxh11/${encodeURIComponent(hxh11Thumbs[0].name)}`;
    console.log('Downloading hxh11 thumb:', hxh11Thumbs[0].name);
    await download(thumbUrl, 'scratch/hxh11_thumb.jpg');
    console.log('Downloaded scratch/hxh11_thumb.jpg');
  }

  // 3. Check hunterxhunter_202605
  console.log('\n--- Inspecting hunterxhunter_202605 ---');
  const meta2026 = await getItemMetadata('hunterxhunter_202605');
  const hxh2026Mp4s = meta2026.files.filter(f => f.name.endsWith('.mp4') && !f.name.endsWith('.ia.mp4'));
  console.log(`hunterxhunter_202605 original MP4s: ${hxh2026Mp4s.length}`);
  console.log('First 5:', hxh2026Mp4s.slice(0, 5).map(f => f.name));
  console.log('Last 5:', hxh2026Mp4s.slice(-5).map(f => f.name));

  const hxh2026Thumbs = meta2026.files.filter(f => f.name.includes('.thumbs') && f.name.endsWith('.jpg'));
  console.log(`hunterxhunter_202605 thumbs: ${hxh2026Thumbs.length}`);
  if (hxh2026Thumbs.length > 0) {
    const thumbUrl = `https://archive.org/download/hunterxhunter_202605/${encodeURIComponent(hxh2026Thumbs[0].name)}`;
    console.log('Downloading hunterxhunter_202605 thumb:', hxh2026Thumbs[0].name);
    await download(thumbUrl, 'scratch/hxh2026_thumb.jpg');
    console.log('Downloaded scratch/hxh2026_thumb.jpg');
  }
}

inspectCollections();

