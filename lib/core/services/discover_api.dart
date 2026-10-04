import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/discovered_track.dart';

/// Noir Player's backend. It holds the service keys Discover runs on.
const String noirBackend = 'https://noir-player-api.vercel.app';

/// The backend refuses searches longer than this (see its `validate.ts`).
const int maxQueryLength = 200;

/// A Discover failure, with a message written for the person using the app.
class DiscoverException implements Exception {
  const DiscoverException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Keys entered in Settings. A service with a key here is called directly
/// with it; a service without one goes through Noir Player's backend.
class DiscoverKeys {
  DiscoverKeys({String lastFm = '', String youtube = '', String rapidApi = ''})
    : lastFm = lastFm.trim(),
      youtube = youtube.trim(),
      rapidApi = rapidApi.trim();

  final String lastFm;
  final String youtube;
  final String rapidApi;

  /// Every key, for checking a service hasn't echoed one back into a link.
  List<String> get all => [lastFm, youtube, rapidApi];
}

const String _rapidApiHost = 'youtube-mp36.p.rapidapi.com';

/// Responses from these services are small; anything bigger is not what was
/// asked for.
const int _maxBodyBytes = 1048576;

final RegExp _controlChars = RegExp(r'[\x00-\x1F\x7F]');
final RegExp _videoIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Talks to Last.fm, YouTube and the audio service, either directly with the
/// user's own key or through Noir Player's backend.
class DiscoverApi {
  DiscoverApi({
    required DiscoverKeys Function() keys,
    http.Client? client,
    String backend = noirBackend,
    Duration retryDelay = const Duration(seconds: 2),
  }) : _keys = keys,
       _client = client ?? http.Client(),
       _backend = backend,
       _retryDelay = retryDelay;

  final DiscoverKeys Function() _keys;
  final http.Client _client;
  final String _backend;
  final Duration _retryDelay;

  // ---------------------------------------------------------------------------
  // Tracks (Last.fm)
  // ---------------------------------------------------------------------------

  /// Trending tracks.
  Future<List<DiscoveredTrack>> fetchTrending() async {
    final keys = _keys();
    if (keys.lastFm.isEmpty) {
      final answer = await _backendJson(
        '/api/tracks',
        null,
        const Duration(seconds: 15),
      );
      return parseTracks(answer, search: false);
    }

    final root = await _lastFmJson(keys.lastFm, {
      'method': 'geo.gettoptracks',
      'country': 'pakistan',
    });
    return _withAlbumArt(keys.lastFm, parseTracks(root, search: false));
  }

  /// Tracks matching [query]. An empty query gives an empty list.
  Future<List<DiscoveredTrack>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final keys = _keys();
    if (keys.lastFm.isEmpty) {
      final clean = validSearchQuery(trimmed);
      if (clean == null) {
        throw const DiscoverException(
          "That search is too long or contains characters it can't use.",
        );
      }
      final answer = await _backendJson(
        '/api/tracks',
        {'q': clean},
        const Duration(seconds: 15),
      );
      return parseTracks(answer, search: true);
    }

    final root = await _lastFmJson(keys.lastFm, {
      'method': 'track.search',
      'track': trimmed,
    });
    return _withAlbumArt(keys.lastFm, parseTracks(root, search: true));
  }

