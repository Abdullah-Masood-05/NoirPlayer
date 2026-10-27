import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/notification_permission.dart';
import '../../core/state/library.dart';
import '../../core/theme/app_theme.dart';
import 'tabs/songs_tab.dart';
import 'tabs/albums_tab.dart';
import 'tabs/artists_tab.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToPlayer;

  const LibraryScreen({super.key, required this.onNavigateToPlayer});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
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

  void _showSnack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: Duration(seconds: action == null ? 4 : 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Once storage is sorted, ask (one time) for the Android 13+ notification
  /// permission: without it OEM pop-up players (OnePlus Live Alerts, HyperOS
  /// island, Samsung Now Bar) may not show the playing song.
  Future<void> _askForNotifications() async {
    final status = await NotificationPermission.maybeRequest();
    if (status == null || status.isGranted || !mounted) return;
    _showSnack(
      'Notifications are off, so the pop-up player (Live Alerts / '
      'island) may not show the playing song.',
      action: SnackBarAction(
        label: 'Settings',
        onPressed: () => openAppSettings(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // One place reacts to the media-access answer for every Library tab.
    ref.listen<AsyncValue<LibraryAccess>>(libraryAccessProvider, (_, next) {
      switch (next.value) {
        case LibraryAccess.newlyGranted:
          _showSnack('Loaded all songs.');
          _askForNotifications();
        case LibraryAccess.granted:
          _askForNotifications();
        case LibraryAccess.denied:
          _showSnack('Permission denied. Cannot load songs.');
        case null:
          break;
      }
    });
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
