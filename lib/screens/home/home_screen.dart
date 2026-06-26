import 'package:flutter/material.dart';
import '../library/library_screen.dart';
import '../player/player_screen.dart';
import '../playlists/playlists_screen.dart';
import '../discover/discover_screen.dart';
import '../settings/settings_screen.dart';
import '../about/about_screen.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/sleep_timer_service.dart';
import '../../widgets/playback_menus.dart';
import '../../widgets/mini_player.dart';

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
        return DiscoverScreen(onNavigateToPlayer: _navigateToPlayer);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Every tab floats its content up behind a transparent app bar over a
    // subtle gradient (the player's immersive look), for one cohesive top area.
    final isPlayer = _selectedIndex == 1;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: isPlayer
            ? [
                ListenableBuilder(
                  listenable: SettingsService.instance,
                  builder: (context, _) => TextButton(
                    onPressed: () => showPlaybackSpeedSheet(context),
                    child: Text(
                      formatSpeed(SettingsService.instance.playbackSpeed),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sleep timer',
                  icon: const Icon(Icons.bedtime_outlined),
                  onPressed: () => showSleepTimerSheet(context),
                ),
              ]
            : null,
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: List.generate(
                _titles.length,
                (i) => _visited.contains(i)
                    ? _buildScreen(i)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          // Mini-player above the nav bar (hidden on the Player tab and when
          // nothing is loaded).
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _selectedIndex == 1
                ? const SizedBox.shrink()
                : MiniPlayer(onTap: () => _onItemTapped(1)),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note),
            label: 'Player',
          ),
          NavigationDestination(
            icon: Icon(Icons.playlist_play_outlined),
            selectedIcon: Icon(Icons.playlist_play),
            label: 'Playlists',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.65),
                ],
              ),
            ),
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
