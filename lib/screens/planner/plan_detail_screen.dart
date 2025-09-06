// ...existing code...
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/plan.dart';
import '../../services/plan_service.dart';
import '../../services/settings_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/plan_templates.dart';

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
  bool _saving = false;
  String _currency = 'PHP';
  late final Stream<Settings?> _settingsStream;
  final _capitalCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _salesCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _capitalCtl.text = _plan.capitalEstimated.toStringAsFixed(0);
    _priceCtl.text = _plan.pricePerUnit.toStringAsFixed(0);
    _salesCtl.text = _plan.estMonthlySales.toString();
    _loadSettings();
    _settingsStream = _settingsSvc.watchSettings();
    _settingsStream.listen((s) {
      if (!mounted) return;
      setState(() => _currency = (s?.currency ?? _currency));
    });
  }

  @override
  void dispose() {
    _capitalCtl.dispose();
    _priceCtl.dispose();
    _salesCtl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final s = await _settingsSvc.fetchSettings();
    if (s != null && mounted) setState(() => _currency = s.currency);
  }

  Future<void> _toggleMilestone(int idx, bool? v) async {
    setState(() => _plan.milestones[idx].done = v ?? false);
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
    if (confirm == true) setState(() => _plan.milestones.removeAt(idx));
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
    }
  }

  Future<void> _save() async {
    if (_plan.id.isEmpty) return;
    // Sync numeric fields from controllers before saving
    final capital = double.tryParse(_capitalCtl.text) ?? 0.0;
    final price = double.tryParse(_priceCtl.text) ?? 0.0;
    final sales = int.tryParse(_salesCtl.text) ?? 0;
    _plan = Plan(
      id: _plan.id,
      businessId: _plan.businessId,
      title: _plan.title,
      capitalEstimated: capital,
      pricePerUnit: price,
      estMonthlySales: sales,
      inventory: _plan.inventory,
      milestones: _plan.milestones,
      expenses: _plan.expenses,
      createdAt: _plan.createdAt,
    );
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

  // Inventory and expense editing (moved from extension)
  Future<void> _addInventoryItem() async {
    final nameCtl = TextEditingController();
    final qtyCtl = TextEditingController(text: '1');
    final costCtl = TextEditingController(text: '0.0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add inventory item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(hintText: 'Item name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtl,
              decoration: const InputDecoration(hintText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: costCtl,
              decoration: const InputDecoration(hintText: 'Unit cost'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
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
    if (ok == true && nameCtl.text.trim().isNotEmpty) {
      final qty = int.tryParse(qtyCtl.text.trim()) ?? 1;
      final unitCost = double.tryParse(costCtl.text.trim()) ?? 0.0;
      setState(
        () => _plan.inventory.add(
          PlanItem(
            id: const Uuid().v4(),
            name: nameCtl.text.trim(),
            qty: qty,
            unitCost: unitCost,
          ),
        ),
      );
    }
  }

  Future<void> _editInventoryItem(int idx) async {
    final item = _plan.inventory[idx];
    final nameCtl = TextEditingController(text: item.name);
    final qtyCtl = TextEditingController(text: item.qty.toString());
    final costCtl = TextEditingController(text: item.unitCost.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit inventory item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(hintText: 'Item name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qtyCtl,
              decoration: const InputDecoration(hintText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: costCtl,
              decoration: const InputDecoration(hintText: 'Unit cost'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
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
    if (ok == true && nameCtl.text.trim().isNotEmpty) {
      final qty = int.tryParse(qtyCtl.text.trim()) ?? 1;
      final unitCost = double.tryParse(costCtl.text.trim()) ?? 0.0;
      setState(
        () => _plan.inventory[idx] = PlanItem(
          id: item.id,
          name: nameCtl.text.trim(),
          qty: qty,
          unitCost: unitCost,
        ),
      );
    }
  }

  Future<void> _addExpenseItem() async {
    final nameCtl = TextEditingController();
    final costCtl = TextEditingController(text: '0.0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add operating expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(
                hintText: 'Expense name (e.g., Salary, Rent)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: costCtl,
              decoration: const InputDecoration(hintText: 'Monthly cost'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
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
    if (ok == true && nameCtl.text.trim().isNotEmpty) {
      final cost = double.tryParse(costCtl.text.trim()) ?? 0.0;
      setState(
        () => _plan.expenses.add(
          ExpenseItem(
            id: const Uuid().v4(),
            name: nameCtl.text.trim(),
            monthlyCost: cost,
          ),
        ),
      );
    }
  }

  Future<void> _editExpenseItem(int idx) async {
    final ex = _plan.expenses[idx];
    final nameCtl = TextEditingController(text: ex.name);
    final costCtl = TextEditingController(text: ex.monthlyCost.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit operating expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(hintText: 'Expense name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: costCtl,
              decoration: const InputDecoration(hintText: 'Monthly cost'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
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
    if (ok == true && nameCtl.text.trim().isNotEmpty) {
      final cost = double.tryParse(costCtl.text.trim()) ?? 0.0;
      setState(
        () => _plan.expenses[idx] = ExpenseItem(
          id: ex.id,
          name: nameCtl.text.trim(),
          monthlyCost: cost,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _plan.milestones.isEmpty
        ? 0.0
        : (_plan.milestones.where((m) => m.done).length /
              _plan.milestones.length);
    final isEmptyPlan =
        _plan.capitalEstimated == 0 &&
        _plan.pricePerUnit == 0 &&
        _plan.estMonthlySales == 0 &&
        _plan.inventory.isEmpty &&
        _plan.milestones.isEmpty;
    String fmt(double v) => formatCurrency(v, _currency);
    double monthlyRevenue =
        (double.tryParse(_priceCtl.text) ?? _plan.pricePerUnit) *
        (double.tryParse(_salesCtl.text) ?? _plan.estMonthlySales.toDouble());
    double avgUnitCost = _plan.inventory.isEmpty
        ? 0.0
        : _plan.inventory.map((i) => i.unitCost).fold(0.0, (a, b) => a + b) /
              _plan.inventory.length;
    double monthlyCOGS =
        avgUnitCost *
        (double.tryParse(_salesCtl.text) ?? _plan.estMonthlySales.toDouble());
    double monthlyOpEx = _plan.expenses.fold(0.0, (s, e) => s + e.monthlyCost);
    double monthlyNet = monthlyRevenue - monthlyCOGS - monthlyOpEx;
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
          if (isEmptyPlan)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This plan is empty',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('Populate suggestions'),
                      onPressed: () async {
                        final tmpl = getTemplateForTitle(_plan.title);
                        if (tmpl != null) {
                          setState(() {
                            _plan = Plan(
                              id: _plan.id,
                              businessId: _plan.businessId,
                              title: _plan.title,
                              capitalEstimated: tmpl.capital,
                              pricePerUnit: tmpl.pricePerUnit,
                              estMonthlySales: tmpl.estMonthlySales,
                              inventory: tmpl.inventory
                                  .map(
                                    (m) => PlanItem(
                                      id: const Uuid().v4(),
                                      name: (m['name'] as String?) ?? 'Item',
                                      qty: (m['qty'] as int?) ?? 1,
                                      unitCost:
                                          (m['unitCost'] as num?)?.toDouble() ??
                                          0.0,
                                    ),
                                  )
                                  .toList(),
                              milestones: tmpl.milestones
                                  .map(
                                    (s) => Milestone(
                                      id: const Uuid().v4(),
                                      title: s,
                                    ),
                                  )
                                  .toList(),
                              createdAt: _plan.createdAt,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
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
                      Chip(label: Text('Revenue: ${fmt(monthlyRevenue)}')),
                      Chip(label: Text('COGS: ${fmt(monthlyCOGS)}')),
                      Chip(label: Text('OpEx: ${fmt(monthlyOpEx)}')),
                      Chip(label: Text('Net: ${fmt(monthlyNet)}')),
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
          const SizedBox(height: 12),
          // Editable core fields
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _capitalCtl,
                    decoration: const InputDecoration(
                      labelText: 'Estimated capital',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceCtl,
                          decoration: const InputDecoration(
                            labelText: 'Price per unit',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _salesCtl,
                          decoration: const InputDecoration(
                            labelText: 'Est. monthly sales',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hints:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Revenue = price × sales',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const Text(
                    '• COGS ≈ average unit cost × sales',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const Text(
                    '• Net = revenue − COGS − operating expenses',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Inventory editable list
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Inventory',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addInventoryItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_plan.inventory.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No inventory'),
                    ),
                  ..._plan.inventory.asMap().entries.map((e) {
                    final idx = e.key;
                    final it = e.value;
                    return ListTile(
                      title: Text(it.name),
                      subtitle: Text(
                        'Qty: ${it.qty} • Unit: ${fmt(it.unitCost)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editInventoryItem(idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() {
                              _plan.inventory.removeAt(idx);
                            }),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Operating expenses editable list
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Operating expenses',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _addExpenseItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_plan.expenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No operating expenses'),
                    ),
                  ..._plan.expenses.asMap().entries.map((e) {
                    final idx = e.key;
                    final ex = e.value;
                    return ListTile(
                      title: Text(ex.name),
                      subtitle: Text('Monthly: ${fmt(ex.monthlyCost)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editExpenseItem(idx),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => setState(() {
                              _plan.expenses.removeAt(idx);
                            }),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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
