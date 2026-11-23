const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');

function probeUrl(url) {
  console.log(`\nProbing URL: ${url}`);
  try {
    execSync(`"${ffmpeg}" -i "${url}"`, { encoding: 'utf8' });
  } catch (e) {
    const out = e.stderr ? e.stderr.toString() : e.message;
    console.log(out);
  }
}

probeUrl('https://archive.org/download/death-note-complete-2006-2007/E01%20-%20Rebirth.mp4');