  Future<Map<String, dynamic>> _lastFmJson(
    String key,
    Map<String, String> params,
  ) {
    final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {
      ...params,
      'api_key': key,
      'format': 'json',
    });
    return _directJson(
      uri,
      timeout: const Duration(seconds: 15),
      unreachable:
          'Could not reach Last.fm. Check your connection and API key, then retry.',
      unsuccessful: 'Last.fm returned an unsuccessful response.',
      invalid: 'Last.fm returned an invalid response.',
    );
  }

  /// Fills in album artwork from Last.fm (only possible with the user's own
  /// Last.fm key), falling back to the image in the track list.
  Future<List<DiscoveredTrack>> _withAlbumArt(
    String key,
    List<DiscoveredTrack> tracks,
  ) {
    return Future.wait(
      tracks.map((track) async {
        final art = await _fetchAlbumArt(key, track.name, track.artist);
        if (art.isEmpty) return track;
        return DiscoveredTrack(
          name: track.name,
          artist: track.artist,
          imageUrl: art,
        );
      }),
    );
  }

  Future<String> _fetchAlbumArt(String key, String track, String artist) async {
    final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {
      'method': 'track.getInfo',
      'api_key': key,
      'artist': artist,
      'track': track,
      'format': 'json',
    });
    try {
      final response = await _get(uri, const {}, const Duration(seconds: 15));
      if (response.statusCode != 200) return '';
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) return '';
      final trackInfo = data['track'];
      final album = trackInfo is Map ? trackInfo['album'] : null;
      final images = album is Map ? album['image'] : null;
      return largestImage(images);
    } catch (_) {
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Audio (YouTube + audio service)
  // ---------------------------------------------------------------------------

  /// The id of the YouTube video that best matches the track.
  Future<String> findVideoId(String trackName, String artistName) async {
    final keys = _keys();
    final query = '$trackName $artistName';

    final Map<String, dynamic> root;
    if (keys.youtube.isEmpty) {
      final clean = backendVideoQuery(query);
      if (clean.isEmpty) {
        throw const DiscoverException('No matching YouTube video was found.');
      }
      root = await _backendJson(
        '/api/video',
        {'q': clean},
        const Duration(seconds: 25),
      );
    } else {
      final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
        'part': 'snippet',
        'q': query,
        'type': 'video',
        'maxResults': '1',
        'key': keys.youtube,
      });
      root = await _directJson(
        uri,
        timeout: const Duration(seconds: 20),
        unreachable:
            'YouTube search failed. Check your connection, API key or quota.',
        unsuccessful:
            'YouTube rejected the search. Check your API key or quota.',
        invalid: 'YouTube returned an invalid response.',
      );
    }
    return parseVideoId(root);
  }

  /// A downloadable audio link for [videoId]. The audio service converts
  /// some videos on demand, so this asks again while it reports
  /// "processing" — four attempts, two seconds apart.
  Future<String> resolveAudioLink(String videoId) async {
    if (!_videoIdPattern.hasMatch(videoId)) {
      throw const DiscoverException('No matching YouTube video was found.');
    }
    final keys = _keys();
    const attempts = 4;

    for (var attempt = 0; attempt < attempts; attempt++) {
      final Map<String, dynamic> root;
      if (keys.rapidApi.isEmpty) {
        root = await _backendJson(
          '/api/resolve',
          {'id': videoId},
          const Duration(seconds: 30),
        );
      } else {
        root = await _directJson(
          Uri.https(_rapidApiHost, '/dl', {'id': videoId}),
          headers: {
            'X-RapidAPI-Key': keys.rapidApi,
            'X-RapidAPI-Host': _rapidApiHost,
          },
          timeout: const Duration(seconds: 20),
          unreachable:
              'Audio resolution failed. Check your connection, RapidAPI key or quota.',
          unsuccessful:
              'The audio service rejected the request. Check your RapidAPI key or quota.',
          invalid: 'The audio service returned an invalid response.',
        );
      }

      final link = parseResolution(root);
      if (link != null) {
        rejectCredentialsInLink(link, keys.all);
        return link;
      }
      if (attempt < attempts - 1) {
        await Future<void>.delayed(_retryDelay);
      }
    }
    throw const DiscoverException(
      'The audio is still processing after four attempts. Try again later.',
    );
  }

  // ---------------------------------------------------------------------------
  // Requests
  // ---------------------------------------------------------------------------

  /// GETs [uri] without following redirects, within [timeout].
  Future<http.Response> _get(
    Uri uri,
    Map<String, String> headers,
    Duration timeout,
  ) {
    Future<http.Response> run() async {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers.addAll(headers);
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    }

    return run().timeout(timeout);
  }

  /// GETs one of Noir Player's backend endpoints. Its errors are written for
  /// the person using the app, so they are shown as they come.
  Future<Map<String, dynamic>> _backendJson(
    String path,
    Map<String, String>? query,
    Duration timeout,
  ) async {
    final uri = Uri.parse(
      _backend,
    ).replace(path: path, queryParameters: query);

    final http.Response response;
    try {
      response = await _get(uri, const {}, timeout);
    } catch (_) {
      throw const DiscoverException(
        "Couldn't reach Noir Player's server. Check your connection and try again.",
      );
    }
    if (response.bodyBytes.length > _maxBodyBytes) {
      throw const DiscoverException(
        "Couldn't read the answer from Noir Player's server.",
      );
    }
    final root = decodeJsonObject(response.bodyBytes);
    if (root == null) {
      throw const DiscoverException(
        "Noir Player's server sent back something unexpected.",
      );
    }
    if (response.statusCode != 200) {
      throw DiscoverException(backendErrorMessage(root));
    }
    return root;
  }

  /// GETs a service directly with the user's own key.
  Future<Map<String, dynamic>> _directJson(
    Uri uri, {
    Map<String, String> headers = const {},
    required Duration timeout,
    required String unreachable,
    required String unsuccessful,
    required String invalid,
  }) async {
    final http.Response response;
    try {
      response = await _get(uri, headers, timeout);
    } catch (_) {
      throw DiscoverException(unreachable);
    }
    if (response.statusCode != 200) {
      throw DiscoverException(unsuccessful);
    }
    if (response.bodyBytes.length > _maxBodyBytes) {
      throw DiscoverException(invalid);
    }
    final root = decodeJsonObject(response.bodyBytes);
    if (root == null) {
      throw DiscoverException(invalid);
    }
    return root;
  }
}

