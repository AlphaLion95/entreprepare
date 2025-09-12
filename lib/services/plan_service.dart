import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/auth_toggle.dart';
import 'local_store.dart';
import '../models/plan.dart';

class PlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createPlan(Plan plan) async {
    if (kAuthDisabled) {
      final plans = await LocalStore.loadPlans();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final map = {...plan.toMap(), 'id': id};
      // Convert any Firestore Timestamp to ISO string for JSON storage
      final createdAt = map['createdAt'];
      if (createdAt is Timestamp) {
        map['createdAt'] = createdAt.toDate().toIso8601String();
      }
      plans.add(map);
      await LocalStore.savePlans(plans);
      return id;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    final col = _db.collection('users').doc(user.uid).collection('plans');
    final ref = col.doc();
    await ref.set(plan.toMap());
    return ref.id;
  }

  Future<String?> findPlanIdByTitle(String title) async {
    if (kAuthDisabled) {
      final plans = await LocalStore.loadPlans();
      final tLower = title.trim().toLowerCase();
      final match = plans.firstWhere(
        (p) =>
            (p['titleLower'] ?? p['title']?.toString().toLowerCase()) == tLower,
        orElse: () => {},
      );
      if (match.isEmpty) return null;
      return match['id']?.toString();
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final col = _db.collection('users').doc(user.uid).collection('plans');
    final tLower = title.trim().toLowerCase();
    final q1 = await col.where('titleLower', isEqualTo: tLower).limit(1).get();
    if (q1.docs.isNotEmpty) return q1.docs.first.id;
    final q2 = await col.where('title', isEqualTo: title.trim()).limit(1).get();
    if (q2.docs.isNotEmpty) return q2.docs.first.id;
    return null;
  }

  Future<void> updatePlan(Plan plan) async {
    if (kAuthDisabled) {
      final plans = await LocalStore.loadPlans();
      final idx = plans.indexWhere((p) => p['id'] == plan.id);
      if (idx != -1) {
        final updated = {...plans[idx], ...plan.toMap()};
        if (updated['createdAt'] is Timestamp) {
          updated['createdAt'] = (updated['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        plans[idx] = updated;
        await LocalStore.savePlans(plans);
      }
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('plans')
        .doc(plan.id)
        .set(plan.toMap(), SetOptions(merge: true));
  }

  Future<List<Plan>> fetchPlans() async {
    if (kAuthDisabled) {
      final raw = await LocalStore.loadPlans();
      return raw
          .map((m) => Plan.fromMap(m['id']?.toString() ?? '', m))
          .toList();
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snap = await _db
        .collection('users')
        .doc(user.uid)
        .collection('plans')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Plan.fromMap(d.id, d.data())).toList();
  }
}
