import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:noir_player/core/services/audio_handler.dart'; // your global audio handler instance

class ArtistSongsScreen extends StatefulWidget {
  final ArtistModel artist;

  final VoidCallback onNavigateToPlayer;

  const ArtistSongsScreen({
    super.key,
    required this.artist,
    required this.onNavigateToPlayer, 
  });

  @override
  State<ArtistSongsScreen> createState() => _ArtistSongsScreenState();
}

class _ArtistSongsScreenState extends State<ArtistSongsScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.artist.artist)),
      body: FutureBuilder<List<SongModel>>(
        future: _audioQuery.queryAudiosFrom(
          AudiosFromType.ARTIST_ID,
          widget.artist.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading songs: ${snapshot.error}'),
            );
          }

          final songs = snapshot.data ?? [];
          if (songs.isEmpty) {
            return const Center(child: Text('No songs found for this artist.'));
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.circular(8),
                  nullArtworkWidget: const Icon(Icons.music_note),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(song.album ?? 'Unknown Album'),
                onTap: () async {
                  widget.onNavigateToPlayer();

                  if (!isAudioServiceInitialized()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Audio service is not ready yet. Please wait...',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }

                  final handler = audioHandler as AudioPlayerHandler;
                  handler.setQueue(songs); 
                  await handler.playSongAt(index); 
                },
              );
            },
          );
        },
      ),
    );
  }
}
