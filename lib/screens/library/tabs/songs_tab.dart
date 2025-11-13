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

// !MAIN CODE BELOW
// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:noir_player/core/services/audio_handler.dart';
// import 'package:on_audio_query/on_audio_query.dart';
// import 'package:permission_handler/permission_handler.dart';

// class SongsTab extends StatefulWidget {
//   // ✅ Callback for navigating to player
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

//     // ✅ NEW: set the global queue in AudioHandler
//     if (isAudioServiceInitialized()) {
//       (audioHandler as AudioPlayerHandler).setQueue(songs);
//       print('🎶 Queue set in AudioHandler with ${songs.length} songs.');
//     } else {
//       print('⚠️ AudioService not initialized yet, queue not set.');
//     }
//   }

//   // ✅ Updated to register current index when playing a song
//   Future<void> _playSongAndNavigate(
//     SongModel song,
//     BuildContext context,
//   ) async {
//     try {
//       print('🎵 Song tapped: ${song.title}');

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

//       // ✅ Navigate first
//       if (mounted) {
//         widget.onNavigateToPlayer();
//       }

//       // ✅ Find the tapped song’s index and update handler
//       final handler = audioHandler as AudioPlayerHandler;
//       final tappedIndex = _songs.indexWhere((s) => s.id == song.id);

//       if (tappedIndex != -1) {
//         handler.setQueue(_songs); // ensure queue is synced
//         await handler.playSongAt(tappedIndex); // play the song at index
//         print('▶️ Playing song at index $tappedIndex: ${song.title}');
//       } else {
//         print('⚠️ Could not find tapped song in queue.');
//         await handler.playSong(song);
//       }

//       print('✅ Navigated to player, playback started.');
//     } catch (e) {
//       print('❌ Error in _playSongAndNavigate: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error playing song: $e')));
//       }
//     }
//   }

//   // ⚡ The rest of your UI list (like ListView.builder) stays unchanged.

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
//                     // ✅ Smooth scrolling physics for 120Hz displays
//                     physics: const BouncingScrollPhysics(
//                       parent: AlwaysScrollableScrollPhysics(),
//                     ),
//                     // ✅ Enable caching for better performance
//                     cacheExtent: 500,
//                     itemCount: filteredSongs.length,
//                     itemBuilder: (context, index) {
//                       final song = filteredSongs[index];
//                       // ✅ Add staggered animation
//                       return AnimatedBuilder(
//                         animation: AlwaysStoppedAnimation(0),
//                         builder: (context, child) {
//                           return TweenAnimationBuilder<double>(
//                             duration: Duration(
//                               milliseconds: 200 + (index * 20).clamp(0, 400),
//                             ),
//                             tween: Tween(begin: 0.0, end: 1.0),
//                             curve: Curves.easeOutCubic,
//                             builder: (context, value, child) {
//                               return Opacity(
//                                 opacity: value,
//                                 child: Transform.translate(
//                                   offset: Offset(0, 20 * (1 - value)),
//                                   child: child,
//                                 ),
//                               );
//                             },
//                             child: child,
//                           );
//                         },
//                         child: ListTile(
//                           // ✅ Add hero animation for artwork
//                           leading: Hero(
//                             tag: 'song_${song.id}',
//                             child: QueryArtworkWidget(
//                               id: song.id,
//                               type: ArtworkType.AUDIO,
//                               nullArtworkWidget: const Icon(
//                                 Icons.music_note,
//                                 size: 40,
//                               ),
//                             ),
//                           ),
//                           title: Text(
//                             song.title,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           subtitle: Text(song.artist ?? "Unknown Artist"),
//                           trailing: Text(
//                             _formatDuration(song.duration ?? 0),
//                             style: const TextStyle(color: Colors.white60),
//                           ),
//                           onTap: () => _playSongAndNavigate(song, context),
//                         ),
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






// !  MAIN CODE BELOW WITH 

// import 'dart:convert';
// import 'dart:io';

// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:noir_player/core/services/audio_handler.dart';
// import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;
// import 'package:permission_handler/permission_handler.dart';
// import '../../../core/models/playlist_model.dart';
// import 'package:path_provider/path_provider.dart';

// class SongsTab extends StatefulWidget {
//   final VoidCallback onNavigateToPlayer;

//   const SongsTab({super.key, required this.onNavigateToPlayer});

//   @override
//   State<SongsTab> createState() => _SongsTabState();
// }

// class _SongsTabState extends State<SongsTab> {
//   final OnAudioQuery _audioQuery = OnAudioQuery();
//   List<SongModel> _songs = [];
//   List<PlaylistModel> _playlists = [];
//   String _searchText = '';

