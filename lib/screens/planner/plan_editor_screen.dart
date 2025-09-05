import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/plan.dart';
import '../../models/business.dart';
import '../../services/plan_service.dart';
import '../../services/settings_service.dart';
import '../../services/license_service.dart';
import '../../utils/currency_utils.dart';

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
  final LicenseService _licenseSvc = LicenseService();

  List<PlanItem> _inventory = [];
  List<Milestone> _milestones = [];
  String _currency = 'USD';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applyPrefill();
    _loadSettings();
  }

  void _applyPrefill() {
    if (widget.business != null) {
      _titleCtl.text = widget.business!.title;
    }
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
        content: const Text('Your access has expired. Please contact the developer to continue.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _savePlan() async {
    final expired = await _licenseSvc.isExpired();
    if (expired) {
      await _showExpiredDialog();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final userPlan = Plan(
      id: '',
      businessId: widget.business?.docId ?? '',
      title: _titleCtl.text.trim(),
      capitalEstimated: double.tryParse(_capitalCtl.text) ?? 0.0,
      pricePerUnit: double.tryParse(_priceCtl.text) ?? 0.0,
      estMonthlySales: int.tryParse(_salesCtl.text) ?? 0,
      inventory: _inventory,
      milestones: _milestones,
      createdAt: DateTime.now(),
    );

    try {
      await _service.createPlan(userPlan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan saved')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
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
        content: TextField(controller: ctl, decoration: const InputDecoration(hintText: 'Milestone title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && ctl.text.trim().isNotEmpty) {
      setState(() => _milestones.add(Milestone(id: const Uuid().v4(), title: ctl.text.trim())));
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
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
            TextField(controller: nameCtl, decoration: const InputDecoration(hintText: 'Item name')),
            const SizedBox(height: 8),
            TextField(controller: qtyCtl, decoration: const InputDecoration(hintText: 'Quantity'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: costCtl, decoration: const InputDecoration(hintText: 'Unit cost'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );

    if (ok == true && nameCtl.text.trim().isNotEmpty) {
      final qty = int.tryParse(qtyCtl.text.trim()) ?? 1;
      final unitCost = double.tryParse(costCtl.text.trim()) ?? 0.0;
      setState(() => _inventory.add(PlanItem(id: const Uuid().v4(), name: nameCtl.text.trim(), qty: qty, unitCost: unitCost)));
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
            TextField(controller: nameCtl, decoration: const InputDecoration(hintText: 'Item name')),
            const SizedBox(height: 8),
            TextField(controller: qtyCtl, decoration: const InputDecoration(hintText: 'Quantity'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(controller: costCtl, decoration: const InputDecoration(hintText: 'Unit cost'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok == true && nameCtl.text.trim().isNotEmpty) {
      final qty = int.tryParse(qtyCtl.text.trim()) ?? 1;
      final unitCost = double.tryParse(costCtl.text.trim()) ?? 0.0;
      setState(() => _inventory[idx] = PlanItem(id: item.id, name: nameCtl.text.trim(), qty: qty, unitCost: unitCost));
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
    final avgUnitCost = _inventory.map((i) => i.unitCost).fold<double>(0, (s, e) => s + e) / _inventory.length;
    final sales = double.tryParse(_salesCtl.text) ?? 0.0;
    return avgUnitCost * sales;
  }

  double get _monthlyProfit => _monthlyRevenue - _monthlyCOGS;

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
            onPressed: _saving ? null : _savePlan,
            child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _titleCtl,
            decoration: const InputDecoration(labelText: 'Plan title'),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter title' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _capitalCtl,
            decoration: InputDecoration(labelText: 'Estimated capital ($_currency)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _priceCtl,
                decoration: InputDecoration(labelText: 'Price per unit ($_currency)'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _salesCtl,
                decoration: const InputDecoration(labelText: 'Est. monthly sales'),
                keyboardType: TextInputType.number,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Projection', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Monthly revenue: ${_fmtCurrency(_monthlyRevenue)}'),
                Text('Monthly cost of goods: ${_fmtCurrency(_monthlyCOGS)}'),
                Text('Estimated monthly profit: ${_fmtCurrency(_monthlyProfit)}'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Milestones', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(onPressed: _addMilestone, icon: const Icon(Icons.add), label: const Text('Add')),
                ]),
                if (_milestones.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No milestones')),
                ..._milestones.asMap().entries.map((e) {
                  final idx = e.key;
                  final m = e.value;
                  return ListTile(
                    title: Text(m.title),
                    leading: Checkbox(value: m.done, onChanged: (v) => setState(() => m.done = v ?? false)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editMilestoneTitle(idx)),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeMilestone(idx)),
                    ]),
                  );
                }).toList(),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(onPressed: _addInventoryItem, icon: const Icon(Icons.add), label: const Text('Add')),
                ]),
                if (_inventory.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No inventory')),
                ..._inventory.asMap().entries.map((e) {
                  final idx = e.key;
                  final it = e.value;
                  return ListTile(
                    title: Text(it.name),
                    subtitle: Text('Qty: ${it.qty} • Unit: ${_fmtCurrency(it.unitCost)}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editInventoryItem(idx)),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _inventory.removeAt(idx))),
                    ]),
                  );
                }).toList(),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(onPressed: _saving ? null : _savePlan, icon: const Icon(Icons.save), label: const Text('Save plan')),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}