import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/models/discovered_track.dart';
import '../../core/services/music_discovery_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final MusicDiscoveryService _discoveryService = MusicDiscoveryService();
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _player = AudioPlayer();

  List<DiscoveredTrack> _tracks = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _currentlyPlayingTrack; // "trackName-artistName"
  bool _isPlaying = false;
  String? _loadingTrack; // Track being loaded
  Map<String, double> _downloadProgress =
      {}; // "trackName-artistName" -> progress

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  @override
  void dispose() {
    _player.dispose();
    _searchController.dispose();
    _discoveryService.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoading = true);
    try {
      final tracks = await _discoveryService.fetchTrendingTracks();
      setState(() {
        _tracks = tracks;
        _isLoading = false;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading trending: $e')));
      }
    }
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) {
      _loadTrending();
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final tracks = await _discoveryService.searchTracks(query);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching: $e')));
      }
    }
  }

  Future<void> _playTrack(DiscoveredTrack track) async {
    final trackKey = '${track.name}-${track.artist}';

    // Toggle play/pause if same track
    if (_currentlyPlayingTrack == trackKey) {
      if (_isPlaying) {
        await _player.pause();
        setState(() => _isPlaying = false);
      } else {
        await _player.play();
        setState(() => _isPlaying = true);
      }
      return;
    }

    // Load new track
    await _player.stop();

    try {
      setState(() => _loadingTrack = trackKey);

      final videoId = await _discoveryService.fetchYoutubeVideoId(
        track.name,
        track.artist,
      );

      if (videoId.isEmpty) {
        throw Exception('No video found');
      }

      final mp3Url = await _discoveryService.getDownloadUrl(videoId);

      if (mp3Url == null || mp3Url.isEmpty) {
        throw Exception('No stream URL found');
      }

      await _player.setUrl(mp3Url);
      setState(() {
        _loadingTrack = null;
        _isPlaying = true;
        _currentlyPlayingTrack = trackKey;
      });
      await _player.play();
    } catch (e) {
      setState(() {
        _loadingTrack = null;
        _currentlyPlayingTrack = null;
        _isPlaying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing track: $e')));
      }
    }
  }

  Future<void> _downloadTrack(DiscoveredTrack track) async {
    final trackKey = '${track.name}-${track.artist}';

    try {
      // Initialize progress
      setState(() {
        _downloadProgress[trackKey] = 0.0;
      });

      // Get video ID
      final videoId = await _discoveryService.fetchYoutubeVideoId(
        track.name,
        track.artist,
      );

      if (videoId.isEmpty) {
        throw Exception('No video found');
      }

      // Get download URL
      final mp3Url = await _discoveryService.getDownloadUrl(videoId);

      if (mp3Url == null || mp3Url.isEmpty) {
        throw Exception('No download URL found');
      }

      // Download file
      final savedUri = await _discoveryService.saveFile(
        mp3Url,
        track.name,
        onProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[trackKey] = received / total;
            });
          }
        },
      );

      // Remove progress indicator
      setState(() {
        _downloadProgress.remove(trackKey);
      });

      if (savedUri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${track.name} downloaded successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _downloadProgress.remove(trackKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: 'Search songs...',
            hintStyle: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _loadTrending();
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _searchSongs(_searchController.text),
                  ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _searchSongs,
          onChanged: (value) => setState(() {}),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_off,
                    size: 64,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching ? 'No results found' : 'No tracks available',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.6,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _tracks.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final track = _tracks[index];
                final trackKey = '${track.name}-${track.artist}';
                final isCurrentTrack = _currentlyPlayingTrack == trackKey;
                final isLoading = _loadingTrack == trackKey;
                final downloadProgress = _downloadProgress[trackKey];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: track.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              track.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.music_note,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                    title: Text(
                      track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrentTrack
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrentTrack
                            ? theme.colorScheme.primary
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Play/Pause button
                        IconButton(
                          icon: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  isCurrentTrack && _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: isCurrentTrack
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                          onPressed: isLoading ? null : () => _playTrack(track),
                        ),
                        // Download button
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: downloadProgress != null
                              ? Center(
                                  child: CircularProgressIndicator(
                                    value: downloadProgress,
                                    strokeWidth: 4,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _downloadTrack(track),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
