const admin = require('firebase-admin');
const argv = process.argv.slice(2);
if (argv.length < 2) {
  console.error('Usage: node scripts\\set_user_expiry.js <TARGET_UID_OR_EMAIL> <ISO_DATETIME>');
  console.error('Example: node scripts\\set_user_expiry.js user@example.com 2025-09-10T12:00:00Z');
  process.exit(1);
}
const target = argv[0];
const iso = argv[1];
const expiryDate = new Date(iso);
if (isNaN(expiryDate)) {
  console.error('Invalid date:', iso);
  process.exit(1);
}
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || './serviceAccountKey.json';
admin.initializeApp({ credential: admin.credential.cert(require(serviceAccountPath)) });
const db = admin.firestore();

async function run() {
  let uid = target;
  if (target.includes('@')) {
    const user = await admin.auth().getUserByEmail(target);
    uid = user.uid;
  }
  await db.doc(`users/${uid}/meta/settings`).set({ expiry: admin.firestore.Timestamp.fromDate(expiryDate) }, { merge: true });
  console.log(`Set expiry for ${uid} => ${expiryDate.toISOString()}`);
}
run().catch(err => { console.error(err); process.exit(1); });