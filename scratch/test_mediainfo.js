const { mediaInfoFactory } = require('mediainfo.js');
const fs = require('fs');

async function analyze(filePath) {
  console.log(`\nAnalyzing ${filePath}...`);
  const mediainfo = await mediaInfoFactory({ format: 'object' });
  const fileHandle = await fs.promises.open(filePath, 'r');
  const size = (await fileHandle.stat()).size;

  const readChunk = async (chunkSize, offset) => {
    const buffer = Buffer.alloc(chunkSize);
    const { bytesRead } = await fileHandle.read(buffer, 0, chunkSize, offset);
    return buffer.subarray(0, bytesRead);
  };

  try {
    const result = await mediainfo.analyzeDataSize(readChunk, size);
    console.log(JSON.stringify(result.media.track, null, 2));
  } catch (e) {
    console.error('Error analyzing:', e.message);
  } finally {
    await fileHandle.close();
  }
}

analyze('scratch/hxh_horrible_sample.mp4').catch(console.error);