// -----------------------------------------------------------------------------
// Parsing (pure functions, unit-tested)
// -----------------------------------------------------------------------------

/// A JSON object from [bytes], or null when it isn't one.
Map<String, dynamic>? decodeJsonObject(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// The message from a backend error body (`{"error": "..."}`).
String backendErrorMessage(Map<String, dynamic> root) {
  final error = root['error'];
  if (error is String && error.trim().isNotEmpty) return error.trim();
  return "Noir Player's server couldn't handle that. Try again later.";
}

/// A trimmed search the backend accepts, or null when it is empty, too long
/// or contains control characters.
String? validSearchQuery(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.length > maxQueryLength) return null;
  if (_controlChars.hasMatch(trimmed)) return null;
  return trimmed;
}

/// "Song Artist" made acceptable to the backend: control characters become
/// spaces and the text is cut to [maxQueryLength] without splitting a
/// character in two.
String backendVideoQuery(String raw) {
  var text = raw.replaceAll(_controlChars, ' ').trim();
  if (text.length > maxQueryLength) {
    var end = maxQueryLength;
    final last = text.codeUnitAt(end - 1);
    if (last >= 0xD800 && last <= 0xDBFF) end--; // high surrogate
    text = text.substring(0, end).trim();
  }
  return text;
}

/// Tracks from a Last.fm-shaped answer: `tracks.track[]` for the chart,
/// `results.trackmatches.track[]` for a search. The artist is a string in
/// search results and an object with a `name` in charts.
List<DiscoveredTrack> parseTracks(
  Map<String, dynamic> root, {
  required bool search,
}) {
  if (root.containsKey('error')) {
    throw const DiscoverException(
      'Last.fm rejected the request. Check your API key or retry later.',
    );
  }

  final dynamic list;
  if (search) {
    final results = root['results'];
    final matches = results is Map ? results['trackmatches'] : null;
    list = matches is Map ? matches['track'] : null;
  } else {
    final tracks = root['tracks'];
    list = tracks is Map ? tracks['track'] : null;
  }

  final List<dynamic> entries;
  if (list is List) {
    entries = list;
  } else if (list is Map) {
    // Last.fm sends a single match as an object rather than a list.
    entries = [list];
  } else if (search && list == null) {
    return [];
  } else {
    throw const DiscoverException(
      'Last.fm returned an unexpected track list.',
    );
  }

  final result = <DiscoveredTrack>[];
  for (final entry in entries) {
    if (entry is! Map) continue;
    final name = entry['name'];
    if (name is! String || name.trim().isEmpty) continue;

    final artistField = entry['artist'];
    String artist = '';
    if (artistField is String) {
      artist = artistField;
    } else if (artistField is Map && artistField['name'] is String) {
      artist = artistField['name'] as String;
    }
    if (artist.trim().isEmpty) artist = 'Unknown Artist';

    result.add(
      DiscoveredTrack(
        name: name,
        artist: artist,
        imageUrl: largestImage(entry['image']),
      ),
    );
  }
  return result;
}

