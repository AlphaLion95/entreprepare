import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/business_service.dart';
import '../models/business.dart';
import '../screens/quiz/quiz_screen.dart';
import 'business/business_detail_screen.dart';
import '../services/plan_service.dart' as ps;
import '../services/settings_service.dart' as ss;
import '../models/plan.dart';
import '../utils/currency_utils.dart';
import 'planner/plan_detail_screen.dart';
import 'planner/plan_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int index)? onSelectTab;
  const HomeScreen({super.key, this.onSelectTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BusinessService _businessService = BusinessService();
  final ps.PlanService _planService = ps.PlanService();
  final ss.SettingsService _settingsSvc = ss.SettingsService();
  bool _loading = true;
  bool _quizCompleted = false;
  List<Business> _topBusinesses = [];
  List<Business> _savedBusinesses = [];
  List<Plan> _plans = [];
  String _currency = 'PHP';
  late final Stream<ss.Settings?> _settingsStream;

  @override
  void initState() {
    super.initState();
    _initializeHome();
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
    // load plans and settings
    await _loadPlans();
    _settingsStream = _settingsSvc.watchSettings();
    _settingsStream.listen((s) {
      if (!mounted) return;
      setState(() => _currency = (s?.currency ?? 'PHP'));
    });

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

  Future<void> _loadPlans() async {
    try {
      final plans = await _planService.fetchPlans();
      if (mounted) setState(() => _plans = plans);
    } catch (_) {
      if (mounted) setState(() => _plans = []);
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

  Widget _buildPlanCard(Plan p) {
    return InkWell(
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: p)),
        );
        if (changed == true) await _loadPlans();
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.12),
                child: Text(
                  p.title.isNotEmpty ? p.title[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        Chip(
                          label: Text(
                            'Net: ${formatCurrency(p.monthlyNetProfit, _currency)}',
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
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

                  // MY PLANS section
                  if (_plans.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Plans',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (widget.onSelectTab != null) {
                                widget.onSelectTab!(1);
                              } else {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PlanListScreen(),
                                  ),
                                );
                                await _loadPlans();
                              }
                            },
                            child: const Text('See all'),
                          ),
                        ],
                      ),
                    ),
                    ..._plans.take(3).map(_buildPlanCard),
                    const SizedBox(height: 8),
                  ],

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
