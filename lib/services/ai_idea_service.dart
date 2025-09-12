import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import 'local_store.dart';

class AiIdeaService {
  Future<List<String>> getIdeas(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final cached = await LocalStore.loadAiIdeaCache();
    if (cached[q] != null) return List<String>.from(cached[q] as List);

    if (!(kAiRemoteEnabled && kAiIdeasEndpoint.isNotEmpty)) {
      throw Exception('Remote AI disabled. Configure endpoints and enable.');
    }
    final ideas = await _fetchRemote(q);
    cached[q] = ideas;
    if (cached.length > 50) cached.remove(cached.keys.first);
    await LocalStore.saveAiIdeaCache(cached);
    return ideas;
  }

  Future<List<String>> _fetchRemote(String q) async {
    final resp = await http
        .post(
          Uri.parse(kAiIdeasEndpoint),
          headers: {
            'Content-Type': 'application/json',
            if (kAiApiKey.isNotEmpty) 'Authorization': 'Bearer $kAiApiKey',
          },
          body: jsonEncode({'query': q, 'limit': 8}),
        )
        .timeout(const Duration(seconds: 25));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data['ideas'] is List) {
        final list = (data['ideas'] as List)
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .take(12)
            .toList();
        if (list.isNotEmpty) return list;
      }
      throw Exception('Malformed AI response');
    }
    throw Exception('AI request failed (${resp.statusCode})');
  }
}
