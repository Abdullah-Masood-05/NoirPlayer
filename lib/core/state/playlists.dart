import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/playlist_model.dart';

/// Reads and writes `playlists.json`.
class PlaylistRepository {
  PlaylistRepository({Future<File> Function()? file}) : _fileFn = file;

  final Future<File> Function()? _fileFn;

  /// Writes are chained so two quick changes can never land out of order.
  Future<void> _pendingWrite = Future.value();

  Future<File> get _file async {
    final custom = _fileFn;
    if (custom != null) return custom();
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/playlists.json');
  }

  /// The saved playlists, always with exactly one Favourites playlist first.
  Future<List<PlaylistModel>> load() async {
    var playlists = <PlaylistModel>[];
    try {
      final file = await _file;
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString()) as List<dynamic>;
        playlists = data.map((e) => PlaylistModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    }
    return withFavouritesFirst(playlists);
  }

  void save(List<PlaylistModel> playlists) {
    final json = jsonEncode(playlists.map((p) => p.toJson()).toList());
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await (await _file).writeAsString(json, flush: true);
      } catch (e) {
        debugPrint('Error saving playlists: $e');
      }
    });
  }

  /// Completes once every queued write has finished.
  Future<void> flush() => _pendingWrite;

  /// Guarantee exactly one Favourites playlist, pinned to the front.
  static List<PlaylistModel> withFavouritesFirst(List<PlaylistModel> input) {
    final playlists = List<PlaylistModel>.of(input);
    final favIndex = playlists.indexWhere((p) => p.isFavourite);
    if (favIndex == -1) {
      playlists.insert(
        0,
        PlaylistModel(
          name: PlaylistsNotifier.favouritesName,
          songs: const [],
          isFavourite: true,
        ),
      );
    } else if (favIndex != 0) {
      playlists.insert(0, playlists.removeAt(favIndex));
    }
    return playlists;
  }
}

final playlistRepositoryProvider = Provider<PlaylistRepository>(
  (ref) => PlaylistRepository(),
);

/// Playlists loaded before `runApp`, so the UI never sees a loading state.
final initialPlaylistsProvider = Provider<List<PlaylistModel>>(
  (ref) => PlaylistRepository.withFavouritesFirst(const []),
);

/// All playlists (Favourites first). Every change replaces the list.
final playlistsProvider =
    NotifierProvider<PlaylistsNotifier, List<PlaylistModel>>(
      PlaylistsNotifier.new,
    );

/// Ids of the songs in Favourites, for quick heart lookups in long lists.
final favouriteIdsProvider = Provider<Set<int>>((ref) {
  final playlists = ref.watch(playlistsProvider);
  final fav = playlists.where((p) => p.isFavourite).firstOrNull;
  return {for (final s in fav?.songs ?? const <PlaylistSong>[]) s.id};
});

/// Whether one song is a favourite. Rows watch this, so toggling a heart
/// rebuilds only that row.
final isFavouriteProvider = Provider.family<bool, int>(
  (ref, songId) =>
      ref.watch(favouriteIdsProvider.select((ids) => ids.contains(songId))),
);

class PlaylistsNotifier extends Notifier<List<PlaylistModel>> {
  /// Max number of playlists (including Favourites).
  static const int maxPlaylists = 5;
  static const String favouritesName = 'Favourites';

  @override
  List<PlaylistModel> build() => List.unmodifiable(
    PlaylistRepository.withFavouritesFirst(ref.watch(initialPlaylistsProvider)),
  );

  bool get canCreateMore => state.length < maxPlaylists;

  PlaylistModel get favourites => state.firstWhere((p) => p.isFavourite);

  void _set(List<PlaylistModel> playlists) {
    state = List.unmodifiable(playlists);
    ref.read(playlistRepositoryProvider).save(state);
  }

  /// Replace the playlist named like [playlist] with [updated].
  void _replace(PlaylistModel playlist, PlaylistModel updated) {
    _set([for (final p in state) p.name == playlist.name ? updated : p]);
  }

  /// Returns false if the limit is reached or the name is blank/duplicate.
  bool createPlaylist(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || !canCreateMore) return false;
    final lower = trimmed.toLowerCase();
    if (state.any((p) => p.name.toLowerCase() == lower)) return false;
    _set([...state, PlaylistModel(name: trimmed, songs: const [])]);
    return true;
  }

  void deletePlaylist(PlaylistModel playlist) {
    if (playlist.isFavourite) return;
    _set([
      for (final p in state)
        if (p.name != playlist.name) p,
    ]);
  }

  void addSong(PlaylistModel playlist, PlaylistSong song) {
    final current = byName(playlist.name);
    if (current == null || current.contains(song.id)) return;
    _replace(current, current.copyWith(songs: [...current.songs, song]));
  }

  void removeSong(PlaylistModel playlist, int songId) {
    final current = byName(playlist.name);
    if (current == null) return;
    _replace(
      current,
      current.copyWith(
        songs: [
          for (final s in current.songs)
            if (s.id != songId) s,
        ],
      ),
    );
  }

  /// Add/remove a song from Favourites.
  void toggleFavourite(PlaylistSong song) {
    final fav = favourites;
    _replace(
      fav,
      fav.copyWith(
        songs: fav.contains(song.id)
            ? [
                for (final s in fav.songs)
                  if (s.id != song.id) s,
              ]
            : [...fav.songs, song],
      ),
    );
  }

  PlaylistModel? byName(String name) =>
      state.where((p) => p.name == name).firstOrNull;
}
