// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:noir_player/core/services/audio_handler.dart';
// import 'package:noir_player/screens/player/player_screen.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'core/theme/app_theme.dart';
// import 'screens/home/home_screen.dart';
// //import 'screens/playlists/playlists_screen.dart';

// // Future<void> _requestPermissions() async {
// //   [Permission.storage].request;
// // }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await initAudioService();
//   timeDilation = 1.0;
//   runApp(const NoirPlayerApp());
// }

// class NoirPlayerApp extends StatelessWidget {
//   const NoirPlayerApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Noir Player',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.darkTheme,
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const HomeScreen(),
//         '/player': (context) => const PlayerScreen(),
//         // '/playlists_screen': (context) => PlaylistsScreen(
//         //       onNavigateToPlayer: () {
//         //         Navigator.of(context).pushNamed('/player');
//         //       },
//         //     ),
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:noir_player/core/services/audio_handler.dart';
import 'package:noir_player/screens/player/player_screen.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initAudioService();
  timeDilation = 1.0;
  runApp(NoirPlayerApp());
}

class NoirPlayerApp extends StatelessWidget {
  NoirPlayerApp({super.key});

  // 👇 This controls whether the app is light or dark
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
            '/': (context) => HomeScreen(themeNotifier: themeNotifier),
            '/player': (context) => const PlayerScreen(),
          },
        );
      },
    );
  }
}
