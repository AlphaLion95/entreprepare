const admin = require('firebase-admin');
const argv = process.argv.slice(2);
if (argv.length < 1) {
  console.error('Usage: node scripts\\disable_expired_users.js <ADMIN_UID>');
  process.exit(1);
}
const ADMIN_UID = argv[0];
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || './serviceAccountKey.json';
admin.initializeApp({ credential: admin.credential.cert(require(serviceAccountPath)) });
const db = admin.firestore();

async function run() {
  console.log('Checking users for expiry...');
  let nextPageToken;
  do {
    const list = await admin.auth().listUsers(1000, nextPageToken);
    for (const u of list.users) {
      if (u.uid === ADMIN_UID) continue;
      try {
        const doc = await db.doc(`users/${u.uid}/meta/settings`).get();
        if (!doc.exists) continue;
        const expiry = doc.get('expiry');
        if (!expiry) continue;
        const expiryDate = expiry.toDate ? expiry.toDate() : new Date(expiry);
        if (expiryDate <= new Date()) {
          await admin.auth().updateUser(u.uid, { disabled: true });
          console.log(`Disabled expired user: ${u.uid} (${u.email}) - expiry ${expiryDate.toISOString()}`);
        }
      } catch (e) {
        console.error('Error checking user', u.uid, e);
      }
    }
    nextPageToken = list.pageToken;
  } while (nextPageToken);
  console.log('Done.');
}
run().catch(err => { console.error(err); process.exit(1); });