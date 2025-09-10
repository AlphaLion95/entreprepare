import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

class MilestoneSuggestion {
  final String definition;
  final List<String> steps;
  MilestoneSuggestion({required this.definition, required this.steps});

  factory MilestoneSuggestion.fromMap(Map<String, dynamic> m) =>
      MilestoneSuggestion(
        definition: (m['definition'] ?? '').toString(),
        steps: (m['steps'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
  Map<String, dynamic> toMap() => {
        'definition': definition,
        'steps': steps,
      };
}

class AiMilestoneService {
  // Simple keyword pattern mapping for milestone assistance.
  static final List<_MilestonePattern> _patterns = [
    _MilestonePattern(
      keywords: ['launch', 'go live', 'release'],
      definition: 'Prepare and execute initial public release with readiness checks.',
      steps: [
        'Freeze feature scope and finalize MVP checklist.',
        'Prepare marketing blurb & visuals.',
        'Dry run deployment in staging / local environment.',
        'Set launch date & announce teaser to audience.',
        'Release and monitor first 48h metrics (errors, signups, feedback).',
      ],
    ),
    _MilestonePattern(
      keywords: ['marketing', 'campaign', 'promo'],
      definition: 'Design and run a focused marketing campaign to drive awareness or conversions.',
      steps: [
        'Define single measurable goal (e.g., 100 signups).',
        'Pick 1-2 channels (e.g., FB groups + email list).',
        'Draft campaign message & creative assets.',
        'Schedule posts / sends with clear CTA.',
        'Collect results and compute cost per acquisition.',
      ],
    ),
    _MilestonePattern(
      keywords: ['partnership', 'partner'],
      definition: 'Establish a mutually beneficial collaboration with another organization.',
      steps: [
        'List 5 potential complementary partners.',
        'Draft value proposition & mutual benefit outline.',
        'Send concise outreach (personalized).',
        'Negotiate simple pilot (timeline + KPI).',
        'Review pilot outcomes; formalize ongoing terms.',
      ],
    ),
    _MilestonePattern(
      keywords: ['prototype', 'mvp', 'proof'],
      definition: 'Create a minimal functional version to validate core assumptions quickly.',
      steps: [
        'Identify core user problem & top 1-2 must-have features.',
        'Sketch simple user flow / wireframes.',
        'Implement smallest version enabling end-to-end usage.',
        'Test with 3-5 target users; capture feedback.',
        'Iterate on critical usability issues only.',
      ],
    ),
    _MilestonePattern(
      keywords: ['onboard', 'onboarding'],
      definition: 'Improve first-time user experience to accelerate activation.',
      steps: [
        'Map current first-time flow (screens / steps).',
        'Identify friction points (drops / confusion).',
        'Draft concise welcome & guidance copy.',
        'Add progress cue or checklist for first key action.',
        'Measure activation rate before vs after changes.',
      ],
    ),
    _MilestonePattern(
      keywords: ['retention', 'repeat', 'loyalty'],
      definition: 'Increase repeat usage/purchase frequency and customer lifetime value.',
      steps: [
        'Segment active vs dormant users (e.g., 30+ days inactive).',
        'Define a simple re-engagement offer or content.',
        'Automate reminder / follow-up sequence.',
        'Track reactivation rate weekly.',
        'Refine incentive or timing based on performance.',
      ],
    ),
  ];

  Future<MilestoneSuggestion> generate(String title) async {
    final t = title.toLowerCase();
    if (kAiRemoteEnabled && kAiMilestoneEndpoint.isNotEmpty) {
      try {
        final resp = await http
            .post(
              Uri.parse(kAiMilestoneEndpoint),
              headers: {
                'Content-Type': 'application/json',
                if (kAiApiKey.isNotEmpty) 'Authorization': 'Bearer $kAiApiKey',
              },
              body: jsonEncode({'title': title}),
            )
            .timeout(const Duration(seconds: 15));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          if (data is Map && data['definition'] != null) {
            return MilestoneSuggestion.fromMap(Map<String, dynamic>.from(data));
          }
        }
      } catch (_) {}
    }
    // fallback heuristic
    final matched = _patterns.firstWhere(
      (p) => p.keywords.any((k) => t.contains(k) || k.contains(t)),
      orElse: () => _patterns.first,
    );
    return MilestoneSuggestion(
      definition: matched.definition,
      steps: matched.steps,
    );
  }
}

class _MilestonePattern {
  final List<String> keywords;
  final String definition;
  final List<String> steps;
  _MilestonePattern({
    required this.keywords,
    required this.definition,
    required this.steps,
  });
}
