const admin = require('firebase-admin');

const svc = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (svc) {
  admin.initializeApp({ credential: admin.credential.cert(require(svc)) });
} else {
  try { admin.initializeApp({ credential: admin.credential.cert(require('./serviceAccountKey.json')) }); }
  catch (e) { admin.initializeApp(); }
}

async function run(whitelist = []) {
  let nextPageToken;
  let processed = 0, changed = 0;
  console.log('Preserving admin users and whitelist UIDs:', whitelist);
  do {
    const list = await admin.auth().listUsers(1000, nextPageToken);
    for (const user of list.users) {
      processed++;
      const uid = user.uid;
      const claims = user.customClaims || {};
      const isAdmin = claims.admin === true;
      const inWhitelist = whitelist.includes(uid);
      if (isAdmin || inWhitelist) continue;

      try {
        if (!user.disabled) await admin.auth().updateUser(uid, { disabled: true });
        await admin.auth().revokeRefreshTokens(uid);
        const refreshed = await admin.auth().getUser(uid);
        console.log(`Disabled+revoked: ${uid} (${refreshed.email || 'no-email'}) tokensValidAfterTime=${refreshed.tokensValidAfterTime}`);
        changed++;
      } catch (err) {
        console.error(`Failed for ${uid}:`, err);
      }
    }
    nextPageToken = list.pageToken;
  } while (nextPageToken);
  console.log(`Done. Processed ${processed} users, changed ${changed}.`);
}

const args = process.argv.slice(2);
// args are optional whitelist UIDs to preserve (no angle brackets)
run(args).catch(err => { console.error(err); process.exit(1); });