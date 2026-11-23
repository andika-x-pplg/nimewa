const https = require('https');
const http = require('http');
const fs = require('fs');
const urlModule = require('url');

function download(url, dest) {
  return new Promise((resolve, reject) => {
    function get(currentUrl, hops = 0) {
      if (hops > 5) return reject(new Error('Too many redirects'));
      const parsed = urlModule.parse(currentUrl);
      const client = parsed.protocol === 'https:' ? https : http;
      
      client.get(currentUrl, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          const redirectUrl = urlModule.resolve(currentUrl, res.headers.location);
          return get(redirectUrl, hops + 1);
        }
        if (res.statusCode !== 200) {
          return reject(new Error(`Status ${res.statusCode} for ${currentUrl}`));
        }
        const f = fs.createWriteStream(dest);
        res.pipe(f);
        f.on('finish', () => resolve({ size: fs.statSync(dest).size }));
      }).on('error', reject);
    }
    get(url);
  });
}

module.exports = { download };

