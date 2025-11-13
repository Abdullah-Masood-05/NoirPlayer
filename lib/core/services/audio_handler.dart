import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/playlist_model.dart';

late final AudioHandler audioHandler;
bool _isInitialized = false;

Future<void> initAudioService() async {
  if (_isInitialized) return;

  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.noir_player.channel.audio',
      androidNotificationChannelName: 'Noir Player',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    ),
  );

  _isInitialized = true;
}

bool isAudioServiceInitialized() => _isInitialized;

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  List<dynamic> _queue = [];
  int _currentIndex = 0;

  Stream<Duration> get positionStream => _player.positionStream;

  AudioPlayerHandler() {
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      _updatePlaybackState(state);
    });

    // Listen to position changes and update the playback state
    _player.positionStream.listen((position) {
      _broadcastPosition(position);
    });

    // Listen to when song completes to play next
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  // Update playback state with position
  void _updatePlaybackState(PlayerState state) {
    final position = _player.position;
    final duration = _player.duration ?? Duration.zero;

    playbackState.add(
      PlaybackState(
        playing: state.playing,
        processingState: _mapState(state.processingState),
        controls: [
          MediaControl.skipToPrevious,
          if (state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  // Broadcast position updates
  void _broadcastPosition(Duration position) {
    final duration = _player.duration ?? Duration.zero;
    final playing = _player.playing;

    playbackState.add(
      playbackState.value.copyWith(
        updatePosition: position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  // Play a SongModel or PlaylistSong
  Future<void> playSong(dynamic song) async {
    try {
      String path;
      String title;
      String artist;
      String album = '';
      int? durationMs;
      String id;

      if (song is SongModel) {
        path = song.data;
        title = song.title;
        artist = song.artist ?? 'Unknown Artist';
        album = song.album ?? '';
        durationMs = song.duration;
        id = song.id.toString();
      } else if (song is PlaylistSong) {
        path = song.data;
        title = song.title;
        artist = song.artist ?? 'Unknown Artist';
        album = '';
        durationMs = song.duration;
        id = song.id.toString();
      } else {
        throw Exception('Unsupported song type');
      }

      final item = MediaItem(
        id: id,
        title: title,
        artist: artist,
        album: album,
        duration: Duration(milliseconds: durationMs ?? 0),
      );

      // Update media item
      mediaItem.add(item);

      // Set audio source and play
      await _player.setFilePath(path);
      await _player.play();
    } catch (e) {
      print('❌ Error playing song: $e');
    }
  }

  // Manage the queue
  void setQueue(List<dynamic> songs) {
    _queue = songs;
    print('🎶 Queue set with ${songs.length} songs');
  }

  Future<void> playSongAt(int index) async {
    if (_queue.isEmpty || index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await playSong(_queue[_currentIndex]);
  }

  Future<void> playNext() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _queue.length;
    await playSongAt(_currentIndex);
  }

  Future<void> playPrevious() async {
    if (_queue.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await playSongAt(_currentIndex);
  }

  // ✅ CRITICAL: Override these methods for notification controls
  @override
  Future<void> skipToNext() async {
    await playNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await playPrevious();
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _player.dispose();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> dispose() async {
    await _player.dispose();
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



