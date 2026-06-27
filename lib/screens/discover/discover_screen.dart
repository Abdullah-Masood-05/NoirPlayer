import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/discovered_track.dart';
import '../../core/services/audio_handler.dart';
import '../../core/services/music_discovery_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/now_playing_indicator.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, required this.onNavigateToPlayer});

  final VoidCallback onNavigateToPlayer;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final MusicDiscoveryService _discoveryService = MusicDiscoveryService();
  final TextEditingController _searchController = TextEditingController();

  List<DiscoveredTrack> _tracks = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _loadingTrack;
  final Map<String, double> _downloadProgress = {};

  String _keyFor(DiscoveredTrack t) => '${t.name}-${t.artist}';

  @override
  void initState() {
    super.initState();
    _discoveryService.loadDownloadedKeys().then((_) {
      if (mounted) setState(() {});
    });
    _loadTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discoveryService.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoading = true);
    try {
      final tracks = await _discoveryService.fetchTrendingTracks();
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _isLoading = false;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Error loading trending: $e');
    }
  }

  Future<void> _searchSongs(String query) async {
    if (query.trim().isEmpty) {
      _loadTrending();
      return;
    }
    setState(() {
      _isLoading = true;
      _isSearching = true;
    });
    try {
      final tracks = await _discoveryService.searchTracks(query);
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Error searching: $e');
    }
  }

  Future<void> _playTrack(DiscoveredTrack track) async {
    final key = _keyFor(track);
    setState(() => _loadingTrack = key);
    try {
      final videoId = await _discoveryService.fetchYoutubeVideoId(
        track.name,
        track.artist,
      );
      if (videoId.isEmpty) throw Exception('No source found');

      final mp3Url = await _discoveryService.getDownloadUrl(videoId);
      if (mp3Url == null || mp3Url.isEmpty) {
        throw Exception('No stream URL found');
      }

      // Play through the main player so it shows in the player / mini-player /
      // notification and is fully controllable.
      await (audioHandler as AudioPlayerHandler).playStream(
        id: 'discover:$key',
        url: mp3Url,
        title: track.name,
        artist: track.artist,
        artUri: track.imageUrl,
      );
      if (!mounted) return;
      setState(() => _loadingTrack = null);
      widget.onNavigateToPlayer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTrack = null);
      _showSnack('Error playing track: $e');
    }
  }

  Future<void> _downloadTrack(DiscoveredTrack track) async {
    final key = _keyFor(track);
    if (_discoveryService.isDownloaded(key)) {
      _showSnack('${track.name} is already downloaded');
      return;
    }
    if (_downloadProgress.containsKey(key)) return;

    setState(() => _downloadProgress[key] = 0.0);
    final result = await _discoveryService.downloadTrack(
      track,
      onProgress: (received, total) {
        if (total > 0 && mounted) {
          setState(() => _downloadProgress[key] = received / total);
        }
      },
    );
    if (!mounted) return;
    setState(() => _downloadProgress.remove(key));

    switch (result) {
      case DownloadResult.success:
        _showSnack(
          'Saved to ${SettingsService.instance.musicFolderLabel}: ${track.name}',
        );
        break;
      case DownloadResult.alreadyExists:
        _showSnack('${track.name} is already downloaded');
        break;
      case DownloadResult.noSource:
        _showSnack('No downloadable source found for ${track.name}');
        break;
      case DownloadResult.failed:
        _showSnack('Failed to download ${track.name}');
        break;
      case DownloadResult.permissionDenied:
        _showSnack(
          'Storage access needed — allow "All files access" for Noir Player, '
          'then try again',
        );
        break;
      case DownloadResult.inProgress:
        break;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.topFade(context),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight),
              _searchBar(theme),
              Expanded(child: _content(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _searchSongs,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search songs, artists…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadTrending();
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _content(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No results found' : 'No tracks available',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
      itemCount: _tracks.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                Icon(
                  _isSearching ? Icons.search : Icons.trending_up,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _isSearching ? 'Results' : 'Trending now',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          );
        }
        final index = i - 1;
        return _trackCard(_tracks[index], index, theme);
      },
    );
  }

  Widget _trackCard(DiscoveredTrack track, int index, ThemeData theme) {
    final key = _keyFor(track);
    final isLoading = _loadingTrack == key;
    final progress = _downloadProgress[key];
    final isDownloaded = _discoveryService.isDownloaded(key);
    final primary = theme.colorScheme.primary;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snap) {
        final isCurrent = snap.data?.id == 'discover:$key';
        return Card(
          child: InkWell(
            onTap: isLoading
                ? null
                : isCurrent
                ? widget.onNavigateToPlayer
                : () => _playTrack(track),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _artwork(track, theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            color: isCurrent ? primary : null,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : isCurrent
                          ? NowPlayingIndicator(color: primary, size: 20)
                          : IconButton(
                              icon: Icon(
                                Icons.play_circle_fill,
                                color: primary,
                                size: 34,
                              ),
                              onPressed: () => _playTrack(track),
                            ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: progress != null
                          ? CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              strokeWidth: 3,
                            )
                          : isDownloaded
                          ? IconButton(
                              tooltip: 'Downloaded',
                              icon: const Icon(
                                Icons.download_done,
                                color: Colors.green,
                              ),
                              onPressed: () =>
                                  _showSnack('${track.name} is already downloaded'),
                            )
                          : IconButton(
                              tooltip: 'Download',
                              icon: const Icon(Icons.download_outlined),
                              onPressed: () => _downloadTrack(track),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 250.ms, delay: (index * 35).ms).slideX(
              begin: 0.06,
              curve: Curves.easeOut,
            );
      },
    );
  }

  Widget _artwork(DiscoveredTrack track, ThemeData theme) {
    final placeholder = Container(
      width: 56,
      height: 56,
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Icon(Icons.music_note, color: theme.colorScheme.primary),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: track.imageUrl.isEmpty
          ? placeholder
          : Image.network(
              track.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}
