import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'library.dart';

typedef ArtworkFetcher =
    Future<Uint8List?> Function(int id, ArtworkType type, int size);

/// Embedded artwork, kept in memory for the most recently shown items.
///
/// Every list row used to query the platform again whenever it scrolled back
/// into view. Here each (item, size) is fetched once; the bytes stay cached
/// (up to [maxEntries], least recently used dropped first), and because the
/// same bytes object is returned, Flutter's image cache reuses the decoded
/// image too.
class ArtworkCache {
  ArtworkCache(this._fetch, {this.maxEntries = 300});

  final ArtworkFetcher _fetch;
  final int maxEntries;
  final LinkedHashMap<String, _Entry> _entries = LinkedHashMap();

  static String _key(int id, ArtworkType type, int size) =>
      '${type.index}:$id:$size';

  /// The artwork if it has already loaded, so a row can draw it in its first
  /// frame without flashing the placeholder.
  Uint8List? peek(int id, ArtworkType type, int size) =>
      _entries[_key(id, type, size)]?.bytes;

  /// True once a lookup for this item has finished (with or without art).
  bool isResolved(int id, ArtworkType type, int size) =>
      _entries[_key(id, type, size)]?.resolved ?? false;

  Future<Uint8List?> load(int id, ArtworkType type, int size) {
    final key = _key(id, type, size);
    final hit = _entries.remove(key);
    if (hit != null) {
      _entries[key] = hit; // most recently used
      return hit.future;
    }

    final entry = _Entry();
    entry.future = _fetch(id, type, size)
        .then<Uint8List?>((bytes) {
          entry.bytes = (bytes == null || bytes.isEmpty) ? null : bytes;
          entry.resolved = true;
          return entry.bytes;
        })
        .catchError((Object e) {
          debugPrint('Artwork $key failed: $e');
          entry.resolved = true;
          return null;
        });
    _entries[key] = entry;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return entry.future;
  }

  int get length => _entries.length;
}

class _Entry {
  late Future<Uint8List?> future;
  Uint8List? bytes;
  bool resolved = false;
}

final artworkCacheProvider = Provider<ArtworkCache>((ref) {
  final query = ref.watch(onAudioQueryProvider);
  return ArtworkCache(
    (id, type, size) => query.queryArtwork(
      id,
      type,
      format: ArtworkFormat.JPEG,
      size: size,
      quality: 90,
    ),
  );
});
