const admin = require('firebase-admin');
const svc = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (svc) admin.initializeApp({ credential: admin.credential.cert(require(svc)) });
else admin.initializeApp();

const uid = process.argv[2];
if (!uid) { console.error('Usage: node get_user_claims.js <uid>'); process.exit(1); }

admin.auth().getUser(uid)
  .then(u => {
    console.log('uid:', u.uid);
    console.log('email:', u.email);
    console.log('disabled:', u.disabled);
    console.log('customClaims:', JSON.stringify(u.customClaims || {}, null, 2));
  })
  .catch(err => { console.error(err); process.exit(1); });