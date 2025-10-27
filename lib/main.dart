import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const NoirPlayerApp());
}

class NoirPlayerApp extends StatelessWidget {
  const NoirPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noir Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
