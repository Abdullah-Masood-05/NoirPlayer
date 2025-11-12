import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:noir_player/core/services/audio_handler.dart';

class ArtistSongsScreen extends StatefulWidget {
  final ArtistModel artist;

  const ArtistSongsScreen({super.key, required this.artist});

  @override
  State<ArtistSongsScreen> createState() => _ArtistSongsScreenState();
}

class _ArtistSongsScreenState extends State<ArtistSongsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  late Future<List<SongModel>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _audioQuery.queryAudiosFrom(
      AudiosFromType.ARTIST_ID,
      widget.artist.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artist.artist),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SongModel>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final songs = snapshot.data ?? [];
          if (songs.isEmpty) {
            return const Center(child: Text('No songs found for this artist.'));
          }

          return ListView.separated(
            itemCount: songs.length,
            separatorBuilder: (_, __) => const Divider(indent: 72, endIndent: 12),
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.circular(6),
                  nullArtworkWidget: const Icon(Icons.music_note, size: 40),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(song.album ?? 'Unknown Album'),
                onTap: () async {
                  final handler = audioHandler as AudioPlayerHandler;
                  handler.setQueue(songs);
                  await handler.playSongAt(index);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('▶️ Playing: ${song.title}')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