/// The largest non-empty image URL in a Last.fm `image` list, or ''.
String largestImage(dynamic images) {
  if (images is! List) return '';
  for (final image in images.reversed) {
    final text = image is Map ? image['#text'] : null;
    if (text is String && text.isNotEmpty) return text;
  }
  return '';
}

/// The video id from a YouTube-shaped answer (`items[0].id.videoId`).
String parseVideoId(Map<String, dynamic> root) {
  if (root.containsKey('error')) {
    throw const DiscoverException(
      'YouTube rejected the search. Check your API key or quota.',
    );
  }
  final items = root['items'];
  final first = items is List && items.isNotEmpty ? items.first : null;
  final id = first is Map ? first['id'] : null;
  final videoId = id is Map ? id['videoId'] : null;
  if (videoId is String && _videoIdPattern.hasMatch(videoId)) return videoId;
  throw const DiscoverException('No matching YouTube video was found.');
}

/// The link from an audio-service answer, or null while it reports
/// `{"status": "processing"}`.
String? parseResolution(Map<String, dynamic> root) {
  final link = root['link'];
  if (link is String && link.isNotEmpty) {
    if (!isSafeAudioLink(link)) {
      throw const DiscoverException(
        "The audio service sent back a link that isn't safe to use.",
      );
    }
    return link;
  }
  if (root['status'] == 'processing') return null;
  throw const DiscoverException(
    'No downloadable audio was returned for this song. Try another one.',
  );
}

/// True for an HTTPS link to a public DNS name on the default port, with no
/// credentials, fragment or unusual characters.
bool isSafeAudioLink(String url) {
  if (url.length > 8192) return false;
  for (final c in url.codeUnits) {
    // Controls, spaces, non-ASCII, backslash and '#'.
    if (c <= 32 || c >= 127 || c == 0x5C || c == 0x23) return false;
  }

  final Uri uri;
  try {
    uri = Uri.parse(url);
  } on FormatException {
    return false;
  }
  if (uri.scheme != 'https' ||
      uri.userInfo.isNotEmpty ||
      uri.authority.contains('@') ||
      uri.port != 443) {
    return false;
  }

  final host = uri.host.toLowerCase();
  if (host.isEmpty || host.length > 253 || !host.contains('.')) return false;
  const localSuffixes = [
    '.localhost',
    '.local',
    '.internal',
    '.lan',
    '.home',
    '.localdomain',
  ];
  for (final suffix in localSuffixes) {
    if (host.endsWith(suffix)) return false;
  }

  final labels = host.split('.');
  final topLevel = labels.last;
  if (topLevel.length < 2 || !RegExp(r'^[a-z]+$').hasMatch(topLevel)) {
    return false;
  }
  final labelPattern = RegExp(r'^[a-z0-9-]{1,63}$');
  for (final label in labels) {
    if (!labelPattern.hasMatch(label) ||
        label.startsWith('-') ||
        label.endsWith('-')) {
      return false;
    }
  }
  return true;
}

/// Throws when [link] contains any of [keys], raw or percent-decoded. A
/// service that echoed a key back into a link would otherwise leak it.
void rejectCredentialsInLink(String link, List<String> keys) {
  final String decoded;
  try {
    decoded = Uri.decodeComponent(link);
  } catch (_) {
    throw const DiscoverException(
      "The audio service sent back a link that isn't safe to use.",
    );
  }
  for (final key in keys) {
    if (key.isNotEmpty && (link.contains(key) || decoded.contains(key))) {
      throw const DiscoverException(
        "The audio service sent back a link that isn't safe to use.",
      );
    }
  }
}
