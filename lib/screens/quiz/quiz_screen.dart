import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/auth_toggle.dart';
import '../../models/quiz_question.dart';
import '../../services/quiz_service.dart';
import '../../screens/quiz/result_screen.dart';
import '../../models/business.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();
  late final List<QuizQuestion> _questions;
  final PageController _pageController = PageController();
  final Map<String, dynamic> _answers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _questions = _quizService.getQuestions();
  }

  void _selectChoice(String questionId, String choice) {
    setState(() => _answers[questionId] = choice);
  }

  void _setSlider(String questionId, double value) {
    setState(() => _answers[questionId] = value.round());
  }

  bool _hasAnswer(String id) => _answers.containsKey(id);

  Future<void> _nextPage() async {
    final current = _pageController.page?.round() ?? 0;
    if (!_hasAnswer(_questions[current].id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer to continue')),
      );
      return;
    }
    if (current < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      await _submit();
    }
  }

  void _prevPage() {
    if (_pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      if (!kAuthDisabled) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not logged in')),
          );
          setState(() => _saving = false);
          return;
        }
      }

      await _quizService.saveAnswers(_answers);

      // try computing top businesses here with a short timeout
      // increase timeout to give compute a bit more time on larger datasets
      List<Business>? top;
      try {
        top = await _quizService
            .getTopBusinesses(_answers, topN: 3)
            .timeout(const Duration(seconds: 8)); // increased timeout
        // top may be an empty list meaning "no matches" (keep that)
      } on TimeoutException {
        // explicitly indicate "not computed" so ResultScreen will fetch/retry in background
        top = null;
      } catch (e) {
        // on other errors we also let ResultScreen try to fetch
        top = null;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(answers: _answers, topBusinesses: top),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildChoiceButton(String qid, String option) {
    final selected = _answers[qid] == option;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.deepPurple : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black87,
        side: const BorderSide(color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      onPressed: () => _selectChoice(qid, option),
      child: Align(alignment: Alignment.centerLeft, child: Text(option)),
    );
  }

  Widget _buildQuestionPage(QuizQuestion q) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            q.question,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (q.type == 'choice')
            ...q.options.map(
              (opt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: _buildChoiceButton(q.id, opt),
              ),
            ),
          if (q.type == 'slider') ...[
            const SizedBox(height: 8),
            Text(
              (_answers[q.id] ?? q.sliderMin ?? 0).toString(),
              style: const TextStyle(fontSize: 18),
            ),
            Slider(
              min: (q.sliderMin ?? 0).toDouble(),
              max: (q.sliderMax ?? 10).toDouble(),
              divisions: q.sliderDivisions,
              value: (_answers[q.id] ?? q.sliderMin ?? 0).toDouble(),
              onChanged: (v) => _setSlider(q.id, v),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              if ((_pageController.hasClients
                      ? _pageController.page?.round() ?? 0
                      : 0) >
                  0)
                OutlinedButton(onPressed: _prevPage, child: const Text('Back')),
              const Spacer(),
              ElevatedButton(
                onPressed: _nextPage,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(q == _questions.last ? 'Submit' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lifestyle Quiz'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value:
                ((_pageController.hasClients
                        ? (_pageController.page ?? 0)
                        : 0) +
                    1) /
                total,
            color: Colors.deepPurple,
            backgroundColor: Colors.grey[200],
            minHeight: 6,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: total,
              itemBuilder: (context, index) =>
                  _buildQuestionPage(_questions[index]),
            ),
          ),
        ],
      ),
    );
  }
}
