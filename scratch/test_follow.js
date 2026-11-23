const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');

try {
  execSync(`"${ffmpeg}" -follow 1 -i "https://archive.org/download/DeathNoteTV/01%20-%20Rebirth.mp4"`);
} catch (e) {
  const lines = e.stderr.toString().split('\n');
  console.log(lines.filter(l => l.includes('Input #0') || l.includes('Stream #0')).join('\n'));
}

