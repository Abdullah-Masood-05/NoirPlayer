import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/playlist_model.dart';
import 'auth_service.dart';

/// Singleton service for managing playlists in Firestore
class PlaylistService {
  static final PlaylistService _instance = PlaylistService._internal();
  factory PlaylistService() => _instance;
  PlaylistService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Get reference to user's playlists collection
  CollectionReference? get _playlistsCollection {
    final userId = _authService.currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('playlists');
  }

  /// Stream of playlists for current user (real-time updates)
  Stream<List<PlaylistModel>> getPlaylistsStream() {
    final collection = _playlistsCollection;
    if (collection == null) {
      return Stream.value([]);
    }

    return collection.orderBy('createdAt', descending: false).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PlaylistModel.fromJson({
          ...data,
          'id': doc.id, // Include document ID
        });
      }).toList();
    });
  }

  /// Get playlists once (not real-time)
  Future<List<PlaylistModel>> getPlaylists() async {
    final collection = _playlistsCollection;
    if (collection == null) return [];

    try {
      final snapshot = await collection
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PlaylistModel.fromJson({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting playlists: $e');
      return [];
    }
  }

  /// Create a new playlist
  Future<void> createPlaylist({
    required String name,
    bool isFavourite = false,
    int maxSongs = 5,
  }) async {
    final collection = _playlistsCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    try {
      await collection.add({
        'name': name,
        'songs': [],
        'isFavourite': isFavourite,
        'maxSongs': maxSongs,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Playlist created: $name');
    } catch (e) {
      debugPrint('❌ Error creating playlist: $e');
      rethrow;
    }
  }

  /// Update an existing playlist
  Future<void> updatePlaylist({
    required String playlistId,
    required PlaylistModel playlist,
  }) async {
    final collection = _playlistsCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    try {
      await collection.doc(playlistId).update({
        'name': playlist.name,
        'songs': playlist.songs.map((s) => s.toJson()).toList(),
        'isFavourite': playlist.isFavourite,
        'maxSongs': playlist.maxSongs,
      });
      debugPrint('✅ Playlist updated: ${playlist.name}');
    } catch (e) {
      debugPrint('❌ Error updating playlist: $e');
      rethrow;
    }
  }

  /// Delete a playlist
  Future<void> deletePlaylist(String playlistId) async {
    final collection = _playlistsCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    try {
      await collection.doc(playlistId).delete();
      debugPrint('✅ Playlist deleted: $playlistId');
    } catch (e) {
      debugPrint('❌ Error deleting playlist: $e');
      rethrow;
    }
  }

  /// Add a song to a playlist
  Future<void> addSongToPlaylist({
    required String playlistId,
    required PlaylistSong song,
  }) async {
    final collection = _playlistsCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    try {
      await collection.doc(playlistId).update({
        'songs': FieldValue.arrayUnion([song.toJson()]),
      });
      debugPrint('✅ Song added to playlist: ${song.title}');
    } catch (e) {
      debugPrint('❌ Error adding song to playlist: $e');
      rethrow;
    }
  }

  /// Remove a song from a playlist
  Future<void> removeSongFromPlaylist({
    required String playlistId,
    required PlaylistSong song,
  }) async {
    final collection = _playlistsCollection;
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    try {
      await collection.doc(playlistId).update({
        'songs': FieldValue.arrayRemove([song.toJson()]),
      });
      debugPrint('✅ Song removed from playlist: ${song.title}');
    } catch (e) {
      debugPrint('❌ Error removing song from playlist: $e');
      rethrow;
    }
  }

  /// Migrate local playlists.json to Firebase
  Future<void> migrateLocalPlaylistsToFirebase() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/playlists.json');

      if (!await file.exists()) {
        debugPrint('ℹ️ No local playlists to migrate');
        // Create default Favorites playlist
        await createPlaylist(name: 'Favorites', isFavourite: true);
        return;
      }

      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      final localPlaylists = jsonList
          .map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint(
        '📦 Migrating ${localPlaylists.length} playlists to Firebase...',
      );

      for (final playlist in localPlaylists) {
        await createPlaylist(
          name: playlist.name,
          isFavourite: playlist.isFavourite,
          maxSongs: playlist.maxSongs,
        );

        // Get the newly created playlist ID
        final playlists = await getPlaylists();
        final newPlaylist = playlists.firstWhere(
          (p) => p.name == playlist.name,
          orElse: () => playlist,
        );

        // Add songs to the playlist
        if (newPlaylist.id != null) {
          final collection = _playlistsCollection;
          if (collection != null) {
            await collection.doc(newPlaylist.id).update({
              'songs': playlist.songs.map((s) => s.toJson()).toList(),
            });
          }
        }
      }

      debugPrint('✅ Migration complete!');

      // Optionally delete local file after successful migration
      // await file.delete();
    } catch (e) {
      debugPrint('❌ Error migrating playlists: $e');
      // Don't throw - create default Favorites playlist instead
      await createPlaylist(name: 'Favorites', isFavourite: true);
    }
  }

  /// Initialize playlists for new user (create default Favorites)
  Future<void> initializeDefaultPlaylists() async {
    final playlists = await getPlaylists();
    if (playlists.isEmpty) {
      await createPlaylist(name: 'Favorites', isFavourite: true);
    }
  }
}
