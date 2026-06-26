import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'tabs/songs_tab.dart';
import 'tabs/albums_tab.dart';
import 'tabs/artists_tab.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback onNavigateToPlayer;

  const LibraryScreen({super.key, required this.onNavigateToPlayer});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: AppTheme.topFade(context),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Clear the transparent app bar drawn by the home shell (kept tight
            // so the tabs sit just under the "Library" title).
            const SizedBox(height: kToolbarHeight - 14),
            TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              isScrollable: false,
              tabs: const [
                Tab(text: 'Music'),
                Tab(text: 'Audio'),
                Tab(text: 'Albums'),
                Tab(text: 'Artists'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Music: only audios from the chosen folder (default tab).
                  SongsTab(
                    onNavigateToPlayer: widget.onNavigateToPlayer,
                    musicFolderOnly: true,
                  ),
                  // Audio: every audio file on the device.
                  SongsTab(onNavigateToPlayer: widget.onNavigateToPlayer),
                  const AlbumsTab(),
                  const ArtistsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
