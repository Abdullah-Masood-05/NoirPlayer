// //import 'package:audio_service/audio_service.dart';
// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:noir_player/core/services/audio_handler.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:permission_handler/permission_handler.dart';

// class SongsTab extends StatefulWidget {
//   const SongsTab({super.key});

//   @override
//   State<SongsTab> createState() => _SongsTabState();
// }

// class _SongsTabState extends State<SongsTab> {
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   List<SongModel> _songs = [];
//   String _searchText = '';

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissionAndLoad();
//   }

//   // ✅ Updated permission handling for Android 13+ and below
//   Future<void> _requestPermissionAndLoad() async {
//     if (await Permission.audio.isGranted ||
//         await Permission.storage.isGranted) {
//       _loadSongs();

//       return;
//     }

//     // ✅ Android 13+ uses READ_MEDIA_AUDIO instead of storage
//     if (await Permission.audio.request().isGranted ||
//         await Permission.storage.request().isGranted) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('loaded all songs.')));
//       _loadSongs();
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Permission denied. Cannot load songs.')),
//       );
//     }
//   }

//   Future<void> _loadSongs() async {
//     final songs = await _audioQuery.querySongs(
//       sortType: SongSortType.TITLE,
//       orderType: OrderType.ASC_OR_SMALLER,
//       uriType: UriType.EXTERNAL,
//       ignoreCase: true,
//     );
//     setState(() => _songs = songs);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredSongs = _songs
//         .where(
//           (song) =>
//               song.title.toLowerCase().contains(_searchText.toLowerCase()) ||
//               (song.artist ?? '').toLowerCase().contains(
//                 _searchText.toLowerCase(),
//               ),
//         )
//         .toList();

