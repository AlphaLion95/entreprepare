const admin = require('firebase-admin');
const crypto = require('crypto');
const path = require('path');
const fs = require('fs');

/*
  Usage:
  1) Place a Firebase service account JSON on your machine and set:
     Windows CMD:    set GOOGLE_APPLICATION_CREDENTIALS=C:\seed-firestore\serviceAccountKey.json
     PowerShell:     $env:GOOGLE_APPLICATION_CREDENTIALS='C:\seed-firestore\serviceAccountKey.json'
     mac/linux:      export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccountKey.json"
  2) From the scripts folder install dependency once:
     npm init -y
     npm install firebase-admin
  3) Run:
     node ./create_license_keys.js
*/

// Initialize Admin SDK safely
const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
  const sa = require(path.resolve(serviceAccountPath));
  admin.initializeApp({
    credential: admin.credential.cert(sa),
  });
} else {
  // In Cloud Functions or GCP the default credentials are used.
  admin.initializeApp();
}
const db = admin.firestore();

function genKey() {
  return crypto.randomBytes(8).toString('hex').toUpperCase(); // 16 hex chars
}

// Edit this array with the exact 5 keys you want to use.
// You can replace values with your own strings like "ABC-123-XYZ".
const keys = [
  { key: 'PRO-001-TEWFD', plan: 'pro', features: { advanced_analytics: true, unlimited_plans: true }, oneTime: true },
  { key: 'PRO-002-FSDFF', plan: 'pro', features: { advanced_analytics: true }, oneTime: true },
  { key: 'PRO-003-FDSDS', plan: 'pro', features: { unlimited_plans: true }, oneTime: true },
  { key: 'PRO-004-FDSFF', plan: 'pro', features: { priority_support: true }, oneTime: true },
  { key: 'PRO-005-FDFDS', plan: 'pro', features: { advanced_analytics: true, priority_support: true }, oneTime: true },
];

// If you prefer auto-generated keys, uncomment below and comment out the keys array above.
// const keys = Array.from({length:5}).map(() => ({ key: genKey(), plan: 'pro', features: {}, oneTime: true }));

(async () => {
  try {
    for (const k of keys) {
      const id = String(k.key).trim().toUpperCase();
      const docRef = db.collection('licenses').doc(id);
      const docData = {
        active: k.active !== undefined ? Boolean(k.active) : true,
        plan: k.plan || 'pro',
        features: k.features || {},
        oneTime: Boolean(k.oneTime === true),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        // explicit fields for clean schema:
        activatedBy: null,
        activatedAt: null,
      };
      if (k.expiresAt) {
        const dt = (typeof k.expiresAt === 'string') ? new Date(k.expiresAt) : k.expiresAt;
        docData.expiresAt = admin.firestore.Timestamp.fromDate(new Date(dt));
      }
      await docRef.set(docData, { merge: true });
      console.log(`Wrote license: ${id}`);
    }
    console.log('All licenses created/updated.');
    process.exit(0);
  } catch (err) {
    console.error('Error creating licenses:', err);
    process.exit(1);
  }
})();
