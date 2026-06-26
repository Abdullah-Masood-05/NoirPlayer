import 'package:flutter/material.dart';
import '../library/library_screen.dart';
import '../player/player_screen.dart';
import '../playlists/playlists_screen.dart';
import '../discover/discover_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../../core/services/sleep_timer_service.dart';
import '../../widgets/playback_menus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Tabs opened at least once, so the IndexedStack builds them lazily and keeps
  // their state once built.
  final Set<int> _visited = {0};

  final List<String> _titles = const [
    'Library',
    'Now Playing',
    'Playlists',
    'Discover',
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
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex]), centerTitle: true),
      drawer: _buildDrawer(context),
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
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Player'),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: 'Playlists',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.music_note, color: Colors.white, size: 44),
                SizedBox(height: 10),
                Text(
                  'Noir Player',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ValueListenableBuilder<Duration?>(
            valueListenable: SleepTimerService.instance.remaining,
            builder: (_, remaining, __) => ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: const Text('Sleep Timer'),
              subtitle: remaining != null
                  ? Text('Stops in ${formatTimerDuration(remaining)}')
                  : null,
              onTap: () {
                Navigator.pop(context);
                showSleepTimerSheet(context);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
