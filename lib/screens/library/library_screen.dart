// import 'package:flutter/material.dart';
// import 'tabs/songs_tab.dart';
// import 'tabs/albums_tab.dart';
// import 'tabs/artists_tab.dart';
// import 'tabs/playlists_tab.dart';

// class LibraryScreen extends StatefulWidget {
//   const LibraryScreen({super.key});

//   @override
//   State<LibraryScreen> createState() => _LibraryScreenState();
// }

// class _LibraryScreenState extends State<LibraryScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Library'),
//         centerTitle: true,
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Theme.of(context).colorScheme.primary,
//           tabs: const [
//             Tab(text: 'Songs'),
//             Tab(text: 'Albums'),
//             Tab(text: 'Artists'),
//             Tab(text: 'Playlists'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: const [
//           SongsTab(),
//           AlbumsTab(),
//           ArtistsTab(),
//           PlaylistsTab(),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'tabs/songs_tab.dart';
// import 'tabs/albums_tab.dart';
// import 'tabs/artists_tab.dart';
// import 'tabs/playlists_tab.dart';

// class LibraryScreen extends StatefulWidget {
//   final VoidCallback onNavigateToPlayer; // ✅ callback from HomeScreen

//   const LibraryScreen({super.key, required this.onNavigateToPlayer});

//   @override
//   State<LibraryScreen> createState() => _LibraryScreenState();
// }

// class _LibraryScreenState extends State<LibraryScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Library'),
//         centerTitle: true,
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Theme.of(context).colorScheme.primary,
//           tabs: const [
//             Tab(text: 'Songs'),
//             Tab(text: 'Albums'),
//             Tab(text: 'Artists'),
//             Tab(text: 'Playlists'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // ✅ Pass callback only to SongsTab
//           SongsTab(onNavigateToPlayer: widget.onNavigateToPlayer),
//           const AlbumsTab(),
//           const ArtistsTab(),
//           const PlaylistsTab(),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'tabs/songs_tab.dart';
// import 'tabs/albums_tab.dart';
// import 'tabs/artists_tab.dart';
// import 'tabs/playlists_tab.dart';

// class LibraryScreen extends StatefulWidget {
//   const LibraryScreen({super.key});

//   @override
//   State<LibraryScreen> createState() => _LibraryScreenState();
// }

// class _LibraryScreenState extends State<LibraryScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Library'),
//         centerTitle: true,
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Theme.of(context).colorScheme.primary,
//           tabs: const [
//             Tab(text: 'Songs'),
//             Tab(text: 'Albums'),
//             Tab(text: 'Artists'),
//             Tab(text: 'Playlists'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: const [SongsTab(), AlbumsTab(), ArtistsTab(), PlaylistsTab()],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'tabs/songs_tab.dart';
import 'tabs/albums_tab.dart';
import 'tabs/artists_tab.dart';
import 'tabs/playlists_tab.dart';

class LibraryScreen extends StatefulWidget {
  // ✅ Add callback parameter
  final VoidCallback onNavigateToPlayer;

  const LibraryScreen({super.key, required this.onNavigateToPlayer});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Library'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Songs'),
            Tab(text: 'Albums'),
            Tab(text: 'Artists'),
            Tab(text: 'Playlists'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ✅ Pass callback to SongsTab
          SongsTab(onNavigateToPlayer: widget.onNavigateToPlayer),
          const AlbumsTab(),
          const ArtistsTab(),
          const PlaylistsTab(),
        ],
      ),
    );
  }
}
