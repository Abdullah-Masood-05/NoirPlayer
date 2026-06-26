
import 'package:flutter/material.dart';
import '../library/library_screen.dart';
import '../player/player_screen.dart';
import '../playlists/playlists_screen.dart';
import '../discover/discover_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const HomeScreen({super.key, required this.themeNotifier});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Tabs opened at least once. Lets the IndexedStack build screens lazily (so
  // e.g. Discover doesn't hit the network until first opened) while keeping
  // each one alive — and its state — once built.
  final Set<int> _visited = {0};

  final List<String> _titles = const [
    'Library',
    'Now Playing',
    'Playlists',
    'Discover',
    'Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _visited.add(index);
    });
  }

  void _navigateToPlayer() {
    setState(() {
      _selectedIndex = 1;
      _visited.add(1);
    });
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return LibraryScreen(onNavigateToPlayer: _navigateToPlayer);
      case 1:
        return const PlayerScreen();
      case 2:
        return PlaylistsScreen(onNavigateToPlayer: _navigateToPlayer);
      case 3:
        return const DiscoverScreen();
      case 4:
        return SettingsScreen(themeNotifier: widget.themeNotifier);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex]), centerTitle: true),
      // IndexedStack keeps every visited screen alive, so switching tabs is
      // instant and doesn't re-run initState (e.g. re-querying the library).
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(
          _titles.length,
          (i) =>
              _visited.contains(i) ? _buildScreen(i) : const SizedBox.shrink(),
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
            icon: Icon(Icons.explore),
            label: 'Discover',
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
