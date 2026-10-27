import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/state/playback.dart';
import 'song_artwork.dart';

/// The songs of an album or artist; tapping one plays the whole list from
/// there.
class SourceSongList extends ConsumerWidget {
  const SourceSongList({
    super.key,
    required this.title,
    required this.songs,
    required this.emptyText,
    required this.subtitleOf,
    required this.onNavigateToPlayer,
  });

  final String title;
  final AsyncValue<List<SongModel>> songs;
  final String emptyText;
  final String Function(SongModel song) subtitleOf;
  final VoidCallback onNavigateToPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: songs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading songs: $e')),
        data: (songs) {
          if (songs.isEmpty) return Center(child: Text(emptyText));
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: SongArtwork(
                  id: song.id,
                  size: 50,
                  borderRadius: BorderRadius.circular(8),
                  placeholder: const Icon(Icons.music_note),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(subtitleOf(song)),
                onTap: () async {
                  onNavigateToPlayer();
                  final handler = ref.read(audioHandlerProvider);
                  if (handler == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Audio service is not ready yet. Please wait...',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  handler.setQueue(songs);
                  await handler.playSongAt(index);
                },
              );
            },
          );
        },
      ),
    );
  }
}
