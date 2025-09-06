const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

exports.activateLicense = functions.https.onCall(async (data, context) => {
  const key = data && data.key ? String(data.key).trim().toUpperCase() : null;
  if (!key) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing license key.');
  }

  // Recommended: require the caller to be authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'You must sign in to activate a license.');
  }
  const uid = context.auth.uid;
  const deviceInfo = data.deviceInfo || null;

  const licenseRef = db.collection('licenses').doc(key);

  try {
    const result = await db.runTransaction(async (tx) => {
      const doc = await tx.get(licenseRef);
      if (!doc.exists) {
        throw new functions.https.HttpsError('not-found', 'Invalid license key.');
      }
      const lic = doc.data();

      // expiry check (if present)
      if (lic.expiresAt && lic.expiresAt.toDate && lic.expiresAt.toDate() < new Date()) {
        throw new functions.https.HttpsError('failed-precondition', 'License expired.');
      }

      // One-time license logic
      if (lic.oneTime === true) {
        if (lic.active === false || lic.activatedBy) {
          throw new functions.https.HttpsError('already-exists', 'License already used.');
        }
        tx.update(licenseRef, {
          active: false,
          activatedBy: uid,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastDevice: deviceInfo
        });
        // audit log
        const logRef = db.collection('license_activations').doc();
        tx.set(logRef, {
          licenseId: key,
          userId: uid,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          device: deviceInfo,
          oneTime: true
        });
        return { plan: lic.plan, features: lic.features || {}, oneTime: true };
      } else {
        // reusable license: update counters + last activation
        const activationCount = (lic.activationCount || 0) + 1;
        tx.update(licenseRef, {
          activationCount: activationCount,
          lastActivatedBy: uid,
          lastActivatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastDevice: deviceInfo
        });
        const logRef = db.collection('license_activations').doc();
        tx.set(logRef, {
          licenseId: key,
          userId: uid,
          activatedAt: admin.firestore.FieldValue.serverTimestamp(),
          device: deviceInfo,
          oneTime: false
        });
        return { plan: lic.plan, features: lic.features || {}, oneTime: false, activationCount: activationCount };
      }
    });

    return { success: true, ...result };
  } catch (err) {
    if (err instanceof functions.https.HttpsError) throw err;
    console.error('activation error', err);
    throw new functions.https.HttpsError('internal', 'Server error: ' + (err.message || 'unknown'));
  }
});
