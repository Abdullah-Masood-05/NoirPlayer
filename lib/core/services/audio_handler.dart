import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
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
      // Keep the notification ongoing and the service in the foreground even
      // while paused. This stops aggressive OEM memory management (e.g.
      // OxygenOS) from killing the backgrounded process, which otherwise leaves
      // the app frozen / unable to play when reopened from recents.
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  _isInitialized = true;
}

bool isAudioServiceInitialized() => _isInitialized;

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Raw queue (SongModel / PlaylistSong), parallel to the published [queue].
  List<dynamic> _songs = [];

  /// True once the just_audio playlist matches [_songs].
  bool _sourceMatchesQueue = false;

  /// Cache of songId -> artwork file uri so we only extract artwork once.
  final Map<int, Uri?> _artCache = {};

  Stream<Duration> get positionStream => _player.positionStream;

  AudioPlayerHandler() {
    _player.setLoopMode(LoopMode.all);

    // Drive the audio_service playback state (notification, lock screen,
    // system media controls) from just_audio's events.
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) =>
          debugPrint('❌ Playback event error: $e'),
    );

    // Whenever the current track changes, update the now-playing MediaItem
    // (title/artist/album + lazily-loaded artwork).
    _player.currentIndexStream.listen(
      _updateMediaItemForIndex,
      onError: (Object e, StackTrace st) => debugPrint('❌ currentIndex error: $e'),
    );

    // Keep the MediaItem duration in sync once just_audio knows it.
    _player.durationStream.listen(
      (duration) {
        final item = mediaItem.value;
        if (item != null && duration != null && item.duration != duration) {
          mediaItem.add(item.copyWith(duration: duration));
        }
      },
      onError: (Object e, StackTrace st) => debugPrint('❌ duration error: $e'),
    );
  }

  // ---------------------------------------------------------------------------
  // Playback state broadcasting
  // ---------------------------------------------------------------------------

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;

    playbackState.add(
      playbackState.value.copyWith(
        // Buttons shown in the notification.
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        // Actions the system UI (lock screen / expanded media player /
        // OxygenOS dynamic island) is allowed to invoke. Without these the
        // lock-screen and pop-up controls appear but do nothing.
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MediaItem / artwork
  // ---------------------------------------------------------------------------

  Future<void> _updateMediaItemForIndex(int? index) async {
    if (index == null || index < 0 || index >= queue.value.length) return;

    var item = queue.value[index];
    // Emit immediately so the title/artist update even before artwork loads.
    mediaItem.add(item);

    if (item.artUri != null) return;

    final songId = int.tryParse(item.id);
    if (songId == null) return;

    final uri = await _loadArtUri(songId);
    if (uri == null) return;

    item = item.copyWith(artUri: uri);

    // Update the cached queue entry.
    if (index < queue.value.length && queue.value[index].id == item.id) {
      final newQueue = List<MediaItem>.from(queue.value);
      newQueue[index] = item;
      queue.add(newQueue);
    }

    // Only update the now-playing item if it's still this song.
    if (mediaItem.value?.id == item.id) {
      mediaItem.add(item);
    }
  }

  /// Extract embedded artwork and persist it to a cache file, returning a
  /// `file://` uri the notification/lock-screen can render.
  Future<Uri?> _loadArtUri(int songId) async {
    if (_artCache.containsKey(songId)) return _artCache[songId];

    try {
      final bytes = await _audioQuery.queryArtwork(
        songId,
        ArtworkType.AUDIO,
        format: ArtworkFormat.JPEG,
        size: 512,
      );

      if (bytes == null || bytes.isEmpty) {
        _artCache[songId] = null;
        return null;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/artwork_$songId.jpg');
      if (!await file.exists()) {
        await file.writeAsBytes(bytes, flush: true);
      }

      final uri = Uri.file(file.path);
      _artCache[songId] = uri;
      return uri;
    } catch (e) {
      debugPrint('❌ Error loading artwork for $songId: $e');
      _artCache[songId] = null;
      return null;
    }
  }

  MediaItem _toMediaItem(dynamic song) {
    if (song is SongModel) {
      return MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        album: song.album ?? '',
        duration: song.duration != null
            ? Duration(milliseconds: song.duration!)
            : null,
      );
    } else if (song is PlaylistSong) {
      return MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist,
        album: '',
        duration: song.duration != null
            ? Duration(milliseconds: song.duration!)
            : null,
      );
    }
    throw Exception('Unsupported song type');
  }

  String _pathOf(dynamic song) {
    if (song is SongModel) return song.data;
    if (song is PlaylistSong) return song.data;
    throw Exception('Unsupported song type');
  }

  // ---------------------------------------------------------------------------
  // Public queue API (used by the UI screens)
  // ---------------------------------------------------------------------------

  void setQueue(List<dynamic> songs) {
    _songs = songs;
    _sourceMatchesQueue = false;
    queue.add(songs.map(_toMediaItem).toList());
    debugPrint('🎶 Queue set with ${songs.length} songs');
  }

  Future<void> playSongAt(int index) async {
    if (_songs.isEmpty || index < 0 || index >= _songs.length) return;

    try {
      if (!_sourceMatchesQueue) {
        final children = _songs
            .map(
              (s) => AudioSource.uri(Uri.file(_pathOf(s)), tag: _toMediaItem(s)),
            )
            .toList();
        await _player.setAudioSources(
          children,
          initialIndex: index,
          initialPosition: Duration.zero,
        );
        _sourceMatchesQueue = true;
      } else {
        await _player.seek(Duration.zero, index: index);
      }
      await _player.play();
    } catch (e) {
      debugPrint('❌ Error playing song at $index: $e');
    }
  }

  /// Play a single song (wraps it in a one-item queue).
  Future<void> playSong(dynamic song) async {
    setQueue([song]);
    await playSongAt(0);
  }

  Future<void> playNext() => _player.seekToNext();

  Future<void> playPrevious() => _player.seekToPrevious();

  // ---------------------------------------------------------------------------
  // audio_service overrides (notification / lock screen / system media)
  // ---------------------------------------------------------------------------

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) => playSongAt(index);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
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
