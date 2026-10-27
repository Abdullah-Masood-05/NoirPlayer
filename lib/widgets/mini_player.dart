import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/state/playback.dart';
import 'song_artwork.dart';

/// Compact now-playing bar shown above the navigation bar. Tapping it opens the
/// full player. Hidden when nothing is loaded.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref.watch(mediaItemProvider).value;
    if (mediaItem == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Progress(total: mediaItem.duration, color: primary),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  _artwork(mediaItem, primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mediaItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          mediaItem.artist ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const _Buttons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artwork(MediaItem mediaItem, Color primary) {
    final placeholder = _placeholder(primary);
    final artUri = mediaItem.artUri;
    final Widget image;
    if (artUri != null &&
        (artUri.isScheme('http') || artUri.isScheme('https'))) {
      image = RemoteArtwork(
        url: artUri.toString(),
        size: 46,
        placeholder: placeholder,
      );
    } else {
      final songId = int.tryParse(mediaItem.id);
      image = songId == null
          ? placeholder
          : SongArtwork(id: songId, size: 46, placeholder: placeholder);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: 46, height: 46, child: image),
    );
  }

  Widget _placeholder(Color primary) => Container(
    color: primary.withValues(alpha: 0.12),
    child: Icon(Icons.music_note, color: primary),
  );
}

/// Thin progress line; the only part of the bar that follows the position.
class _Progress extends ConsumerWidget {
  const _Progress({required this.total, required this.color});

  final Duration? total;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final totalMs = total?.inMilliseconds ?? 0;
    final value = totalMs > 0
        ? (pos.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;
    return LinearProgressIndicator(
      value: value,
      minHeight: 2.5,
      backgroundColor: color.withValues(alpha: 0.15),
    );
  }
}

/// Play/pause and next; rebuilds only when playing / paused flips.
class _Buttons extends ConsumerWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(isPlayingProvider);
    final handler = ref.watch(audioHandlerProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              key: ValueKey(playing),
              size: 30,
            ),
          ),
          onPressed: handler == null
              ? null
              : () => playing ? handler.pause() : handler.play(),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 30),
          onPressed: handler?.playNext,
        ),
      ],
    );
  }
}
