import 'package:flutter/material.dart';
import '../../config/ai_config.dart';
import '../../services/ai_idea_service.dart';

class AiIdeaScreen extends StatefulWidget {
  const AiIdeaScreen({super.key});

  @override
  State<AiIdeaScreen> createState() => _AiIdeaScreenState();
}

class _AiIdeaScreenState extends State<AiIdeaScreen> {
  final _service = AiIdeaService();
  final _queryCtl = TextEditingController();
  bool _loading = false;
  List<String> _ideas = [];
  String _error = '';

  Future<void> _run() async {
    final q = _queryCtl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final results = await _service.getIdeas(q);
      if (mounted) setState(() => _ideas = results);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _queryCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Ideas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _queryCtl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _run(),
              decoration: InputDecoration(
                labelText: 'Search or describe a business idea',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _run,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(minHeight: 3),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _ideas.isEmpty && !_loading
                  ? const Center(
                      child: Text(
                        'Enter a keyword like "food", "tech", or describe a problem to get idea suggestions.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _ideas.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final idea = _ideas[i];
                        return ListTile(
                          leading: const Icon(Icons.lightbulb_outline),
                          title: Text(idea),
                          subtitle: Text('Suggestion #${i + 1}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied idea')),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
            if (kAiIdeasEndpoint.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Generated locally. Configure backend endpoint for richer AI output.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
