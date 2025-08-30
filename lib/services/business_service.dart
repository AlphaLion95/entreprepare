// lib/services/business_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/business.dart';
import '../models/quiz_question.dart';

class BusinessService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static final List<Map<String, dynamic>> _localData = [
    {
      "title": "Freelance Web Dev",
      "personality": "Introvert",
      "budget": "Low",
      "time": "Part-time",
      "skills": "Tech",
      "environment": "Home",
      "description":
          "Build websites and web apps for clients or small businesses.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Build a portfolio website",
        "Choose a freelance platform (Upwork, Fiverr)",
        "Reach out to local businesses",
      ],
    },
    {
      "title": "Data Entry Specialist",
      "personality": "Introvert",
      "budget": "Low",
      "time": "Part-time",
      "skills": "Tech",
      "environment": "Home",
      "description":
          "Provide accurate data entry and basic data cleansing services.",
      "cost": "Low",
      "earnings": "Low",
      "initialSteps": [
        "Set up a professional profile",
        "Apply to small data projects online",
      ],
    },
    {
      "title": "Graphic Design Freelancer",
      "personality": "Introvert",
      "budget": "Low",
      "time": "Part-time",
      "skills": "Design",
      "environment": "Home",
      "description":
          "Design logos, social assets, and marketing materials for clients.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Create a portfolio of sample designs",
        "List services and prices",
        "Promote on social media and design platforms",
      ],
    },
    {
      "title": "Boutique Clothing Store",
      "personality": "Extrovert",
      "budget": "High",
      "time": "Full-time",
      "skills": "Fashion",
      "environment": "Office",
      "description":
          "Operate a retail store selling curated clothing and accessories.",
      "cost": "High",
      "earnings": "High",
      "initialSteps": [
        "Research suppliers and margins",
        "Find a suitable retail location",
        "Create merchandising and marketing plan",
      ],
    },
    {
      "title": "Event Planner",
      "personality": "Extrovert",
      "budget": "Medium",
      "time": "Full-time",
      "skills": "Management",
      "environment": "Office",
      "description":
          "Plan and coordinate events (weddings, corporate events, parties).",
      "cost": "Medium",
      "earnings": "Medium",
      "initialSteps": [
        "Create sample event packages",
        "Network with vendors and venues",
        "Run a few pilot events or offer discounts",
      ],
    },
    {
      "title": "Social Media Manager",
      "personality": "Extrovert",
      "budget": "Low",
      "time": "Part-time",
      "skills": "Marketing",
      "environment": "Home",
      "description":
          "Manage social accounts, create content and grow audiences.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Learn social media tools and scheduling",
        "Prepare content samples",
        "Pitch to small businesses",
      ],
    },
    {
      "title": "Food Truck",
      "personality": "Risk-taker",
      "budget": "Medium",
      "time": "Full-time",
      "skills": "Food",
      "environment": "Travel",
      "description": "Mobile food service selling meals at events and streets.",
      "cost": "Medium",
      "earnings": "Medium",
      "initialSteps": [
        "Decide on a menu and price points",
        "Buy or lease a truck",
        "Find permits and parking spots",
      ],
    },
    {
      "title": "Restaurant / Cafe",
      "personality": "Risk-taker",
      "budget": "High",
      "time": "Full-time",
      "skills": "Food",
      "environment": "Office",
      "description": "Brick-and-mortar food service with dine-in and takeaway.",
      "cost": "High",
      "earnings": "High",
      "initialSteps": [
        "Create a business & financial plan",
        "Secure a location and equipment",
        "Hire staff and finalize menu",
      ],
    },
    {
      "title": "Tech Startup",
      "personality": "Risk-taker",
      "budget": "Medium",
      "time": "Full-time",
      "skills": "Tech",
      "environment": "Office",
      "description": "Build a scalable tech product or platform.",
      "cost": "Medium",
      "earnings": "High",
      "initialSteps": [
        "Validate the idea and market",
        "Build an MVP",
        "Find early customers and iterate",
      ],
    },
    {
      "title": "Mobile App Development",
      "personality": "Risk-taker",
      "budget": "Medium",
      "time": "Part-time",
      "skills": "Tech",
      "environment": "Home",
      "description": "Develop mobile apps for clients or monetized apps.",
      "cost": "Medium",
      "earnings": "High",
      "initialSteps": [
        "Define app idea and features",
        "Build an MVP or portfolio apps",
        "Publish to app stores and market",
      ],
    },
    {
      "title": "E-commerce Store",
      "personality": "Risk-taker",
      "budget": "Medium",
      "time": "Full-time",
      "skills": "Tech/Fashion",
      "environment": "Home",
      "description": "Sell products online via a store or marketplace.",
      "cost": "Medium",
      "earnings": "High",
      "initialSteps": [
        "Choose products and suppliers",
        "Build a store (Shopify/Shopify-like)",
        "Run ads and optimize conversions",
      ],
    },
    {
      "title": "Dropshipping Business",
      "personality": "Risk-taker",
      "budget": "Low",
      "time": "Part-time",
      "skills": "Marketing",
      "environment": "Home",
      "description":
          "Sell products without holding inventory via dropshipping.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Find reliable suppliers",
        "Build a store with good UX",
        "Focus on ads and customer service",
      ],
    },
    {
      "title": "YouTube Content Creator",
      "personality": "Risk-taker",
      "budget": "Low",
      "time": "Part-time",
      "skills": "Media/Tech",
      "environment": "Home",
      "description":
          "Create video content and build a channel monetized by ads/sponsors.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Choose a niche and equipment",
        "Produce consistent quality videos",
        "Optimize and grow audience",
      ],
    },
    {
      "title": "Fitness Trainer / Coach",
      "personality": "Extrovert",
      "budget": "Low",
      "time": "Part-time",
      "skills": "Fitness",
      "environment": "Travel",
      "description": "Offer personal training sessions or classes.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Get certifications (if necessary)",
        "Create training packages",
        "Offer free sessions to get testimonials",
      ],
    },
    {
      "title": "Online Tutoring",
      "personality": "Introvert",
      "budget": "Low",
      "time": "Part-time",
      "skills": "Education",
      "environment": "Home",
      "description": "Teach students online in your subject area.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Choose subject & curriculum",
        "Set up a tutoring profile",
        "Pick a scheduling/payment system",
      ],
    },
    {
      "title": "Handmade Crafts Seller",
      "personality": "Introvert",
      "budget": "Low",
      "time": "Part-time",
      "skills": "Craft/Design",
      "environment": "Home",
      "description": "Sell handmade goods on marketplaces like Etsy.",
      "cost": "Low",
      "earnings": "Medium",
      "initialSteps": [
        "Make a small inventory",
        "Create listings with good photos",
        "Promote on social and marketplaces",
      ],
    },
    {
      "title": "Travel Blogging",
      "personality": "Risk-taker",
      "budget": "Medium",
      "time": "Full-time",
      "skills": "Writing/Media",
      "environment": "Travel",
      "description": "Write travel guides, monetize via ads/affiliate deals.",
      "cost": "Medium",
      "earnings": "Medium",
      "initialSteps": [
        "Pick a niche & start publishing",
        "Monetize via ads or affiliates",
        "Network with tourism businesses",
      ],
    },
    {
      "title": "Photography Business",
      "personality": "Extrovert",
      "budget": "Medium",
      "time": "Full-time",
      "skills": "Photography",
      "environment": "Travel",
      "description":
          "Offer photography services for events or commercial work.",
      "cost": "Medium",
      "earnings": "Medium",
      "initialSteps": [
        "Build a portfolio & website",
        "Offer introductory packages",
        "Partner with event planners",
      ],
    },
    {
      "title": "Consulting Services",
      "personality": "Extrovert",
      "budget": "High",
      "time": "Full-time",
      "skills": "Business",
      "environment": "Office",
      "description": "Provide specialized business consulting services.",
      "cost": "High",
      "earnings": "High",
      "initialSteps": [
        "Define your niche & services",
        "Create case studies and proposals",
        "Find first clients via network",
      ],
    },
    {
      "title": "App/Game Development Studio",
      "personality": "Risk-taker",
      "budget": "High",
      "time": "Full-time",
      "skills": "Tech",
      "environment": "Office",
      "description": "Build games or apps at studio level for sale or clients.",
      "cost": "High",
      "earnings": "High",
      "initialSteps": [
        "Assemble a small dev team",
        "Define a project and prototype",
        "Find funding or client contracts",
      ],
    },
  ];

  // Convert local data to Business objects
  List<Business> _localBusinesses() =>
      _localData.map((m) => Business.fromMap(m)).toList();

  // Returns raw maps (used for compute to avoid sending complex objects).
  Future<List<Map<String, dynamic>>> _fetchAllRaw({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final snap = await firestore
          .collection('businesses')
          .get()
          .timeout(timeout);
      final docs = snap.docs;
      if (docs.isEmpty) return _localData;
      return docs.map((d) {
        final data = Map<String, dynamic>.from(d.data() as Map);
        // optional: keep doc id
        data['__docId'] = d.id;
        return data;
      }).toList();
    } catch (_) {
      // Firestore read failed or timed out -> fallback to local dataset
      return _localData;
    }
  }

  // Public fetchAll returning Business objects (used elsewhere; fast fallback)
  Future<List<Business>> fetchAll() async {
    final raw = await _fetchAllRaw();
    return raw.map((m) => Business.fromMap(m)).toList();
  }

  // getTop3 runs scoring in a background isolate via compute() to avoid blocking UI.
  // It accepts answers and returns topN Business objects.
  Future<List<Business>> getTop3(
    Map<String, dynamic> answers, {
    int topN = 3,
    Duration firestoreTimeout = const Duration(seconds: 3),
  }) async {
    final rawBusinesses = await _fetchAllRaw(timeout: firestoreTimeout);

    // compute expects only simple values: pass maps and answers
    final arg = {
      'businesses': rawBusinesses,
      'answers': Map<String, dynamic>.from(answers),
      'topN': topN,
    };

    final scored = await compute(_scoreAndPick, arg) as List<dynamic>;

    // scored is a list of maps { 'business': Map, 'score': int }
    final top = scored
        .map(
          (m) =>
              Business.fromMap(Map<String, dynamic>.from(m['business'] as Map)),
        )
        .toList();
    return top;
  }

  // Other methods retained (implementations can remain as before or be expanded).
  Future<List<QuizQuestion>> getQuestionsForCategory(String category) async {
    // keep existing or return default questions
    return [];
  }

  Future<void> saveQuizAnswers(String uid, Map<String, dynamic> answers) async {
    await firestore.collection('users').doc(uid).set({
      'quizCompletedAt': FieldValue.serverTimestamp(),
      'lastQuizAnswers': answers,
    }, SetOptions(merge: true));
  }

  Future<bool> fetchUserQuizStatus(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      return doc.data()?['quizCompleted'] ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> uploadLocalToFirestore() async {
    final batch = firestore.batch();
    final col = firestore.collection('businesses');
    for (final m in _localData) {
      final docRef = col.doc();
      batch.set(docRef, m);
    }
    await batch.commit();
  }
}

