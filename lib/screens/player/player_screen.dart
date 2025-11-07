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
      size: 800,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use Scaffold so bottom nav (if present) occupies space; we anchor controls above SafeArea
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // title: const Text('Now Playing'),
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

          // Main layout: content above + fixed controls area at bottom (inside SafeArea)
          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Expanded content area - artwork + title/artist/album.
                // This area can grow/shrink based on text size but WILL NOT push the controls.
                Expanded(
                  child: SingleChildScrollView(
                    // allows long titles/metadata to wrap/scroll without shifting controls
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // 🎵 Album Art
                        if (songId != null)
                          FutureBuilder<Uint8List?>(
                            future: _loadArtwork(songId),
                            builder: (context, artSnapshot) {
                              if (artSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (artSnapshot.hasData &&
                                  artSnapshot.data != null) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    artSnapshot.data!,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              return Container(
                                width: 200,
                                height: 200,
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
                            width: 200,
                            height: 200,
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

                        const SizedBox(height: 30),

                        // 🎵 Song Info (Title, Artist, Album). Allow wrapping and center alignment.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              Text(
                                mediaItem.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                mediaItem.artist ?? 'Unknown Artist',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                mediaItem.album ?? 'Unknown Album',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Give a little breathing room so Expanded content doesn't stick to controls
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // -----------------------
                // Controls container anchored at the bottom (above bottom nav).
                // Wrapped with SafeArea to stay above system/bottom nav bars.
                // -----------------------
                SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  bottom: true,
                  child: Container(
                    // give a bit of elevation-like look via color difference if needed
                    // but keep transparent so it blends with black app background
                    color: Colors.black,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Slider + time row, padded so times align with slider edges
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: StreamBuilder<Duration>(
                            stream: (audioHandler as AudioPlayerHandler)
                                .positionStream,
                            builder: (context, positionSnapshot) {
                              final position =
                                  positionSnapshot.data ?? Duration.zero;
                              final total = mediaItem.duration ?? Duration.zero;
                              final maxMs = total.inMilliseconds > 0
                                  ? total.inMilliseconds.toDouble()
                                  : 1.0;
                              final value = position.inMilliseconds
                                  .clamp(0, total.inMilliseconds)
                                  .toDouble();

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Slider(
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.grey[700],
                                    min: 0.0,
                                    max: maxMs,
                                    value: value > maxMs ? maxMs : value,
                                    onChanged: (v) {
                                      (audioHandler as AudioPlayerHandler).seek(
                                        Duration(milliseconds: v.toInt()),
                                      );
                                    },
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(total),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                        ),

                        // Playback buttons (centered) with fixed vertical padding
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12.0,
                            right: 12.0,
                            bottom: 8.0,
                            top: 1.0,
                          ),
                          child: StreamBuilder<PlaybackState>(
                            stream: audioHandler.playbackState,
                            builder: (context, snapshot) {
                              final playbackState = snapshot.data;
                              final playing = playbackState?.playing ?? false;

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_previous,
                                      size: 40,
                                    ),
                                    color: Colors.white,
                                    onPressed: () async {
                                      await (audioHandler as AudioPlayerHandler)
                                          .playPrevious();
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
                                    onPressed: () async {
                                      await (audioHandler as AudioPlayerHandler)
                                          .playNext();
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
