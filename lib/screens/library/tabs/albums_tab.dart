import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../core/state/library.dart';
import '../../../widgets/library_grid.dart';
import '../../../widgets/song_artwork.dart';
import '../../albums/album_songs_screen.dart';
import '../../player/player_screen.dart';

class AlbumsTab extends ConsumerStatefulWidget {
  const AlbumsTab({super.key});

  @override
  ConsumerState<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends ConsumerState<AlbumsTab>
    with AutomaticKeepAliveClientMixin {
  // Keep the tab alive so switching away keeps its scroll position.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    if (ref.watch(libraryAccessProvider).value == LibraryAccess.denied) {
      return const LibraryMessage(
        'Please grant storage/media permission to access albums.',
      );
    }

    return ref
        .watch(albumsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => LibraryMessage('Error loading albums: $e'),
          data: (albums) {
            if (albums.isEmpty) {
              return const LibraryMessage('No albums found on this device');
            }
            return LibraryGrid(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final album = albums[index];
                return LibraryCard(
                  title: album.album,
                  subtitle: album.artist ?? 'Unknown Artist',
                  artwork: SongArtwork(
                    id: album.id,
                    type: ArtworkType.ALBUM,
                    requestSize: 400,
                    placeholder: LibraryCardPlaceholder(
                      icon: Icons.album_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlbumSongsScreen(
                        album: album,
                        onNavigateToPlayer: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PlayerScreen(),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
  }
}
