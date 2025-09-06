const admin = require('firebase-admin');

const svc = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (svc) {
  admin.initializeApp({ credential: admin.credential.cert(require(svc)) });
} else {
  try { admin.initializeApp({ credential: admin.credential.cert(require('./serviceAccountKey.json')) }); }
  catch (e) { admin.initializeApp(); }
}

async function makeAdmin(uid) {
  await admin.auth().setCustomUserClaims(uid, { admin: true });
  await admin.auth().revokeRefreshTokens(uid);
  const user = await admin.auth().getUser(uid);
  console.log(`Set admin:true and revoked tokens for ${uid}. tokensValidAfterTime=${user.tokensValidAfterTime}`);
}

const uid = process.argv[2];
if (!uid) {
  console.error('Usage: node set_admin_claim_and_revoke.js <uid>');
  process.exit(1);
}
makeAdmin(uid).catch(e => { console.error(e); process.exit(1); });