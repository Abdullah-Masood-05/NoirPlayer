// // lib/screens/album_songs_screen.dart
// import 'package:flutter/material.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:noir_player/core/services/audio_handler.dart'; // your global audio handler instance

// class AlbumSongsScreen extends StatefulWidget {
//   final AlbumModel album;
//   const AlbumSongsScreen({super.key, required this.album});

//   @override
//   State<AlbumSongsScreen> createState() => _AlbumSongsScreenState();
// }

// class _AlbumSongsScreenState extends State<AlbumSongsScreen> {
//   final OnAudioQuery _audioQuery = OnAudioQuery();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.album.album)),
//       body: FutureBuilder<List<SongModel>>(
//         future: _audioQuery.queryAudiosFrom(
//           AudiosFromType.ALBUM_ID,
//           widget.album.id,
//         ),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(
//               child: Text('Error loading songs: ${snapshot.error}'),
//             );
//           }

//           final songs = snapshot.data ?? [];
//           if (songs.isEmpty) {
//             return const Center(child: Text('No songs found in this album.'));
//           }

//           return ListView.builder(
//             itemCount: songs.length,
//             itemBuilder: (context, index) {
//               final song = songs[index];
//               return ListTile(
//                 leading: QueryArtworkWidget(
//                   id: song.id,
//                   type: ArtworkType.AUDIO,
//                   artworkBorder: BorderRadius.circular(8),
//                   nullArtworkWidget: const Icon(Icons.music_note),
//                 ),
//                 title: Text(
//                   song.title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 subtitle: Text(song.artist ?? 'Unknown Artist'),
//                 onTap: () async {
//                   // ✅ Play the tapped song using your global handler
//                   final handler = audioHandler as AudioPlayerHandler;
//                           handler.setQueue(songs);
//                           await handler.playSongAt(index);
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('▶️ Playing: ${song.title}')),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// lib/screens/album_songs_screen.dart
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:noir_player/core/services/audio_handler.dart'; // your global audio handler instance

class AlbumSongsScreen extends StatefulWidget {
  final AlbumModel album;

  /// Callback that should navigate to the player UI.
  final VoidCallback onNavigateToPlayer;

  const AlbumSongsScreen({
    super.key,
    required this.album,
    required this.onNavigateToPlayer, // <-- new
  });

  @override
  State<AlbumSongsScreen> createState() => _AlbumSongsScreenState();
}

class _AlbumSongsScreenState extends State<AlbumSongsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.album.album)),
      body: FutureBuilder<List<SongModel>>(
        future: _audioQuery.queryAudiosFrom(
          AudiosFromType.ALBUM_ID,
          widget.album.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading songs: ${snapshot.error}'),
            );
          }

          final songs = snapshot.data ?? [];
          if (songs.isEmpty) {
            return const Center(child: Text('No songs found in this album.'));
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.circular(8),
                  nullArtworkWidget: const Icon(Icons.music_note),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(song.artist ?? 'Unknown Artist'),
                onTap: () async {
                  // 1️⃣ Navigate to the player screen first
                  widget.onNavigateToPlayer();

                  // 2️⃣ (Optional) Make sure AudioService is ready
                  if (!isAudioServiceInitialized()) {
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

                  // 3️⃣ Sync the queue & play the tapped song
                  final handler = audioHandler as AudioPlayerHandler;
                  handler.setQueue(songs); // keep queue up‑to‑date
                  await handler.playSongAt(index); // start playback

                  // 4️⃣ Optional UX feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('▶️ Playing: ${song.title}')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