//   @override
//   void initState() {
//     super.initState();
//     _requestPermissionAndLoad();
//     _loadPlaylists();
//   }

//   Future<File> get _playlistFile async {
//     final dir = await getApplicationDocumentsDirectory();
//     return File('${dir.path}/playlists.json');
//   }

//   Future<void> _loadPlaylists() async {
//     try {
//       final file = await _playlistFile;
//       if (await file.exists()) {
//         final content = await file.readAsString();
//         final List<dynamic> jsonList = jsonDecode(content);
//         setState(() {
//           _playlists = jsonList.map((e) => PlaylistModel.fromJson(e)).toList();
//         });
//       } else {
//         // create default playlist
//         final fav = PlaylistModel(
//           name: 'Favorites',
//           songs: [],
//           isFavourite: true,
//         );
//         setState(() {
//           _playlists = [fav];
//         });
//         await _savePlaylists();
//       }
//     } catch (e) {
//       print('❌ Error loading playlists: $e');
//     }
//   }

//   Future<void> _savePlaylists() async {
//     try {
//       final file = await _playlistFile;
//       await file.writeAsString(
//         jsonEncode(_playlists.map((p) => p.toJson()).toList()),
//       );
//     } catch (e) {
//       print('❌ Error saving playlists: $e');
//     }
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

//     if (isAudioServiceInitialized()) {
//       (audioHandler as AudioPlayerHandler).setQueue(songs);
//       print('🎶 Queue set in AudioHandler with ${songs.length} songs.');
//     }
//   }

//   Future<void> _playSongAndNavigate(
//     SongModel song,
//     BuildContext context,
//   ) async {
//     if (!isAudioServiceInitialized()) return;

//     widget.onNavigateToPlayer();

//     final handler = audioHandler as AudioPlayerHandler;
//     final tappedIndex = _songs.indexWhere((s) => s.id == song.id);

//     if (tappedIndex != -1) {
//       handler.setQueue(_songs);
//       await handler.playSongAt(tappedIndex);
//     } else {
//       await handler.playSong(song);
//     }
//   }

//   Future<void> _addSongToPlaylist(SongModel song) async {
//     if (_playlists.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('No playlists available.')));
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (ctx) {
//         return AlertDialog(
//           title: const Text('Add to Playlist'),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: ListView.builder(
//               shrinkWrap: true,
//               itemCount: _playlists.length,
//               itemBuilder: (context, index) {
//                 final playlist = _playlists[index];
//                 return ListTile(
//                   title: Text(playlist.name),
//                   onTap: () async {
//                     // Avoid duplicates
//                     if (!playlist.songs.any((s) => s.id == song.id)) {
//                       playlist.songs.add(
//                         PlaylistSong(
//                           id: song.id,
//                           title: song.title,
//                           artist:
//                               song.artist ??
//                               'Unknown Artist', // ✅ fallback for null
//                           data: song.data,
//                           duration: song.duration,
//                         ),
//                       );
//                       await _savePlaylists();
//                       setState(() {}); // update UI if needed
//                       Navigator.pop(ctx);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(
//                             'Added "${song.title}" to ${playlist.name}',
//                           ),
//                         ),
//                       );
//                     } else {
//                       Navigator.pop(ctx);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(
//                             '"${song.title}" is already in ${playlist.name}',
//                           ),
//                         ),
//                       );
//                     }
//                   },
//                 );
//               },
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx),
//               child: const Text('Cancel'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredSongs = _songs.where((song) {
//       final lowerSearch = _searchText.toLowerCase();
//       return song.title.toLowerCase().contains(lowerSearch) ||
//           (song.artist ?? '').toLowerCase().contains(lowerSearch);
//     }).toList();

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
//                     physics: const BouncingScrollPhysics(
//                       parent: AlwaysScrollableScrollPhysics(),
//                     ),
//                     cacheExtent: 500,
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
//                         onLongPress: () =>
//                             _addSongToPlaylist(song), // ✅ Added long press
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





import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:noir_player/core/services/audio_handler.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/models/playlist_model.dart';
import 'package:path_provider/path_provider.dart';

class SongsTab extends StatefulWidget {
  final VoidCallback onNavigateToPlayer;

  const SongsTab({super.key, required this.onNavigateToPlayer});

  @override
  State<SongsTab> createState() => _SongsTabState();
}

