// import 'package:flutter/material.dart';

// class PlaylistsScreen extends StatelessWidget {
//   const PlaylistsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text('Playlists Screen'),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/models/playlist_model.dart'; // PlaylistModel & PlaylistSong
import 'playlist_songs_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key, required this.onNavigateToPlayer});

  final VoidCallback onNavigateToPlayer;

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<PlaylistModel> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<File> get _playlistFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/playlists.json');
  }

  Future<void> _loadPlaylists() async {
    try {
      final file = await _playlistFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonData = json.decode(contents);
        setState(() {
          _playlists = jsonData.map((e) => PlaylistModel.fromJson(e)).toList();
        });
      } else {
        // initialize with favourite playlist
        setState(() {
          _playlists = [
            PlaylistModel(
              name: 'Favourites',
              maxSongs: 10,
              songs: [],
              isFavourite: true,
            ),
          ];
        });
      }
    } catch (e) {
      debugPrint('Error reading playlists: $e');
    }
  }

  Future<void> _savePlaylists() async {
    final file = await _playlistFile;
    await file.writeAsString(
      json.encode(_playlists.map((e) => e.toJson()).toList()),
    );
  }

  void _deletePlaylist(int index) {
    final playlist = _playlists[index];
    if (playlist.isFavourite) return; // cannot delete favourites
    setState(() => _playlists.removeAt(index));
    _savePlaylists();
  }

  @override
  Widget build(BuildContext context) {
    if (_playlists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaylistSongsScreen(
                  playlist: playlist,
                  onNavigateToPlayer: widget.onNavigateToPlayer,
                  onUpdatePlaylist: () =>
                      _savePlaylists(), // callback to save changes
                ),
              ),
            );
          },
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey[850],
                    child: Center(
                      child: Icon(
                        playlist.isFavourite
                            ? Icons.favorite
                            : Icons.playlist_play,
                        size: 50,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.songs.length} songs',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (!playlist.isFavourite)
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () => _deletePlaylist(index),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
