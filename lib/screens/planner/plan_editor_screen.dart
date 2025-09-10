import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/plan.dart';
import '../../models/business.dart';
import '../../services/plan_service.dart';
import '../../services/settings_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/plan_templates.dart';
import '../main_tabs_page.dart';
import 'plan_detail_screen.dart';
import '../../services/ai_milestone_service.dart';

class PlanEditorScreen extends StatefulWidget {
  final Business? business;
  const PlanEditorScreen({super.key, this.business});

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _capitalCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _salesCtl = TextEditingController();

  final PlanService _service = PlanService();
  final SettingsService _settingsSvc = SettingsService();

  List<PlanItem> _inventory = [];
  List<Milestone> _milestones = [];
  final AiMilestoneService _aiMilestoneService = AiMilestoneService();
  List<ExpenseItem> _expenses = [];
  String _currency = 'PHP';
  late final Stream<Settings?> _settingsStream;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applyPrefill();
    _loadSettings();
    _settingsStream = _settingsSvc.watchSettings();
    _settingsStream.listen((s) {
      if (!mounted) return;
      setState(() => _currency = (s?.currency ?? _currency));
    });
  }

  void _applyPrefill() {
    if (widget.business != null) {
      // Reset local working data so editor is a non-persistent template
      _inventory = [];
      _milestones = [];
      _expenses = [];
      _titleCtl.text = widget.business!.title;
      final tmpl = getTemplateForTitle(widget.business!.title);
      if (tmpl != null) {
        _capitalCtl.text = tmpl.capital.toStringAsFixed(0);
        _priceCtl.text = tmpl.pricePerUnit.toStringAsFixed(0);
        _salesCtl.text = tmpl.estMonthlySales.toString();
        if (_inventory.isEmpty) {
          _inventory = tmpl.inventory
              .map(
                (m) => PlanItem(
                  id: const Uuid().v4(),
                  name: (m['name'] as String?) ?? 'Item',
                  qty: (m['qty'] as int?) ?? 1,
                  unitCost: (m['unitCost'] as num?)?.toDouble() ?? 0.0,
                ),
              )
              .toList();
        }
        if (_milestones.isEmpty) {
          _milestones = tmpl.milestones
              .map((s) => Milestone(id: const Uuid().v4(), title: s))
              .toList();
        }
      }
    }
  }

  Future<void> _loadSettings() async {
    final s = await _settingsSvc.fetchSettings();
    if (s != null && mounted) setState(() => _currency = s.currency);
  }

  Future<void> _savePlan({bool editAfter = false}) async {
    if (!_formKey.currentState!.validate()) return;

    // Build plan from form
    final userPlan = Plan(
      id: '',
      businessId: widget.business?.docId ?? '',
      title: _titleCtl.text.trim(),
      capitalEstimated: double.tryParse(_capitalCtl.text) ?? 0.0,
      pricePerUnit: double.tryParse(_priceCtl.text) ?? 0.0,
      estMonthlySales: int.tryParse(_salesCtl.text) ?? 0,
      inventory: _inventory,
      milestones: _milestones,
      expenses: _expenses,
      createdAt: DateTime.now(),
    );

    try {
      setState(() => _saving = true);
      // Check for an existing plan with same title
      final existingId = await _service.findPlanIdByTitle(userPlan.title);
      Plan? savedPlan;
      if (existingId != null) {
        // Ask user to overwrite
        final overwrite = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Plan title exists'),
            content: Text(
              'A plan named "${userPlan.title}" already exists. Overwrite it?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Overwrite'),
              ),
            ],
          ),
        );

        if (overwrite == true) {
          // preserve doc id when updating existing
          final toUpdate = Plan(
            id: existingId,
            businessId: userPlan.businessId,
            title: userPlan.title,
            capitalEstimated: userPlan.capitalEstimated,
            pricePerUnit: userPlan.pricePerUnit,
            estMonthlySales: userPlan.estMonthlySales,
            inventory: userPlan.inventory,
            milestones: userPlan.milestones,
            expenses: userPlan.expenses,
            createdAt: userPlan.createdAt,
          );
          await _service.updatePlan(toUpdate);
          savedPlan = toUpdate;
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Plan overwritten')));
            if (editAfter) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanDetailScreen(plan: savedPlan!),
                ),
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const MainTabsPage(initialIndex: 1),
                ),
                (route) => false,
              );
            }
          }
        } else {
          // user canceled overwrite
          if (mounted) setState(() => _saving = false);
          return;
        }
      } else {
        final newId = await _service.createPlan(userPlan);
        savedPlan = Plan(
          id: newId,
          businessId: userPlan.businessId,
          title: userPlan.title,
          capitalEstimated: userPlan.capitalEstimated,
          pricePerUnit: userPlan.pricePerUnit,
          estMonthlySales: userPlan.estMonthlySales,
          inventory: userPlan.inventory,
          milestones: userPlan.milestones,
          expenses: userPlan.expenses,
          createdAt: userPlan.createdAt,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Plan saved')));
          if (editAfter) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PlanDetailScreen(plan: savedPlan!),
              ),
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const MainTabsPage(initialIndex: 1),
              ),
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        () => _milestones.add(
          Milestone(id: const Uuid().v4(), title: ctl.text.trim()),
        ),
      );
    }
  }

  Future<void> _editMilestoneTitle(int idx) async {
    final ctl = TextEditingController(text: _milestones[idx].title);
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
      setState(() => _milestones[idx].title = ctl.text.trim());
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
    if (confirm == true) setState(() => _milestones.removeAt(idx));
  }

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
        () => _inventory.add(
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
    final item = _inventory[idx];
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
        () => _inventory[idx] = PlanItem(
          id: item.id,
          name: nameCtl.text.trim(),
          qty: qty,
          unitCost: unitCost,
        ),
      );
    }
  }

  String _fmtCurrency(double v) => formatCurrency(v, _currency);

  double get _monthlyRevenue {
    final price = double.tryParse(_priceCtl.text) ?? 0.0;
    final sales = double.tryParse(_salesCtl.text) ?? 0.0;
    return price * sales;
  }

  double get _monthlyCOGS {
    if (_inventory.isEmpty) return 0.0;
    final avgUnitCost =
        _inventory.map((i) => i.unitCost).fold<double>(0, (s, e) => s + e) /
        _inventory.length;
    final sales = double.tryParse(_salesCtl.text) ?? 0.0;
    return avgUnitCost * sales;
  }

  double get _monthlyOperatingExpenses =>
      _expenses.fold<double>(0.0, (s, e) => s + e.monthlyCost);
  double get _monthlyNetProfit =>
      _monthlyRevenue - _monthlyCOGS - _monthlyOperatingExpenses;

  @override
  void dispose() {
    _titleCtl.dispose();
    _capitalCtl.dispose();
    _priceCtl.dispose();
    _salesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan editor'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _savePlan(),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Plan title'),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter title' : null,
            ),
            const SizedBox(height: 6),
            const Text(
              'Note: Saving with an existing plan name will overwrite that plan.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capitalCtl,
              decoration: const InputDecoration(labelText: 'Estimated capital'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtl,
                    decoration: const InputDecoration(
                      labelText: 'Price per unit',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _salesCtl,
                    decoration: const InputDecoration(
                      labelText: 'Est. monthly sales',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.area_chart, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Projections',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text('Revenue: ${"${""}${""}"}'),
                        ), // placeholder to keep layout if any
                        Chip(
                          label: Text('COGS: ${_fmtCurrency(_monthlyCOGS)}'),
                        ),
                        Chip(
                          label: Text(
                            'OpEx: ${_fmtCurrency(_monthlyOperatingExpenses)}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'Net: ${_fmtCurrency(_monthlyNetProfit)}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '• Revenue = price × sales',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const Text(
                      '• COGS ≈ average unit cost × sales',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const Text(
                      '• Net = revenue − COGS − operating expenses',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.flag_outlined, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Milestones',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _addMilestone,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_milestones.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No milestones'),
                      ),
                    ..._milestones.asMap().entries.map((e) {
                      final idx = e.key;
                      final m = e.value;
                      return ListTile(
                        title: Text(m.title),
                        leading: Checkbox(
                          value: m.done,
                          onChanged: (v) => setState(() => m.done = v ?? false),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'AI help',
                              icon: const Icon(Icons.lightbulb_outline),
                              onPressed: () {
                                final suggestion = _aiMilestoneService.generate(m.title);
                                showModalBottomSheet(
                                  context: context,
                                  showDragHandle: true,
                                  isScrollControlled: true,
                                  builder: (_) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                                      left: 16,
                                      right: 16,
                                      top: 8,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(suggestion.definition),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Suggested steps:',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        ...suggestion.steps.asMap().entries.map(
                                          (st) => ListTile(
                                            dense: true,
                                            contentPadding: EdgeInsets.zero,
                                            leading: CircleAvatar(
                                              radius: 10,
                                              child: Text(
                                                '${st.key + 1}',
                                                style: const TextStyle(fontSize: 11),
                                              ),
                                            ),
                                            title: Text(st.value),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            TextButton.icon(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                setState(() {
                                                  // Append steps as new milestones after current
                                                  final insertAt = idx + 1;
                                                  _milestones.insertAll(
                                                    insertAt,
                                                    suggestion.steps.map(
                                                      (s) => Milestone(
                                                        id: const Uuid().v4(),
                                                        title: s,
                                                      ),
                                                    ),
                                                  );
                                                });
                                              },
                                              icon: const Icon(Icons.add_task),
                                              label: const Text('Add steps as milestones'),
                                            ),
                                            const Spacer(),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.inventory_2_outlined, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Inventory',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _addInventoryItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_inventory.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No inventory'),
                      ),
                    ..._inventory.asMap().entries.map((e) {
                      final idx = e.key;
                      final it = e.value;
                      return ListTile(
                        title: Text(it.name),
                        subtitle: Text(
                          'Qty: ${it.qty} • Unit: ${_fmtCurrency(it.unitCost)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await _editInventoryItem(idx);
                                setState(() {});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => setState(() {
                                _inventory.removeAt(idx);
                              }),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.receipt_long_outlined, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Operating expenses',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _addExpenseItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_expenses.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No operating expenses'),
                      ),
                    ..._expenses.asMap().entries.map((e) {
                      final idx = e.key;
                      final ex = e.value;
                      return ListTile(
                        title: Text(ex.name),
                        subtitle: Text(
                          'Monthly: ${_fmtCurrency(ex.monthlyCost)}',
                        ),
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
                                _expenses.removeAt(idx);
                              }),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : () => _savePlan(),
              icon: const Icon(Icons.save),
              label: const Text('Save plan'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : () => _savePlan(editAfter: true),
              icon: const Icon(Icons.edit_note),
              label: const Text('Save & edit in list'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
        () => _expenses.add(
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
    final ex = _expenses[idx];
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
        () => _expenses[idx] = ExpenseItem(
          id: ex.id,
          name: nameCtl.text.trim(),
          monthlyCost: cost,
        ),
      );
    }
  }
}
