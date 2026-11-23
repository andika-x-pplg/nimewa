const { searchArchive } = require('./archive_util');

async function run() {
  const docs = await searchArchive('uploader:(sahinerdemdeniz@gmail.com)', 20);
  for (const d of docs) {
    console.log(d.identifier, '|', d.title);
  }
}

run();

