import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_tabs_page.dart';
import 'config/auth_toggle.dart';
import 'services/currency_notifier.dart';
import 'services/settings_service.dart';
import 'services/currency_scope.dart';

Future<void> checkTokenAndSignOutIfRevoked() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  try {
    // force refresh; will fail if refresh token was revoked
    await user.getIdTokenResult(true);
  } catch (_) {
    await FirebaseAuth.instance.signOut();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kAuthDisabled) {
    await checkTokenAndSignOutIfRevoked();
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _tokenCheckTimer;
  late final CurrencyNotifier _currencyNotifier;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currencyNotifier = CurrencyNotifier(SettingsService());
    _currencyNotifier.initialize();
    if (!kAuthDisabled) {
      _tokenCheckTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        checkTokenAndSignOutIfRevoked();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kAuthDisabled && state == AppLifecycleState.resumed) {
      checkTokenAndSignOutIfRevoked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CurrencyScope(
      notifier: _currencyNotifier,
      child: MaterialApp(
      title: 'EntrePrepare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.deepPurple,
          indicatorColor: Colors.white.withOpacity(0.18),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? Colors.white : Colors.white70,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            );
          }),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
      ),
      // If auth is disabled, skip the StreamBuilder entirely.
      home: kAuthDisabled
          ? const MainTabsPage()
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                final user = snapshot.data;
                if (user == null) return const LoginScreen();
                return const MainTabsPage();
              },
            ),
    ));
  }
}

/// InheritedWidget to expose CurrencyNotifier without external packages.
// CurrencyScope moved to services/currency_scope.dart for reuse.
