import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/business_service.dart';
import '../models/business.dart';
import '../screens/quiz/quiz_screen.dart';
import 'business/business_detail_screen.dart';
import 'learn/learn_list_screen.dart';
import 'planner/plan_list_screen.dart';
import 'settings_screen.dart';
import '../screens/about_screen.dart';
import '../services/settings_service.dart';
import '../services/license_service.dart';

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
  List<Business> _savedBusinesses = [];
  final SettingsService _settingsSvc = SettingsService();
  String _currentPlan = 'trial';
  final LicenseService _licenseSvc = LicenseService();
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _initializeHome();
    _loadSettingsBadge();
    _checkExpiry();
  }

  Future<void> _checkExpiry() async {
    try {
      final expired = await _licenseSvc.isExpired();
      if (mounted) setState(() => _isExpired = expired);
    } catch (_) {}
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Access disabled'),
        content: const Text(
          'Your trial has expired. Please contact me to continue or unlock the full app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          // optionally open payment/contact link
        ],
      ),
    );
  }

  Future<void> _loadSettingsBadge() async {
    final s = await _settingsSvc.fetchSettings();
    if (s != null && mounted) setState(() => _currentPlan = s.plan);
  }

  Future<void> _loadSavedBusinesses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _savedBusinesses = []);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .get();
      final saved = snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        return Business.fromMap(m, docId: d.id);
      }).toList();
      if (mounted) setState(() => _savedBusinesses = saved);
    } catch (_) {
      if (mounted) setState(() => _savedBusinesses = []);
    }
  }

  Future<void> _initializeHome() async {
    setState(() => _loading = true);

    // load saved favorites first
    await _loadSavedBusinesses();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

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
        answers =
            (userDoc.data()?['quizAnswers'] ?? {}) as Map<String, dynamic>;
        // safe fetch of top businesses; getTop3 should handle timeouts/fallbacks
        topBusinesses = await _businessService.getTop3(answers, topN: 3);
      }

      if (mounted) {
        setState(() {
          _quizCompleted = quizCompleted;
          _topBusinesses = topBusinesses;
        });
      }
    } catch (e) {
      // optional: print('Home init error: $e');
    } finally {
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

    final tag = 'business-${b.docId ?? b.title}';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessDetailScreen(business: b, answers: null),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: tag,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (b.title.isNotEmpty ? b.title[0].toUpperCase() : '?'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right, color: Colors.black26),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      b.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (b.personality.isNotEmpty)
                          Chip(
                            label: Text(
                              b.personality.map(capitalize).join(', '),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (b.budget.isNotEmpty)
                          Chip(
                            label: Text(
                              'Budget: ${b.budget.map(capitalize).join(', ')}',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        if (b.time.isNotEmpty)
                          Chip(
                            label: Text(
                              'Time: ${b.time.map(capitalize).join(', ')}',
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          // Settings icon with small badge showing plan (T = trial, P = paid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                    // refresh badge after returning
                    _loadSettingsBadge();
                  },
                ),
                if (_currentPlan.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _currentPlan == 'paid'
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _currentPlan == 'paid' ? 'PRO' : 'TRI',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.school),
            tooltip: 'Learning Hub',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LearnListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'My Plans',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlanListScreen()),
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initializeHome,
              child: ListView(
                padding: const EdgeInsets.only(top: 16, bottom: 32),
                children: [
                  _buildQuizCard(),

                  // SAVED section (inserted here)
                  if (_savedBusinesses.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Saved',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ..._savedBusinesses.map(_buildBusinessCard),
                    const SizedBox(height: 8),
                  ],

                  // Recommended for You (existing block)
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
