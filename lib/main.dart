import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:noir_player/core/services/audio_handler.dart';
import 'package:noir_player/screens/player/player_screen.dart';
import 'package:noir_player/screens/auth/auth_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initAudioService();
  timeDilation = 1.0;
  runApp(NoirPlayerApp());
}

class NoirPlayerApp extends StatelessWidget {
  NoirPlayerApp({super.key});

  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Noir Player',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          initialRoute: '/',
          routes: {
            '/': (context) => AuthWrapper(themeNotifier: themeNotifier),
            '/player': (context) => const PlayerScreen(),
          },
        );
      },
    );
  }
}
