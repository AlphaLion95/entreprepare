import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'planner/plan_list_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'learn/learn_list_screen.dart';

class MainTabsPage extends StatefulWidget {
  final int initialIndex;
  const MainTabsPage({super.key, this.initialIndex = 0});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  late int _selectedIndex = widget.initialIndex;

  late final List<Widget> _pages = [
    HomeScreen(onSelectTab: (i) => _onItemTapped(i)),
    const PlanListScreen(),
    const SettingsScreen(),
    const AboutScreen(),
    const LearnListScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        // colors come from NavigationBarTheme in ThemeData
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info_rounded),
            label: 'About',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Learn',
          ),
        ],
      ),
    );
  }
}
