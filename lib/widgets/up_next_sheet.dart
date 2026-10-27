import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/audio_handler.dart' show UpNext;
import '../core/state/playback.dart';
import 'now_playing_indicator.dart';
import 'song_artwork.dart';

/// Bottom sheet listing the queue in play order (shuffled when shuffle is
/// on). Opens scrolled to the playing song; tapping a song plays it.
Future<void> showUpNextSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _UpNextSheet(),
  );
}

class _UpNextSheet extends ConsumerStatefulWidget {
  const _UpNextSheet();

  @override
  ConsumerState<_UpNextSheet> createState() => _UpNextSheetState();
}

class _UpNextSheetState extends ConsumerState<_UpNextSheet> {
  static const double _rowHeight = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upNext = ref.watch(upNextProvider).value ?? UpNext.empty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Up next', style: theme.textTheme.titleLarge),
                  ),
                  if (upNext.items.isNotEmpty)
                    Text(
                      '${upNext.currentPosition + 1} of ${upNext.items.length}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Expanded(
              child: upNext.items.isEmpty
                  ? Center(
                      child: Text(
                        'Nothing queued',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : _list(theme, upNext, scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _list(
    ThemeData theme,
    UpNext upNext,
    ScrollController scrollController,
  ) {
    // Start with the playing song near the top.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrolled && scrollController.hasClients) {
        _scrolled = true;
        final target =
            (upNext.currentPosition - 1).clamp(0, upNext.items.length) *
            _rowHeight;
        scrollController.jumpTo(
          target.clamp(0.0, scrollController.position.maxScrollExtent),
        );
      }
    });

    return ListView.builder(
      controller: scrollController,
      itemExtent: _rowHeight,
      itemCount: upNext.items.length,
      itemBuilder: (context, position) {
        final item = upNext.items[position];
        final isCurrent = position == upNext.currentPosition;
        final songId = int.tryParse(item.id);
        final placeholder = Container(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.music_note, color: theme.colorScheme.primary),
        );
        return ListTile(
          key: ValueKey('${upNext.queueIndices[position]}-${item.id}'),
          selected: isCurrent,
          selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          leading: songId == null
              ? SizedBox(width: 44, height: 44, child: placeholder)
              : SongArtwork(
                  id: songId,
                  size: 44,
                  borderRadius: BorderRadius.circular(8),
                  placeholder: placeholder,
                ),
          title: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: isCurrent
                ? TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  )
                : null,
          ),
          subtitle: Text(
            item.artist ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isCurrent
              ? NowPlayingIndicator(color: theme.colorScheme.primary, size: 18)
              : null,
          onTap: isCurrent
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(audioHandlerProvider)
                      ?.skipToQueueItem(upNext.queueIndices[position]);
                },
        );
      },
    );
  }

  bool _scrolled = false;
}
