// // import 'package:flutter/material.dart';

// // class PlayerScreen extends StatelessWidget {
// //   const PlayerScreen({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return const Center(
// //       child: Text('Player Screen'),
// //     );
// //   }
// // }
// // lib/screens/player/player_screen.dart

// import 'package:flutter/material.dart';
// import 'package:audio_service/audio_service.dart';
// import '../../core/services/audio_handler.dart';

// class PlayerScreen extends StatefulWidget {
//   const PlayerScreen({super.key});

//   @override
//   State<PlayerScreen> createState() => _PlayerScreenState();
// }

// class _PlayerScreenState extends State<PlayerScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: StreamBuilder<MediaItem?>(
//         stream: audioHandler.mediaItem, // ✅ Correct stream
//         builder: (context, snapshot) {
//           final mediaItem = snapshot.data;

//           if (mediaItem == null) {
//             return const Center(
//               child: Text(
//                 'No song is currently playing',
//                 style: TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//             );
//           }

//           return Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // 🎵 Album Art Placeholder
//                 Container(
//                   width: 220,
//                   height: 220,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[800],
//                     borderRadius: BorderRadius.circular(16),
//                     image: mediaItem.artUri != null
//                         ? DecorationImage(
//                             image: NetworkImage(mediaItem.artUri.toString()),
//                             fit: BoxFit.cover,
//                           )
//                         : null,
//                   ),
//                   child: mediaItem.artUri == null
//                       ? const Icon(
//                           Icons.music_note,
//                           size: 80,
//                           color: Colors.white54,
//                         )
//                       : null,
//                 ),
//                 const SizedBox(height: 40),

//                 // 🎵 Song Title
//                 Text(
//                   mediaItem.title,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 10),

//                 // 👤 Artist
//                 Text(
//                   mediaItem.artist ?? 'Unknown Artist',
//                   style: const TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 5),

//                 // 💿 Album
//                 Text(
//                   mediaItem.album ?? 'Unknown Album',
//                   style: const TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:just_audio/just_audio.dart';
// import '../../core/services/audio_handler.dart';

// class PlayerScreen extends StatefulWidget {
//   const PlayerScreen({super.key});

//   @override
//   State<PlayerScreen> createState() => _PlayerScreenState();
// }

// class _PlayerScreenState extends State<PlayerScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text('Now Playing'),
//         backgroundColor: Colors.black,
//       ),
//       body: Center(
//         child: StreamBuilder<PlayerState>(
//           stream: audioHandler.playerStateStream,
//           builder: (context, snapshot) {
//             final state = snapshot.data;

//             if (state == null || !state.playing) {
//               return const Text('No song playing',
//                   style: TextStyle(color: Colors.white));
//             }

