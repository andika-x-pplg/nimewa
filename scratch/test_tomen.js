const ffmpeg = require('ffmpeg-static');
const { execSync } = require('child_process');
const fs = require('fs');

async function testTomen() {
  const url = 'https://archive.org/download/death-note-01/Death%20Note%2001.mp4';
  console.log('Testing:', url);
  try {
    execSync(`curl.exe -L -r 0-10000000 -s -o scratch/dn_tomen_sample.mp4 "${url}"`);
    console.log('Downloaded sample size:', fs.statSync('scratch/dn_tomen_sample.mp4').size);
    // Extract a frame at 60s
    execSync(`"${ffmpeg}" -y -ss 60 -i scratch/dn_tomen_sample.mp4 -frames:v 1 -update 1 scratch/dn_tomen_60.jpg`);
    console.log('Extracted frame 60s:', fs.statSync('scratch/dn_tomen_60.jpg').size);
  } catch (e) {
    console.error('Error:', e.message);
  }
}

testTomen();

