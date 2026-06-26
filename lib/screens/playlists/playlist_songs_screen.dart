import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;

import '../../core/models/playlist_model.dart';
import '../../core/services/audio_handler.dart';
import '../../core/services/playlist_service.dart';

class PlaylistSongsScreen extends StatelessWidget {
  const PlaylistSongsScreen({
    super.key,
    required this.playlist,
    required this.onNavigateToPlayer,
  });

  final PlaylistModel playlist;
  final VoidCallback onNavigateToPlayer;

  void _play(BuildContext context, int index) {
    final handler = audioHandler as AudioPlayerHandler;
    handler.setQueue(playlist.songs);
    handler.playSongAt(index);
    Navigator.pop(context);
    onNavigateToPlayer();
  }

  Future<void> _confirmRemove(
    BuildContext context,
    PlaylistSong song,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove song'),
        content: Text('Remove "${song.title}" from ${playlist.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await PlaylistService.instance.removeSong(playlist, song.id);
    }
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
        actions: [
          if (playlist.isFavourite)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.favorite, color: theme.colorScheme.primary),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: PlaylistService.instance,
        builder: (context, _) {
          final songs = playlist.songs;
          if (songs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    playlist.isFavourite
                        ? Icons.favorite_border
                        : Icons.queue_music,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 16),
                  Text('No songs yet', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    playlist.isFavourite
                        ? 'Tap the heart on a song to add it here'
                        : 'Long-press a song to add it to a playlist',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                onTap: () => _play(context, index),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.circular(10),
                      nullArtworkWidget: Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          Icons.music_note,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(song.duration ?? 0),
                      style: theme.textTheme.bodySmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _confirmRemove(context, song),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms);
            },
          );
        },
      ),
    );
  }
}
