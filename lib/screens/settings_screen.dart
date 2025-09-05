// Overwrite this existing file with this content (top-level settings screen)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/settings_service.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _svc = SettingsService();
  bool _loading = true;
  String _currency = 'USD';
  String _plan = 'trial';
  Map<String, bool> _features = {
    'advanced_analytics': false,
    'unlimited_plans': false,
    'priority_support': false,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await _svc.fetchSettings();
    if (s != null) {
      setState(() {
        _currency = s.currency;
        _plan = s.plan;
        _features = {
          'advanced_analytics': s.features['advanced_analytics'] ?? false,
          'unlimited_plans': s.features['unlimited_plans'] ?? false,
          'priority_support': s.features['priority_support'] ?? false,
        };
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final s = Settings(
      currency: _currency,
      plan: _plan,
      features: _features,
      updatedAt: DateTime.now(),
    );
    try {
      await _svc.saveSettings(s);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final currencies = ['USD', 'EUR', 'PHP'];
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Currency',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _currency,
                          items: currencies
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _currency = v ?? _currency),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Plan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        RadioListTile<String>(
                          title: const Text('Trial (basic features)'),
                          value: 'trial',
                          groupValue: _plan,
                          onChanged: (v) => setState(() => _plan = v ?? _plan),
                        ),
                        RadioListTile<String>(
                          title: const Text('Paid (full features)'),
                          value: 'paid',
                          groupValue: _plan,
                          onChanged: (v) => setState(() => _plan = v ?? _plan),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Feature toggles',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SwitchListTile(
                          title: const Text('Advanced analytics'),
                          value: _features['advanced_analytics'] ?? false,
                          onChanged: (v) => setState(
                            () => _features['advanced_analytics'] = v,
                          ),
                        ),
                        SwitchListTile(
                          title: const Text('Unlimited plans'),
                          value: _features['unlimited_plans'] ?? false,
                          onChanged: (v) =>
                              setState(() => _features['unlimited_plans'] = v),
                        ),
                        SwitchListTile(
                          title: const Text('Priority support'),
                          value: _features['priority_support'] ?? false,
                          onChanged: (v) =>
                              setState(() => _features['priority_support'] = v),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save settings'),
                            onPressed: _save,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
