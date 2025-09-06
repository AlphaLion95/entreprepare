const admin = require('firebase-admin');

const svc = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (svc) {
  admin.initializeApp({ credential: admin.credential.cert(require(svc)) });
} else {
  // fallback to local file if present
  try {
    admin.initializeApp({ credential: admin.credential.cert(require('./serviceAccountKey.json')) });
  } catch (e) {
    admin.initializeApp();
  }
}

async function run(whitelist = []) {
  console.log('Preserving admin users and whitelist UIDs:', whitelist);
  let nextPageToken;
  let processed = 0;
  let disabledCount = 0;

  do {
    const list = await admin.auth().listUsers(1000, nextPageToken);
    for (const user of list.users) {
      processed++;
      const uid = user.uid;
      const claims = user.customClaims || {};
      const isAdmin = claims.admin === true;
      const inWhitelist = whitelist.includes(uid);

      if (isAdmin || inWhitelist) {
        // preserve
        continue;
      }

      if (user.disabled) {
        console.log(`Already disabled: ${uid} (${user.email || 'no-email'})`);
        continue;
      }

      try {
        await admin.auth().updateUser(uid, { disabled: true });
        await admin.auth().revokeRefreshTokens(uid);
        const refreshed = await admin.auth().getUser(uid);
        console.log(`Disabled & revoked: ${uid} (${refreshed.email || 'no-email'}) tokensValidAfterTime=${refreshed.tokensValidAfterTime}`);
        disabledCount++;
      } catch (err) {
        console.error(`Failed for ${uid}:`, err);
      }
    }
    nextPageToken = list.pageToken;
  } while (nextPageToken);

  console.log(`Done. Processed ${processed} users, disabled ${disabledCount} users.`);
}

const args = process.argv.slice(2);
// treat args as whitelist UIDs to preserve (optional)
run(args).catch(err => { console.error('Fatal error:', err); process.exit(1); });