//             // For now, just show placeholder metadata
//             return const Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text("Title: Song Title", style: TextStyle(color: Colors.white)),
//                 SizedBox(height: 8),
//                 Text("Artist: Unknown", style: TextStyle(color: Colors.white)),
//                 SizedBox(height: 8),
//                 Text("Album: Unknown", style: TextStyle(color: Colors.white)),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// extension on AudioHandler {
//   Stream<PlayerState>? get playerStateStream => null;
// }

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; // For audio playback
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:typed_data';
import '../../core/services/audio_handler.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  Future<Uint8List?> _loadArtwork(int songId) async {
    return await _audioQuery.queryArtwork(
      songId,
      ArtworkType.AUDIO,
      format: ArtworkFormat.JPEG,
      size: 800, // Request a large image
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;

          if (mediaItem == null) {
            return const Center(
              child: Text(
                'No song is currently playing',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final songId = int.tryParse(mediaItem.id);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🎵 Album Art
                if (songId != null)
                  FutureBuilder<Uint8List?>(
                    future: _loadArtwork(songId),
                    builder: (context, artSnapshot) {
                      if (artSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (artSnapshot.hasData && artSnapshot.data != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            artSnapshot.data!,
                            width: 300,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      // Fallback if no artwork
                      return Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          size: 100,
                          color: Colors.white54,
                        ),
                      );
                    },
                  )
                else
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 100,
                      color: Colors.white54,
                    ),
                  ),
                const SizedBox(height: 40),

                // 🎵 Song Title
                Text(
                  mediaItem.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // 👤 Artist
                Text(
                  mediaItem.artist ?? 'Unknown Artist',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 5),

                // 💿 Album
                Text(
                  mediaItem.album ?? 'Unknown Album',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // ⏯️ Playback State
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (context, snapshot) {
                    final playbackState = snapshot.data;
                    final playing = playbackState?.playing ?? false;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous, size: 40),
                          color: Colors.white,
                          onPressed: () {
                            // TODO: Implement previous song
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            playing ? Icons.pause : Icons.play_arrow,
                            size: 64,
                          ),
                          color: Colors.white,
                          onPressed: () {
                            if (playing) {
                              audioHandler.pause();
                            } else {
                              audioHandler.play();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next, size: 40),
                          color: Colors.white,
                          onPressed: () {
                            // TODO: Implement next song
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import '../../core/services/audio_handler.dart';

// class PlayerScreen extends StatefulWidget {
//   const PlayerScreen({super.key});

//   @override
//   State<PlayerScreen> createState() => _PlayerScreenState();
// }

// class _PlayerScreenState extends State<PlayerScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text('Now Playing'),
//         backgroundColor: Colors.black,
//         actions: [
//           // Back button to navigate to the previous screen
//           IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () {
//               Navigator.pop(context); // Pops this screen from the stack
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder<MediaItem?>(
//         stream: audioHandler.mediaItem,
//         builder: (context, snapshot) {
//           final mediaItem = snapshot.data;

//           if (mediaItem == null) {
//             return const Center(
//               child: Text(
//                 'No song is currently playing',
//                 style: TextStyle(fontSize: 18, color: Colors.grey),
//               ),
//             );
//           }

//           // ✅ Parse song ID from MediaItem
//           final songId = int.tryParse(mediaItem.id);

//           return Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // 🎵 Album Art using QueryArtworkWidget
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(16),
//                   child: songId != null
                      // ? QueryArtworkWidget(
                      //     id: songId,
                      //     type: ArtworkType.AUDIO,
                      //     size: 220,
                      //     quality: 100,
                      //     artworkBorder: BorderRadius.circular(16),
                      //     nullArtworkWidget: Container(
                      //       width: 220,
                      //       height: 100,
                      //       decoration: BoxDecoration(
                      //         color: Colors.grey[800],
                      //         borderRadius: BorderRadius.circular(16),
                      //       ),
                      //       child: const Icon(
                      //         Icons.music_note,
                      //         size: 180,
                      //         color: Colors.white54,
                      //       ),
                      //     ),
                      //   )
//                       : Container(
//                           width: 220,
//                           height: 100,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[800],
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: const Icon(
//                             Icons.music_note,
//                             size: 80,
//                             color: Colors.white54,
//                           ),
//                         ),
//                 ),
//                 const SizedBox(height: 80),

//                 // 🎵 Song Title
//                 Text(
//                   mediaItem.title,
//                   textAlign: TextAlign.center,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 10),

//                 // 👤 Artist
//                 Text(
//                   mediaItem.artist ?? 'Unknown Artist',
//                   textAlign: TextAlign.center,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 5),

//                 // 💿 Album
//                 Text(
//                   mediaItem.album ?? 'Unknown Album',
//                   textAlign: TextAlign.center,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(fontSize: 14, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 40),

//                 // ⏯️ Playback State
//                 StreamBuilder<PlaybackState>(
//                   stream: audioHandler.playbackState,
//                   builder: (context, snapshot) {
//                     final playbackState = snapshot.data;
//                     final playing = playbackState?.playing ?? false;

//                     return Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.skip_previous, size: 40),
//                           color: Colors.white,
//                           onPressed: () {
//                             // TODO: Implement previous song
//                           },
//                         ),
//                         IconButton(
//                           icon: Icon(
//                             playing ? Icons.pause : Icons.play_arrow,
//                             size: 64,
//                           ),
//                           color: Colors.white,
//                           onPressed: () {
//                             if (playing) {
//                               audioHandler.pause();
//                             } else {
//                               audioHandler.play();
//                             }
//                           },
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.skip_next, size: 40),
//                           color: Colors.white,
//                           onPressed: () {
//                             // TODO: Implement next song
//                           },
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
