// import 'package:flutter/material.dart';
// import '../library/library_screen.dart'; // ✅ new import
// import '../player/player_screen.dart';
// import '../playlists/playlists_screen.dart';
// import '../settings/settings_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;

//   // ✅ Added LibraryScreen as the first tab
//   final List<Widget> _screens = const [
//     LibraryScreen(),
//     PlayerScreen(),
//     PlaylistsScreen(),
//     SettingsScreen(),
//   ];

//   final List<String> _titles = const [
//     'Library',
//     'Now Playing',
//     'Playlists',
//     'Settings',
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(_titles[_selectedIndex]), centerTitle: true),
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.library_music),
//             label: 'Library',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.music_note),
//             label: 'Player',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.playlist_play),
//             label: 'Playlists',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import '../library/library_screen.dart';
// import '../player/player_screen.dart';
// import '../playlists/playlists_screen.dart';
// import '../settings/settings_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;

//   late final List<Widget> _screens;

//   @override
//   void initState() {
//     super.initState();
//     // Pass callback to LibraryScreen
//     _screens = [
//       LibraryScreen(onNavigateToPlayer: () => _onItemTapped(1)),
//       const PlayerScreen(),
//       const PlaylistsScreen(),
//       const SettingsScreen(),
//     ];
//   }

//   final List<String> _titles = const [
//     'Library',
//     'Now Playing',
//     'Playlists',
//     'Settings',
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(_titles[_selectedIndex]), centerTitle: true),
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.library_music),
//             label: 'Library',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.music_note),
//             label: 'Player',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.playlist_play),
//             label: 'Playlists',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import '../library/library_screen.dart';
// import '../player/player_screen.dart';
// import '../playlists/playlists_screen.dart';
// import '../settings/settings_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;

//   final List<String> _titles = const [
//     'Library',
//     'Now Playing',
//     'Playlists',
//     'Settings',
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   // ✅ Callback to navigate to Player tab from nested screens
//   void _navigateToPlayer() {
//     setState(() {
//       _selectedIndex = 1; // Switch to Player tab
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ✅ Build screens list dynamically to pass callback
//     final List<Widget> screens = [
//       LibraryScreen(onNavigateToPlayer: _navigateToPlayer),
//       const PlayerScreen(),
//       PlaylistsScreen(onNavigateToPlayer: _navigateToPlayer),
//       const SettingsScreen(),
//     ];

//     return Scaffold(
//       appBar: AppBar(title: Text(_titles[_selectedIndex]), centerTitle: true),
//       body: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 300),
//         switchInCurve: Curves.easeInOut,
//         switchOutCurve: Curves.easeInOut,
//         transitionBuilder: (Widget child, Animation<double> animation) {
//           // ✅ Slide and fade transition
//           return FadeTransition(
//             opacity: animation,
//             child: SlideTransition(
//               position: Tween<Offset>(
//                 begin: const Offset(0.1, 0.0),
//                 end: Offset.zero,
//               ).animate(animation),
//               child: child,
//             ),
//           );
//         },
//         child: Container(
//           key: ValueKey<int>(_selectedIndex),
//           child: screens[_selectedIndex],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.library_music),
//             label: 'Library',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.music_note),
//             label: 'Player',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.playlist_play),
//             label: 'Playlists',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: 'Settings',
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import '../library/library_screen.dart';
import '../player/player_screen.dart';
import '../playlists/playlists_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const HomeScreen({super.key, required this.themeNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = const [
    'Library',
    'Now Playing',
    'Playlists',
    'Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToPlayer() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      LibraryScreen(onNavigateToPlayer: _navigateToPlayer),
      const PlayerScreen(),
      PlaylistsScreen(onNavigateToPlayer: _navigateToPlayer),
      SettingsScreen(themeNotifier: widget.themeNotifier), // 👈 FIXED HERE
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex]), centerTitle: true),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(_selectedIndex),
          child: screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Player',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: 'Playlists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
