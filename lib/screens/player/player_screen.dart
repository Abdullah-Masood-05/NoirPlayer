// import 'package:flutter/material.dart';

// class PlayerScreen extends StatelessWidget {
//   const PlayerScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text('Player Screen'),
//     );
//   }
// }
// lib/screens/player/player_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../../core/services/audio_handler.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/services/audio_handler.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  Stream<Duration> get _positionStream =>
      audioHandler.playbackState.map((ps) => ps.position);

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  // combine mediaItem + playbackState streams for easier UI
  Stream<CombinedState> get _combinedStateStream =>
      Rx.combineLatest2<MediaItem?, PlaybackState, CombinedState>(
        audioHandler.mediaItem,
        audioHandler.playbackState,
        (mediaItem, playbackState) => CombinedState(mediaItem, playbackState),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CombinedState>(
      stream: _combinedStateStream,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final mediaItem = data?.mediaItem;
        final playbackState = data?.playbackState;

        final duration = mediaItem?.duration ?? Duration.zero;
        final position = playbackState?.position ?? Duration.zero;
        final playing = playbackState?.playing ?? false;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // App bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Text(
                      "Now Playing",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Rotating album art
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2.0 * math.pi,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(140),
                            child: mediaItem?.artUri != null
                                ? Image.network(
                                    mediaItem!.artUri! as String,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    child: const Icon(
                                      Icons.music_note,
                                      size: 120,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Metadata
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Text(
                        mediaItem?.title ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mediaItem?.artist ?? 'Unknown Artist',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Seek bar
                if (duration > Duration.zero)
                  Column(
                    children: [
                      StreamBuilder<PlaybackState>(
                        stream: audioHandler.playbackState,
                        builder: (context, snap) {
                          final state = snap.data;
                          final pos = state?.position ?? Duration.zero;
                          return Slider(
                            min: 0,
                            max: duration.inMilliseconds.toDouble(),
                            value: pos.inMilliseconds
                                .clamp(0, duration.inMilliseconds)
                                .toDouble(),
                            onChanged: (value) {
                              audioHandler.seek(
                                Duration(milliseconds: value.round()),
                              );
                            },
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(position)),
                            Text(_formatDuration(duration)),
                          ],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 10),

                // Controls (shuffle / prev / play / next / repeat)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle),
                        onPressed: () async {
                          final enabled =
                              (await audioHandler.playbackState.first)
                                  .shuffleMode ==
                              AudioServiceShuffleMode.all;
                          audioHandler.setShuffleMode(
                            enabled
                                ? AudioServiceShuffleMode.none
                                : AudioServiceShuffleMode.all,
                          );
                        },
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.skip_previous),
                        onPressed: () => audioHandler.skipToPrevious(),
                      ),
                      FloatingActionButton(
                        onPressed: () => playing
                            ? audioHandler.pause()
                            : audioHandler.play(),
                        child: Icon(playing ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.skip_next),
                        onPressed: () => audioHandler.skipToNext(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat),
                        onPressed: () async {
                          final current =
                              (await audioHandler.playbackState.first)
                                  .repeatMode;
                          final next = current == AudioServiceRepeatMode.none
                              ? AudioServiceRepeatMode.all
                              : current == AudioServiceRepeatMode.all
                              ? AudioServiceRepeatMode.one
                              : AudioServiceRepeatMode.none;
                          audioHandler.setRepeatMode(next);
                        },
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
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Helper combined state class
class CombinedState {
  final MediaItem? mediaItem;
  final PlaybackState playbackState;

  CombinedState(this.mediaItem, this.playbackState);
}
