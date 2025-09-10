import 'package:flutter/material.dart';
import '../../config/ai_config.dart';
import '../../services/ai_idea_service.dart';
import '../../services/ai_solution_service.dart';
import '../../services/plan_service.dart';
import '../../models/plan.dart';
import 'package:uuid/uuid.dart';

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

  // Idea tab
  final _queryCtl = TextEditingController();
  bool _loadingIdeas = false;
  List<String> _ideas = [];
  String _ideaError = '';

  // Problem solver tab
  final _activityCtl = TextEditingController();
  final _problemCtl = TextEditingController();
  final _goalCtl = TextEditingController();
  bool _loadingSolutions = false;
  List<ProblemSolutionSuggestion> _solutions = [];
  String _solutionError = '';

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
      if (mounted) setState(() => _ideaError = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loadingIdeas = false);
    }
  }

  Future<void> _runSolutions() async {
    final act = _activityCtl.text.trim();
    final prob = _problemCtl.text.trim();
    final goal = _goalCtl.text.trim();
    if (act.isEmpty || prob.isEmpty) return;
    setState(() {
      _loadingSolutions = true;
      _solutionError = '';
    });
    try {
      final res = await _solutionService.generateSolutions(
        activity: act,
        problem: prob,
        goal: goal,
      );
      if (mounted) setState(() => _solutions = res);
    } catch (e) {
      if (mounted) setState(() => _solutionError = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loadingSolutions = false);
    }
  }

  Future<void> _addSuggestionToPlan(ProblemSolutionSuggestion s) async {
    // Build a simple plan with milestones from steps
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Plan created: $id')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create plan: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  void dispose() {
    _queryCtl.dispose();
    _activityCtl.dispose();
    _problemCtl.dispose();
    _goalCtl.dispose();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        bottom: TabBar(
          controller: _tab,
            tabs: const [
              Tab(icon: Icon(Icons.lightbulb_outline), text: 'Ideas'),
              Tab(icon: Icon(Icons.build_circle_outlined), text: 'Problem Solver'),
            ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildIdeasTab(),
          _buildProblemSolverTab(),
        ],
      ),
    );
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
              child: Text(_ideaError, style: const TextStyle(color: Colors.red)),
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
        children: [
          TextField(
            controller: _activityCtl,
            decoration: const InputDecoration(
              labelText: 'Business activity (e.g. cafe, tutoring, retail)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _problemCtl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Problem causing decline (e.g. low foot traffic, inventory waste)',
            ),
          ),
          const SizedBox(height: 12),
            TextField(
            controller: _goalCtl,
            decoration: const InputDecoration(
              labelText: 'Goal (optional, e.g. increase repeat customers 20%)',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loadingSolutions ? null : _runSolutions,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Generate'),
              ),
              const SizedBox(width: 12),
              if (_loadingSolutions)
                const Expanded(
                  child: LinearProgressIndicator(minHeight: 4),
                ),
            ],
          ),
          if (_solutionError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_solutionError,
                  style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: _solutions.isEmpty && !_loadingSolutions
                ? const Center(
                    child: Text(
                      'Enter your business activity and a specific problem to get innovation suggestions.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _solutions.length,
                    itemBuilder: (c, i) {
                      final s = _solutions[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: const Icon(Icons.lightbulb),
                          title: Text(s.title),
                          subtitle: Text(s.rationale),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Steps:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  ...s.steps.asMap().entries.map((e) => ListTile(
                                        dense: true,
                                        leading: CircleAvatar(
                                          radius: 10,
                                          child: Text('${e.key + 1}',
                                              style: const TextStyle(
                                                  fontSize: 11)),
                                        ),
                                        title: Text(e.value),
                                      )),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _addSuggestionToPlan(s),
                                      icon: const Icon(Icons.add_task),
                                      label: const Text('Add to Plans'),
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
}
