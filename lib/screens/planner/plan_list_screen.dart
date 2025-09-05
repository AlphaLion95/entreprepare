import 'package:flutter/material.dart';
import '../../models/plan.dart';
import '../../services/plan_service.dart';
import '../../services/settings_service.dart';
import '../../services/license_service.dart';
import '../../utils/currency_utils.dart';
import 'plan_detail_screen.dart';
import 'plan_editor_screen.dart';

class PlanListScreen extends StatefulWidget {
  const PlanListScreen({super.key});
  @override
  State<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends State<PlanListScreen> {
  final PlanService _service = PlanService();
  final SettingsService _settingsSvc = SettingsService();
  final LicenseService _licenseSvc = LicenseService();
  List<Plan> _plans = [];
  bool _loading = true;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _load();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsSvc.fetchSettings();
    if (s != null && mounted) setState(() => _currency = s.currency);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final plans = await _service.fetchPlans();
      if (mounted) setState(() {
        _plans = plans;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _plans = [];
        _loading = false;
      });
    }
  }

  double _progressOf(Plan p) {
    if (p.milestones.isEmpty) return 0.0;
    final done = p.milestones.where((m) => m.done).length;
    return done / p.milestones.length;
  }

  Future<void> _showExpiredDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Access disabled'),
        content: const Text('Your access has expired. Please contact the developer to continue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _openEditor({Plan? plan}) async {
    final expired = await _licenseSvc.isExpired();
    if (expired) {
      await _showExpiredDialog();
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlanEditorScreen()),
    );
    if (result == true) await _load();
  }

  Future<void> _openDetail(Plan p) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: p)),
    );
    if (changed == true) await _load();
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plans'),
        elevation: 2,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _plans.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 64),
                      Center(
                        child: Icon(
                          Icons.workspace_premium,
                          size: 72,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'No plans yet',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create your first plan'),
                          onPressed: () async => await _openEditor(),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _plans.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (c, i) {
                      final p = _plans[i];
                      final progress = _progressOf(p);
                      final profit = p.monthlyProfit;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _openDetail(p),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                    child: Text(
                                      (p.title.isNotEmpty ? p.title[0].toUpperCase() : '?'),
                                      style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Chip(label: Text('${formatCurrency(profit, _currency)}/mo'), visualDensity: VisualDensity.compact),
                                            const SizedBox(width: 8),
                                            Text(_fmtDate(p.createdAt), style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(value: progress, minHeight: 6),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.chevron_right, color: Colors.black26),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('New Plan'),
        icon: const Icon(Icons.add),
        onPressed: () async => await _openEditor(),
      ),
    );
  }
}