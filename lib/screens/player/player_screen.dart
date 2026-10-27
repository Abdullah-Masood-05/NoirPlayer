import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;

import '../../core/state/playback.dart';
import '../../core/state/settings.dart';
import '../../widgets/seek_button.dart';
import '../../widgets/song_artwork.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final mediaItem = ref.watch(mediaItemProvider).value;

    final background = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primary.withValues(alpha: 0.28),
          theme.scaffoldBackgroundColor,
          theme.scaffoldBackgroundColor,
        ],
        stops: const [0.0, 0.55, 1.0],
      ),
    );

    if (mediaItem == null) {
      return Container(
        decoration: background,
        child: Center(
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
        ),
      );
    }

    final artSize = (MediaQuery.sizeOf(context).width - 96).clamp(180.0, 330.0);

    return Container(
      decoration: background,
      child: SafeArea(
        child: Column(
          children: [
            // Clear the transparent app bar that the home shell draws over
            // this gradient.
            const SizedBox(height: kToolbarHeight),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Artwork(
                        key: ValueKey(mediaItem.id),
                        size: artSize,
                        mediaItem: mediaItem,
                      ),
                      const SizedBox(height: 40),
                      _TrackInfo(mediaItem: mediaItem),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SeekBar(fallbackDuration: mediaItem.duration),
                    const SizedBox(height: 8),
                    const _TransportRow(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [_ShuffleButton(), _RepeatButton()],
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
  }
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo({required this.mediaItem});

  final MediaItem mediaItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.15, curve: Curves.easeOut);
  }
}

/// Progress slider + times. The total comes from just_audio's live duration
/// (falling back to the MediaItem) so streamed tracks work; seeking is
/// disabled until the duration is known to avoid accidental restarts.
class _SeekBar extends ConsumerWidget {
  const _SeekBar({required this.fallbackDuration});

  final Duration? fallbackDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final handler = ref.watch(audioHandlerProvider);
    final total =
        ref.watch(durationProvider).value ?? fallbackDuration ?? Duration.zero;
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final totalMs = total.inMilliseconds;
    final hasDuration = totalMs > 0;
    final value = hasDuration
        ? position.inMilliseconds.clamp(0, totalMs).toDouble()
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(
            context,
          ).copyWith(trackShape: const RoundedRectSliderTrackShape()),
          child: Slider(
            min: 0,
            max: hasDuration ? totalMs.toDouble() : 1.0,
            value: value,
            onChanged: hasDuration && handler != null
                ? (v) => handler.seek(Duration(milliseconds: v.toInt()))
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position), style: theme.textTheme.bodySmall),
              Text(
                hasDuration ? _formatDuration(total) : '--:--',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Back N s · prev · play/pause · next · forward N s
class _TransportRow extends ConsumerWidget {
  const _TransportRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final handler = ref.watch(audioHandlerProvider);
    final playing = ref.watch(isPlayingProvider);
    final seekSeconds = ref.watch(
      settingsProvider.select((s) => s.seekIntervalSeconds),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SeekButton(
          seconds: seekSeconds,
          forward: false,
          onPressed: () => handler?.rewind(),
        ),
        IconButton(
          iconSize: 40,
          onPressed: handler?.playPrevious,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        _PlayPauseButton(
          playing: playing,
          color: theme.colorScheme.primary,
          onPressed: () => playing ? handler?.pause() : handler?.play(),
        ),
        IconButton(
          iconSize: 40,
          onPressed: handler?.playNext,
          icon: const Icon(Icons.skip_next_rounded),
        ),
        SeekButton(
          seconds: seekSeconds,
          forward: true,
          onPressed: () => handler?.fastForward(),
        ),
      ],
    );
  }
}

class _ShuffleButton extends ConsumerWidget {
  const _ShuffleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final on = ref.watch(shuffleEnabledProvider).value ?? false;
    return IconButton(
      iconSize: 24,
      tooltip: 'Shuffle',
      onPressed: ref.watch(audioHandlerProvider)?.toggleShuffle,
      icon: Icon(
        Icons.shuffle_rounded,
        color: on
            ? theme.colorScheme.primary
            : theme.iconTheme.color?.withValues(alpha: 0.5),
      ),
    );
  }
}

class _RepeatButton extends ConsumerWidget {
  const _RepeatButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(loopModeProvider).value ?? LoopMode.all;
    return IconButton(
      iconSize: 24,
      tooltip: switch (mode) {
        LoopMode.off => 'Repeat off',
        LoopMode.one => 'Repeat one',
        LoopMode.all => 'Repeat all',
      },
      onPressed: ref.watch(audioHandlerProvider)?.cycleRepeatMode,
      icon: Icon(
        mode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
        color: mode == LoopMode.off
            ? theme.iconTheme.color?.withValues(alpha: 0.5)
            : theme.colorScheme.primary,
      ),
    );
  }
}

/// Album art with a soft glow, cross-fading between songs, gently scaling and
/// glowing while playing.
class _Artwork extends ConsumerWidget {
  const _Artwork({super.key, required this.size, required this.mediaItem});

  final double size;
  final MediaItem mediaItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final playing = ref.watch(isPlayingProvider);

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
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scaleXY(begin: 0.9, curve: Curves.easeOut);
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
    // Remote artwork (e.g. Discover tracks).
    final uri = mediaItem.artUri;
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      return RemoteArtwork(
        url: uri.toString(),
        size: size,
        placeholder: _placeholder(theme),
      );
    }
    final songId = int.tryParse(mediaItem.id);
    if (songId == null) return _placeholder(theme);
    return SongArtwork(
      id: songId,
      size: size,
      requestSize: 800,
      placeholder: _placeholder(theme),
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
        width: 76,
        height: 76,
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
