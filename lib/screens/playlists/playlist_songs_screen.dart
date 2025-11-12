// lib/screens/playlists/playlist_songs_screen.dart
// import 'package:flutter/material.dart';
// import '../../core/models/playlist_model.dart';
// import 'package:noir_player/core/services/audio_handler.dart';
// import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;

// class PlaylistSongsScreen extends StatefulWidget {
//   final PlaylistModel playlist;
//   final VoidCallback onUpdate; // call this to save updates in parent

//   const PlaylistSongsScreen({
//     super.key,
//     required this.playlist,
//     required this.onUpdate,
//   });

//   @override
//   State<PlaylistSongsScreen> createState() => _PlaylistSongsScreenState();
// }

// class _PlaylistSongsScreenState extends State<PlaylistSongsScreen> {
//   void _playSong(int index) async {
//     final song = widget.playlist.songs[index];

//     if (!isAudioServiceInitialized()) return;

//     final handler = audioHandler as AudioPlayerHandler;

//     // Just pass your playlist songs directly
//     handler.setQueue(widget.playlist.songs);

//     // Play the tapped song at the given index
//     //await handler.playSongAt(index);

//     await handler.playSongAt(index);

//     // Navigate to player screen
//     if (mounted) {
//       Navigator.of(
//         context,
//       ).pushNamed('/player'); // or callback like in HomeScreen
//     }
//   }

//   void _removeSong(int index) {
//     setState(() {
//       widget.playlist.songs.removeAt(index);
//     });
//     widget.onUpdate();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final songs = widget.playlist.songs;

//     if (songs.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(title: Text(widget.playlist.name)),
//         body: const Center(child: Text('No songs in this playlist.')),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(title: Text(widget.playlist.name)),
//       body: ListView.separated(
//         itemCount: songs.length,
//         separatorBuilder: (_, __) => const Divider(),
//         itemBuilder: (context, index) {
//           final song = songs[index];
//           return ListTile(
//             leading: const Icon(Icons.music_note),
//             title: Text(song.title),
//             subtitle: Text(song.artist),
//             trailing: IconButton(
//               icon: const Icon(Icons.remove_circle_outline),
//               onPressed: () => _removeSong(index),
//             ),
//             onTap: () => _playSong(index),
//           );
//         },
//       ),
//     );
//   }
// }


// lib/screens/playlist/playlist_songs_screen.dart
import 'package:flutter/material.dart';
import '../../core/models/playlist_model.dart';
import '../../core/services/audio_handler.dart';
import '../../screens/player/player_screen.dart';

class PlaylistSongsScreen extends StatefulWidget {
  final PlaylistModel playlist;
  final VoidCallback onNavigateToPlayer;
  final VoidCallback onUpdatePlaylist;

  const PlaylistSongsScreen({
    super.key,
    required this.playlist,
    required this.onNavigateToPlayer,
    required this.onUpdatePlaylist,
  });

  @override
  State<PlaylistSongsScreen> createState() => _PlaylistSongsScreenState();
}

class _PlaylistSongsScreenState extends State<PlaylistSongsScreen> {
  void _playSong(int index) {
    final handler = audioHandler as AudioPlayerHandler;
    handler.setQueue(
      widget.playlist.songs.map((s) {
        return s; // use PlaylistSong directly if AudioHandler supports it
      }).toList(),
    );
    handler.playSongAt(index);
    widget.onNavigateToPlayer();
  }

  void _removeSong(int index) {
    setState(() {
      widget.playlist.songs.removeAt(index);
    });
    widget.onUpdatePlaylist();
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.playlist.songs;
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: songs.isEmpty
          ? const Center(child: Text('No songs in this playlist'))
          : ListView.separated(
              itemCount: songs.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeSong(index),
                  ),
                  onTap: () => _playSong(index),
                );
              },
            ),
    );
  }
}
