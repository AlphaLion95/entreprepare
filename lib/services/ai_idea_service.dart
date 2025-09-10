import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import 'local_store.dart';

class AiIdeaService {
  // Simple offline heuristic keywords to idea expansions
  static const Map<String, List<String>> _seedExpansions = {
    'food': [
      'Healthy meal prep delivery for remote workers',
      'Local farmer produce subscription boxes',
      'Cloud kitchen specializing in fusion snacks',
    ],
    'tech': [
      'Low-code internal dashboard builder for SMEs',
      'AI-driven inventory forecasting micro SaaS',
      'No-code templates for local service bookings',
    ],
    'fashion': [
      'Eco-friendly upcycled streetwear micro brand',
      'On-demand tailoring via mobile measurements',
      'Niche accessories subscription (e.g. socks / ties)',
    ],
    'education': [
      'Micro-learning app for vocational skills',
      'Local language tutoring marketplace',
      'Parent-child collaborative study planner',
    ],
    'fitness': [
      'Hybrid online/offline small group coaching',
      'Office employee stretch break program',
      'Gamified walking challenges with local sponsors',
    ],
  };

  Future<List<String>> getIdeas(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    // Try cache first
    final cached = await LocalStore.loadAiIdeaCache();
    if (cached[q] != null) return List<String>.from(cached[q] as List);

    List<String> ideas;
    if (kAiIdeasEndpoint.isNotEmpty) {
      ideas = await _fetchRemote(q);
    } else {
      ideas = _generateHeuristic(q);
    }

    // Store (limit cache size)
    cached[q] = ideas;
    if (cached.length > 30) {
      // remove oldest key (naive approach)
      final firstKey = cached.keys.first;
      cached.remove(firstKey);
    }
    await LocalStore.saveAiIdeaCache(cached);
    return ideas;
  }

  List<String> _generateHeuristic(String q) {
    // gather expansions containing any seed keyword
    final hits = <String>{};
    for (final entry in _seedExpansions.entries) {
      if (q.contains(entry.key) || entry.key.contains(q)) {
        hits.addAll(entry.value);
      }
    }
    if (hits.isEmpty) {
      hits.addAll([
        '${_titleCase(q)} marketplace platform',
        '${_titleCase(q)} subscription box',
        'On-demand ${q} services aggregator',
        'Local community ${q} events hub',
        'AI assisted ${q} planning tool',
      ]);
    }
    // Score / reorder deterministically by length then alphabet
    final list = hits.toList();
    list.sort((a, b) => a.length == b.length ? a.compareTo(b) : a.length.compareTo(b.length));
    return list.take(8).toList();
  }

  Future<List<String>> _fetchRemote(String q) async {
    try {
      final resp = await http
          .post(
            Uri.parse(kAiIdeasEndpoint),
            headers: {
              'Content-Type': 'application/json',
              if (kAiApiKey.isNotEmpty) 'Authorization': 'Bearer $kAiApiKey',
            },
            body: jsonEncode({'query': q, 'limit': 8}),
          )
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data is Map && data['ideas'] is List) {
          return (data['ideas'] as List).map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    return _generateHeuristic(q);
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(RegExp(r'\s+')).map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}
