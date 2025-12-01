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
  final String? id; // Firestore document ID
  final String name;
  List<PlaylistSong> songs;
  final bool isFavourite; // mark favorites
  final int maxSongs; // maximum allowed songs

  PlaylistModel({
    this.id,
    required this.name,
    required this.songs,
    this.isFavourite = false,
    this.maxSongs = 5,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'songs': songs.map((s) => s.toJson()).toList(),
    'isFavourite': isFavourite,
    'maxSongs': maxSongs,
  };

  factory PlaylistModel.fromJson(Map<String, dynamic> json) => PlaylistModel(
    id: json['id'],
    name: json['name'],
    songs: (json['songs'] as List<dynamic>)
        .map((e) => PlaylistSong.fromJson(e))
        .toList(),
    isFavourite: json['isFavourite'] ?? false,
    maxSongs: json['maxSongs'] ?? 5,
  );
}