class _SongsTabState extends State<SongsTab> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  List<PlaylistModel> _playlists = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
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
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        setState(() {
          _playlists = jsonList.map((e) => PlaylistModel.fromJson(e)).toList();
        });
      } else {
        final fav = PlaylistModel(
          name: 'Favorites',
          songs: [],
          isFavourite: true,
        );
        setState(() {
          _playlists = [fav];
        });
        await _savePlaylists();
      }
    } catch (e) {
      debugPrint('❌ Error loading playlists: $e');
    }
  }

  Future<void> _savePlaylists() async {
    try {
      final file = await _playlistFile;
      await file.writeAsString(
        jsonEncode(_playlists.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('❌ Error saving playlists: $e');
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Loaded all songs.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      _loadSongs();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Permission denied. Cannot load songs.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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

    if (isAudioServiceInitialized()) {
      (audioHandler as AudioPlayerHandler).setQueue(songs);
      debugPrint('🎶 Queue set in AudioHandler with ${songs.length} songs.');
    }
  }

  Future<void> _playSongAndNavigate(
    SongModel song,
    BuildContext context,
  ) async {
    if (!isAudioServiceInitialized()) return;

    widget.onNavigateToPlayer();

    final handler = audioHandler as AudioPlayerHandler;
    final tappedIndex = _songs.indexWhere((s) => s.id == song.id);

    if (tappedIndex != -1) {
      handler.setQueue(_songs);
      await handler.playSongAt(tappedIndex);
    } else {
      await handler.playSong(song);
    }
  }

  Future<void> _addSongToPlaylist(SongModel song) async {
    if (_playlists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No playlists available.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: theme.colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.playlist_add,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add to Playlist',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Playlist list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    final alreadyAdded =
                        playlist.songs.any((s) => s.id == song.id);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: alreadyAdded
                            ? null
                            : () async {
                                playlist.songs.add(
                                  PlaylistSong(
                                    id: song.id,
                                    title: song.title,
                                    artist: song.artist ?? 'Unknown Artist',
                                    data: song.data,
                                    duration: song.duration,
                                  ),
                                );
                                await _savePlaylists();
                                setState(() {});
                                Navigator.pop(ctx);
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added "${song.title}" to ${playlist.name}',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: alreadyAdded
                                      ? Colors.grey.withOpacity(0.2)
                                      : theme.colorScheme.primary
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  playlist.isFavourite
                                      ? Icons.favorite
                                      : Icons.playlist_play,
                                  color: alreadyAdded
                                      ? (isDark
                                          ? Colors.white38
                                          : Colors.black38)
                                      : theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playlist.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: alreadyAdded
                                            ? theme.textTheme.bodyMedium?.color
                                                ?.withOpacity(0.5)
                                            : theme.textTheme.titleMedium?.color,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${playlist.songs.length} song${playlist.songs.length != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (alreadyAdded)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.withOpacity(0.7),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Cancel button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredSongs = _songs.where((song) {
      final lowerSearch = _searchText.toLowerCase();
      return song.title.toLowerCase().contains(lowerSearch) ||
          (song.artist ?? '').toLowerCase().contains(lowerSearch);
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: 'Search songs or artists...',
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: theme.iconTheme.color?.withOpacity(0.7),
                ),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.iconTheme.color?.withOpacity(0.7),
                        ),
                        onPressed: () => setState(() => _searchText = ''),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) => setState(() => _searchText = value),
            ),
          ),
        ),
        
        // Songs list
        Expanded(
          child: _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading songs...',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                )
              : filteredSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: theme.iconTheme.color?.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No songs found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: theme.colorScheme.primary,
                      onRefresh: _loadSongs,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        cacheExtent: 500,
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          
                          return TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds: 200 + (index % 10) * 30,
                            ),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                highlightColor:
                                    theme.colorScheme.primary.withOpacity(0.05),
                                onTap: () => _playSongAndNavigate(song, context),
                                onLongPress: () => _addSongToPlaylist(song),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.black.withOpacity(0.03),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Artwork
                                      Hero(
                                        tag: 'song_art_${song.id}',
                                        child: Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isDark
                                                    ? Colors.black
                                                        .withOpacity(0.3)
                                                    : Colors.grey
                                                        .withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: QueryArtworkWidget(
                                              id: song.id,
                                              type: ArtworkType.AUDIO,
                                              artworkBorder:
                                                  BorderRadius.circular(12),
                                              nullArtworkWidget: Container(
                                                color: isDark
                                                    ? Colors.grey[850]
                                                    : Colors.grey[300],
                                                child: Icon(
                                                  Icons.music_note,
                                                  size: 28,
                                                  color: isDark
                                                      ? Colors.white38
                                                      : Colors.black38,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      
                                      // Song info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              song.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: theme
                                                    .textTheme.titleMedium?.color,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              song.artist ?? "Unknown Artist",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: theme
                                                    .textTheme.bodyMedium?.color
                                                    ?.withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Duration
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.black.withOpacity(0.03),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _formatDuration(song.duration ?? 0),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: theme
                                                .textTheme.bodySmall?.color
                                                ?.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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