import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_question.dart';
import 'business_service.dart';
import '../models/business.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BusinessService _businessService = BusinessService();

  // Inside QuizService
  Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // Hard-coded questions for now (easy to move to Firestore later)
  List<QuizQuestion> getQuestions() {
    return [
      QuizQuestion(
        id: 'personality',
        question: "What's your personality type?",
        options: ['Introvert', 'Extrovert', 'Risk-taker'],
        type: 'choice',
      ),
      QuizQuestion(
        id: 'budget',
        question: "What's your startup budget range?",
        options: ['Low', 'Medium', 'High'],
        type: 'choice',
      ),
      QuizQuestion(
        id: 'time',
        question: "How much time can you commit?",
        options: ['Part-time', 'Full-time', 'Weekends only'],
        type: 'choice',
      ),
      QuizQuestion(
        id: 'skills',
        question: "What are your main skills / interests?",
        options: [
          'Tech',
          'Food',
          'Fashion',
          'Education',
          'Design',
          'Marketing',
        ],
        type: 'choice',
      ),
      QuizQuestion(
        id: 'environment',
        question: "Preferred work environment?",
        options: ['Home-based', 'Office', 'Outdoor', 'Travel'],
        type: 'choice',
      ),
      // Example slider question (optional)
      QuizQuestion(
        id: 'riskTolerance',
        question:
            "On a scale of 0 (low) to 10 (high), how much risk do you take?",
        options: [],
        type: 'slider',
        sliderMin: 0,
        sliderMax: 10,
        sliderDivisions: 10,
      ),
    ];
  }

  // Save answers under users/{uid}.quizAnswers
  Future<void> saveAnswers(Map<String, dynamic> answers) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final docRef = _firestore.collection('users').doc(user.uid);
    await docRef.set({
      'quizAnswers': answers,
      'quizCompleted': true,
      'quizCompletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get top N businesses based on user answers
  Future<List<Business>> getTopBusinesses(
    Map<String, dynamic> answers, {
    int topN = 3,
  }) async {
    return await _businessService.getTop3(answers, topN: topN);
  }
}
