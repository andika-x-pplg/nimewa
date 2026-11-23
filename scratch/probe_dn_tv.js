const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');

function probeUrl(url) {
  console.log(`\n================ Probing: ${url} ================`);
  try {
    execSync(`"${ffmpeg}" -i "${url}"`);
  } catch (e) {
    const lines = (e.stderr ? e.stderr.toString() : e.message).split('\n');
    for (const l of lines) {
      if (l.includes('Stream #0') || l.includes('Duration:') || l.includes('title') || l.includes('language') || l.includes('handler_name')) {
        console.log(' ', l.trim());
      }
    }
  }
}

probeUrl('https://archive.org/download/DeathNoteTV/01%20-%20Rebirth.mp4');

