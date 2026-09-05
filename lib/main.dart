import 'package:flutter/material.dart';
import 'package:fynoxfow/screens.dart';

import 'models.dart';

void main() {
  runApp(const FluxFlowApp());
}

class FluxFlowApp extends StatelessWidget {
  const FluxFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FluxFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          brightness: Brightness.light,
        ).copyWith(
          primary: primaryGreen,
          secondary: accentGreen,
          surface: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: primaryGreen,
              width: 1.5,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: primaryGreen,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          titleLarge: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
          ),
          titleMedium: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: textDark),
          bodyMedium: TextStyle(color: mutedText),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
