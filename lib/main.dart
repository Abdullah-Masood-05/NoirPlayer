import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/audio_handler.dart';
import 'core/state/playback.dart';
import 'core/state/playlists.dart';
import 'core/state/settings.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/player/player_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted settings and playlists before anything reads them, so the
  // first frame already has them.
  final prefs = await SharedPreferences.getInstance();
  final repository = PlaylistRepository();
  final playlists = await repository.load();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      playlistRepositoryProvider.overrideWithValue(repository),
      initialPlaylistsProvider.overrideWithValue(playlists),
    ],
  );

  // Don't let an audio-service init failure block the UI from starting.
  // Screens read a null handler and do nothing.
  try {
    final handler = await initAudioService(container);
    container.read(audioHandlerProvider.notifier).attach(handler);

    // Restore the last played song (paused) if enabled.
    if (container.read(settingsProvider).resumeLastSong) {
      await handler.restoreLastSong();
    }
  } catch (e) {
    debugPrint('Audio service init failed: $e');
  }

  // Remember the current song and position whenever the app leaves the
  // foreground, so the mini-player can show it again after the system kills
  // the process.
  WidgetsBinding.instance.addObserver(_SaveOnBackground(container));

  timeDilation = 1.0;
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NoirPlayerApp(),
    ),
  );
}

class _SaveOnBackground with WidgetsBindingObserver {
  _SaveOnBackground(this._container);

  final ProviderContainer _container;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _container.read(audioHandlerProvider)?.saveLastSong();
    }
  }
}

class NoirPlayerApp extends ConsumerWidget {
  const NoirPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only a theme change rebuilds the whole app, not every settings change.
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      title: 'Noir Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/player': (context) => const PlayerScreen(),
      },
    );
  }
}
