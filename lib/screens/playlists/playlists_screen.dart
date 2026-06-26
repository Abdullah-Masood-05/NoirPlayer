import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/playlist_model.dart';
import '../../core/services/playlist_service.dart';
import 'playlist_songs_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key, required this.onNavigateToPlayer});

  final VoidCallback onNavigateToPlayer;

  @override
  Widget build(BuildContext context) {
    final service = PlaylistService.instance;

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final playlists = service.playlists;
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createPlaylist(context, service),
            icon: const Icon(Icons.add),
            label: const Text('New playlist'),
          ),
          body: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return _PlaylistCard(
                playlist: playlist,
                onTap: () => _openPlaylist(context, playlist),
                onDelete: playlist.isFavourite
                    ? null
                    : () => _confirmDelete(context, service, playlist),
              ).animate().fadeIn(duration: 300.ms, delay: (index * 60).ms).scaleXY(
                    begin: 0.92,
                    curve: Curves.easeOut,
                  );
            },
          ),
        );
      },
    );
  }

  void _openPlaylist(BuildContext context, PlaylistModel playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistSongsScreen(
          playlist: playlist,
          onNavigateToPlayer: onNavigateToPlayer,
        ),
      ),
    );
  }

  Future<void> _createPlaylist(
    BuildContext context,
    PlaylistService service,
  ) async {
    if (!service.canCreateMore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'You can have at most ${PlaylistService.maxPlaylists} playlists',
          ),
        ),
      );
      return;
    }

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Playlist name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;
    final created = await service.createPlaylist(name);
    if (context.mounted && !created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not create playlist (limit or duplicate name)'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PlaylistService service,
    PlaylistModel playlist,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete playlist'),
        content: Text('Delete "${playlist.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await service.deletePlaylist(playlist);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Deleted "${playlist.name}"'),
          ),
        );
      }
    }
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
    required this.onDelete,
  });

  final PlaylistModel playlist;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary.withValues(alpha: 0.30),
                          primary.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        playlist.isFavourite
                            ? Icons.favorite
                            : Icons.queue_music,
                        size: 52,
                        color: primary,
                      ),
                    ),
                  ),
                  if (onDelete != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        onPressed: onDelete,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist.songs.length} song${playlist.songs.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
