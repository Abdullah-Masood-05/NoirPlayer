import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/playlist_model.dart';

/// Single source of truth for playlists (incl. Favourites), persisted to
/// `playlists.json`. A [ChangeNotifier] singleton so every screen stays in sync
/// via `ListenableBuilder`.
class PlaylistService extends ChangeNotifier {
  PlaylistService._();
  static final PlaylistService instance = PlaylistService._();

  /// Max number of playlists (including Favourites).
  static const int maxPlaylists = 5;
  static const String favouritesName = 'Favourites';

  final List<PlaylistModel> _playlists = [];
  bool _loaded = false;

  List<PlaylistModel> get playlists => List.unmodifiable(_playlists);
  bool get canCreateMore => _playlists.length < maxPlaylists;

  PlaylistModel get favourites =>
      _playlists.firstWhere((p) => p.isFavourite);

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/playlists.json');
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final file = await _file;
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString()) as List<dynamic>;
        _playlists
          ..clear()
          ..addAll(data.map((e) => PlaylistModel.fromJson(e)));
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    }

    // Guarantee exactly one Favourites playlist, pinned to the front.
    final favIndex = _playlists.indexWhere((p) => p.isFavourite);
    if (favIndex == -1) {
      _playlists.insert(
        0,
        PlaylistModel(name: favouritesName, songs: [], isFavourite: true),
      );
    } else if (favIndex != 0) {
      final fav = _playlists.removeAt(favIndex);
      _playlists.insert(0, fav);
    }

    _loaded = true;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final file = await _file;
      await file.writeAsString(
        jsonEncode(_playlists.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving playlists: $e');
    }
  }

  // ── Queries ────────────────────────────────────────────────────────────────
  bool isFavourite(int songId) =>
      favourites.songs.any((s) => s.id == songId);

  bool isInPlaylist(PlaylistModel playlist, int songId) =>
      playlist.songs.any((s) => s.id == songId);

  // ── Mutations ───────────────────────────────────────────────────────────────
  /// Returns false if the limit is reached or the name is blank/duplicate.
  Future<bool> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || !canCreateMore) return false;
    if (_playlists.any((p) => p.name.toLowerCase() == trimmed.toLowerCase())) {
      return false;
    }
    _playlists.add(PlaylistModel(name: trimmed, songs: []));
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> deletePlaylist(PlaylistModel playlist) async {
    if (playlist.isFavourite) return;
    _playlists.remove(playlist);
    await _save();
    notifyListeners();
  }

  Future<void> addSong(PlaylistModel playlist, PlaylistSong song) async {
    if (playlist.songs.any((s) => s.id == song.id)) return;
    playlist.songs.add(song);
    await _save();
    notifyListeners();
  }

  Future<void> removeSong(PlaylistModel playlist, int songId) async {
    playlist.songs.removeWhere((s) => s.id == songId);
    await _save();
    notifyListeners();
  }

  /// Add/remove a song from Favourites.
  Future<void> toggleFavourite(PlaylistSong song) async {
    final fav = favourites;
    if (fav.songs.any((s) => s.id == song.id)) {
      fav.songs.removeWhere((s) => s.id == song.id);
    } else {
      fav.songs.add(song);
    }
    await _save();
    notifyListeners();
  }
}
