import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;

import '../../../core/models/playlist_model.dart';
import '../../../core/state/library.dart';
import '../../../core/state/playback.dart';
import '../../../core/state/playlists.dart';
import '../../../widgets/now_playing_indicator.dart';
import '../../../widgets/song_artwork.dart';

class SongsTab extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToPlayer;

  /// When true, only show audios from the selected music folder.
  final bool musicFolderOnly;

  const SongsTab({
    super.key,
    required this.onNavigateToPlayer,
    this.musicFolderOnly = false,
  });

  @override
  ConsumerState<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends ConsumerState<SongsTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchText = '';

  // The last filter result, reused until the songs or the query change.
  List<SongModel>? _filterSource;
  String? _filterQuery;
  List<SongModel> _filtered = const [];

  // Lower-cased "title\nartist" per song id, built once per song list.
  final Map<int, String> _searchKeys = {};

  // The last grouped layout, reused until the filtered list changes.
  List<SongModel>? _groupSource;
  _GroupedSongs _grouped = const _GroupedSongs([], []);

  /// The Music tab lists songs under A–Z headings with row numbers.
  bool get _groupByLetter => widget.musicFolderOnly;

  _GroupedSongs _group(List<SongModel> songs) {
    if (!identical(songs, _groupSource)) {
      _groupSource = songs;
      _grouped = _GroupedSongs.of(songs);
    }
    return _grouped;
  }

  // The whole tab grouped, used as the play queue while searching.
  List<SongModel>? _allGroupSource;
  List<SongModel> _allGrouped = const [];

  List<SongModel> _groupAll(List<SongModel> songs) {
    if (!identical(songs, _allGroupSource)) {
      _allGroupSource = songs;
      _allGrouped = identical(songs, _groupSource)
          ? _grouped.songs
          : _GroupedSongs.of(songs).songs;
    }
    return _allGrouped;
  }

  /// Rows above this index fade in when first built; rows further down appear
  /// straight away so fast scrolling doesn't start an animation per row.
  static const _animatedRows = 15;

  // Keep the tab alive so switching tabs doesn't dispose it.
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// New search text: show the results from the top.
  void _setSearch(String value) {
    setState(() => _searchText = value);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _playAll(List<SongModel> songs, {required bool shuffle}) async {
    final handler = ref.read(audioHandlerProvider);
    if (handler == null || songs.isEmpty) return;
    HapticFeedback.lightImpact();
    widget.onNavigateToPlayer();
    await handler.playAll(songs, shuffle: shuffle);
  }

  List<SongModel> _filter(List<SongModel> songs) {
    final query = _searchText.toLowerCase();
    if (identical(songs, _filterSource) && query == _filterQuery) {
      return _filtered;
    }
    if (!identical(songs, _filterSource)) _searchKeys.clear();
    _filterSource = songs;
    _filterQuery = query;
    _filtered = query.isEmpty
        ? songs
        : songs
              .where(
                (s) => _searchKeys
                    .putIfAbsent(
                      s.id,
                      () => '${s.title}\n${s.artist ?? ''}'.toLowerCase(),
                    )
                    .contains(query),
              )
              .toList(growable: false);
    return _filtered;
  }

  Future<void> _play(List<SongModel> queueSongs, SongModel song) async {
    final handler = ref.read(audioHandlerProvider);
    if (handler == null) return;

    widget.onNavigateToPlayer();

    final tappedIndex = queueSongs.indexWhere((s) => s.id == song.id);
    if (tappedIndex != -1) {
      handler.setQueue(queueSongs);
      await handler.playSongAt(tappedIndex);
    } else {
      await handler.playSong(song);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _addSongToPlaylist(SongModel song) async {
    if (ref.read(playlistsProvider).isEmpty) {
      _showSnack('No playlists available.');
      return;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: theme.colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.playlist_add,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to Playlist',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Playlist list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Consumer(
                  builder: (context, ref, _) {
                    final playlists = ref.watch(playlistsProvider);
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        final alreadyAdded = playlist.contains(song.id);
                        return _PlaylistChoice(
                          playlist: playlist,
                          alreadyAdded: alreadyAdded,
                          isDark: isDark,
                          onTap: alreadyAdded
                              ? null
                              : () {
                                  ref
                                      .read(playlistsProvider.notifier)
                                      .addSong(playlist, _toPlaylistSong(song));
                                  Navigator.of(ctx).pop();
                                  _showSnack(
                                    'Added "${song.title}" to ${playlist.name}',
                                  );
                                },
                        );
                      },
                    );
                  },
                ),
              ),

              // Cancel button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final access = ref.watch(libraryAccessProvider).value;
    final songsAsync = widget.musicFolderOnly
        ? ref.watch(musicFolderSongsProvider)
        : ref.watch(librarySongsProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: 'Search songs or artists...',
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.5,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.iconTheme.color?.withValues(alpha: 0.7),
                ),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.iconTheme.color?.withValues(alpha: 0.7),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _setSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: _setSearch,
            ),
          ),
        ),

        // Songs list
        Expanded(
          child: access == LibraryAccess.denied
              ? _message(
                  theme,
                  icon: Icons.lock_outline,
                  title: 'No access to your music',
                  subtitle: 'Allow Noir Player to read audio files.',
                  action: TextButton(
                    onPressed: () => ref.invalidate(libraryAccessProvider),
                    child: const Text('Try again'),
                  ),
                )
              : songsAsync.when(
                  skipLoadingOnRefresh: true,
                  loading: () => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading songs...',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (e, _) => _message(
                    theme,
                    icon: Icons.error_outline,
                    title: 'Could not load songs',
                    subtitle: '$e',
                  ),
                  data: (songs) => _list(theme, songs),
                ),
        ),
      ],
    );
  }

  Widget _list(ThemeData theme, List<SongModel> songs) {
    final filteredSongs = _filter(songs);
    if (filteredSongs.isEmpty) {
      final searching = _searchText.isNotEmpty;
      return _message(
        theme,
        icon: searching ? Icons.search_off : Icons.library_music_outlined,
        title: 'No songs found',
        subtitle: searching
            ? 'Try a different search term'
            : widget.musicFolderOnly
            ? 'Nothing in the music folder. Pick another in Settings.'
            : 'No audio files on this device',
        action: searching
            ? null
            : TextButton(
                onPressed: () => ref.refresh(librarySongsProvider.future),
                child: const Text('Refresh'),
              ),
      );
    }

    // In the Music tab, songs play in the order shown: by letter group.
    final grouped = _groupByLetter ? _group(filteredSongs) : null;
    final shown = grouped?.songs ?? filteredSongs;
    final queue = _groupByLetter ? _groupAll(songs) : songs;
    final entries = grouped?.entries;

    return Column(
      children: [
        _ListHeader(
          count: shown.length,
          onPlay: () => _playAll(shown, shuffle: false),
          onShuffle: () => _playAll(shown, shuffle: true),
        ),
        Expanded(
          child: RefreshIndicator(
            color: theme.colorScheme.primary,
            onRefresh: () => ref.refresh(librarySongsProvider.future),
            // Drag the thumb to move quickly through a long library.
            child: Scrollbar(
              controller: _scrollController,
              interactive: true,
              thickness: 6,
              radius: const Radius.circular(8),
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                cacheExtent: 500,
                itemCount: entries?.length ?? shown.length,
                itemBuilder: (context, index) {
                  final entry = entries?[index];
                  if (entry is _LetterEntry) {
                    return _LetterHeader(
                      key: ValueKey('letter-${entry.letter}'),
                      letter: entry.letter,
                      count: entry.count,
                    );
                  }
                  final song = entry is _SongEntry ? entry.song : shown[index];
                  return _SongTile(
                    key: ValueKey(song.id),
                    song: song,
                    number: entry is _SongEntry ? entry.number : null,
                    animationIndex: index < _animatedRows ? index : null,
                    // Queue the whole tab, not just the search results.
                    onTap: () => _play(queue, song),
                    onAddToPlaylist: () => _addSongToPlaylist(song),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _message(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.iconTheme.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}

/// The artist tag, or "Unknown Artist" when it is missing. The media library
/// reports a missing tag as the literal "<unknown>".
String _artistOf(SongModel song) {
  final artist = song.artist?.trim();
  return artist == null || artist.isEmpty || artist == '<unknown>'
      ? 'Unknown Artist'
      : artist;
}

PlaylistSong _toPlaylistSong(SongModel song) => PlaylistSong(
  id: song.id,
  title: song.title,
  artist: _artistOf(song),
  data: song.data,
  duration: song.duration,
);

String _formatDuration(int milliseconds) {
  final seconds = (milliseconds / 1000).round();
  final minutes = seconds ~/ 60;
  final remaining = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remaining';
}

/// One song row. Watches only its own favourite and now-playing state, so a
/// song change or a heart tap rebuilds just the rows involved.
class _SongTile extends ConsumerWidget {
  const _SongTile({
    super.key,
    required this.song,
    required this.animationIndex,
    required this.onTap,
    required this.onAddToPlaylist,
    this.number,
  });

  final SongModel song;

  /// Row number shown on the left (Music tab), or null for none.
  final int? number;

  /// Position used to stagger the fade-in, or null for no animation.
  final int? animationIndex;
  final VoidCallback onTap;
  final VoidCallback onAddToPlaylist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fav = ref.watch(isFavouriteProvider(song.id));
    final isCurrent = ref.watch(isCurrentMediaProvider('${song.id}'));

    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        onTap: onTap,
        onLongPress: onAddToPlaylist,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              if (number != null)
                SizedBox(
                  width: 34,
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: theme.textTheme.bodySmall?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
              // Artwork
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SongArtwork(
                  id: song.id,
                  size: 56,
                  borderRadius: BorderRadius.circular(12),
                  placeholder: Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    child: Icon(
                      Icons.music_note,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Song info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_artistOf(song)} · '
                      '${_formatDuration(song.duration ?? 0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Favourite toggle
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: fav ? 'Remove from Favourites' : 'Add to Favourites',
                icon: Icon(
                  fav ? Icons.favorite : Icons.favorite_border,
                  size: 22,
                  color: fav
                      ? theme.colorScheme.primary
                      : theme.iconTheme.color?.withValues(alpha: 0.55),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(playlistsProvider.notifier)
                      .toggleFavourite(_toPlaylistSong(song));
                },
              ),

              // Marks the playing song.
              if (isCurrent)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: NowPlayingIndicator(
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
              PopupMenuButton<_SongAction>(
                tooltip: 'More',
                icon: Icon(
                  Icons.more_vert,
                  color: theme.iconTheme.color?.withValues(alpha: 0.55),
                ),
                onSelected: (action) => switch (action) {
                  _SongAction.play => onTap(),
                  _SongAction.addToPlaylist => onAddToPlaylist(),
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _SongAction.play,
                    child: ListTile(
                      leading: Icon(Icons.play_arrow_rounded),
                      title: Text('Play'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _SongAction.addToPlaylist,
                    child: ListTile(
                      leading: Icon(Icons.playlist_add),
                      title: Text('Add to playlist…'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final index = animationIndex;
    if (index == null) return row;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + index * 30),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: row,
    );
  }
}

enum _SongAction { play, addToPlaylist }

/// A row of the Music tab: a letter heading or a numbered song.
sealed class _Entry {
  const _Entry();
}

class _LetterEntry extends _Entry {
  const _LetterEntry(this.letter, this.count);
  final String letter;
  final int count;
}

class _SongEntry extends _Entry {
  const _SongEntry(this.song, this.number);
  final SongModel song;
  final int number;
}

/// Songs grouped under '#' (titles not starting with a letter) and A–Z,
/// keeping their order within each group.
class _GroupedSongs {
  const _GroupedSongs(this.entries, this.songs);

  /// Headings and songs, in display order.
  final List<_Entry> entries;

  /// The songs alone, in display order (the play queue).
  final List<SongModel> songs;

  static String letterOf(String title) {
    final first = title.trimLeft();
    if (first.isEmpty) return '#';
    final c = first[0].toUpperCase();
    final code = c.codeUnitAt(0);
    return code >= 65 && code <= 90 ? c : '#';
  }

  factory _GroupedSongs.of(List<SongModel> songs) {
    final groups = <String, List<SongModel>>{};
    for (final s in songs) {
      (groups[letterOf(s.title)] ??= []).add(s);
    }
    final letters = groups.keys.toList()
      ..sort((a, b) {
        if (a == b) return 0;
        if (a == '#') return -1;
        if (b == '#') return 1;
        return a.compareTo(b);
      });

    final entries = <_Entry>[];
    final ordered = <SongModel>[];
    for (final letter in letters) {
      final group = groups[letter]!;
      entries.add(_LetterEntry(letter, group.length));
      for (final s in group) {
        ordered.add(s);
        entries.add(_SongEntry(s, ordered.length));
      }
    }
    return _GroupedSongs(
      List.unmodifiable(entries),
      List.unmodifiable(ordered),
    );
  }
}

/// "A  3" heading above each letter's songs.
class _LetterHeader extends StatelessWidget {
  const _LetterHeader({super.key, required this.letter, required this.count});

  final String letter;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 6),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              letter,
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Song count with Play and Shuffle for everything currently listed.
class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.count,
    required this.onPlay,
    required this.onShuffle,
  });

  final int count;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count song${count == 1 ? '' : 's'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onShuffle,
            icon: const Icon(Icons.shuffle_rounded, size: 20),
            label: const Text('Shuffle'),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: const Text('Play'),
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}

class _PlaylistChoice extends StatelessWidget {
  const _PlaylistChoice({
    required this.playlist,
    required this.alreadyAdded,
    required this.isDark,
    required this.onTap,
  });

  final PlaylistModel playlist;
  final bool alreadyAdded;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: alreadyAdded
                      ? Colors.grey.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  playlist.isFavourite ? Icons.favorite : Icons.playlist_play,
                  color: alreadyAdded
                      ? (isDark ? Colors.white38 : Colors.black38)
                      : theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: alreadyAdded
                            ? theme.textTheme.bodyMedium?.color?.withValues(
                                alpha: 0.5,
                              )
                            : theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${playlist.songs.length} song${playlist.songs.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (alreadyAdded)
                Icon(
                  Icons.check_circle,
                  color: Colors.green.withValues(alpha: 0.7),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The letter heading a song title is listed under in the Music tab.
@visibleForTesting
String songLetterOf(String title) => _GroupedSongs.letterOf(title);
