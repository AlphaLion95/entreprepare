// Create file: c:\flutter_projects\entreprepare\lib\services\settings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/auth_toggle.dart';
import 'local_store.dart';

class Settings {
  String currency; // e.g. "USD", "PHP", "EUR"
  String plan; // "trial" | "paid"
  Map<String, bool> features;
  DateTime updatedAt;

  Settings({
    required this.currency,
    required this.plan,
    required this.features,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'currency': currency,
    'plan': plan,
    'features': features,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory Settings.fromMap(Map<String, dynamic> m) => Settings(
    currency: (m['currency'] ?? 'PHP').toString(),
    plan: (m['plan'] ?? 'trial').toString(),
    features: Map<String, bool>.from(m['features'] ?? {}),
    updatedAt: m['updatedAt'] is Timestamp
        ? (m['updatedAt'] as Timestamp).toDate()
        : DateTime.now(),
  );
}

class SettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Settings?> fetchSettings() async {
    if (kAuthDisabled) {
      final m = await LocalStore.loadSettings();
      return m == null ? null : Settings.fromMap(m);
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('meta')
        .doc('settings')
        .get();
    if (!doc.exists) return null;
    return Settings.fromMap(doc.data()!);
  }

  Future<void> saveSettings(Settings s) async {
    if (kAuthDisabled) {
      await LocalStore.saveSettings(s.toMap());
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('meta')
        .doc('settings')
        .set(s.toMap(), SetOptions(merge: true));
  }

  Stream<Settings?> watchSettings() {
    if (kAuthDisabled) {
      return Stream.fromFuture(fetchSettings());
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('meta')
        .doc('settings')
        .snapshots()
        .map((snap) => snap.exists ? Settings.fromMap(snap.data()!) : null);
  }
}