//     return Column(
//       children: [
//         // 🔍 Search bar
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: TextField(
//             decoration: const InputDecoration(
//               hintText: 'Search songs or artists...',
//               prefixIcon: Icon(Icons.search),
//               filled: true,
//             ),
//             onChanged: (value) => setState(() => _searchText = value),
//           ),
//         ),

//         // 🎵 Song list
//         Expanded(
//           child: _songs.isEmpty
//               ? const Center(child: CircularProgressIndicator())
//               : RefreshIndicator(
//                   onRefresh: _loadSongs,
//                   child: ListView.builder(
//                     itemCount: filteredSongs.length,
//                     itemBuilder: (context, index) {
//                       final song = filteredSongs[index];
//                       return ListTile(
//                         leading: QueryArtworkWidget(
//                           id: song.id,
//                           type: ArtworkType.AUDIO,
//                           nullArtworkWidget: const Icon(
//                             Icons.music_note,
//                             size: 40,
//                           ),
//                         ),
//                         title: Text(
//                           song.title,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         subtitle: Text(song.artist ?? "Unknown Artist"),
//                         trailing: Text(
//                           _formatDuration(song.duration ?? 0),
//                           style: const TextStyle(color: Colors.white60),
//                         ),
//                         onTap: () async {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('Played the songs.')),
//                           );
//                           // if (!AudioService.running) {
//                           //   ScaffoldMessenger.of(context).showSnackBar(
//                           //     const SnackBar(
//                           //       content: Text(
//                           //         'Audio service is not initialized yet.',
//                           //       ),
//                           //     ),
//                           //   );
//                           //   return;
//                           // }
//                           //Navigator.pushNamed(context, '/player');
//                           await AudioPlayerHandler().playSong(song.data);

//                           //await audioHandler.playSong(song.data);
//                           // await (audioHandler as AudioPlayerHandler).playSong(
//                           //   song.data,
//                           // );
//                           if (mounted) {
//                             // Navigate to the player screen
//                             Navigator.pushNamed(context, '/player');
//                           }
//                         },
//                       );
//                     },
//                   ),
//                 ),
//         ),
//       ],
//     );
//   }

//   String _formatDuration(int milliseconds) {
//     final seconds = (milliseconds / 1000).round();
//     final minutes = seconds ~/ 60;
//     final remaining = (seconds % 60).toString().padLeft(2, '0');
//     return '$minutes:$remaining';
//   }
// }

// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:noir_player/core/services/audio_handler.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:permission_handler/permission_handler.dart';

// class SongsTab extends StatefulWidget {
//   const SongsTab({super.key});

//   @override
//   State<SongsTab> createState() => _SongsTabState();
// }

// class _SongsTabState extends State<SongsTab> {
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   List<SongModel> _songs = [];
//   String _searchText = '';

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissionAndLoad();
//   }

//   Future<void> _requestPermissionAndLoad() async {
//     if (await Permission.audio.isGranted ||
//         await Permission.storage.isGranted) {
//       _loadSongs();
//       return;
//     }

//     if (await Permission.audio.request().isGranted ||
//         await Permission.storage.request().isGranted) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Loaded all songs.')),
//         );
//       }
//       _loadSongs();
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Permission denied. Cannot load songs.')),
//         );
//       }
//     }
//   }

//   Future<void> _loadSongs() async {
//     final songs = await _audioQuery.querySongs(
//       sortType: SongSortType.TITLE,
//       orderType: OrderType.ASC_OR_SMALLER,
//       uriType: UriType.EXTERNAL,
//       ignoreCase: true,
//     );
//     setState(() => _songs = songs);
//   }

//   Future<void> _playSongAndNavigate(String songPath, BuildContext context) async {
//     try {
//       print('🎵 Song tapped: $songPath');

//       // ✅ Check if audio service is initialized
//       if (!isAudioServiceInitialized()) {
//         print('❌ AudioService not initialized yet!');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Audio service is not ready yet. Please wait...'),
//               duration: Duration(seconds: 2),
//             ),
//           );
//         }
//         return;
//       }

//       // ✅ Cast audioHandler to AudioPlayerHandler and play the song
//       final handler = audioHandler as AudioPlayerHandler;
//       await handler.playSong(songPath );

//       print('✅ Song playing, navigating to player...');

//       if (mounted) {
//         Navigator.pushNamed(context, '/player');
//       }
//     } catch (e) {
//       print('❌ Error in _playSongAndNavigate: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error playing song: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredSongs = _songs
//         .where(
//           (song) =>
//               song.title.toLowerCase().contains(_searchText.toLowerCase()) ||
//               (song.artist ?? '').toLowerCase().contains(
//                 _searchText.toLowerCase(),
//               ),
//         )
//         .toList();

//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: TextField(
//             decoration: const InputDecoration(
//               hintText: 'Search songs or artists...',
//               prefixIcon: Icon(Icons.search),
//               filled: true,
//             ),
//             onChanged: (value) => setState(() => _searchText = value),
//           ),
//         ),
//         Expanded(
//           child: _songs.isEmpty
//               ? const Center(child: CircularProgressIndicator())
//               : RefreshIndicator(
//                   onRefresh: _loadSongs,
//                   child: ListView.builder(
//                     itemCount: filteredSongs.length,
//                     itemBuilder: (context, index) {
//                       final song = filteredSongs[index];
//                       return ListTile(
//                         leading: QueryArtworkWidget(
//                           id: song.id,
//                           type: ArtworkType.AUDIO,
//                           nullArtworkWidget: const Icon(
//                             Icons.music_note,
//                             size: 40,
//                           ),
//                         ),
//                         title: Text(
//                           song.title,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         subtitle: Text(song.artist ?? "Unknown Artist"),
//                         trailing: Text(
//                           _formatDuration(song.duration ?? 0),
//                           style: const TextStyle(color: Colors.white60),
//                         ),
//                         onTap: () => _playSongAndNavigate(song.data, context),
//                       );
//                     },
//                   ),
//                 ),
//         ),
//       ],
//     );
//   }

//   String _formatDuration(int milliseconds) {
//     final seconds = (milliseconds / 1000).round();
//     final minutes = seconds ~/ 60;
//     final remaining = (seconds % 60).toString().padLeft(2, '0');
//     return '$minutes:$remaining';
//   }
// }

// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:noir_player/core/services/audio_handler.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:permission_handler/permission_handler.dart';

// class SongsTab extends StatefulWidget {
//   const SongsTab({super.key});

//   @override
//   State<SongsTab> createState() => _SongsTabState();
// }

// class _SongsTabState extends State<SongsTab> {
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   List<SongModel> _songs = [];
//   String _searchText = '';

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissionAndLoad();
//   }

//   Future<void> _requestPermissionAndLoad() async {
//     if (await Permission.audio.isGranted ||
//         await Permission.storage.isGranted) {
//       _loadSongs();
//       return;
//     }

//     if (await Permission.audio.request().isGranted ||
//         await Permission.storage.request().isGranted) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Loaded all songs.')));
//       }
//       _loadSongs();
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Permission denied. Cannot load songs.'),
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _loadSongs() async {
//     final songs = await _audioQuery.querySongs(
//       sortType: SongSortType.TITLE,
//       orderType: OrderType.ASC_OR_SMALLER,
//       uriType: UriType.EXTERNAL,
//       ignoreCase: true,
//     );
//     setState(() => _songs = songs);
//   }

//   // ✅ Updated to accept SongModel instead of just String path
//   Future<void> _playSongAndNavigate(
//     SongModel song,
//     BuildContext context,
//   ) async {
//     try {
//       print('🎵 Song tapped: ${song.title}');

//       // ✅ Check if audio service is initialized
//       if (!isAudioServiceInitialized()) {
//         print('❌ AudioService not initialized yet!');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Audio service is not ready yet. Please wait...'),
//               duration: Duration(seconds: 2),
//             ),
//           );
//         }
//         return;
//       }

//       // ✅ Cast audioHandler to AudioPlayerHandler and play the song
//       final handler = audioHandler as AudioPlayerHandler;
//       await handler.playSong(song); // ✅ Pass the entire SongModel

//       print('✅ Song playing, navigating to player...');

//       if (mounted) {
//         Navigator.pushNamed(context, '/player');
//       }
//     } catch (e) {
//       print('❌ Error in _playSongAndNavigate: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error playing song: $e')));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredSongs = _songs
//         .where(
//           (song) =>
//               song.title.toLowerCase().contains(_searchText.toLowerCase()) ||
//               (song.artist ?? '').toLowerCase().contains(
//                 _searchText.toLowerCase(),
//               ),
//         )
//         .toList();

//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: TextField(
//             decoration: const InputDecoration(
//               hintText: 'Search songs or artists...',
//               prefixIcon: Icon(Icons.search),
//               filled: true,
//             ),
//             onChanged: (value) => setState(() => _searchText = value),
//           ),
//         ),
//         Expanded(
//           child: _songs.isEmpty
//               ? const Center(child: CircularProgressIndicator())
//               : RefreshIndicator(
//                   onRefresh: _loadSongs,
//                   child: ListView.builder(
//                     itemCount: filteredSongs.length,
//                     itemBuilder: (context, index) {
//                       final song = filteredSongs[index];
//                       return ListTile(
//                         leading: QueryArtworkWidget(
//                           id: song.id,
//                           type: ArtworkType.AUDIO,
//                           nullArtworkWidget: const Icon(
//                             Icons.music_note,
//                             size: 40,
//                           ),
//                         ),
//                         title: Text(
//                           song.title,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         subtitle: Text(song.artist ?? "Unknown Artist"),
//                         trailing: Text(
//                           _formatDuration(song.duration ?? 0),
//                           style: const TextStyle(color: Colors.white60),
//                         ),
//                         // ✅ Pass the entire SongModel instead of just song.data
//                         onTap: () => _playSongAndNavigate(song, context),
//                       );
//                     },
//                   ),
//                 ),
//         ),
//       ],
//     );
//   }

//   String _formatDuration(int milliseconds) {
//     final seconds = (milliseconds / 1000).round();
//     final minutes = seconds ~/ 60;
//     final remaining = (seconds % 60).toString().padLeft(2, '0');
//     return '$minutes:$remaining';
//   }
// }
//!Main song ABOVE

// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:noir_player/core/services/audio_handler.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:permission_handler/permission_handler.dart';

// class SongsTab extends StatefulWidget {
//   final VoidCallback onNavigateToPlayer; // ✅ callback from LibraryScreen

//   const SongsTab({super.key, required this.onNavigateToPlayer});

//   @override
//   State<SongsTab> createState() => _SongsTabState();
// }

// class _SongsTabState extends State<SongsTab> {
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   List<SongModel> _songs = [];
//   String _searchText = '';

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissionAndLoad();
//   }

//   Future<void> _requestPermissionAndLoad() async {
//     if (await Permission.audio.isGranted ||
//         await Permission.storage.isGranted) {
//       _loadSongs();
//       return;
//     }

//     if (await Permission.audio.request().isGranted ||
//         await Permission.storage.request().isGranted) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Loaded all songs.')));
//       }
//       _loadSongs();
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Permission denied. Cannot load songs.'),
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _loadSongs() async {
//     final songs = await _audioQuery.querySongs(
//       sortType: SongSortType.TITLE,
//       orderType: OrderType.ASC_OR_SMALLER,
//       uriType: UriType.EXTERNAL,
//       ignoreCase: true,
//     );
//     setState(() => _songs = songs);
//   }

//   Future<void> _playSongAndNavigate(
//     SongModel song,
//     BuildContext context,
//   ) async {
//     try {
//       print('🎵 Song tapped: ${song.title}');

//       // ✅ Ensure audio service is initialized
//       if (!isAudioServiceInitialized()) {
//         print('❌ AudioService not initialized yet!');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Audio service is not ready yet. Please wait...'),
//               duration: Duration(seconds: 2),
//             ),
//           );
//         }
//         return;
//       }

//       // ✅ Cast and play
//       final handler = audioHandler as AudioPlayerHandler;
//       await handler.playSong(song);

//       print('✅ Song playing, switching to Player tab...');
//       widget.onNavigateToPlayer(); // ✅ navigate using callback
//     } catch (e) {
//       print('❌ Error in _playSongAndNavigate: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error playing song: $e')));
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredSongs = _songs
//         .where(
//           (song) =>
//               song.title.toLowerCase().contains(_searchText.toLowerCase()) ||
//               (song.artist ?? '').toLowerCase().contains(
//                 _searchText.toLowerCase(),
//               ),
//         )
//         .toList();

//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: TextField(
//             decoration: const InputDecoration(
//               hintText: 'Search songs or artists...',
//               prefixIcon: Icon(Icons.search),
//               filled: true,
//             ),
//             onChanged: (value) => setState(() => _searchText = value),
//           ),
//         ),
//         Expanded(
//           child: _songs.isEmpty
//               ? const Center(child: CircularProgressIndicator())
//               : RefreshIndicator(
//                   onRefresh: _loadSongs,
//                   child: ListView.builder(
//                     itemCount: filteredSongs.length,
//                     itemBuilder: (context, index) {
//                       final song = filteredSongs[index];
//                       return ListTile(
//                         leading: QueryArtworkWidget(
//                           id: song.id,
//                           type: ArtworkType.AUDIO,
//                           nullArtworkWidget: const Icon(
//                             Icons.music_note,
//                             size: 40,
//                           ),
//                         ),
//                         title: Text(
//                           song.title,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         subtitle: Text(song.artist ?? "Unknown Artist"),
//                         trailing: Text(
//                           _formatDuration(song.duration ?? 0),
//                           style: const TextStyle(color: Colors.white60),
//                         ),
//                         onTap: () => _playSongAndNavigate(song, context),
//                       );
//                     },
//                   ),
//                 ),
//         ),
//       ],
//     );
//   }

//   String _formatDuration(int milliseconds) {
//     final seconds = (milliseconds / 1000).round();
//     final minutes = seconds ~/ 60;
//     final remaining = (seconds % 60).toString().padLeft(2, '0');
//     return '$minutes:$remaining';
//   }
// }

// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:noir_player/core/services/audio_handler.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:permission_handler/permission_handler.dart';

// class SongsTab extends StatefulWidget {
//   // ✅ Add callback parameter
//   final VoidCallback onNavigateToPlayer;

//   const SongsTab({super.key, required this.onNavigateToPlayer});

//   @override
//   State<SongsTab> createState() => _SongsTabState();
// }

// class _SongsTabState extends State<SongsTab> {
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   List<SongModel> _songs = [];
//   String _searchText = '';

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissionAndLoad();
//   }

//   Future<void> _requestPermissionAndLoad() async {
//     if (await Permission.audio.isGranted ||
//         await Permission.storage.isGranted) {
//       _loadSongs();
//       return;
//     }

//     if (await Permission.audio.request().isGranted ||
//         await Permission.storage.request().isGranted) {
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Loaded all songs.')));
//       }
//       _loadSongs();
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Permission denied. Cannot load songs.'),
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _loadSongs() async {
//     final songs = await _audioQuery.querySongs(
//       sortType: SongSortType.TITLE,
//       orderType: OrderType.ASC_OR_SMALLER,
//       uriType: UriType.EXTERNAL,
//       ignoreCase: true,
//     );
//     setState(() => _songs = songs);
//   }

//   // ✅ Updated to use callback instead of Navigator.pushNamed
//   Future<void> _playSongAndNavigate(
//     SongModel song,
//     BuildContext context,
//   ) async {
//     try {
//       print('🎵 Song tapped: ${song.title}');

//       // ✅ Check if audio service is initialized
//       if (!isAudioServiceInitialized()) {
//         print('❌ AudioService not initialized yet!');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Audio service is not ready yet. Please wait...'),
//               duration: Duration(seconds: 2),
//             ),
//           );
//         }
//         return;
//       }

//       // ✅ Navigate IMMEDIATELY before starting playback
//       if (mounted) {
//         widget.onNavigateToPlayer();
//       }

//       // ✅ Cast audioHandler to AudioPlayerHandler and play the song
//       final handler = audioHandler as AudioPlayerHandler;
//       handler.playSong(song); // ✅ Removed await - don't wait for completion

//       print('✅ Navigated to player, song starting...');
//     } catch (e) {
//       print('❌ Error in _playSongAndNavigate: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error playing song: $e')));
//       }
//     }
//   }
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:noir_player/core/services/audio_handler.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

class SongsTab extends StatefulWidget {
  // ✅ Callback for navigating to player
  final VoidCallback onNavigateToPlayer;

  const SongsTab({super.key, required this.onNavigateToPlayer});

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

  Future<void> _requestPermissionAndLoad() async {
    if (await Permission.audio.isGranted ||
        await Permission.storage.isGranted) {
      _loadSongs();
      return;
    }

    if (await Permission.audio.request().isGranted ||
        await Permission.storage.request().isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Loaded all songs.')));
      }
      _loadSongs();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Cannot load songs.'),
          ),
        );
      }
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

    // ✅ NEW: set the global queue in AudioHandler
    if (isAudioServiceInitialized()) {
      (audioHandler as AudioPlayerHandler).setQueue(songs);
      print('🎶 Queue set in AudioHandler with ${songs.length} songs.');
    } else {
      print('⚠️ AudioService not initialized yet, queue not set.');
    }
  }

  // ✅ Updated to register current index when playing a song
  Future<void> _playSongAndNavigate(
    SongModel song,
    BuildContext context,
  ) async {
    try {
      print('🎵 Song tapped: ${song.title}');

      if (!isAudioServiceInitialized()) {
        print('❌ AudioService not initialized yet!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio service is not ready yet. Please wait...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // ✅ Navigate first
      if (mounted) {
        widget.onNavigateToPlayer();
      }

      // ✅ Find the tapped song’s index and update handler
      final handler = audioHandler as AudioPlayerHandler;
      final tappedIndex = _songs.indexWhere((s) => s.id == song.id);

      if (tappedIndex != -1) {
        handler.setQueue(_songs); // ensure queue is synced
        await handler.playSongAt(tappedIndex); // play the song at index
        print('▶️ Playing song at index $tappedIndex: ${song.title}');
      } else {
        print('⚠️ Could not find tapped song in queue.');
        await handler.playSong(song);
      }

      print('✅ Navigated to player, playback started.');
    } catch (e) {
      print('❌ Error in _playSongAndNavigate: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing song: $e')));
      }
    }
  }

  // ⚡ The rest of your UI list (like ListView.builder) stays unchanged.

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
        Expanded(
          child: _songs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadSongs,
                  child: ListView.builder(
                    // ✅ Smooth scrolling physics for 120Hz displays
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    // ✅ Enable caching for better performance
                    cacheExtent: 500,
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      // ✅ Add staggered animation
                      return AnimatedBuilder(
                        animation: AlwaysStoppedAnimation(0),
                        builder: (context, child) {
                          return TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds: 200 + (index * 20).clamp(0, 400),
                            ),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: child,
                          );
                        },
                        child: ListTile(
                          // ✅ Add hero animation for artwork
                          leading: Hero(
                            tag: 'song_${song.id}',
                            child: QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: const Icon(
                                Icons.music_note,
                                size: 40,
                              ),
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
                          onTap: () => _playSongAndNavigate(song, context),
                        ),
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
