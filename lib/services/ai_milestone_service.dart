import '../config/ai_config.dart';
import 'ai_api_client.dart';

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
  late final AiApiClient _client;

  AiMilestoneService() {
    _client = AiApiClient(
      baseUrl: kAiMilestoneEndpoint,
      debug: kAiDebugLogging,
    );
  }
  Future<MilestoneSuggestion> generate(String title) async {
    if (title.trim().isEmpty) {
      return MilestoneSuggestion(definition: '', steps: const []);
    }
    if (!(kAiRemoteEnabled && kAiMilestoneEndpoint.isNotEmpty)) {
      throw Exception('Remote AI disabled. Configure endpoints and enable.');
    }
    try {
      final data = await _client.postType('milestone', {'title': title});
      if (data['definition'] is String && data['steps'] is List) {
        return MilestoneSuggestion(
          definition: (data['definition'] as String).trim(),
          steps: (data['steps'] as List)
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        );
      }
      throw Exception('Malformed milestone response');
    } on AiApiException catch (e) {
      throw Exception(
        'AI milestone failed: ${e.code}${e.message != null ? ': ' + e.message! : ''}',
      );
    }
  }
}
