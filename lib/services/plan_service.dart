import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plan.dart';

class PlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createPlan(Plan plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    final col = _db.collection('users').doc(user.uid).collection('plans');
    final ref = col.doc();
    await ref.set(plan.toMap());
    return ref.id;
  }

  Future<String?> findPlanIdByTitle(String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final col = _db.collection('users').doc(user.uid).collection('plans');
    final tLower = title.trim().toLowerCase();
    // Prefer normalized check
    final q1 = await col.where('titleLower', isEqualTo: tLower).limit(1).get();
    if (q1.docs.isNotEmpty) return q1.docs.first.id;
    // Fallback exact case match for older docs without titleLower
    final q2 = await col.where('title', isEqualTo: title.trim()).limit(1).get();
    if (q2.docs.isNotEmpty) return q2.docs.first.id;
    return null;
  }

  Future<void> updatePlan(Plan plan) async {
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
