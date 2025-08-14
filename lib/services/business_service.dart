// lib/services/business_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business.dart';
import '../models/quiz_question.dart';

class BusinessService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static final List<Map<String, dynamic>> _localData = [
    {
      "title": "Freelance Web Dev",
      "personality": ["Introvert"],
      "budget": ["Low"],
      "time": ["Part-time"],
      "skills": ["Tech"],
      "environment": ["Home-based"],
      "description":
          "Build websites and web apps for clients or small businesses.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Build a portfolio website",
        "Choose a freelance platform",
        "Reach out to clients",
      ],
    },
    {
      "title": "Local Bakery",
      "personality": ["Practical", "Extrovert"],
      "budget": ["Medium"],
      "time": ["Full-time"],
      "skills": ["Cooking"],
      "environment": ["Shop"],
      "description": "Start a small bakery for bread, cakes, and pastries.",
      "cost": "Medium",
      "earnings": "High",
      "initialSteps": [
        "Rent a small space",
        "Buy baking equipment",
        "Create a menu and start selling locally",
      ],
    },
    {
      "title": "Fitness Trainer",
      "personality": ["Extrovert"],
      "budget": ["Low", "Medium"],
      "time": ["Part-time", "Full-time"],
      "skills": ["Fitness"],
      "environment": ["Gym", "Home-based"],
      "description": "Provide fitness coaching and training services.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Get certified",
        "Promote services on social media",
        "Offer free trial sessions",
      ],
    },
    {
      "title": "Online Tutoring",
      "personality": ["Introvert", "Practical"],
      "budget": ["Low"],
      "time": ["Part-time"],
      "skills": ["Education"],
      "environment": ["Home-based"],
      "description":
          "Teach subjects online for students via Zoom or other platforms.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Choose subjects",
        "Create lesson plans",
        "Register on tutoring platforms",
      ],
    },
    {
      "title": "Fashion Boutique",
      "personality": ["Extrovert"],
      "budget": ["Medium", "High"],
      "time": ["Full-time"],
      "skills": ["Fashion", "Design"],
      "environment": ["Shop"],
      "description":
          "Sell fashionable clothing and accessories locally or online.",
      "cost": "Medium",
      "earnings": "High",
      "initialSteps": [
        "Find a location",
        "Stock inventory",
        "Market your boutique",
      ],
    },
  ];

  List<Business> _localBusinesses() =>
      _localData.map((m) => Business.fromMap(m)).toList();

  Future<List<Business>> fetchAll() async {
    try {
      final snap = await firestore.collection('businesses').get();
      if (snap.docs.isEmpty) return _localBusinesses();
      return snap.docs
          .map((d) => Business.fromMap(d.data(), docId: d.id))
          .toList();
    } catch (_) {
      return _localBusinesses();
    }
  }

  Future<List<Business>> getTop3(
    Map<String, dynamic> answers, {
    int topN = 3,
  }) async {
    final all = await fetchAll();
    List<Map<String, dynamic>> scored = [];
    String aPersonality = (answers['personality'] ?? '')
        .toString()
        .toLowerCase();
    String aBudget = (answers['budget'] ?? '').toString().toLowerCase();
    String aTime = (answers['time'] ?? '').toString().toLowerCase();
    String aSkills = (answers['skills'] ?? '').toString().toLowerCase();
    String aEnvironment = (answers['environment'] ?? '')
        .toString()
        .toLowerCase();

    for (final b in all) {
      int score = 0;
      if (b.personality.any((p) => p.toLowerCase() == aPersonality)) score += 3;
      if (b.skills.any((s) => s.toLowerCase() == aSkills)) score += 3;
      if (b.budget.any((x) => x.toLowerCase() == aBudget)) score += 2;
      if (b.time.any((x) => x.toLowerCase() == aTime)) score += 2;
      if (b.environment.any((x) => x.toLowerCase() == aEnvironment)) score += 1;
      scored.add({'business': b, 'score': score});
    }

    scored.sort((x, y) => (y['score'] as int).compareTo(x['score'] as int));
    return scored.map((e) => e['business'] as Business).take(topN).toList();
  }

  Future<List<QuizQuestion>> getQuestionsForCategory(String category) async {
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

  Future<void> saveQuizAnswers(String uid, Map<String, dynamic> answers) async {
    await firestore.collection('users').doc(uid).set({
      'quizAnswers': answers,
      'quizCompleted': true,
      'quizCompletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> fetchUserQuizStatus(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      return doc.data()?['quizCompleted'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> uploadLocalToFirestore() async {
    final batch = firestore.batch();
    for (final m in _localData) {
      final id = m['title']
          .toString()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'(^-|-$)'), '');
      final ref = firestore.collection('businesses').doc(id);
      batch.set(ref, m);
    }
    await batch.commit();
  }
}
