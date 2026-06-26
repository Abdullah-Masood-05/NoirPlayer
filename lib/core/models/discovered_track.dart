class DiscoveredTrack {
  final String name;
  final String artist;
  final String imageUrl;
  final String? youtubeVideoId;
  final String? streamUrl;

  DiscoveredTrack({
    required this.name,
    required this.artist,
    required this.imageUrl,
    this.youtubeVideoId,
    this.streamUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'artist': artist,
    'imageUrl': imageUrl,
    'youtubeVideoId': youtubeVideoId,
    'streamUrl': streamUrl,
  };

  factory DiscoveredTrack.fromJson(Map<String, dynamic> json) =>
      DiscoveredTrack(
        name: json['name'],
        artist: json['artist'],
        imageUrl: json['imageUrl'],
        youtubeVideoId: json['youtubeVideoId'],
        streamUrl: json['streamUrl'],
      );
}
