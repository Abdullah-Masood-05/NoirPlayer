// import 'package:flutter/material.dart';

// class PlaylistsTab extends StatelessWidget {
//   const PlaylistsTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('Playlists will appear here'));
//   }
// }






// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:noir_player/screens/playlists/playlist_songs_screen.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import '../../playlists/playlists_screen.dart';
// import 'package:noir_player/core/services/audio_handler.dart';

// class PlaylistsTab extends StatefulWidget {
//   const PlaylistsTab({super.key});

//   @override
//   State<PlaylistsTab> createState() => _PlaylistsTabState();
// }

// class _PlaylistsTabState extends State<PlaylistsTab> {
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   List<PlaylistModel> _playlists = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadPlaylists();
//   }

//   Future<File> get _playlistsFile async {
//     final dir = await getApplicationDocumentsDirectory();
//     return File('${dir.path}/playlists.json');
//   }

//   Future<void> _loadPlaylists() async {
//     try {
//       final file = await _playlistsFile;
//       if (!await file.exists()) {
//         // Create default JSON with Favorites
//         final defaultJson = jsonEncode({
//           "playlists": [
//             {
//               "name": "Favorites",
//               "maxSongs": 10,
//               "songs": [],
//               "isFavourite": true
//             }
//           ]
//         });
//         await file.writeAsString(defaultJson);
//       }

//       final contents = await file.readAsString();
//       final data = jsonDecode(contents) as Map<String, dynamic>;
//       final list = (data['playlists'] as List)
//           .map((e) => PlaylistModel.fromJson(e))
//           .toList();

