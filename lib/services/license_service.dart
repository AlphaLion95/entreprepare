// ...existing code...
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LicenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------------
  // Expiry logic (untouched)
  // ------------------------

  Future<DateTime?> fetchExpiryForUser(String uid) async {
    final doc = await _db.doc('users/$uid/meta/settings').get();
    if (!doc.exists) return null;
    final data = doc.data();
    final expiry = data?['expiry'];
    if (expiry is Timestamp) return expiry.toDate();
    if (expiry is String) return DateTime.tryParse(expiry);
    if (expiry is int) return DateTime.fromMillisecondsSinceEpoch(expiry);
    return null;
  }

  Future<DateTime?> fetchExpiryForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return fetchExpiryForUser(user.uid);
  }

  Future<bool> isExpiredForUser(String uid) async {
    final expiry = await fetchExpiryForUser(uid);
    if (expiry == null) return false;
    return DateTime.now().toUtc().isAfter(expiry.toUtc());
  }

  Future<bool> isExpired() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return isExpiredForUser(user.uid);
  }

  Future<void> setExpiryForUser(String uid, DateTime expiry) async {
    await _db.doc('users/$uid/meta/settings').set({
      'expiry': Timestamp.fromDate(expiry),
    }, SetOptions(merge: true));
  }

  Future<void> clearExpiryForUser(String uid) async {
    await _db.doc('users/$uid/meta/settings').set({
      'expiry': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  // ------------------------
  // License verification
  // ------------------------

  // Verify a key by reading licenses/{key} and attaching it to the current user.
  // Also writes usage info back to the license document (usedBy / activatedAt)
  // and forces a token refresh on the client.
  Future<Map<String, dynamic>> verifyKey(String key) async {
    final snapRef = _db.collection('licenses').doc(key);
    final snap = await snapRef.get();

    if (!snap.exists) {
      throw Exception('Invalid license key');
    }

    final data = snap.data()!;
    final active = data['active'] == true;

    if (!active) {
      throw Exception('License not active');
    }

    // Attach license to current user
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');

    // Write user's license meta
    final userLicenseRef = _db
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('license');

    final licenseData = {
      'licenseKey': key,
      'plan': data['plan'],
      'features': data['features'],
      'activatedAt': FieldValue.serverTimestamp(),
    };

    await userLicenseRef.set(licenseData, SetOptions(merge: true));

    // Update license document usage info (record usedBy and optionally deactivate one-time keys)
    try {
      final updateMap = <String, dynamic>{
        'lastUsedBy': uid,
        'lastActivatedAt': FieldValue.serverTimestamp(),
        'usedBy': FieldValue.arrayUnion([uid]),
      };
      // if the license is oneTime, deactivate it
      if (data['oneTime'] == true) {
        updateMap['active'] = false;
      }
      await snapRef.set(updateMap, SetOptions(merge: true));
    } catch (_) {
      // non-fatal if we can't update license doc
    }

    // Force client token refresh to pick up any server-side claims if applicable
    await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);

    return {
      'success': true,
      'message': 'License activated',
      'plan': data['plan'],
      'features': data['features'],
    };
  }

  // ------------------------
  // License status checks
  // ------------------------

  Future<bool> isPaid() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('meta')
        .doc('license')
        .get();
    if (!doc.exists) return false;

    final data = doc.data() ?? {};
    return data['licenseKey'] != null;
  }

  Future<Map<String, dynamic>> getUserLicenseFeatures() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('meta')
        .doc('license')
        .get();
    if (!snap.exists) return {};
    final data = snap.data() ?? {};
    if (data['features'] is Map) {
      return Map<String, dynamic>.from(data['features']);
    }
    return {};
  }

  // Stream the user's license meta so UI can react to changes immediately.
  Stream<DocumentSnapshot<Map<String, dynamic>>> licenseStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('license')
        .snapshots()
        .cast<DocumentSnapshot<Map<String, dynamic>>>();
  }
}
