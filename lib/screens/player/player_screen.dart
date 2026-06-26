import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/services/audio_handler.dart';
import '../../core/services/settings_service.dart';
import '../../widgets/playback_menus.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // Cache the artwork future per song so it isn't re-fetched (and the image
  // re-decoded / flashed) on every rebuild — e.g. each time play/pause toggles.
  int? _artSongId;
  Future<Uint8List?>? _artFuture;

  Future<Uint8List?> _artworkFor(int songId) {
    if (_artSongId != songId || _artFuture == null) {
      _artSongId = songId;
      _artFuture = _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 800,
      );
    }
    return _artFuture!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          ListenableBuilder(
            listenable: SettingsService.instance,
            builder: (context, _) => TextButton(
              onPressed: () => showPlaybackSpeedSheet(context),
              child: Text(
                formatSpeed(SettingsService.instance.playbackSpeed),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sleep timer',
            icon: const Icon(Icons.bedtime_outlined),
            onPressed: () => showSleepTimerSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, snapshot) {
          final mediaItem = snapshot.data;

          if (mediaItem == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    size: 72,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No song is currently playing',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final songId = int.tryParse(mediaItem.id);
          final artSize = (MediaQuery.sizeOf(context).width - 96).clamp(
            180.0,
            330.0,
          );

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primary.withValues(alpha: 0.22),
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Artwork(
                              key: ValueKey(songId),
                              size: artSize,
                              future: songId != null ? _artworkFor(songId) : null,
                            ),
                            const SizedBox(height: 40),
                            _trackInfo(mediaItem, theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _controls(mediaItem, theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _trackInfo(MediaItem mediaItem, ThemeData theme) {
    return Column(
      children: [
        Text(
          mediaItem.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(fontSize: 23),
        ),
        const SizedBox(height: 8),
        Text(
          mediaItem.artist ?? 'Unknown Artist',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if ((mediaItem.album ?? '').isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            mediaItem.album!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15, curve: Curves.easeOut);
  }

  Widget _controls(MediaItem mediaItem, ThemeData theme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress slider + times
            StreamBuilder<Duration>(
              stream: (audioHandler as AudioPlayerHandler).positionStream,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final total = mediaItem.duration ?? Duration.zero;
                final maxMs = total.inMilliseconds > 0
                    ? total.inMilliseconds.toDouble()
                    : 1.0;
                final value = position.inMilliseconds
                    .clamp(0, total.inMilliseconds)
                    .toDouble();

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackShape: const RoundedRectSliderTrackShape(),
                      ),
                      child: Slider(
                        min: 0,
                        max: maxMs,
                        value: value > maxMs ? maxMs : value,
                        onChanged: (v) => (audioHandler as AudioPlayerHandler)
                            .seek(Duration(milliseconds: v.toInt())),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _formatDuration(total),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Playback buttons
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ghostButton(
                      icon: Icons.skip_previous_rounded,
                      onPressed: () =>
                          (audioHandler as AudioPlayerHandler).playPrevious(),
                    ),
                    _PlayPauseButton(
                      playing: playing,
                      color: theme.colorScheme.primary,
                      onPressed: () =>
                          playing ? audioHandler.pause() : audioHandler.play(),
                    ),
                    _ghostButton(
                      icon: Icons.skip_next_rounded,
                      onPressed: () =>
                          (audioHandler as AudioPlayerHandler).playNext(),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _ghostButton({required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      iconSize: 42,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Album art with a soft glow, cross-fading between songs, gently scaling and
/// glowing while playing.
class _Artwork extends StatelessWidget {
  const _Artwork({super.key, required this.size, required this.future});

  final double size;
  final Future<Uint8List?>? future;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return AnimatedScale(
          scale: playing ? 1.0 : 0.93,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: primary.withValues(alpha: playing ? 0.35 : 0.0),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _image(theme),
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.9, curve: Curves.easeOut);
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Icon(
        Icons.music_note,
        size: size * 0.4,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _image(ThemeData theme) {
    if (future == null) return _placeholder(theme);
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snap) {
        if (snap.hasData && snap.data != null) {
          return Image.memory(
            snap.data!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: 700,
            cacheHeight: 700,
          );
        }
        return _placeholder(theme);
      },
    );
  }
}

/// Large circular play/pause button with an animated icon swap.
class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.playing,
    required this.color,
    required this.onPressed,
  });

  final bool playing;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(playing),
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
