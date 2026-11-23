const { searchArchive } = require('./archive_util');

async function run() {
  const docs = await searchArchive('uploader:(crazyfish6474@gmail.com)', 100);
  console.log(`Found ${docs.length} items by crazyfish:`);
  for (const d of docs) {
    console.log(d.identifier, '|', d.title);
  }
}

run();

