import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discovered_track.dart';

/// Outcome of a download attempt.
enum DownloadResult { success, alreadyExists, inProgress, noSource, failed }

class MusicDiscoveryService {
  static final MusicDiscoveryService _instance =
      MusicDiscoveryService._internal();
  factory MusicDiscoveryService() => _instance;
  MusicDiscoveryService._internal();

  // API keys are loaded from the .env file (see .env.example) via flutter_dotenv.
  final String lastFmApiKey = dotenv.env['LASTFM_API_KEY'] ?? '';
  final String youtubeApiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
  final String rapidApiKey = dotenv.env['RAPIDAPI_KEY'] ?? '';

  static bool mediaStoreInitialized = false;

  static const String _downloadedPrefsKey = 'downloaded_track_keys';

  /// Keys of tracks already downloaded (kept in sync with SharedPreferences).
  final Set<String> _downloadedKeys = {};
  bool _downloadedLoaded = false;

  /// Keys of downloads currently running, to avoid concurrent duplicates.
  final Set<String> _inProgressKeys = {};

  /// Stable identity for a track, used for de-duplicating downloads.
  String trackKey(DiscoveredTrack track) => '${track.name}-${track.artist}';

  // ---------------------------------------------------------------------------
  // Discovery (Last.fm / YouTube / RapidAPI)
  // ---------------------------------------------------------------------------

  /// Fetch album artwork from Last.fm.
  Future<String> fetchAlbumArt(String track, String artist) async {
    final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {
      'method': 'track.getInfo',
      'api_key': lastFmApiKey,
      'artist': artist,
      'track': track,
      'format': 'json',
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return '';
      final data = jsonDecode(response.body);

      final images = data['track']?['album']?['image'];
      if (images is List) {
        // Pick the largest available image.
        for (final img in images.reversed) {
          final text = img is Map ? img['#text'] : null;
          if (text is String && text.isNotEmpty) return text;
        }
      }
    } catch (e) {
      _logError('No album image found for $track - $artist: $e');
    }
    return ''; // fallback if no image
  }

  /// Fetch trending tracks from Last.fm.
  Future<List<DiscoveredTrack>> fetchTrendingTracks() async {
    final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {
      'method': 'geo.gettoptracks',
      'country': 'pakistan',
      'api_key': lastFmApiKey,
      'format': 'json',
    });

    final response = await http.get(uri);
    final data = jsonDecode(response.body);
    final tracks = data['tracks']?['track'];
    if (tracks is! List) return [];

    final trackFutures = tracks.map<Future<DiscoveredTrack>>((t) async {
      final trackName = (t['name'] ?? '').toString();
      final artistName = (t['artist']?['name'] ?? 'Unknown Artist').toString();

      final realImageUrl = await fetchAlbumArt(trackName, artistName);

      return DiscoveredTrack(
        name: trackName,
        artist: artistName,
        imageUrl: realImageUrl.isNotEmpty
            ? realImageUrl
            : _fallbackImage(t['image']),
      );
    }).toList();

