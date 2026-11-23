const https = require('https');

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch(e) {
          resolve(null);
        }
      });
    }).on('error', reject);
  });
}

async function searchArchive(query, rows = 30) {
  const url = 'https://archive.org/advancedsearch.php?q=' + encodeURIComponent(query) + '&fl[]=identifier,title,description,downloads,item_size&sort[]=-downloads&rows=' + rows + '&output=json';
  const data = await fetchJson(url);
  return (data && data.response && data.response.docs) ? data.response.docs : [];
}

async function getItemMetadata(identifier) {
  return await fetchJson('https://archive.org/metadata/' + identifier);
}

module.exports = { fetchJson, searchArchive, getItemMetadata };

