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
    // Get theme colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor,
      ),
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;

          if (mediaItem == null) {
            return Center(
              child: Text(
                'No song is currently playing',
                style: TextStyle(
                  fontSize: 18,
                  color:
                      theme.textTheme.bodyMedium?.color ??
                      Colors.grey, 
                ),
              ),
            );
          }

          final songId = int.tryParse(mediaItem.id);

          return Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
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
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[300], 
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
                                  color: isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[300], 
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  size: 100,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black45, 
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.music_note,
                              size: 100,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black45, 
                            ),
                          ),

                        const SizedBox(height: 30),

                        // 🎵 Song Info
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              Text(
                                mediaItem.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: theme
                                      .textTheme
                                      .titleLarge
                                      ?.color, 
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                mediaItem.artist ?? 'Unknown Artist',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme
                                      .textTheme
                                      .bodyMedium
                                      ?.color, // ✅ Use theme text color
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                mediaItem.album ?? 'Unknown Album',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme
                                      .textTheme
                                      .bodyMedium
                                      ?.color, // ✅ Use theme text color
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Controls area
                SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  bottom: true,
                  child: Container(
                    color:
                        theme.scaffoldBackgroundColor, 
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Slider + time
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
                                    activeColor: theme
                                        .colorScheme
                                        .primary, // ✅ Use theme primary color
                                    inactiveColor: isDark
                                        ? Colors.grey[700]
                                        : Colors.grey[400], // ✅ Adapt to theme
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
                                        style: TextStyle(
                                          color: theme
                                              .textTheme
                                              .bodyMedium
                                              ?.color, // ✅ Use theme text color
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(total),
                                        style: TextStyle(
                                          color: theme
                                              .textTheme
                                              .bodyMedium
                                              ?.color, // ✅ Use theme text color
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

                        // Playback buttons
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
                                    color: theme
                                        .iconTheme
                                        .color, // ✅ Use theme icon color
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
                                    color: theme
                                        .iconTheme
                                        .color, // ✅ Use theme icon color
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
                                    color: theme
                                        .iconTheme
                                        .color, // ✅ Use theme icon color
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
