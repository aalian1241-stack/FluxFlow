import 'package:flutter/material.dart';

import 'data.dart';
import 'home.dart';
import 'onboarding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FynoxFowApp());
}

class FynoxFowApp extends StatefulWidget {
  const FynoxFowApp({super.key});

  static const primary = Color(0xFF4F46E5);
  static const darkPrimary = Color(0xFF3730A3);
  static const background = Color(0xFFF9FAFB);
  static const ink = Color(0xFF111827);

  @override
  State<FynoxFowApp> createState() => _FynoxFowAppState();
}

class _FynoxFowAppState extends State<FynoxFowApp> {
  final LocalStore _store = LocalStore();
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _loadStartup();
  }

  Future<void> _loadStartup() async {
    final done = await _store.hasSeenOnboarding();

    if (!mounted) return;
    setState(() => _onboardingDone = done);
  }

  Future<void> _finishOnboarding() async {
    await _store.setSeenOnboarding();

    if (!mounted) return;
    setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fynox Flow',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: FynoxFowApp.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: FynoxFowApp.primary,
          brightness: Brightness.light,
          surface: Colors.white,
        ),
        fontFamily: 'sans',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: FynoxFowApp.primary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFE8EAF6),
          height: 72,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF5F5FA),
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: FynoxFowApp.primary, width: 1.5),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: _onboardingDone == null
          ? const _StartupPage()
          : _onboardingDone!
              ? const HomeScreen()
              : OnboardingScreen(onFinished: _finishOnboarding),
    );
  }
}

class _StartupPage extends StatelessWidget {
  const _StartupPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: FynoxFowApp.primary,
        ),
      ),
    );
  }
}
