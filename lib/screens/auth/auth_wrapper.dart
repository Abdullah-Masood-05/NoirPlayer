import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

/// Wrapper widget that handles authentication state
/// Shows LoginScreen if not authenticated, HomeScreen if authenticated
class AuthWrapper extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const AuthWrapper({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show home screen if authenticated
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen(themeNotifier: themeNotifier);
        }

        // Show login screen if not authenticated
        return const LoginScreen();
      },
    );
  }
}
