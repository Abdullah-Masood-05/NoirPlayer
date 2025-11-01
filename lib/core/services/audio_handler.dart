

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

late final AudioHandler audioHandler; // ✅ Global instance

Future<void> initAudioService() async {
  try {
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.noir_player.channel.audio',
        androidNotificationChannelName: 'Noir Player',
        androidNotificationOngoing: true,
      ),
    );
    print( 'AudioService initialized successfully.');
  } catch (e) {
    print('Error initializing AudioService: $e');
  }
}
// Create a MediaItem to represent the current song.



class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    // Keep media item and playback state updated
    _player.playerStateStream.listen((state) {
      playbackState.add(
        PlaybackState(
          playing: state.playing,
          processingState: _mapState(state.processingState),
        ),
      );
    });
  }

  Future<void> playSong(String uri) async {
    try {
      final item = MediaItem(
        id: uri,
        title: uri.split('/').last,
      );
      mediaItem.add(item);
      await _player.setUrl(uri);
      await _player.play();
      print('Playing song: $uri');
      return;
      
    } catch (e) {
      print('Error playing song: $e');
    }
  }

  AudioProcessingState _mapState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
  
}

