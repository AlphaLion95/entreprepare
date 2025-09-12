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
        steps: (m['steps'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
  Map<String, dynamic> toMap() => {'definition': definition, 'steps': steps};
}

class AiMilestoneService {
  Future<MilestoneSuggestion> generate(String title) async {
    if (title.trim().isEmpty) {
      return MilestoneSuggestion(definition: '', steps: const []);
    }
    if (!(kAiRemoteEnabled && kAiMilestoneEndpoint.isNotEmpty)) {
      throw Exception('Remote AI disabled. Configure endpoints and enable.');
    }
    final resp = await http
        .post(
          Uri.parse(kAiMilestoneEndpoint),
          headers: {
            'Content-Type': 'application/json',
            if (kAiApiKey.isNotEmpty) 'Authorization': 'Bearer $kAiApiKey',
          },
          body: jsonEncode({'title': title}),
        )
        .timeout(const Duration(seconds: 25));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data['definition'] != null && data['steps'] is List) {
        return MilestoneSuggestion.fromMap(Map<String, dynamic>.from(data));
      }
      throw Exception('Malformed AI response');
    }
    throw Exception('AI request failed (${resp.statusCode})');
  }
}
