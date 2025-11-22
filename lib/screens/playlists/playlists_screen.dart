import 'package:flutter/material.dart';
import '../../core/models/playlist_model.dart';
import '../../core/services/playlist_service.dart';
import 'playlist_songs_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key, required this.onNavigateToPlayer});

  final VoidCallback onNavigateToPlayer;

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final PlaylistService _playlistService = PlaylistService();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _confirmDeletePlaylist(PlaylistModel playlist) async {
    if (playlist.isFavourite) return; // Cannot delete Favorites

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Delete Playlist',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),

              // Content
              Text(
                'Are you sure you want to delete "${playlist.name}"?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _playlistService.deletePlaylist(playlist.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playlist "${playlist.name}" deleted'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting playlist: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<List<PlaylistModel>>(
      stream: _playlistService.getPlaylistsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final playlists = snapshot.data ?? [];

        if (playlists.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.88,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Hero(
                tag: 'playlist_${playlist.name}_$index',
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    splashColor: theme.colorScheme.primary.withOpacity(0.15),
                    highlightColor: theme.colorScheme.primary.withOpacity(0.08),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (
                                context,
                                animation,
                                secondaryAnimation,
                              ) => PlaylistSongsScreen(
                                playlist: playlist,
                                onNavigateToPlayer: widget.onNavigateToPlayer,
                                onUpdatePlaylist: () {
                                  // No need to do anything, StreamBuilder handles updates
                                },
                              ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeInOutCubic;

                                var tween = Tween(
                                  begin: begin,
                                  end: end,
                                ).chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);

                                return SlideTransition(
                                  position: offsetAnimation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                    onLongPress: () async {
                      // Haptic-like delay for better UX
                      await Future.delayed(const Duration(milliseconds: 100));
                      _confirmDeletePlaylist(playlist);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Icon section with gradient overlay
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isDark
                                            ? [
                                                Colors.grey[850]!,
                                                Colors.grey[900]!,
                                              ]
                                            : [
                                                Colors.grey[200]!,
                                                Colors.grey[300]!,
                                              ],
                                      ),
                                    ),
                                    child: Center(
                                      child: TweenAnimationBuilder<double>(
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        curve: Curves.elasticOut,
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: child,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            playlist.isFavourite
                                                ? Icons.favorite
                                                : Icons.playlist_play,
                                            size: 42,
                                            color: playlist.isFavourite
                                                ? theme.colorScheme.primary
                                                : (isDark
                                                      ? Colors.white70
                                                      : Colors.black54),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Delete icon for non-favourite playlists
                                  if (!playlist.isFavourite)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.black.withOpacity(0.4)
                                              : Colors.white.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 18,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Info section
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[850]?.withOpacity(0.5)
                                    : Colors.grey[100],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    playlist.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: theme.textTheme.titleLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.music_note,
                                        size: 14,
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${playlist.songs.length} song${playlist.songs.length != 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import '../../core/models/playlist_model.dart';
// import '../../core/services/playlist_service.dart';
// import 'playlist_songs_screen.dart';

// class PlaylistsScreen extends StatefulWidget {
//   const PlaylistsScreen({super.key, required this.onNavigateToPlayer});

//   final VoidCallback onNavigateToPlayer;

//   @override
//   State<PlaylistsScreen> createState() => _PlaylistsScreenState();
// }

// class _PlaylistsScreenState extends State<PlaylistsScreen> {
//   final PlaylistService _playlistService = PlaylistService();

//   Future<void> _confirmDeletePlaylist(PlaylistModel playlist) async {
//     if (playlist.isFavourite) return;

//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     final confirm = await showDialog<bool>(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         elevation: 8,
//         backgroundColor: theme.colorScheme.surface,
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 64,
//                 height: 64,
//                 decoration: BoxDecoration(
//                   color: Colors.red.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.delete_outline,
//                   color: Colors.red,
//                   size: 32,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 'Delete Playlist',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: theme.textTheme.titleLarge?.color,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Are you sure you want to delete "${playlist.name}"?',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 15,
//                   color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
//                   height: 1.4,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'This action cannot be undone.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 13,
//                   color: Colors.red.withOpacity(0.7),
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 28),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.pop(context, false),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         side: BorderSide(
//                           color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
//                           width: 1.5,
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: theme.textTheme.bodyLarge?.color,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () => Navigator.pop(context, true),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         'Delete',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );

//     if (confirm == true) {
//       try {
//         await _playlistService.deletePlaylist(playlist.id!);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Playlist "${playlist.name}" deleted'),
//               duration: const Duration(seconds: 2),
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Error deleting playlist: $e'),
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return StreamBuilder<List<PlaylistModel>>(
//       stream: _playlistService.getPlaylistsStream(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         }

//         final playlists = snapshot.data ?? [];

//         if (playlists.isEmpty) {
//           return const Center(child: Text('No playlists yet'));
//         }

//         return GridView.builder(
//           padding: const EdgeInsets.all(12),
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             mainAxisSpacing: 14,
//             crossAxisSpacing: 14,
//             childAspectRatio: 0.88,
//           ),
//           itemCount: playlists.length,
//           itemBuilder: (context, index) {
//             final playlist = playlists[index];

//             return TweenAnimationBuilder<double>(
//               duration: Duration(milliseconds: 300 + (index * 50)),
//               tween: Tween(begin: 0.0, end: 1.0),
//               builder: (context, value, child) {
//                 return Transform.scale(
//                   scale: 0.8 + (0.2 * value),
//                   child: Opacity(opacity: value, child: child),
//                 );
//               },
//               child: Hero(
//                 tag: 'playlist_${playlist.name}_$index',
//                 child: Material(
//                   color: Colors.transparent,
//                   child: InkWell(
//                     borderRadius: BorderRadius.circular(16),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => PlaylistSongsScreen(
//                             playlist: playlist,
//                             onNavigateToPlayer: widget.onNavigateToPlayer,
//                             onUpdatePlaylist: () {
//                               // No need to call setState, StreamBuilder handles updates
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                     onLongPress: () => _confirmDeletePlaylist(playlist),
//                     child: _buildPlaylistCard(theme, isDark, playlist),
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildPlaylistCard(
//     ThemeData theme,
//     bool isDark,
//     PlaylistModel playlist,
//   ) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: isDark
//                 ? Colors.black.withOpacity(0.3)
//                 : Colors.grey.withOpacity(0.2),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Card(
//         margin: EdgeInsets.zero,
//         elevation: 0,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         clipBehavior: Clip.antiAlias,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Expanded(
//               child: Center(
//                 child: Icon(
//                   playlist.isFavourite ? Icons.favorite : Icons.playlist_play,
//                   size: 42,
//                 ),
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     playlist.name,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                       color: theme.textTheme.titleLarge?.color,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '${playlist.songs.length} songs',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: theme.textTheme.bodyMedium?.color?.withOpacity(
//                         0.7,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
