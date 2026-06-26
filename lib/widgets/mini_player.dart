import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../core/services/audio_handler.dart';

/// Compact now-playing bar shown above the navigation bar. Tapping it opens the
/// full player. Hidden when nothing is loaded.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final mediaItem = snapshot.data;
        if (mediaItem == null) return const SizedBox.shrink();
        final songId = int.tryParse(mediaItem.id);

        return Material(
          color: theme.colorScheme.surface,
          elevation: 8,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<Duration>(
                  stream: (audioHandler as AudioPlayerHandler).positionStream,
                  builder: (context, posSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    final total = mediaItem.duration ?? Duration.zero;
                    final value = total.inMilliseconds > 0
                        ? (pos.inMilliseconds / total.inMilliseconds).clamp(
                            0.0,
                            1.0,
                          )
                        : 0.0;
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 2.5,
                      backgroundColor: primary.withValues(alpha: 0.15),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: _artwork(mediaItem, songId, primary),
                        ),
                      ),
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
                      StreamBuilder<PlaybackState>(
                        stream: audioHandler.playbackState,
                        builder: (context, stateSnap) {
                          final playing = stateSnap.data?.playing ?? false;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(scale: anim, child: child),
                                  child: Icon(
                                    playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    key: ValueKey(playing),
                                    size: 30,
                                  ),
                                ),
                                onPressed: () => playing
                                    ? audioHandler.pause()
                                    : audioHandler.play(),
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded, size: 30),
                                onPressed: () =>
                                    (audioHandler as AudioPlayerHandler)
                                        .playNext(),
                              ),
                            ],
                          );
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

  Widget _artwork(MediaItem mediaItem, int? songId, Color primary) {
    final artUri = mediaItem.artUri;
    if (artUri != null &&
        (artUri.isScheme('http') || artUri.isScheme('https'))) {
      return Image.network(
        artUri.toString(),
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _placeholder(primary),
      );
    }
    return QueryArtworkWidget(
      id: songId ?? -1,
      type: ArtworkType.AUDIO,
      keepOldArtwork: true,
      artworkBorder: BorderRadius.circular(10),
      artworkWidth: 46,
      artworkHeight: 46,
      artworkFit: BoxFit.cover,
      nullArtworkWidget: _placeholder(primary),
    );
  }

  Widget _placeholder(Color primary) => Container(
    color: primary.withValues(alpha: 0.12),
    child: Icon(Icons.music_note, color: primary),
  );
}
