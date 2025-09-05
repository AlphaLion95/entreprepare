const admin = require('firebase-admin');
const argv = process.argv.slice(2);
if (argv.length < 2) {
  console.error('Usage: node scripts\\toggle_users_disabled.js <disable|enable> <ADMIN_UID>');
  process.exit(1);
}
const mode = argv[0];
const ADMIN_UID = argv[1];
const disabled = mode === 'disable';

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || './serviceAccountKey.json';
admin.initializeApp({ credential: admin.credential.cert(require(serviceAccountPath)) });

async function run() {
  console.log(`${disabled ? 'Disabling' : 'Enabling'} all users except ${ADMIN_UID}...`);
  let nextPageToken;
  do {
    const list = await admin.auth().listUsers(1000, nextPageToken);
    for (const u of list.users) {
      if (u.uid === ADMIN_UID) continue;
      await admin.auth().updateUser(u.uid, { disabled });
      console.log(`${disabled ? 'Disabled' : 'Enabled'}: ${u.uid} (${u.email || 'no-email'})`);
    }
    nextPageToken = list.pageToken;
  } while (nextPageToken);
  console.log('Done.');
}
run().catch(err => { console.error(err); process.exit(1); });