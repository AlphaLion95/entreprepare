import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/local_store.dart';
import '../config/ai_config.dart';

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
        steps: (m['steps'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class AiSolutionService {
  Future<List<ProblemSolutionSuggestion>> generateSolutions({
    required String activity,
    required String problem,
    String goal = '',
  }) async {
    final act = activity.trim();
    final prob = problem.trim();
    final g = goal.trim();
    if (act.isEmpty || prob.isEmpty) return [];

    final key =
        'act=${act.toLowerCase()}|prob=${prob.toLowerCase()}|goal=${g.toLowerCase()}';
    final cache = await LocalStore.loadProblemSolutionCache();
    if (cache[key] != null) {
      return (cache[key] as List)
          .map(
            (e) => ProblemSolutionSuggestion.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }

    if (!(kAiRemoteEnabled && kAiSolutionsEndpoint.isNotEmpty)) {
      throw Exception('Remote AI disabled. Configure endpoints and enable.');
    }

    final list = await _remote(act, prob, g);
    if (list.isNotEmpty) {
      cache[key] = list.map((s) => s.toMap()).toList();
      if (cache.length > 80) cache.remove(cache.keys.first);
      await LocalStore.saveProblemSolutionCache(cache);
    }
    return list;
  }

  Future<List<ProblemSolutionSuggestion>> _remote(
    String act,
    String prob,
    String goal,
  ) async {
    final resp = await http
        .post(
          Uri.parse(kAiSolutionsEndpoint),
          headers: {
            'Content-Type': 'application/json',
            if (kAiApiKey.isNotEmpty) 'Authorization': 'Bearer $kAiApiKey',
          },
          body: jsonEncode({
            'activity': act,
            'problem': prob,
            'goal': goal,
            'limit': 3,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data['solutions'] is List) {
        final list = (data['solutions'] as List)
            .map(
              (e) => ProblemSolutionSuggestion.fromMap(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .where((s) => s.title.isNotEmpty && s.steps.isNotEmpty)
            .toList();
        return list;
      }
      throw Exception('Malformed AI response');
    }
    throw Exception('AI request failed (${resp.statusCode})');
  }

  Future<List<ProblemSolutionSuggestion>> generateFromContext(
    String context,
  ) async {
    final text = context.toLowerCase();
    String activity = '';
    String problem = '';
    String goal = '';
    final activityMatch = RegExp(
      r'(activity|business|we\s+do)[:\-]\s*(.+)',
    ).firstMatch(text);
    if (activityMatch != null) {
      activity = activityMatch.group(2)!.split(RegExp(r'\. |\n')).first.trim();
    }
    final problemMatch = RegExp(
      r'(problem|challenge|issue|struggle)[:\-]\s*(.+)',
    ).firstMatch(text);
    if (problemMatch != null) {
      problem = problemMatch.group(2)!.split(RegExp(r'\n')).first.trim();
    }
    final goalMatch = RegExp(
      r'(goal|objective|aim|target)[:\-]\s*(.+)',
    ).firstMatch(text);
    if (goalMatch != null) {
      goal = goalMatch.group(2)!.split(RegExp(r'\n')).first.trim();
    }
    if (activity.isEmpty) {
      activity = text.split(RegExp(r'[\n\.!]')).first.trim();
    }
    if (problem.isEmpty) {
      final m = RegExp(
        r'(low|lack|decline|drop|churn|waste|traffic|sales|revenue|conversion)\s+[^\.\n]{3,}',
      ).firstMatch(text);
      if (m != null) problem = m.group(0)!.trim();
    }
    if (goal.isEmpty) {
      final m = RegExp(
        r'(increase|grow|reduce|improve)\s+[^\.\n]{3,}',
      ).firstMatch(text);
      if (m != null) goal = m.group(0)!.trim();
    }
    return generateSolutions(activity: activity, problem: problem, goal: goal);
  }
}