    return await Future.wait(trackFutures);
  }

  /// Search for tracks on Last.fm.
  Future<List<DiscoveredTrack>> searchTracks(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {
      'method': 'track.search',
      'track': query,
      'api_key': lastFmApiKey,
      'format': 'json',
    });

    final response = await http.get(uri);
    final data = jsonDecode(response.body);
    final tracksData = data['results']?['trackmatches']?['track'];
    if (tracksData == null) return [];

    final tracksList = tracksData is List ? tracksData : [tracksData];

    final futures = tracksList.map<Future<DiscoveredTrack>>((t) async {
      final trackName = (t['name'] ?? '').toString();
      final artistName = (t['artist'] ?? 'Unknown Artist').toString();
      final realImageUrl = await fetchAlbumArt(trackName, artistName);

      return DiscoveredTrack(
        name: trackName,
        artist: artistName,
        imageUrl: realImageUrl.isNotEmpty
            ? realImageUrl
            : _fallbackImage(t['image']),
      );
    });

    return await Future.wait(futures);
  }

  /// Search YouTube for a track and return the first matching video ID.
  Future<String> fetchYoutubeVideoId(
    String trackName,
    String artistName,
  ) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'q': '$trackName $artistName',
      'type': 'video',
      'maxResults': '1',
      'key': youtubeApiKey,
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return '';
      final data = jsonDecode(response.body);

      final items = data['items'];
      if (items is List && items.isNotEmpty) {
        return (items[0]['id']?['videoId'] ?? '').toString();
      }
    } catch (e) {
      _logError('Error fetching YouTube video ID: $e');
    }
    return '';
  }

  /// Resolve an MP3 download URL from RapidAPI (youtube-mp36).
  ///
  /// The API processes some videos asynchronously, so we poll a few times
  /// while it reports `processing`.
  Future<String?> getDownloadUrl(String videoId) async {
    const maxAttempts = 4;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final uri = Uri.https('youtube-mp36.p.rapidapi.com', '/dl', {
          'id': videoId,
        });

        final response = await http.get(
          uri,
          headers: {
            'X-RapidAPI-Key': rapidApiKey,
            'X-RapidAPI-Host': 'youtube-mp36.p.rapidapi.com',
          },
        );

        if (response.statusCode != 200) return null;

        final data = jsonDecode(response.body);
        final link = data['link']?.toString();
        if (link != null && link.isNotEmpty) return link;

        final status = data['status']?.toString();
        if (status == 'processing' && attempt < maxAttempts - 1) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        return null;
      } catch (e) {
        _logError('Error getting download URL: $e');
        return null;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Download bookkeeping (de-duplication)
  // ---------------------------------------------------------------------------

  /// Load the set of already-downloaded track keys from storage (once).
  Future<Set<String>> loadDownloadedKeys() async {
    if (_downloadedLoaded) return _downloadedKeys;
    try {
      final prefs = await SharedPreferences.getInstance();
      _downloadedKeys
        ..clear()
        ..addAll(prefs.getStringList(_downloadedPrefsKey) ?? const []);
    } catch (e) {
      _logError('Error loading downloaded keys: $e');
    }
    _downloadedLoaded = true;
    return _downloadedKeys;
  }

  bool isDownloaded(String key) => _downloadedKeys.contains(key);

  bool isDownloading(String key) => _inProgressKeys.contains(key);

  Future<void> _markDownloaded(String key) async {
    if (_downloadedKeys.add(key)) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _downloadedPrefsKey,
          _downloadedKeys.toList(),
        );
      } catch (e) {
        _logError('Error persisting downloaded key: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Download pipeline
  // ---------------------------------------------------------------------------

  /// Full download flow with de-duplication: resolves the source, saves the
  /// MP3 and records the track so it cannot be downloaded twice.
  Future<DownloadResult> downloadTrack(
    DiscoveredTrack track, {
    void Function(int received, int total)? onProgress,
  }) async {
    await loadDownloadedKeys();
    final key = trackKey(track);

    if (isDownloaded(key)) return DownloadResult.alreadyExists;
    if (!_inProgressKeys.add(key)) return DownloadResult.inProgress;

    try {
      final videoId = await fetchYoutubeVideoId(track.name, track.artist);
      if (videoId.isEmpty) return DownloadResult.noSource;

      final mp3Url = await getDownloadUrl(videoId);
      if (mp3Url == null || mp3Url.isEmpty) return DownloadResult.noSource;

      final savedUri = await saveFile(
        mp3Url,
        track.name,
        onProgress: onProgress,
      );
      if (savedUri == null) return DownloadResult.failed;

      await _markDownloaded(key);
      return DownloadResult.success;
    } catch (e) {
      _logError('Error downloading ${track.name}: $e');
      return DownloadResult.failed;
    } finally {
      _inProgressKeys.remove(key);
    }
  }

  /// Request storage permission (only relevant on older Android versions;
  /// MediaStore writes on Android 10+ do not need it).
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Initialize MediaStore once.
  Future<void> initMediaStore() async {
    if (!mediaStoreInitialized) {
      await MediaStore.ensureInitialized();
      mediaStoreInitialized = true;
    }
  }

  /// Download an MP3 from [url] and save it to the device's Music library.
  Future<String?> saveFile(
    String url,
    String rawFilename, {
    Function(int received, int total)? onProgress,
  }) async {
    String? tempFilePath;
    try {
      await initMediaStore();
      MediaStore.appFolder = 'NoirPlayerDownloads';

      var filename = _sanitizeFileName(rawFilename);
      if (!filename.toLowerCase().endsWith('.mp3')) {
        filename = '$filename.mp3';
      }

      final tempDir = await getTemporaryDirectory();
      tempFilePath = '${tempDir.path}/$filename';

      await Dio().download(
        url,
        tempFilePath,
        options: Options(
          followRedirects: true,
          // Only accept successful responses; otherwise an error page would be
          // saved as a corrupt .mp3 file.
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
        onReceiveProgress: (received, total) =>
            onProgress?.call(received, total),
      );

      final mediaStore = MediaStore();
      final savedInfo = await mediaStore.saveFile(
        tempFilePath: tempFilePath,
        dirType: DirType.audio,
        dirName: DirName.music,
        relativePath: null,
      );

      if (savedInfo == null) {
        _logError('Failed to save file');
        return null;
      }

      return savedInfo.uri.toString();
    } catch (e) {
      _logError('Error saving file: $e');
      return null;
    } finally {
      // Clean up the temp file so the cache does not grow unbounded.
      if (tempFilePath != null) {
        try {
          final f = File(tempFilePath);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Strip path separators and characters that are illegal in file names to
  /// prevent path traversal (e.g. a track named "../../evil") and write errors.
  String _sanitizeFileName(String name) {
    var clean = name
        .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[.\s]+'), '') // no leading dots/space ("..")
        .trim();
    if (clean.isEmpty) clean = 'track';
    if (clean.length > 100) clean = clean.substring(0, 100).trim();
    return clean;
  }

  String _fallbackImage(dynamic images) {
    if (images is List && images.isNotEmpty) {
      final last = images.last;
      final text = last is Map ? last['#text'] : null;
      if (text is String) return text;
    }
    return '';
  }

  void _logError(String message) {
    if (kDebugMode) debugPrint(message);
  }

  void dispose() {
    // Cleanup if needed
  }
}
