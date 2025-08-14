import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/business_service.dart';
import '../../models/business.dart';
import '../home_screen.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> answers;

  const ResultScreen({super.key, required this.answers});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final BusinessService _businessService = BusinessService();
  List<Business> _topBusinesses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTopBusinesses();
  }

  Future<void> _fetchTopBusinesses() async {
    final top = await _businessService.getTop3(widget.answers);
    if (mounted) {
      setState(() {
        _topBusinesses = top;
        _loading = false;
      });
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Widget _buildBusinessCard(Business b) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              b.description,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (b.personality.isNotEmpty)
                  Chip(label: Text(_capitalize(b.personality.join(', ')))),
                if (b.budget.isNotEmpty)
                  Chip(
                    label: Text('Budget: ${_capitalize(b.budget.join(', '))}'),
                  ),
                if (b.time.isNotEmpty)
                  Chip(label: Text('Time: ${_capitalize(b.time.join(', '))}')),
                if (b.skills.isNotEmpty)
                  Chip(
                    label: Text('Skills: ${_capitalize(b.skills.join(', '))}'),
                  ),
                if (b.environment.isNotEmpty)
                  Chip(
                    label: Text(
                      'Environment: ${_capitalize(b.environment.join(', '))}',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerRow(String title, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            '${_capitalize(title)}: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Flexible(child: Text(_capitalize(value.toString()))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Your Answers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                _buildAnswerRow('Personality', widget.answers['personality']),
                _buildAnswerRow('Budget', widget.answers['budget']),
                _buildAnswerRow('Time', widget.answers['time']),
                _buildAnswerRow('Skills', widget.answers['skills']),
                _buildAnswerRow('Environment', widget.answers['environment']),
                _buildAnswerRow(
                  'Risk Tolerance',
                  widget.answers['riskTolerance'],
                ),
                if (_topBusinesses.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      'Top 3 Recommended Businesses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._topBusinesses.map(_buildBusinessCard),
                ],
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    },
                    child: const Text('Go to Home'),
                  ),
                ),
              ],
            ),
    );
  }
}
