// Overwrite existing file with this content
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/plan.dart';
import '../../services/plan_service.dart';
import '../../services/settings_service.dart';
import '../../services/license_service.dart';
import '../../utils/currency_utils.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;
  const PlanDetailScreen({super.key, required this.plan});
  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late Plan _plan;
  final PlanService _service = PlanService();
  final SettingsService _settingsSvc = SettingsService();
  final LicenseService _licenseSvc = LicenseService();
  bool _saving = false;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsSvc.fetchSettings();
    if (s != null && mounted) setState(() => _currency = s.currency);
  }

  Future<void> _showExpiredDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Access disabled'),
        content: const Text(
          'Your access has expired. Please contact the developer to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMilestone(int idx, bool? v) async {
    setState(() => _plan.milestones[idx].done = v ?? false);
    await _save();
  }

  Future<void> _addMilestone() async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add milestone'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(hintText: 'Milestone title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true && ctl.text.trim().isNotEmpty) {
      setState(
        () => _plan.milestones.add(
          Milestone(id: const Uuid().v4(), title: ctl.text.trim()),
        ),
      );
      await _save();
    }
  }

  Future<void> _removeMilestone(int idx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove milestone'),
        content: const Text('Are you sure you want to remove this milestone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _plan.milestones.removeAt(idx));
      await _save();
    }
  }

  Future<void> _editMilestoneTitle(int idx) async {
    final ctl = TextEditingController(text: _plan.milestones[idx].title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit milestone'),
        content: TextField(controller: ctl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && ctl.text.trim().isNotEmpty) {
      setState(() => _plan.milestones[idx].title = ctl.text.trim());
      await _save();
    }
  }

  Future<void> _save() async {
    final expired = await _licenseSvc.isExpired();
    if (expired) {
      await _showExpiredDialog();
      return;
    }

    if (_plan.id.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _service.updatePlan(_plan);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _plan.milestones.isEmpty
        ? 0.0
        : (_plan.milestones.where((m) => m.done).length /
              _plan.milestones.length);
    return Scaffold(
      appBar: AppBar(
        title: Text(_plan.title),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _plan.id.isNotEmpty ? _save : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.12),
                        child: Text(
                          _plan.title.isNotEmpty
                              ? _plan.title[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _plan.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          'Revenue: ${formatCurrency(_plan.monthlyRevenue, _currency)}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'COGS: ${formatCurrency(_plan.monthlyCostOfGoods, _currency)}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Profit: ${formatCurrency(_plan.monthlyProfit, _currency)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: progress, minHeight: 8),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% complete',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Milestones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _addMilestone,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_plan.milestones.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No milestones. Add one to get started.'),
              ),
            ),
          ..._plan.milestones.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: CheckboxListTile(
                value: m.done,
                onChanged: (v) => _toggleMilestone(idx, v),
                title: Text(m.title),
                secondary: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editMilestoneTitle(idx),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeMilestone(idx),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark all done'),
            onPressed: _plan.milestones.isEmpty
                ? null
                : () async {
                    setState(
                      () => _plan.milestones.forEach((m) => m.done = true),
                    );
                    await _save();
                  },
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Suggested innovations',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Offer bundle pricing to increase average order value.',
                  ),
                  Text('- Test a subscription model for repeat customers.'),
                  Text(
                    '- Use targeted promos and collect customer feedback to iterate.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
