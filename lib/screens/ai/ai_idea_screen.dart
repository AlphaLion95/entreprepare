import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../config/ai_config.dart';
import '../../services/ai_idea_service.dart';
import '../../services/ai_solution_service.dart';
import '../../services/plan_service.dart';
import '../../models/plan.dart';

class AiIdeaScreen extends StatefulWidget {
  const AiIdeaScreen({super.key});

  @override
  State<AiIdeaScreen> createState() => _AiIdeaScreenState();
}

class _AiIdeaScreenState extends State<AiIdeaScreen>
    with SingleTickerProviderStateMixin {
  final _ideaService = AiIdeaService();
  final _solutionService = AiSolutionService();
  final _planService = PlanService();

  late final TabController _tab;

  // Ideas
  final _queryCtl = TextEditingController();
  bool _loadingIdeas = false;
  List<String> _ideas = [];
  String _ideaError = '';

  // Problem solver unified context
  final _contextCtl = TextEditingController();
  bool _loadingSolutions = false;
  List<ProblemSolutionSuggestion> _solutions = [];
  String _solutionError = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _queryCtl.dispose();
    _contextCtl.dispose();
    super.dispose();
  }

  Future<void> _runIdeas() async {
    final q = _queryCtl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loadingIdeas = true;
      _ideaError = '';
    });
    try {
      final results = await _ideaService.getIdeas(q);
      if (mounted) setState(() => _ideas = results);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      String friendly = 'Failed: $msg';
      if (msg.contains('Remote AI disabled')) {
        friendly =
            'AI disabled. Set your deployed function URLs in ai_config.dart (kAiIdeasEndpoint, enable kAiRemoteEnabled) then rebuild.';
      }
      setState(() => _ideaError = friendly);
    } finally {
      if (mounted) setState(() => _loadingIdeas = false);
    }
  }

  Future<void> _runSolutions() async {
    final ctx = _contextCtl.text.trim();
    if (ctx.isEmpty) return;
    setState(() {
      _loadingSolutions = true;
      _solutionError = '';
    });
    try {
      final res = await _solutionService.generateFromContext(ctx);
      if (mounted) setState(() => _solutions = res);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      String friendly = 'Failed: $msg';
      if (msg.contains('Remote AI disabled')) {
        friendly =
            'AI disabled. Configure endpoints (kAiSolutionsEndpoint, kAiRemoteEnabled) and redeploy.';
      }
      setState(() => _solutionError = friendly);
    } finally {
      if (mounted) setState(() => _loadingSolutions = false);
    }
  }

  Future<void> _addSuggestionToPlan(ProblemSolutionSuggestion s) async {
    final plan = Plan(
      id: '',
      businessId: '',
      title: s.title,
      capitalEstimated: 0,
      pricePerUnit: 0,
      estMonthlySales: 0,
      inventory: const [],
      milestones: s.steps
          .map((st) => Milestone(id: const Uuid().v4(), title: st))
          .toList(),
      expenses: const [],
      createdAt: DateTime.now(),
    );
    try {
      final id = await _planService.createPlan(plan);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Plan created: $id')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create plan: $e')));
    }
  }

  Widget _buildIdeasTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _queryCtl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runIdeas(),
            decoration: InputDecoration(
              labelText: 'Search or describe a business idea',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _runIdeas,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingIdeas) const LinearProgressIndicator(minHeight: 3),
          if (_ideaError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _ideaError,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _ideas.isEmpty && !_loadingIdeas
                ? const Center(
                    child: Text(
                      'Enter a keyword like "food", "tech", or describe a theme to get ideas.',
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
                            ScaffoldMessenger.of(c).showSnackBar(
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
    );
  }

  Widget _buildProblemSolverTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Context',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 140,
                    child: TextField(
                      controller: _contextCtl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText:
                            'Describe your business, current challenges, goals, metrics, users...\nYou can paste multiple paragraphs.',
                        border: OutlineInputBorder(),
                        isDense: true,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loadingSolutions ? null : _runSolutions,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate Strategies'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _contextCtl.clear();
                          setState(() {
                            _solutions.clear();
                            _solutionError = '';
                          });
                        },
                        icon: const Icon(Icons.clear_all),
                      ),
                    ],
                  ),
                  if (_loadingSolutions)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  if (_solutionError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _solutionError,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (!_loadingSolutions &&
                      _solutions.isEmpty &&
                      _solutionError.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Enter rich context then tap Generate. Examples: traction issues, churn, acquisition goal, launch plan.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _solutions.isEmpty
                ? const Center(child: Text('No strategies yet'))
                : ListView.builder(
                    itemCount: _solutions.length,
                    itemBuilder: (c, i) {
                      final s = _solutions[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: const Icon(Icons.lightbulb_outline),
                          title: Text(s.title),
                          subtitle: Text(s.rationale),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  ...s.steps.asMap().entries.map(
                                    (e) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        radius: 11,
                                        child: Text(
                                          '${e.key + 1}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                      title: Text(e.value),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _addSuggestionToPlan(s),
                                      icon: const Icon(Icons.add_task),
                                      label: const Text('Add to Plan'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assist'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Ideas'),
            Tab(text: 'Problem Solver'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildIdeasTab(), _buildProblemSolverTab()],
      ),
    );
  }
}
