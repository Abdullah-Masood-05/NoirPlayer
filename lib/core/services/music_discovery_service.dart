import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';
import '../models/discovered_track.dart';

class MusicDiscoveryService {
  static final MusicDiscoveryService _instance =
      MusicDiscoveryService._internal();
  factory MusicDiscoveryService() => _instance;
  MusicDiscoveryService._internal();

  final String lastFmApiKey = '';
  final String youtubeApiKey = '';
  final String rapidApiKey = '';

  static bool mediaStoreInitialized = false;

  /// Fetch album artwork from Last.fm
  Future<String> fetchAlbumArt(String track, String artist) async {
    final url =
        "http://ws.audioscrobbler.com/2.0/?method=track.getInfo&api_key=$lastFmApiKey&artist=$artist&track=$track&format=json";

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      List images = data["track"]["album"]["image"];
      // Pick largest available image
      for (var img in images.reversed) {
        if (img['#text'] != null && img['#text'].toString().isNotEmpty) {
          return img['#text'];
        }
      }
    } catch (e) {
      print("No album image found for $track - $artist");
    }
    return ""; // fallback if no image
  }

  /// Fetch trending tracks from Last.fm
  Future<List<DiscoveredTrack>> fetchTrendingTracks() async {
    final response = await http.get(
      Uri.parse(
        "http://ws.audioscrobbler.com/2.0/?method=geo.gettoptracks&country=pakistan&api_key=$lastFmApiKey&format=json",
      ),
    );

    final data = jsonDecode(response.body);
    List tracks = data['tracks']['track'];

    // Map each track to a Future<DiscoveredTrack>
    List<Future<DiscoveredTrack>> trackFutures = tracks
        .map<Future<DiscoveredTrack>>((t) async {
          final trackName = t['name'];
          final artistName = t['artist']['name'];

          // Fetch real image (async)
          final realImageUrl = await fetchAlbumArt(trackName, artistName);

          return DiscoveredTrack(
            name: trackName,
            artist: artistName,
            imageUrl: realImageUrl.isNotEmpty
                ? realImageUrl
                : t['image'][2]['#text'], // fallback
          );
        })
        .toList();

    // Wait for all futures to complete concurrently
    return await Future.wait(trackFutures);
  }

  /// Search for tracks on Last.fm
  Future<List<DiscoveredTrack>> searchTracks(String query) async {
    if (query.isEmpty) return [];

    final response = await http.get(
      Uri.parse(
        "http://ws.audioscrobbler.com/2.0/?method=track.search&track=$query&api_key=$lastFmApiKey&format=json",
      ),
    );

    final data = jsonDecode(response.body);
    dynamic tracksData = data['results']['trackmatches']['track'];
    if (tracksData == null) return [];

    // Ensure it's a list
    final tracksList = tracksData is List ? tracksData : [tracksData];

    // Fetch images in parallel
    final futures = tracksList.map<Future<DiscoveredTrack>>((t) async {
      final trackName = t['name'];
      final artistName = t['artist'];
      final realImageUrl = await fetchAlbumArt(trackName, artistName);

      return DiscoveredTrack(
        name: trackName,
        artist: artistName,
        imageUrl: realImageUrl.isNotEmpty
            ? realImageUrl
            : t['image'][2]['#text'],
      );
    });

    return await Future.wait(futures);
  }

  /// Search YouTube for a track and get video ID
  Future<String> fetchYoutubeVideoId(
    String trackName,
    String artistName,
  ) async {
    final query = Uri.encodeComponent('$trackName $artistName');
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&maxResults=1&key=$youtubeApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      print('YouTube API Response: $data');

      if (data['items'] != null && data['items'].isNotEmpty) {
        return data['items'][0]['id']['videoId'] ?? '';
      }
    } catch (e) {
      print('Error fetching YouTube video ID: $e');
    }
    return '';
  }

  /// Get MP3 download URL from RapidAPI
  Future<String?> getDownloadUrl(String videoId) async {
    try {
      final url = Uri.parse("https://yt-mp3.p.rapidapi.com/dl?id=$videoId");

      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': rapidApiKey,
          'X-RapidAPI-Host': 'youtube-mp36.p.rapidapi.com',
        },
      );

      final data = jsonDecode(response.body);
      print('RapidAPI Response: $data');
      return data['link']; // downloadable MP3 URL
    } catch (e) {
      print('Error getting download URL: $e');
      return null;
    }
  }

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Initialize MediaStore
  Future<void> initMediaStore() async {
    if (!mediaStoreInitialized) {
      await MediaStore.ensureInitialized();
      mediaStoreInitialized = true;
    }
  }

  /// Download and save MP3 file
  Future<String?> saveFile(
    String url,
    String filename, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      await initMediaStore();
      MediaStore.appFolder = "NoirPlayerDownloads";

      if (!filename.toLowerCase().endsWith('.mp3')) {
        filename = '$filename.mp3';
      }

      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/$filename';

      await Dio().download(
        url,
        tempFilePath,
        options: Options(
          followRedirects: true,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
        onReceiveProgress: (received, total) {
          if (onProgress != null) {
            onProgress(received, total);
          }
        },
      );

      final mediaStore = MediaStore();
      final savedInfo = await mediaStore.saveFile(
        tempFilePath: tempFilePath,
        dirType: DirType.audio,
        dirName: DirName.music,
        relativePath: null,
      );

      if (savedInfo == null) {
        print('Failed to save file');
        return null;
      }

      return savedInfo.uri.toString();
    } catch (e) {
      print('Error saving file: $e');
      return null;
    }
  }

  void dispose() {
    // Cleanup if needed
  }
}
