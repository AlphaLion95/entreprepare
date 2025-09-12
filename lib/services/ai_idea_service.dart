import '../config/ai_config.dart';
import 'local_store.dart';
import 'ai_api_client.dart';

class AiIdeaService {
  late final AiApiClient _client;

  AiIdeaService() {
    _client = AiApiClient(
      baseUrl: kAiIdeasEndpoint,
      debug: kAiDebugLogging,
    );
  }
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
    try {
      final data = await _client.postType('ideas', {'query': q, 'limit': 8});
      final ideas = (data['ideas'] as List?) ?? [];
      return ideas.map((e) => e.toString().trim()).where((s)=>s.isNotEmpty).toList();
    } on AiApiException catch (e) {
      throw Exception('AI ideas failed: ${e.code}${e.message!=null?': '+e.message!:''}');
    }
  }
}
