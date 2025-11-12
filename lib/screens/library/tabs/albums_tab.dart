// import 'package:flutter/material.dart';

// class AlbumsTab extends StatelessWidget {
//   const AlbumsTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('Albums will appear here'));
//   }
// }

// lib/tabs/albums_tab.dart

// import 'package:flutter/material.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:noir_player/core/services/audio_handler.dart';

// class AlbumsTab extends StatefulWidget {
//   const AlbumsTab({super.key});

//   @override
//   State<AlbumsTab> createState() => _AlbumsTabState();
// }

// class _AlbumsTabState extends State<AlbumsTab> {
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   bool _permissionGranted = false;
//   int? _expandedAlbumId;
//   List<AlbumModel> _albums = [];
//   bool _isLoading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _checkAndRequestPermissions();
//   }

//   Future<void> _checkAndRequestPermissions() async {
//     final granted = await _audioQuery.checkAndRequest(retryRequest: true);
//     setState(() => _permissionGranted = granted);
//     if (granted) _loadAlbums();
//   }

//   Future<void> _loadAlbums() async {
//     try {
//       final albums = await _audioQuery.queryAlbums();
//       setState(() {
//         _albums = albums;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_permissionGranted) {
//       return const Center(
//         child: Text(
//           'Please grant storage/media permission to access albums.',
//           textAlign: TextAlign.center,
//         ),
//       );
//     }

//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_error != null) {
//       return Center(child: Text('Error loading albums: $_error'));
//     }

//     if (_albums.isEmpty) {
//       return const Center(child: Text('No albums found on this device'));
//     }

//     return ListView.builder(
//       itemCount: _albums.length,
//       itemBuilder: (context, index) {
//         final album = _albums[index];
//         final isExpanded = _expandedAlbumId == album.id;

//         return Column(
//           children: [
//             // 🎵 Album card
//             ListTile(
//               leading: QueryArtworkWidget(
//                 id: album.id,
//                 type: ArtworkType.ALBUM,
//                 artworkBorder: BorderRadius.circular(8),
//                 nullArtworkWidget: const Icon(Icons.album_rounded, size: 40),
//               ),
//               title: Text(
//                 album.album,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Text(album.artist ?? 'Unknown Artist'),
//               trailing: Icon(
//                 isExpanded
//                     ? Icons.keyboard_arrow_up
//                     : Icons.keyboard_arrow_down,
//               ),
//               onTap: () {
//                 setState(() {
//                   // toggle expansion
//                   if (mounted) {
//                     ;
//                     widget.onNavigateToPlayer();
//                   }
//                   _expandedAlbumId = isExpanded ? null : album.id;
//                 });
//               },
//             ),

//             // 🎧 Expanded song list
//             if (isExpanded)
//               FutureBuilder<List<SongModel>>(
//                 future: _audioQuery.queryAudiosFrom(
//                   AudiosFromType.ALBUM_ID,
//                   album.id,
//                 ),
//                 builder: (context, songSnapshot) {
//                   if (songSnapshot.connectionState == ConnectionState.waiting) {
//                     return const Padding(
//                       padding: EdgeInsets.all(12.0),
//                       child: Center(child: CircularProgressIndicator()),
//                     );
//                   }

//                   if (songSnapshot.hasError) {
//                     return Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Text('Error: ${songSnapshot.error}'),
//                     );
//                   }

//                   final songs = songSnapshot.data ?? [];
//                   if (songs.isEmpty) {
//                     return const Padding(
//                       padding: EdgeInsets.all(8.0),
//                       child: Text('No songs found in this album.'),
//                     );
//                   }

//                   return ListView.separated(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: songs.length,
//                     separatorBuilder: (_, __) =>
//                         const Divider(indent: 72, endIndent: 12),
//                     itemBuilder: (context, songIndex) {
//                       final song = songs[songIndex];
//                       return ListTile(
//                         leading: QueryArtworkWidget(
//                           id: song.id,
//                           type: ArtworkType.AUDIO,
//                           artworkBorder: BorderRadius.circular(6),
//                           nullArtworkWidget: const Icon(
//                             Icons.music_note,
//                             size: 32,
//                           ),
//                         ),
//                         title: Text(
//                           song.title,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         subtitle: Text(song.artist ?? 'Unknown Artist'),
//                         onTap: () async {
//                           final handler = audioHandler as AudioPlayerHandler;
//                           handler.setQueue(songs);
//                           await handler.playSongAt(songIndex);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text('▶️ Playing: ${song.title}'),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               ),

//             const Divider(thickness: 1),
//           ],
//         );
//       },
//     );
//   }
// }

// lib/tabs/albums_tab.dart
import 'package:flutter/material.dart';
import 'package:noir_player/screens/player/player_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:noir_player/core/services/audio_handler.dart'; // <-- import your AudioService handler
import '../../albums/album_songs_screen.dart'; // we'll create this next

class AlbumsTab extends StatefulWidget {
  const AlbumsTab({super.key});

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> {
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

  @override
  Widget build(BuildContext context) {
    if (!_permissionGranted) {
      return const Center(
        child: Text(
          'Please grant storage/media permission to access albums.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return FutureBuilder<List<AlbumModel>>(
      future: _audioQuery.queryAlbums(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading albums: ${snapshot.error}'));
        }

        final albums = snapshot.data ?? [];

        if (albums.isEmpty) {
          return const Center(child: Text('No albums found on this device'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];

            return GestureDetector(
              onTap: () {
                // ✅ Navigate to the album‑songs screen **and** provide the callback
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlbumSongsScreen(
                      album: album,
                      onNavigateToPlayer: () {
                        // This is executed *inside* AlbumSongsScreen before playback.
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const PlayerScreen(), // or whatever you use
                          ),
                        );
                      },
                    ),
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
                      child: QueryArtworkWidget(
                        id: album.id,
                        type: ArtworkType.ALBUM,
                        artworkFit: BoxFit.cover,
                        nullArtworkWidget: Container(
                          color: Colors.grey[850],
                          child: const Icon(
                            Icons.album_rounded,
                            size: 60,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.album,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            album.artist ?? 'Unknown Artist',
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
  }
}
