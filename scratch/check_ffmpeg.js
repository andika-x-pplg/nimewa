const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');

console.log('FFMPEG path:', ffmpeg);
const version = execSync(`"${ffmpeg}" -version`).toString();
console.log(version.split('\n')[0]);

