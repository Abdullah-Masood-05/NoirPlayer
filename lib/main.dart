import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:noir_player/core/services/audio_handler.dart';
import 'package:noir_player/core/services/settings_service.dart';
import 'package:noir_player/screens/player/player_screen.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load API keys for the Discover/download module. fileName defaults to ".env";
  // ignore errors so the app still runs if the file is missing.
  try {
    await dotenv.load();
  } catch (_) {}

  // Load persisted user settings before anything reads them.
  await SettingsService.instance.load();

  // Don't let an audio-service init failure block the UI from starting.
  // Screens guard usage with isAudioServiceInitialized().
  try {
    await initAudioService();
  } catch (e) {
    debugPrint('Audio service init failed: $e');
  }

  // Restore the last played song (paused) if enabled.
  if (isAudioServiceInitialized() && SettingsService.instance.resumeLastSong) {
    await (audioHandler as AudioPlayerHandler).restoreLastSong();
  }

  timeDilation = 1.0;
  runApp(const NoirPlayerApp());
}

class NoirPlayerApp extends StatelessWidget {
  const NoirPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Noir Player',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: SettingsService.instance.themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/player': (context) => const PlayerScreen(),
          },
        );
      },
    );
  }
}
