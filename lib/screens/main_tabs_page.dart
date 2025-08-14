import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'quiz/quiz_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/business_service.dart';

class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _selectedIndex = 0;
  bool _quizCompleted = false;
  final BusinessService _businessService = BusinessService();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [const HomeScreen(), const QuizScreen()];
    _checkQuizStatus();
  }

  Future<void> _checkQuizStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final status = await _businessService.fetchUserQuizStatus(user.uid);
    if (mounted) {
      setState(() {
        _quizCompleted = status;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: const Icon(Icons.quiz),
            label: _quizCompleted ? "Quiz (Retake)" : "Quiz (Start)",
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}
