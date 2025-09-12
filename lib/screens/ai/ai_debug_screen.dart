import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/ai_config.dart';
import '../../utils/ai_error_mapper.dart';

class AiDebugScreen extends StatefulWidget {
  const AiDebugScreen({super.key});
  @override
  State<AiDebugScreen> createState() => _AiDebugScreenState();
}

class _AiDebugScreenState extends State<AiDebugScreen> {
  final _controller = TextEditingController();
  String _raw = '';
  String _status = '';
  bool _loading = false;
  int _elapsedMs = 0;
  bool _repaired = false;

  Future<void> _run(Map<String, dynamic> payload, String label) async {
    setState(() {
      _loading = true;
      _status = 'Running $label...';
      _raw = '';
      _repaired = false;
    });
    final sw = Stopwatch()..start();
    try {
      final resp = await http
          .post(
            Uri.parse(kAiIdeasEndpoint), // unified
            headers: {
              'Content-Type': 'application/json',
              if (kAiApiKey.isNotEmpty) 'Authorization': 'Bearer $kAiApiKey',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 35));
      sw.stop();
      _elapsedMs = sw.elapsedMilliseconds;
      if (resp.statusCode == 200) {
        _raw = resp.body;
        try {
          final data = jsonDecode(resp.body);
          if (data is Map && data['repaired'] == true) _repaired = true;
        } catch (_) {}
        _status = 'OK (${resp.statusCode})';
      } else {
        _raw = resp.body;
        _status =
            'Error ${resp.statusCode}: ' +
            AiErrorMapper.map('status=${resp.statusCode} body=${resp.body}');
      }
    } catch (e) {
      sw.stop();
      _elapsedMs = sw.elapsedMilliseconds;
      _status = AiErrorMapper.map(e);
      _raw = e.toString();
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  Widget _buildAction(String title, Map<String, dynamic> payload) {
    return ElevatedButton(
      onPressed: _loading ? null : () => _run(payload, title),
      child: Text(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Debug')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Context / Query',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAction('Ideas', {
                  'query': _controller.text.trim().isEmpty
                      ? 'test business productivity'
                      : _controller.text.trim(),
                }),
                _buildAction('Solutions', {
                  'activity': 'launch productivity app',
                  'problem': _controller.text.trim().isEmpty
                      ? 'low user retention'
                      : _controller.text.trim(),
                  'goal': 'increase retention',
                  'limit': 3,
                }),
                _buildAction('Milestone', {
                  'title': _controller.text.trim().isEmpty
                      ? 'Acquire first 100 users'
                      : _controller.text.trim(),
                }),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Row(
              children: [
                Expanded(
                  child: Text(_status, style: theme.textTheme.bodySmall),
                ),
                if (_elapsedMs > 0)
                  Text('${_elapsedMs}ms', style: theme.textTheme.labelSmall),
                if (_repaired)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Chip(
                      label: Text('Repaired'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _raw,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
