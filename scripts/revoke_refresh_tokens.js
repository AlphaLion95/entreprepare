const admin = require('firebase-admin');
const svc = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (svc) admin.initializeApp({ credential: admin.credential.cert(require(svc)) });
else admin.initializeApp();

async function run(uids) {
  for (const uid of uids) {
    await admin.auth().revokeRefreshTokens(uid);
    const user = await admin.auth().getUser(uid);
    console.log(`Revoked for ${uid}, tokensValidAfterTime=${user.tokensValidAfterTime}`);
  }
}

const uids = process.argv.slice(2);
if (!uids.length) {
  console.error('Usage: node revoke_refresh_tokens.js <uid> [uid2...]');
  process.exit(1);
}
run(uids).catch(e => { console.error(e); process.exit(1); });