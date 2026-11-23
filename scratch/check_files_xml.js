const { fetchJson } = require('./archive_util');
const https = require('https');
const urlModule = require('url');

function fetchText(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return resolve(fetchText(urlModule.resolve(url, res.headers.location)));
      }
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

async function inspectFilesXml(identifier) {
  console.log(`\n================ Inspecting _files.xml for: ${identifier} ================`);
  const url = `https://archive.org/download/${identifier}/${identifier}_files.xml`;
  const xml = await fetchText(url);
  // Look for audio tracks, language, tracks, titles
  const lines = xml.split('\n');
  let currentFile = '';
  let inTargetFile = false;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.includes('<file name=')) {
      currentFile = line;
      inTargetFile = line.endsWith('.mp4">') || line.endsWith('.mkv">');
      if (inTargetFile) {
        console.log(`\nFile: ${line.trim()}`);
      }
    }
    if (inTargetFile) {
      if (line.includes('<track') || line.includes('<format>') || line.includes('<title>') || line.includes('<lang') || line.includes('audio') || line.includes('subtitle') || line.includes('album')) {
        console.log(`  ${line.trim()}`);
      }
      if (line.includes('</file>')) {
        inTargetFile = false;
      }
    }
  }
}

async function run() {
  await inspectFilesXml('horrible-subs-hunter-x-hunter-135-480p');
  await inspectFilesXml('death-note-22-guidance');
}

run().catch(console.error);