//       setState(() {
//         _playlists = list;
//         _isLoading = false;
//       });
//     } catch (e) {
//       debugPrint('Error loading playlists: $e');
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _savePlaylists() async {
//     final file = await _playlistsFile;
//     final jsonStr = jsonEncode({
//       "playlists": _playlists.map((e) => e.toJson()).toList(),
//     });
//     await file.writeAsString(jsonStr);
//   }

//   void _addPlaylist() async {
//     if (_playlists.length >= 5) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Maximum 5 playlists allowed.')),
//       );
//       return;
//     }

//     final controller = TextEditingController();
//     await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('New Playlist'),
//         content: TextField(
//           controller: controller,
//           decoration: const InputDecoration(hintText: 'Playlist name'),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final name = controller.text.trim();
//               if (name.isNotEmpty) {
//                 setState(() {
//                   _playlists.add(
//                     PlaylistModel(
//                       name: name,
//                       maxSongs: 5,
//                       songs: [],
//                       isFavourite: false,
//                     ),
//                   );
//                 });
//                 _savePlaylists();
//                 Navigator.pop(context);
//               }
//             },
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _deletePlaylist(int index) {
//     final playlist = _playlists[index];
//     if (playlist.isFavourite) return; // cannot delete favorites

//     setState(() => _playlists.removeAt(index));
//     _savePlaylists();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) return const Center(child: CircularProgressIndicator());

//     if (_playlists.isEmpty) {
//       return Center(
//         child: TextButton(
//           onPressed: _addPlaylist,
//           child: const Text('Add your first playlist'),
//         ),
//       );
//     }

//     return Scaffold(
//       floatingActionButton: _playlists.length < 5
//           ? FloatingActionButton(
//               onPressed: _addPlaylist,
//               child: const Icon(Icons.add),
//             )
//           : null,
//       body: GridView.builder(
//         padding: const EdgeInsets.all(8),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 12,
//           crossAxisSpacing: 12,
//           childAspectRatio: 0.9,
//         ),
//         itemCount: _playlists.length,
//         itemBuilder: (context, index) {
//           final playlist = _playlists[index];
//           return GestureDetector(
//             onTap: () async {
//               // Navigate to PlaylistSongsScreen
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => PlaylistSongsScreen(
//                     playlist: playlist,
//                     onUpdate: () => _savePlaylists(),
//                   ),
//                 ),
//               );
//             },
//             child: Card(
//               elevation: 3,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               clipBehavior: Clip.antiAlias,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Expanded(
//                     child: playlist.songs.isEmpty
//                         ? Container(
//                             color: Colors.grey[850],
//                             child: const Icon(
//                               Icons.queue_music_rounded,
//                               size: 60,
//                               color: Colors.white54,
//                             ),
//                           )
//                         : QueryArtworkWidget(
//                             id: playlist.songs.first.id,
//                             type: ArtworkType.AUDIO,
//                             artworkFit: BoxFit.cover,
//                             nullArtworkWidget: Container(
//                               color: Colors.grey[850],
//                               child: const Icon(
//                                 Icons.queue_music_rounded,
//                                 size: 60,
//                                 color: Colors.white54,
//                               ),
//                             ),
//                           ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           playlist.name,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           '${playlist.songs.length} songs',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (!playlist.isFavourite)
//                     Align(
//                       alignment: Alignment.topRight,
//                       child: IconButton(
//                         icon: const Icon(Icons.delete),
//                         onPressed: () => _deletePlaylist(index),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // 🎵 Playlist model
// class PlaylistModel {
//   final String name;
//   final int maxSongs;
//   final List<PlaylistSong> songs;
//   final bool isFavourite;

//   PlaylistModel({
//     required this.name,
//     required this.maxSongs,
//     required this.songs,
//     required this.isFavourite,
//   });

//   factory PlaylistModel.fromJson(Map<String, dynamic> json) => PlaylistModel(
//         name: json['name'],
//         maxSongs: json['maxSongs'],
//         songs: (json['songs'] as List)
//             .map((s) => PlaylistSong.fromJson(s as Map<String, dynamic>))
//             .toList(),
//         isFavourite: json['isFavourite'] ?? false,
//       );

//   Map<String, dynamic> toJson() => {
//         'name': name,
//         'maxSongs': maxSongs,
//         'songs': songs.map((s) => s.toJson()).toList(),
//         'isFavourite': isFavourite,
//       };
// }

// // Add this class definition below PlaylistModel or in a separate file if preferred.
// class PlaylistSong {
//   final int id;
//   final String title;
//   final String artist;

//   PlaylistSong({
//     required this.id,
//     required this.title,
//     required this.artist,
//   });

//   factory PlaylistSong.fromJson(Map<String, dynamic> json) => PlaylistSong(
//         id: json['id'],
//         title: json['title'],
//         artist: json['artist'],
//       );

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'title': title,
//         'artist': artist,
//       };
// }




// lib/screens/library/tabs/playlists_tab.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import '../../../core/models/playlist_model.dart';
// import '../../playlists/playlist_songs_screen.dart';
// import '../../player/player_screen.dart';
// import '../../../core/services/audio_handler.dart';

// class PlaylistsTab extends StatefulWidget {
//   final VoidCallback onNavigateToPlayer;

//   const PlaylistsTab({super.key, required this.onNavigateToPlayer});

//   @override
//   State<PlaylistsTab> createState() => _PlaylistsTabState();
// }

// class _PlaylistsTabState extends State<PlaylistsTab> {
//   List<PlaylistModel> _playlists = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadPlaylists();
//   }

//   Future<File> get _localFile async {
//     final dir = await getApplicationDocumentsDirectory();
//     return File('${dir.path}/playlists.json');
//   }

//   Future<void> _loadPlaylists() async {
//     try {
//       final file = await _localFile;
//       if (await file.exists()) {
//         final content = await file.readAsString();
//         final jsonList = jsonDecode(content) as List<dynamic>;
//         setState(() {
//           _playlists = jsonList
//               .map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>))
//               .toList();
//         });
//       } else {
//         // create default favorites playlist
//         final favorite = PlaylistModel(name: 'Favorites', songs: [], isFavourite: true);
//         _playlists = [favorite];
//         await _savePlaylists();
//       }
//     } catch (e) {
//       debugPrint('Error loading playlists: $e');
//     }
//   }

//   Future<void> _savePlaylists() async {
//     final file = await _localFile;
//     await file.writeAsString(jsonEncode(_playlists.map((p) => p.toJson()).toList()));
//   }

//   void _createPlaylist() {
//     if (_playlists.length >= 5) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Maximum 5 playlists allowed.')),
//       );
//       return;
//     }
//     showDialog(
//       context: context,
//       builder: (ctx) {
//         final controller = TextEditingController();
//         return AlertDialog(
//           title: const Text('New Playlist'),
//           content: TextField(controller: controller),
//           actions: [
//             TextButton(
//                 onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
//             ElevatedButton(
//               onPressed: () {
//                 final name = controller.text.trim();
//                 if (name.isNotEmpty) {
//                   setState(() {
//                     _playlists.add(PlaylistModel(name: name, songs: []));
//                   });
//                   _savePlaylists();
//                   Navigator.pop(ctx);
//                 }
//               },
//               child: const Text('Create'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _deletePlaylist(int index) {
//     final playlist = _playlists[index];
//     if (playlist.isFavourite) return;
//     setState(() {
//       _playlists.removeAt(index);
//     });
//     _savePlaylists();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         onPressed: _createPlaylist,
//         child: const Icon(Icons.add),
//       ),
//       body: _playlists.isEmpty
//           ? const Center(child: Text('No playlists yet'))
//           : ListView.separated(
//               itemCount: _playlists.length,
//               separatorBuilder: (_, __) => const Divider(),
//               itemBuilder: (context, index) {
//                 final playlist = _playlists[index];
//                 return ListTile(
//                   leading: const Icon(Icons.playlist_play),
//                   title: Text(playlist.name),
//                   subtitle: Text('${playlist.songs.length} songs'),
//                   trailing: playlist.isFavourite
//                       ? null
//                       : IconButton(
//                           icon: const Icon(Icons.delete),
//                           onPressed: () => _deletePlaylist(index),
//                         ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => PlaylistSongsScreen(
//                           playlist: playlist,
//                           onNavigateToPlayer: widget.onNavigateToPlayer,
//                           onUpdatePlaylist: () {
//                             setState(() {});
//                             _savePlaylists();
//                           },
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }



import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/models/playlist_model.dart';
import '../../playlists/playlist_songs_screen.dart';

class PlaylistsTab extends StatefulWidget {
  final VoidCallback onNavigateToPlayer;

  const PlaylistsTab({super.key, required this.onNavigateToPlayer});

  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  List<PlaylistModel> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/playlists.json');
  }

  Future<void> _loadPlaylists() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = jsonDecode(content) as List<dynamic>;
        setState(() {
          _playlists = jsonList
              .map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } else {
        final favorite =
            PlaylistModel(name: 'Favorites', songs: [], isFavourite: true);
        _playlists = [favorite];
        await _savePlaylists();
      }
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    }
  }

  Future<void> _savePlaylists() async {
    final file = await _localFile;
    await file
        .writeAsString(jsonEncode(_playlists.map((p) => p.toJson()).toList()));
  }

  void _createPlaylist() {
    if (_playlists.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 playlists allowed.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('New Playlist'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Enter playlist name...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _playlists.add(PlaylistModel(name: name, songs: []));
                  });
                  _savePlaylists();
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeletePlaylist(int index) async {
    final playlist = _playlists[index];
    if (playlist.isFavourite) return; // cannot delete favourites

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _playlists.removeAt(index));
      _savePlaylists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        child: const Icon(Icons.add),
      ),
      body: _playlists.isEmpty
          ? const Center(child: Text('No playlists yet'))
          : ListView.separated(
              itemCount: _playlists.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final playlist = _playlists[index];
                return ListTile(
                  leading: Icon(
                    playlist.isFavourite
                        ? Icons.favorite
                        : Icons.playlist_play,
                  ),
                  title: Text(playlist.name),
                  subtitle: Text('${playlist.songs.length} songs'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaylistSongsScreen(
                          playlist: playlist,
                          onNavigateToPlayer: widget.onNavigateToPlayer,
                          onUpdatePlaylist: () {
                            setState(() {});
                            _savePlaylists();
                          },
                        ),
                      ),
                    );
                  },
                  onLongPress: () => _confirmDeletePlaylist(index),
                );
              },
            ),
    );
  }
}
