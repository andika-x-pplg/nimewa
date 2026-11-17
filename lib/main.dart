import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(const NimevaApp());
}

/// Root widget for the Nimeva anime streaming application.
/// Configured with Obsidian & Crimson dark theme.
class NimevaApp extends StatelessWidget {
  const NimevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nimeva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