// Top-level scoring function for compute() — must be a top-level or static function.
// ...existing code...
List<Map<String, dynamic>> _scoreAndPick(Map<String, dynamic> args) {
  final List<dynamic> businesses = args['businesses'] as List<dynamic>;
  final Map<String, dynamic> answers = Map<String, dynamic>.from(
    args['answers'] as Map,
  );
  final int topN = args['topN'] as int? ?? 3;

  // normalize any value to a lowercase single-line string; handle Iterable/Map gracefully
  String norm(dynamic v) {
    if (v == null) return '';
    if (v is String) return v.toLowerCase().trim();
    if (v is Iterable)
      return v.map((e) => e?.toString() ?? '').join(' ').toLowerCase().trim();
    if (v is Map)
      return v.values
          .map((e) => e?.toString() ?? '')
          .join(' ')
          .toLowerCase()
          .trim();
    return v.toString().toLowerCase().trim();
  }

  // configurable weights (tune importance)
  final Map<String, int> weights = {
    'personality': 30,
    'budget': 20,
    'time': 20,
    'skills': 20,
    'environment': 10,
  };

  int scoreField(dynamic aRaw, dynamic bRaw, int weight) {
    final a = norm(aRaw);
    final b = norm(bRaw);
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return weight; // exact match -> full weight
    if (b.contains(a) || a.contains(b))
      return (weight * 60) ~/ 100; // substring -> 60%
    final aTokens = a.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toSet();
    final bTokens = b.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toSet();
    final intersect = aTokens.intersection(bTokens).length;
    final maxTokens = (aTokens.length > bTokens.length)
        ? aTokens.length
        : bTokens.length;
    if (intersect > 0 && maxTokens > 0) {
      final proportion = intersect / maxTokens;
      return (weight * (proportion * 0.8)).round(); // up to 80% of weight
    }
    if (b.startsWith(a) || a.startsWith(b))
      return (weight * 50) ~/ 100; // prefix similarity
    return 0;
  }

  final List<Map<String, dynamic>> scored = [];

  for (var i = 0; i < businesses.length; i++) {
    final bRaw = businesses[i];
    try {
      final b = (bRaw is Map)
          ? Map<String, dynamic>.from(bRaw as Map)
          : <String, dynamic>{};
      int total = 0;
      total += scoreField(
        answers['personality'],
        b['personality'],
        weights['personality'] ?? 30,
      );
      total += scoreField(
        answers['budget'],
        b['budget'],
        weights['budget'] ?? 20,
      );
      total += scoreField(answers['time'], b['time'], weights['time'] ?? 20);
      total += scoreField(
        answers['skills'],
        b['skills'],
        weights['skills'] ?? 20,
      );
      total += scoreField(
        answers['environment'],
        b['environment'],
        weights['environment'] ?? 10,
      );

      // numeric closeness example (slider/investment)
      if (answers.containsKey('investment') && b.containsKey('investment')) {
        try {
          final aNum = double.parse(answers['investment'].toString());
          final bNum = double.parse(b['investment'].toString());
          final diff = (aNum - bNum).abs();
          final closeness = (15 * (1 / (1 + diff))).round();
          total += closeness;
        } catch (_) {
          // ignore individual parse errors
        }
      }

      scored.add({'business': b, 'score': total});
    } catch (e) {
      // If one business entry is malformed, skip it but keep processing others.
      scored.add({
        'business': <String, dynamic>{'title': 'Invalid entry #$i'},
        'score': 0,
      });
    }
  }

  scored.sort((x, y) => (y['score'] as int).compareTo(x['score'] as int));
  return scored.take(topN).toList();
}
// ...existing code...