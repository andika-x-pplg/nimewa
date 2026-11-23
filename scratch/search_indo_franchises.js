const { searchArchive, getItemMetadata } = require('./archive_util');

async function searchIndoFranchises() {
  const providers = ['Kusonime', 'Otakudesu', 'Samehadaku', 'Oploverz', 'Meownime'];
  const franchises = ['Death Note', 'Bleach', 'Hunter x Hunter'];

  for (const f of franchises) {
    console.log(`\n=================== ${f} ===================`);
    for (const p of providers) {
      const q = `"${f}" "${p}"`;
      const docs = await searchArchive(q, 10);
      if (docs.length > 0) {
        console.log(`[${p}]:`);
        for (const d of docs) {
          console.log(`  ${d.identifier} | ${(d.title||'').slice(0, 50)} | ${d.downloads||0} dl`);
        }
      }
    }
  }
}

searchIndoFranchises();

