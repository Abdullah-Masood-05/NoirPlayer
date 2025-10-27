import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

late final AudioHandler audioHandler;

Future<void> initAudioService() async {
  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.noir_player.channel.audio',
      androidNotificationChannelName: 'Noir Player',
      androidNotificationOngoing: true,
    ),
  );
}

class AudioPlayerHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    _player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        playing: _player.playing,
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
      ));
    });
  }

  @override
  Future<void> playMediaItem(MediaItem item) async {
    mediaItem.add(item);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(item.id)));
    play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> skipToNext() async {
    // Implement later for playlists
  }

  @override
  Future<void> skipToPrevious() async {
    // Implement later for playlists
  }

  @override
  Future<void> stop() => _player.stop();
}
  