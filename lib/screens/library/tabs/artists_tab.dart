import 'package:flutter/material.dart';
import 'package:noir_player/screens/player/player_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../artist/artist_songs_screen.dart';

class ArtistsTab extends StatefulWidget {
  const ArtistsTab({super.key});

  @override
  State<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    final granted = await _audioQuery.checkAndRequest(retryRequest: true);
    setState(() => _permissionGranted = granted);
  }

  Future<SongModel?> _getFirstSongOfArtist(int artistId) async {
    final songs = await _audioQuery.queryAudiosFrom(
      AudiosFromType.ARTIST_ID,
      artistId,
    );
    if (songs.isNotEmpty) return songs.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_permissionGranted) {
      return Center(
        child: Text(
          'Please grant storage/media permission to access artists.',
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
      );
    }

    return FutureBuilder<List<ArtistModel>>(
      future: _audioQuery.queryArtists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading artists: ${snapshot.error}',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          );
        }

        final artists = snapshot.data ?? [];
        if (artists.isEmpty) {
          return Center(
            child: Text(
              'No artists found on this device',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: FutureBuilder<SongModel?>(
                future: _getFirstSongOfArtist(artist.id),
                builder: (context, songSnapshot) {
                  final song = songSnapshot.data;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArtistSongsScreen(
                            artist: artist,
                            onNavigateToPlayer: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PlayerScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          song != null
                              ? QueryArtworkWidget(
                                  id: song.id,
                                  type: ArtworkType.AUDIO,
                                  artworkFit: BoxFit.cover,
                                  nullArtworkWidget: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isDark
                                            ? [
                                                Colors.grey[850]!,
                                                Colors.grey[900]!,
                                              ]
                                            : [
                                                Colors.grey[300]!,
                                                Colors.grey[400]!,
                                              ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        size: 80,
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black26,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isDark
                                          ? [
                                              Colors.grey[850]!,
                                              Colors.grey[900]!,
                                            ]
                                          : [
                                              Colors.grey[300]!,
                                              Colors.grey[400]!,
                                            ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 80,
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black26,
                                    ),
                                  ),
                                ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                    Colors.black.withOpacity(0.85),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    artist.artist,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${artist.numberOfAlbums ?? 0} albums • ${artist.numberOfTracks ?? 0} songs',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
