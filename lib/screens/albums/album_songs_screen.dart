import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/state/library.dart';
import '../../widgets/source_song_list.dart';

class AlbumSongsScreen extends ConsumerWidget {
  const AlbumSongsScreen({
    super.key,
    required this.album,
    required this.onNavigateToPlayer,
  });

  final AlbumModel album;
  final VoidCallback onNavigateToPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SourceSongList(
      title: album.album,
      songs: ref.watch(albumSongsProvider(album.id)),
      emptyText: 'No songs found in this album.',
      subtitleOf: (song) => song.artist ?? 'Unknown Artist',
      onNavigateToPlayer: onNavigateToPlayer,
    );
  }
}
