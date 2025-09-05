// ...create or overwrite this file...
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LicenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Read expiry DateTime from users/{uid}/meta/settings.expiry (Timestamp)
  Future<DateTime?> fetchExpiryForUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).collection('meta').doc('settings').get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final expiry = data['expiry'];
    if (expiry is Timestamp) return expiry.toDate();
    if (expiry is int) return DateTime.fromMillisecondsSinceEpoch(expiry);
    return null;
  }

  Future<DateTime?> fetchExpiryForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return fetchExpiryForUser(user.uid);
  }

  /// Returns true if current time is after expiry. If no expiry set, returns false.
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

  /// Admin helper: set expiry for a user (admin action).
  Future<void> setExpiryForUser(String uid, DateTime expiry) async {
    await _db.collection('users').doc(uid).collection('meta').doc('settings').set({
      'expiry': Timestamp.fromDate(expiry),
    }, SetOptions(merge: true));
  }

  /// Remove expiry (unblock) for a user.
  Future<void> clearExpiryForUser(String uid) async {
    await _db.collection('users').doc(uid).collection('meta').doc('settings').set({
      'expiry': FieldValue.delete(),
    }, SetOptions(merge: true));
  }
}