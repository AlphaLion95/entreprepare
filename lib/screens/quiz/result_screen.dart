// ...existing code...
import 'package:flutter/material.dart';
import '../../services/business_service.dart';
import '../../models/business.dart';
import '../home_screen.dart';
import '../business/business_detail_screen.dart';

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> answers;
  final List<Business>? topBusinesses;

  const ResultScreen({super.key, required this.answers, this.topBusinesses});

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
    // If QuizScreen passed a non-null list we use it directly (even empty -> show "no matches").
    // If null was passed it means QuizScreen couldn't compute; fetch here in background.
    if (widget.topBusinesses != null) {
      _topBusinesses = widget.topBusinesses!;
      _loading = false;
    } else {
      _fetchTopBusinesses();
    }
  }

  Future<void> _fetchTopBusinesses() async {
    setState(() => _loading = true);
    try {
      final top = await _businessService.getTop3(widget.answers);
      if (mounted) {
        setState(() {
          _topBusinesses = top;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to compute suggestions: $e')),
        );
      }
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
        .join(' ');
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
          : _topBusinesses.isEmpty
          ? ListView(
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
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'No suggested businesses found for your answers.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchTopBusinesses,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
            )
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
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'Suggested Businesses',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                ..._topBusinesses.map(_buildBusinessCard),
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

  Widget _buildBusinessCard(Business b) {
    String capitalize(String s) =>
        s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

    final tag = 'business-${b.docId ?? b.title}';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessDetailScreen(business: b, answers: null),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: tag,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (b.title.isNotEmpty ? b.title[0].toUpperCase() : '?'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: Colors.black26),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b.description,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (b.personality.isNotEmpty)
                        Chip(label: Text(b.personality.map(capitalize).join(', ')), visualDensity: VisualDensity.compact),
                      if (b.budget.isNotEmpty)
                        Chip(label: Text('Budget: ${b.budget.map(capitalize).join(', ')}'), visualDensity: VisualDensity.compact),
                      if (b.time.isNotEmpty)
                        Chip(label: Text('Time: ${b.time.map(capitalize).join(', ')}'), visualDensity: VisualDensity.compact),
                    ],
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
