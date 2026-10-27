import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/playlist_model.dart';
import '../../core/state/playback.dart';
import '../../core/state/playlists.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/song_artwork.dart';

class PlaylistSongsScreen extends ConsumerWidget {
  const PlaylistSongsScreen({
    super.key,
    required this.playlistName,
    required this.onNavigateToPlayer,
  });

  /// Playlists are looked up by name, so this screen always shows the latest
  /// version of the playlist.
  final String playlistName;
  final VoidCallback onNavigateToPlayer;

  void _play(
    BuildContext context,
    WidgetRef ref,
    PlaylistModel playlist,
    int index,
  ) {
    final handler = ref.read(audioHandlerProvider);
    if (handler != null) {
      handler.setQueue(playlist.songs);
      handler.playSongAt(index);
    }
    Navigator.pop(context);
    onNavigateToPlayer();
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    PlaylistModel playlist,
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
      ref.read(playlistsProvider.notifier).removeSong(playlist, song.id);
    }
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playlist = ref.watch(
      playlistsProvider.select(
        (all) => all.where((p) => p.name == playlistName).firstOrNull,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(playlistName),
        actions: [
          if (playlist?.isFavourite ?? false)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.favorite, color: theme.colorScheme.primary),
            ),
        ],
      ),
      body: Container(
        decoration: AppTheme.topFade(context),
        child: playlist == null
            ? Center(
                child: Text(
                  'This playlist was deleted',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            : _songs(context, ref, theme, playlist),
      ),
    );
  }

  Widget _songs(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    PlaylistModel playlist,
  ) {
    final songs = playlist.songs;
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              playlist.isFavourite ? Icons.favorite_border : Icons.queue_music,
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
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
        bottom: 8,
      ),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          key: ValueKey(song.id),
          onTap: () => _play(context, ref, playlist, index),
          leading: SongArtwork(
            id: song.id,
            size: 50,
            borderRadius: BorderRadius.circular(10),
            placeholder: Container(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.music_note, color: theme.colorScheme.primary),
            ),
          ),
          title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                onPressed: () => _confirmRemove(context, ref, playlist, song),
              ),
            ],
          ),
        ).animate().fadeIn(
          duration: 250.ms,
          delay: (index.clamp(0, 10) * 40).ms,
        );
      },
    );
  }
}
