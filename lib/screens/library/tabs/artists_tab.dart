import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/library.dart';
import '../../../widgets/library_grid.dart';
import '../../../widgets/song_artwork.dart';
import '../../artist/artist_songs_screen.dart';
import '../../player/player_screen.dart';

class ArtistsTab extends ConsumerStatefulWidget {
  const ArtistsTab({super.key});

  @override
  ConsumerState<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends ConsumerState<ArtistsTab>
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
        'Please grant storage/media permission to access artists.',
      );
    }

    // Each artist's cover is one of their songs' artwork, taken from the
    // song list the Library already loaded.
    final covers = ref.watch(artistCoverSongIdsProvider);

    return ref
        .watch(artistsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => LibraryMessage('Error loading artists: $e'),
          data: (artists) {
            if (artists.isEmpty) {
              return const LibraryMessage('No artists found on this device');
            }
            return LibraryGrid(
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                final placeholder = LibraryCardPlaceholder(
                  icon: Icons.person_rounded,
                  color: theme.colorScheme.primary,
                );
                final coverId = covers[artist.id];
                return LibraryCard(
                  title: artist.artist,
                  subtitle:
                      '${artist.numberOfAlbums ?? 0} albums • ${artist.numberOfTracks ?? 0} songs',
                  artwork: coverId == null
                      ? placeholder
                      : SongArtwork(
                          id: coverId,
                          requestSize: 400,
                          placeholder: placeholder,
                        ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistSongsScreen(
                        artist: artist,
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
