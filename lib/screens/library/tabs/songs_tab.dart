//import 'package:audio_service/audio_service.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:noir_player/core/services/audio_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class SongsTab extends StatefulWidget {
  const SongsTab({super.key});

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
  }

  // ✅ Updated permission handling for Android 13+ and below
  Future<void> _requestPermissionAndLoad() async {
    if (await Permission.audio.isGranted ||
        await Permission.storage.isGranted) {
      _loadSongs();

      return;
    }

    // ✅ Android 13+ uses READ_MEDIA_AUDIO instead of storage
    if (await Permission.audio.request().isGranted ||
        await Permission.storage.request().isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('loaded all songs.')));
      _loadSongs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied. Cannot load songs.')),
      );
    }
  }

  Future<void> _loadSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    setState(() => _songs = songs);
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = _songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(_searchText.toLowerCase()) ||
              (song.artist ?? '').toLowerCase().contains(
                _searchText.toLowerCase(),
              ),
        )
        .toList();

    return Column(
      children: [
        // 🔍 Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search songs or artists...',
              prefixIcon: Icon(Icons.search),
              filled: true,
            ),
            onChanged: (value) => setState(() => _searchText = value),
          ),
        ),

        // 🎵 Song list
        Expanded(
          child: _songs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadSongs,
                  child: ListView.builder(
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      return ListTile(
                        leading: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          nullArtworkWidget: const Icon(
                            Icons.music_note,
                            size: 40,
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(song.artist ?? "Unknown Artist"),
                        trailing: Text(
                          _formatDuration(song.duration ?? 0),
                          style: const TextStyle(color: Colors.white60),
                        ),
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Played the songs.')),
                          );
                          // if (!AudioService.running) {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     const SnackBar(
                          //       content: Text(
                          //         'Audio service is not initialized yet.',
                          //       ),
                          //     ),
                          //   );
                          //   return;
                          // }
                          //Navigator.pushNamed(context, '/player');
                          await AudioPlayerHandler().playSong(song.data);

                          //await audioHandler.playSong(song.data);
                          // await (audioHandler as AudioPlayerHandler).playSong(
                          //   song.data,
                          // );
                          if (mounted) {
                            // Navigate to the player screen
                            Navigator.pushNamed(context, '/player');
                          }
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    final minutes = seconds ~/ 60;
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }
}
