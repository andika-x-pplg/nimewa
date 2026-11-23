const { searchArchive, getItemMetadata } = require('./archive_util');

async function testKnyS2() {
  console.log('=== SEARCHING DEMON SLAYER S2 ===');
  const queries = [
    'kimetsu yuukaku',
    'demon slayer yuukaku',
    'entertainment district kimetsu',
    'entertainment district demon slayer',
    'kimetsu no yaiba s2',
    'kimetsu season 2',
    'demon slayer s2',
    'kny s2',
    'otakudesu kimetsu',
    'samehadaku kimetsu'
  ];
  const seen = new Set();
  for (const q of queries) {
    const docs = await searchArchive(q, 10);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`[KNY S2] ${d.identifier} | ${d.title}`);
      }
    }
  }
}

async function testDeathNote() {
  console.log('\n=== SEARCHING DEATH NOTE ===');
  const queries = [
    'death note animepahe',
    'death note horriblesubs',
    'death note otakudesu',
    'death note samehadaku',
    'death note judas',
    'death note sub indo',
    'death note 720p',
    'death note 1080p',
    'death note kametsu',
    'death note japanese'
  ];
  const seen = new Set();
  for (const q of queries) {
    const docs = await searchArchive(q, 10);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`[Death Note] ${d.identifier} | ${d.title}`);
      }
    }
  }
}

async function testHxh() {
  console.log('\n=== SEARCHING HUNTER X HUNTER ===');
  const queries = [
    'oldanimeku hxh',
    'hunter x hunter 2011 animepahe',
    'hunter x hunter 2011 otakudesu',
    'hunter x hunter 2011 samehadaku',
    'hunter x hunter 2011 horriblesubs',
    'hunter x hunter 2011 sub indo',
    'hxh 2011 720p',
    'hunter x hunter 2011 judas'
  ];
  const seen = new Set();
  for (const q of queries) {
    const docs = await searchArchive(q, 10);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`[HxH] ${d.identifier} | ${d.title}`);
      }
    }
  }
}

async function testBleach() {
  console.log('\n=== SEARCHING BLEACH ===');
  const queries = [
    'anime-pahe-bleach',
    'bleach animepahe',
    'bleach horriblesubs',
    'bleach otakudesu',
    'bleach samehadaku',
    'bleach sub indo 01',
    'bleach 001 judas',
    'bleach s01'
  ];
  const seen = new Set();
  for (const q of queries) {
    const docs = await searchArchive(q, 10);
    for (const d of docs) {
      if (!seen.has(d.identifier)) {
        seen.add(d.identifier);
        console.log(`[Bleach] ${d.identifier} | ${d.title}`);
      }
    }
  }
}

async function main() {
  await testKnyS2();
  await testDeathNote();
  await testHxh();
  await testBleach();
}

main();

