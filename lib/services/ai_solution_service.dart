import 'dart:math';
import '../services/local_store.dart';

class ProblemSolutionSuggestion {
  final String title;
  final String rationale;
  final List<String> steps;
  ProblemSolutionSuggestion({
    required this.title,
    required this.rationale,
    required this.steps,
  });

  Map<String, dynamic> toMap() => {
        'title': title,
        'rationale': rationale,
        'steps': steps,
      };

  factory ProblemSolutionSuggestion.fromMap(Map<String, dynamic> m) =>
      ProblemSolutionSuggestion(
        title: (m['title'] ?? '').toString(),
        rationale: (m['rationale'] ?? '').toString(),
        steps: (m['steps'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}

class AiSolutionService {
  // Patterns: keywords -> strategy blueprint
  static final List<_Pattern> _patterns = [
    _Pattern(
      keywords: ['low foot traffic', 'few customers', 'no walk-ins'],
      title: 'Local Awareness Sprint',
      rationale:
          'Drive nearby audience discovery using partnerships + micro-events to increase repeat local visits.',
      steps: [
        'Map 3 complementary local businesses (non-competing).',
        'Create a shared mini event or bundle offer for one weekend.',
        'Design simple flyer / social post template; each partner posts.',
        'Collect visitor emails/phones via a raffle form.',
        'Send follow-up offer within 48 hours to convert first-time to repeat.',
      ],
    ),
    _Pattern(
      keywords: ['high churn', 'low retention', 'customers leave'],
      title: 'Retention Ladder Program',
      rationale:
          'Introduce staged loyalty incentives so each additional purchase unlocks perceived value and reduces churn.',
      steps: [
        'Analyze repeat purchase intervals; set 3 loyalty tiers.',
        'Define rewards (small perk, meaningful discount, VIP benefit).',
        'Implement simple tracking (spreadsheet or POS notes).',
        'Train staff to invite every buyer to tier 1 on checkout.',
        'Weekly review: list customers near next tier; send personal nudge.',
      ],
    ),
    _Pattern(
      keywords: ['inventory waste', 'spoilage', 'unsold stock'],
      title: 'Smart Inventory Rotation & Bundling',
      rationale:
          'Reduce waste by forecasting demand and bundling slow movers with fast sellers to accelerate turnover.',
      steps: [
        'Tag products: fast, medium, slow (based on last 30 days).',
        'Create 2 bundle offers pairing slow + fast items.',
        'Set weekly target to move X% of slow stock.',
        'Review daily remaining slow units; push flash discount if > threshold.',
        'Refine purchase order quantities for next cycle.',
      ],
    ),
    _Pattern(
      keywords: ['low online visibility', 'no social engagement'],
      title: 'Content Flywheel Starter',
      rationale:
          'Establish a repeatable weekly content process that compounds reach through repurposing.',
      steps: [
        'List 6 core customer pain themes.',
        'Record one 5-min explainer addressing a theme.',
        'Transcribe & extract 5 short tips (micro posts).',
        'Schedule shorts across 2 platforms; long form on primary channel.',
        'Weekly: review analytics; double down on top theme.',
      ],
    ),
    _Pattern(
      keywords: ['cash flow', 'runway', 'working capital'],
      title: 'Cash Flow Stabilization Toolkit',
      rationale:
          'Smooth cash gaps by accelerating receivables and deferring non-critical outflows.',
      steps: [
        'List all monthly recurring expenses; flag deferrable items.',
        'Offer small early-payment incentive to top 20% customers.',
        'Negotiate extended terms with 2 largest suppliers.',
        'Introduce pre-order deposit for upcoming launch.',
        'Create a 12-week rolling cash forecast updated weekly.',
      ],
    ),
    _Pattern(
      keywords: ['low conversion', 'poor sales', 'cart abandonment'],
      title: 'Conversion Funnel Tune-Up',
      rationale:
          'Lift conversions by tightening value proposition and reducing friction at each step.',
      steps: [
        'Map current funnel steps (awareness → purchase).',
        'Identify largest drop-off stage via simple counts.',
        'Hypothesize single friction cause; craft 1 improvement.',
        'Run micro test for 1 week; measure delta.',
        'Standardize winning change; move to next bottleneck.',
      ],
    ),
  ];

  Future<List<ProblemSolutionSuggestion>> generateSolutions({
    required String activity,
    required String problem,
    String goal = '',
  }) async {
    final act = activity.trim().toLowerCase();
    final prob = problem.trim().toLowerCase();
    if (act.isEmpty || prob.isEmpty) return [];

    // Cache key
    final key = 'act=$act|prob=$prob|goal=${goal.trim().toLowerCase()}';
    final cache = await LocalStore.loadProblemSolutionCache();
    if (cache[key] != null) {
      final list = (cache[key] as List)
          .map((e) => ProblemSolutionSuggestion.fromMap(
              Map<String, dynamic>.from(e as Map)))
          .toList();
      return list;
    }

    // Score patterns by keyword match count
    final scored = <_Pattern, int>{};
    for (final p in _patterns) {
      var score = 0;
      for (final kw in p.keywords) {
        if (prob.contains(kw) || kw.contains(prob)) score += 2;
        if (act.contains(kw) || kw.contains(act)) score += 1;
      }
      if (score > 0) scored[p] = score;
    }

    final chosen = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final rng = Random(act.hashCode ^ prob.hashCode);
    // Fallback: pick 2 random patterns if none matched
    final selected = chosen.isEmpty
        ? (_patterns..shuffle(rng)).take(2).toList()
        : chosen.take(3).map((e) => e.key).toList();

    final suggestions = selected.map((p) {
      // If goal provided, append tailored rationale sentence
      final rationale = goal.trim().isEmpty
          ? p.rationale
          : '${p.rationale} This directly supports goal: "${goal.trim()}".';
      return ProblemSolutionSuggestion(
        title: p.title,
        rationale: rationale,
        steps: p.steps,
      );
    }).toList();

    // Cache store
    cache[key] = suggestions.map((s) => s.toMap()).toList();
    // Trim cache size
    if (cache.length > 40) {
      cache.remove(cache.keys.first);
    }
    await LocalStore.saveProblemSolutionCache(cache);
    return suggestions;
  }
}

class _Pattern {
  final List<String> keywords;
  final String title;
  final String rationale;
  final List<String> steps;
  _Pattern({
    required this.keywords,
    required this.title,
    required this.rationale,
    required this.steps,
  });
}
