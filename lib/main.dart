import 'package:flutter/material.dart';
import 'package:noir_player/core/services/audio_handler.dart';
import 'package:noir_player/screens/player/player_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

// Future<void> _requestPermissions() async {
//   [Permission.storage].request;
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAudioService();
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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/player': (context) => const PlayerScreen(),
      },
    );
  }
}
