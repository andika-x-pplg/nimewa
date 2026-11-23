const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');

function probeUrl(url) {
  console.log(`\nProbing URL: ${url}`);
  try {
    execSync(`"${ffmpeg}" -headers "User-Agent: Mozilla/5.0\r\n" -i "${url}"`, { encoding: 'utf8' });
  } catch (e) {
    // ffmpeg exits with code 1 when no output file is specified, but stderr contains the probe info!
    const out = e.stderr ? e.stderr.toString() : e.message;
    const lines = out.split('\n');
    for (const l of lines) {
      if (l.includes('Input #0') || l.includes('Stream #0') || l.includes('Duration:') || l.includes('title') || l.includes('language')) {
        console.log(' ', l.trim());
      }
    }
  }
}

probeUrl('https://archive.org/download/death-note-complete-2006-2007/E01%20-%20Rebirth.mp4');

