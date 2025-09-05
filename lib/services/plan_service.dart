import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plan.dart';

class PlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createPlan(Plan plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    final ref = _db.collection('users').doc(user.uid).collection('plans').doc();
    await ref.set(plan.toMap());
    return ref.id;
  }

  Future<void> updatePlan(Plan plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');
    await _db.collection('users').doc(user.uid).collection('plans').doc(plan.id).set(plan.toMap(), SetOptions(merge: true));
  }

  Future<List<Plan>> fetchPlans() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final snap = await _db.collection('users').doc(user.uid).collection('plans').orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Plan.fromMap(d.id, d.data() as Map<String, dynamic>)).toList();
  }
}