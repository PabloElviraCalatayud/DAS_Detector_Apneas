import 'package:flutter/material.dart';
import 'common/core/themes.dart';
import 'screens/onboarding/onboarding_page.dart';

void main() {
  runApp(const InsoleApp());
}

class InsoleApp extends StatelessWidget {
  const InsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAS',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const OnboardingPage(),
    );
  }
}
