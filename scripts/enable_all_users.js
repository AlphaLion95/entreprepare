const admin = require('firebase-admin');
const svc = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (svc) admin.initializeApp({ credential: admin.credential.cert(require(svc)) });
else admin.initializeApp();

async function run() {
  let nextPageToken;
  do {
    const res = await admin.auth().listUsers(1000, nextPageToken);
    for (const u of res.users) {
      if (u.disabled) {
        await admin.auth().updateUser(u.uid, { disabled: false });
        console.log('Enabled:', u.uid);
      }
    }
    nextPageToken = res.pageToken;
  } while (nextPageToken);
  console.log('Done.');
}
run().catch(e => { console.error(e); process.exit(1); });