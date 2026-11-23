const { getItemMetadata } = require('./archive_util');
const { mediaInfoFactory } = require('mediainfo.js');
const https = require('https');
const urlModule = require('url');

function getRange(url, start, end) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'Range': `bytes=${start}-${end}` } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return resolve(getRange(urlModule.resolve(url, res.headers.location), start, end));
      }
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => resolve(Buffer.concat(chunks)));
    }).on('error', reject);
  });
}

async function checkDnComplete() {
  const url = 'https://archive.org/download/death-note-complete-2006-2007/E01%20-%20Rebirth.mp4';
  console.log('Downloading first 2MB of E01...');
  const buf = await getRange(url, 0, 2 * 1024 * 1024);
  console.log('Downloaded bytes:', buf.length);

  const mediainfo = await mediaInfoFactory({ format: 'object' });
  const readChunk = (chunkSize, offset) => {
    return new Uint8Array(buf.buffer, buf.byteOffset + offset, Math.min(chunkSize, buf.length - offset));
  };

  try {
    const res = await mediainfo.analyzeData(buf.length, readChunk);
    console.log(JSON.stringify(res.media.track, null, 2));
  } catch (e) {
    console.log('Error:', e.message);
  } finally {
    mediainfo.close();
  }
}

checkDnComplete().catch(console.error);

