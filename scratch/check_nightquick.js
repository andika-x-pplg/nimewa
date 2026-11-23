const { searchArchive } = require('./archive_util');

async function run() {
  const docs = await searchArchive('uploader:(nightquick@proton.me)', 30);
  for (const d of docs) {
    console.log(d.identifier, '|', d.title);
  }
}

run();

