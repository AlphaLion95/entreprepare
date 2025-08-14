import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/business_service.dart';
import '../models/business.dart';
import '../screens/quiz/quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BusinessService _businessService = BusinessService();
  bool _loading = true;
  bool _quizCompleted = false;
  List<Business> _topBusinesses = [];

  @override
  void initState() {
    super.initState();
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final quizCompleted = await _businessService.fetchUserQuizStatus(
        user.uid,
      );
      Map<String, dynamic> answers = {};
      List<Business> topBusinesses = [];

      if (quizCompleted) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        answers = userDoc.data()?['quizAnswers'] ?? {};
        topBusinesses = await _businessService.getTop3(answers, topN: 3);
      }

      if (mounted) {
        setState(() {
          _quizCompleted = quizCompleted;
          _topBusinesses = topBusinesses;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startQuiz() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
    await _initializeHome(); // Refresh top businesses after quiz
  }

  Widget _buildQuizCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _quizCompleted ? 'Quiz Completed' : 'Start Your Quiz',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _quizCompleted
                  ? 'Your recommendations are below.'
                  : 'Answer a few questions to get personalized business recommendations.',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startQuiz,
                child: Text(_quizCompleted ? 'Retake Quiz' : 'Start Quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(Business b) {
    String capitalize(String s) =>
        s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              b.description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (b.personality.isNotEmpty)
                  Chip(label: Text(b.personality.map(capitalize).join(', '))),
                if (b.budget.isNotEmpty)
                  Chip(
                    label: Text(
                      'Budget: ${b.budget.map(capitalize).join(', ')}',
                    ),
                  ),
                if (b.time.isNotEmpty)
                  Chip(
                    label: Text('Time: ${b.time.map(capitalize).join(', ')}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initializeHome,
              child: ListView(
                padding: const EdgeInsets.only(top: 16, bottom: 32),
                children: [
                  _buildQuizCard(),
                  if (_quizCompleted && _topBusinesses.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Recommended for You',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._topBusinesses.map(_buildBusinessCard),
                  ],
                ],
              ),
            ),
    );
  }
}
