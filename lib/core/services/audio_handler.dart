import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_model.dart';
import 'settings_service.dart';

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
      fastForwardInterval: Duration(seconds: 10),
      rewindInterval: Duration(seconds: 10),
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

  /// Whether the user wants playback to continue — used to auto-resume after a
  /// phone-call interruption ends.
  bool _playIntent = false;

  static const _kLastSong = 'playback.lastSong';

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  AudioPlayerHandler() {
    _player.setLoopMode(LoopMode.all);
    _player.setSpeed(SettingsService.instance.playbackSpeed);
    _configureAudioSession();

    // Periodically remember the current song + position so it can be resumed
    // on next launch.
    Timer.periodic(const Duration(seconds: 5), (_) {
      if (_player.playing) _saveLastSong();
    });

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

    // Reflect loop / shuffle changes in the published state immediately.
    _player.loopModeStream.listen((_) => _broadcastState());
    _player.shuffleModeEnabledStream.listen((_) => _broadcastState());
  }

  // ---------------------------------------------------------------------------
  // Playback state broadcasting
  // ---------------------------------------------------------------------------

  void _broadcastState([PlaybackEvent? event]) {
    final playing = _player.playing;
    final showSeek = SettingsService.instance.seekButtonsInNotification;

    // Buttons shown in the notification.
    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      if (showSeek) MediaControl.rewind,
      if (playing) MediaControl.pause else MediaControl.play,
      if (showSeek) MediaControl.fastForward,
      MediaControl.skipToNext,
    ];
    // The compact view always shows prev / play-pause / next.
    final compactIndices = showSeek ? const [0, 2, 4] : const [0, 1, 2];

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
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
          MediaAction.fastForward,
          MediaAction.rewind,
        },
        androidCompactActionIndices: compactIndices,
        processingState: _mapState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        repeatMode: _repeatMode(),
        shuffleMode: _player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        queueIndex: event?.currentIndex ?? _player.currentIndex,
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
      _playIntent = true;
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

  /// Play a remote stream (e.g. a Discover track) through the main player, so it
  /// appears in the player, mini-player and notification and is fully
  /// controllable.
  Future<void> playStream({
    required String id,
    required String url,
    required String title,
    required String artist,
    String? artUri,
  }) async {
    final item = MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: 'Discover',
      artUri: (artUri != null && artUri.isNotEmpty)
          ? Uri.tryParse(artUri)
          : null,
    );
    _songs = [];
    _sourceMatchesQueue = false;
    queue.add([item]);
    mediaItem.add(item);
    await _player.setAudioSources(
      [AudioSource.uri(Uri.parse(url), tag: item)],
      initialIndex: 0,
      initialPosition: Duration.zero,
    );
    _playIntent = true;
    await _player.play();
  }

  Future<void> playNext() => _player.seekToNext();

  Future<void> playPrevious() => _player.seekToPrevious();

  // ---------------------------------------------------------------------------
  // Repeat / shuffle
  // ---------------------------------------------------------------------------

  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;
  LoopMode get loopMode => _player.loopMode;
  bool get shuffleEnabled => _player.shuffleModeEnabled;

  /// Cycle repeat mode: all → one → off → all.
  Future<void> cycleRepeatMode() {
    final next = switch (_player.loopMode) {
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
      LoopMode.off => LoopMode.all,
    };
    return _player.setLoopMode(next);
  }

  Future<void> toggleShuffle() async {
    final enabled = !_player.shuffleModeEnabled;
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
  }

  AudioServiceRepeatMode _repeatMode() => switch (_player.loopMode) {
    LoopMode.off => AudioServiceRepeatMode.none,
    LoopMode.one => AudioServiceRepeatMode.one,
    LoopMode.all => AudioServiceRepeatMode.all,
  };

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) {
    return _player.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.none => LoopMode.off,
      AudioServiceRepeatMode.one => LoopMode.one,
      _ => LoopMode.all,
    });
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    if (enabled) await _player.shuffle();
    await _player.setShuffleModeEnabled(enabled);
  }

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
  Future<void> play() {
    _playIntent = true;
    return _player.play();
  }

  @override
  Future<void> pause() {
    _playIntent = false;
    _saveLastSong();
    return _player.pause();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> fastForward() => _seekBy(SettingsService.instance.seekInterval);

  @override
  Future<void> rewind() => _seekBy(-SettingsService.instance.seekInterval);

  Future<void> _seekBy(Duration offset) async {
    final duration = _player.duration ?? Duration.zero;
    var target = _player.position + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    await _player.seek(target);
  }

  /// Change playback speed and persist it.
  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    await SettingsService.instance.setPlaybackSpeed(speed);
  }

  @override
  Future<void> stop() async {
    _playIntent = false;
    _saveLastSong();
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    if (SettingsService.instance.stopOnAppSwipe) {
      await stop();
    }
    await super.onTaskRemoved();
  }

  // ---------------------------------------------------------------------------
  // Audio focus / interruptions
  // ---------------------------------------------------------------------------

  Future<void> _configureAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      // just_audio pauses on interruption begin; resume on end when the user
      // still intends to play and the "resume after a call" setting is on.
      session.interruptionEventStream.listen((event) {
        if (!event.begin &&
            event.type == AudioInterruptionType.pause &&
            _playIntent &&
            SettingsService.instance.resumeAfterCall) {
          _player.play();
        }
      });
    } catch (e) {
      debugPrint('❌ Audio session config failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Resume-last-song persistence
  // ---------------------------------------------------------------------------

  void _saveLastSong() {
    final index = _player.currentIndex;
    if (index == null || index < 0 || index >= _songs.length) return;
    final item = mediaItem.value;
    if (item == null) return;
    final data = jsonEncode({
      'id': item.id,
      'title': item.title,
      'artist': item.artist,
      'album': item.album,
      'path': _pathOf(_songs[index]),
      'durationMs': item.duration?.inMilliseconds,
      'positionMs': _player.position.inMilliseconds,
    });
    SharedPreferences.getInstance().then((p) => p.setString(_kLastSong, data));
  }

  /// Restore the last played song (paused, at its saved position) on launch.
  Future<void> restoreLastSong() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLastSong);
      if (raw == null) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final path = data['path'] as String?;
      if (path == null || !await File(path).exists()) return;

      final item = MediaItem(
        id: (data['id'] ?? '').toString(),
        title: (data['title'] ?? '') as String,
        artist: (data['artist'] ?? '') as String,
        album: (data['album'] ?? '') as String,
        duration: data['durationMs'] != null
            ? Duration(milliseconds: data['durationMs'] as int)
            : null,
      );

      queue.add([item]);
      mediaItem.add(item);
      await _player.setAudioSources(
        [AudioSource.uri(Uri.file(path), tag: item)],
        initialIndex: 0,
        initialPosition: Duration(milliseconds: (data['positionMs'] ?? 0) as int),
      );
      // The next library tap rebuilds the real queue.
      _sourceMatchesQueue = false;
      _songs = [];
    } catch (e) {
      debugPrint('❌ Error restoring last song: $e');
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
