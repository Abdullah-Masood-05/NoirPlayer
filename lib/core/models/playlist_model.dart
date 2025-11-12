// // lib/core/models/playlist_model.dart

// import 'package:on_audio_query/on_audio_query.dart';

// class PlaylistSong {
//   final int id;
//   final String title;
//   final String artist;
//   final String data; // path to file
//   final int? duration;

//   PlaylistSong({
//     required this.id,
//     required this.title,
//     required this.artist,
//     required this.data,
//     this.duration,
//   });

//   factory PlaylistSong.fromJson(Map<String, dynamic> json) => PlaylistSong(
//         id: json['id'],
//         title: json['title'],
//         artist: json['artist'],
//         data: json['data'],
//         duration: json['duration'],
//       );

//   Map<String, dynamic> toJson() => {
//         'id': id,
//         'title': title,
//         'artist': artist,
//         'data': data,
//         'duration': duration,
//       };
// }

// class PlaylistModel {
//   String name;
//   int maxSongs;
//   bool isFavourite;
//   List<PlaylistSong> songs;

//   PlaylistModel({
//     required this.name,
//     required this.maxSongs,
//     this.isFavourite = false,
//     this.songs = const [],
//   });

//   factory PlaylistModel.fromJson(Map<String, dynamic> json) => PlaylistModel(
//         name: json['name'],
//         maxSongs: json['maxSongs'],
//         isFavourite: json['isFavourite'] ?? false,
//         songs: (json['songs'] as List<dynamic>)
//             .map((e) => PlaylistSong.fromJson(e))
//             .toList(),
//       );

//   Map<String, dynamic> toJson() => {
//         'name': name,
//         'maxSongs': maxSongs,
//         'isFavourite': isFavourite,
//         'songs': songs.map((e) => e.toJson()).toList(),
//       };
// }

// lib/core/models/playlist_model.dart
// lib/core/models/playlist_model.dart
import 'package:on_audio_query/on_audio_query.dart';

class PlaylistSong {
  final int id;
  final String title;
  final String artist;
  final String data;
  final int? duration;

  PlaylistSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.data,
    this.duration,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'data': data,
    'duration': duration,
  };

  factory PlaylistSong.fromJson(Map<String, dynamic> json) => PlaylistSong(
    id: json['id'],
    title: json['title'],
    artist: json['artist'],
    data: json['data'],
    duration: json['duration'],
  );
}

class PlaylistModel {
  final String name;
  List<PlaylistSong> songs;
  final bool isFavourite; // mark favorites
  final int maxSongs; // maximum allowed songs in this playlist

  PlaylistModel({
    required this.name,
    required this.songs,
    this.isFavourite = false,
    this.maxSongs = 5, // default max 5 songs
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'songs': songs.map((s) => s.toJson()).toList(),
    'isFavourite': isFavourite,
    'maxSongs': maxSongs,
  };

  factory PlaylistModel.fromJson(Map<String, dynamic> json) => PlaylistModel(
    name: json['name'],
    songs: (json['songs'] as List<dynamic>)
        .map((e) => PlaylistSong.fromJson(e))
        .toList(),
    isFavourite: json['isFavourite'] ?? false,
    maxSongs: json['maxSongs'] ?? 5,
  );
}
