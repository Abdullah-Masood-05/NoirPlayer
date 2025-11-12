// import 'package:flutter/material.dart';

// class ArtistsTab extends StatelessWidget {
//   const ArtistsTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('Artists will appear here'));
//   }
// }

import 'package:flutter/material.dart';
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
    if (!_permissionGranted) {
      return const Center(
        child: Text(
          'Please grant storage/media permission to access artists.',
          textAlign: TextAlign.center,
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
          return Center(child: Text('Error loading artists: ${snapshot.error}'));
        }

        final artists = snapshot.data ?? [];
        if (artists.isEmpty) {
          return const Center(child: Text('No artists found on this device'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];

            return FutureBuilder<SongModel?>(
              future: _getFirstSongOfArtist(artist.id),
              builder: (context, songSnapshot) {
                final song = songSnapshot.data;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtistSongsScreen(artist: artist),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: song != null
                              ? QueryArtworkWidget(
                                  id: song.id,
                                  type: ArtworkType.AUDIO,
                                  artworkFit: BoxFit.cover,
                                  nullArtworkWidget: Container(
                                    color: Colors.grey[850],
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 60,
                                      color: Colors.white54,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[850],
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 60,
                                    color: Colors.white54,
                                  ),
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artist.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${artist.numberOfAlbums ?? 0} albums • ${artist.numberOfTracks ?? 0} songs',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
