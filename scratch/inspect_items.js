const { fetchJson, searchArchive, getItemMetadata } = require('./archive_util');

async function checkCrazyfish() {
  console.log('=== UPLOADS BY CRAZYFISH ===');
  const docs = await searchArchive('uploader:crazyfish6474@gmail.com', 50);
  for (const d of docs) {
    console.log(`${d.identifier} | ${d.title}`);
  }
}

async function checkOldanimeku() {
  console.log('\n=== OLDANIMEKU METADATA ===');
  const meta = await getItemMetadata('oldanimeku-hx-h-01-480p');
  if (meta && meta.files) {
    console.log('Files in oldanimeku-hx-h-01-480p:');
    for (const f of meta.files) {
      if (f.name.endsWith('.mp4') || f.name.endsWith('.mkv')) {
        console.log(`  ${f.name} (${f.size} bytes)`);
      }
    }
  }
}

async function checkJeovanneSouza() {
  console.log('\n=== JEOVANNE SOUZA METADATA ===');
  const meta = await getItemMetadata('demon-slayer-kimetsu-no-yaiba-s02-jeovanne-souza');
  if (meta && meta.files) {
    console.log('Files in demon-slayer-kimetsu-no-yaiba-s02-jeovanne-souza:');
    for (const f of meta.files) {
      if (f.name.endsWith('.mp4') || f.name.endsWith('.mkv')) {
        console.log(`  ${f.name} (${f.size} bytes) format=${f.format}`);
      }
    }
  }
}

async function checkHxhCandidates() {
  console.log('\n=== HXH 2011 CANDIDATES ===');
  const items = ['ARGHxH2011720pKaMi', 'hxh2011-anidub-subs-fullbd'];
  for (const it of items) {
    const meta = await getItemMetadata(it);
    console.log(`Item: ${it}`);
    if (meta && meta.files) {
      for (const f of meta.files.slice(0, 5)) {
        console.log(`  ${f.name} (${f.size} bytes)`);
      }
    }
  }
}

async function main() {
  await checkCrazyfish();
  await checkOldanimeku();
  await checkJeovanneSouza();
  await checkHxhCandidates();
}

main();

