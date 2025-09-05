// Create folder if missing: c:\flutter_projects\entreprepare\lib\screens\settings
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/license_service.dart';

class AdminLicenseScreen extends StatefulWidget {
  const AdminLicenseScreen({super.key});
  @override
  State<AdminLicenseScreen> createState() => _AdminLicenseScreenState();
}

class _AdminLicenseScreenState extends State<AdminLicenseScreen> {
  final _uidCtl = TextEditingController();
  DateTime? _expiry;
  bool _loading = false;
  final LicenseService _svc = LicenseService();

  Future<void> _pickExpiry() async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t == null) return;
    setState(() => _expiry = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _setExpiry() async {
    final uid = _uidCtl.text.trim();
    if (uid.isEmpty || _expiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter user id and choose expiry')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _svc.setExpiryForUser(uid, _expiry!);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expiry set')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Set failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _clearExpiry() async {
    final uid = _uidCtl.text.trim();
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter user id')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _svc.clearExpiryForUser(uid);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expiry cleared')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Clear failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _uidCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Admin: License')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(children: [
          const Text('Set expiry for a tester account (admin only)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: _uidCtl, decoration: const InputDecoration(labelText: 'User UID', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(_expiry == null ? 'No expiry selected' : 'Expiry: ${_expiry!.toUtc().toIso8601String()} (UTC)')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: _pickExpiry, child: const Text('Pick')),
          ]),
          const SizedBox(height: 12),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (!_loading)
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: _setExpiry, child: const Text('Set expiry'))),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _clearExpiry, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Clear')),
            ]),
          const SizedBox(height: 16),
          Text('Current admin uid: $me', style: const TextStyle(color: Colors.black54)),
        ]),
      ),
    );
  }
}