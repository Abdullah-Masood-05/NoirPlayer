import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:on_audio_query/on_audio_query.dart' show OnAudioQuery;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discovered_track.dart';
import 'settings_service.dart';

/// Outcome of a download attempt.
enum DownloadResult {
  success,
  alreadyExists,
  inProgress,
  noSource,
  failed,
  permissionDenied,
}

class MusicDiscoveryService {
  static final MusicDiscoveryService _instance =
      MusicDiscoveryService._internal();
  factory MusicDiscoveryService() => _instance;
  MusicDiscoveryService._internal();

  // API keys are loaded from the .env file (see .env.example) via flutter_dotenv.
  final String lastFmApiKey = dotenv.env['LASTFM_API_KEY'] ?? '';
  final String youtubeApiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
  final String rapidApiKey = dotenv.env['RAPIDAPI_KEY'] ?? '';

  /// Used to register freshly downloaded files with the media library so they
  /// appear in the Library/Music tab (and other apps) immediately.
  final OnAudioQuery _audioQuery = OnAudioQuery();

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
      // We write straight into the public Music folder, which needs storage
      // access. Fail fast (before hitting the network) if it isn't granted.
      if (!await _ensureWritePermission()) {
        return DownloadResult.permissionDenied;
      }

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

  /// Ensure we can write into the public Music folder.
  ///
  /// Android 11+ requires "All files access" (MANAGE_EXTERNAL_STORAGE) to write
  /// to shared directories with `dart:io`; older versions use the legacy
  /// storage permission. Requesting `manageExternalStorage` opens the system
  /// "All files access" screen.
  Future<bool> _ensureWritePermission() async {
    if (await Permission.manageExternalStorage.isGranted) return true;
    // Legacy storage permission covers Android 10 and below.
    if (await Permission.storage.request().isGranted) return true;
    // Android 11+: prompt for all-files access.
    return await Permission.manageExternalStorage.request().isGranted;
  }

  /// Resolve the folder downloads are saved into: the user-selected music
  /// folder if set, otherwise the device's default public Music directory.
  Future<String> downloadDirectory() async {
    final custom = SettingsService.instance.musicFolderPath;
    if (custom != null && custom.trim().isNotEmpty) return custom;
    return _defaultMusicDirectory();
  }

  /// The device's public Music directory (e.g. /storage/emulated/0/Music),
  /// derived from the external storage root so it works across devices.
  Future<String> _defaultMusicDirectory() async {
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        // .../Android/data/<pkg>/files -> storage root
        final root = ext.path.split('/Android/').first;
        if (root.isNotEmpty) return '$root/Music';
      }
    } catch (_) {}
    return '/storage/emulated/0/Music';
  }

  /// Download an MP3 from [url] straight into the music folder and register it
  /// with the media library. Returns the saved file path, or null on failure.
  Future<String?> saveFile(
    String url,
    String rawFilename, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      var filename = _sanitizeFileName(rawFilename);
      if (!filename.toLowerCase().endsWith('.mp3')) {
        filename = '$filename.mp3';
      }

      final folder = await downloadDirectory();
      final dir = Directory(folder);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Avoid clobbering an existing file with the same name.
      var filePath = '$folder/$filename';
      if (await File(filePath).exists()) {
        final base = filename.substring(0, filename.length - 4); // strip .mp3
        var n = 1;
        do {
          filePath = '$folder/$base ($n).mp3';
          n++;
        } while (await File(filePath).exists());
      }

      await Dio().download(
        url,
        filePath,
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

      // Make the new file visible in the media library straight away.
      try {
        await _audioQuery.scanMedia(filePath);
      } catch (e) {
        _logError('Media scan failed for $filePath: $e');
      }

      return filePath;
    } catch (e) {
      _logError('Error saving file: $e');
      return null;
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
