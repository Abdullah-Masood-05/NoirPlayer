import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/state/library.dart';
import '../../widgets/source_song_list.dart';

class ArtistSongsScreen extends ConsumerWidget {
  const ArtistSongsScreen({
    super.key,
    required this.artist,
    required this.onNavigateToPlayer,
  });

  final ArtistModel artist;
  final VoidCallback onNavigateToPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SourceSongList(
      title: artist.artist,
      songs: ref.watch(artistSongsProvider(artist.id)),
      emptyText: 'No songs found for this artist.',
      subtitleOf: (song) => song.album ?? 'Unknown Album',
      onNavigateToPlayer: onNavigateToPlayer,
    );
  }
}
