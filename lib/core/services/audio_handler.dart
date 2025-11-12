// import 'package:audio_service/audio_service.dart';
// import 'package:just_audio/just_audio.dart';

// late final AudioHandler audioHandler; // ✅ Global instance

// Future<void> initAudioService() async {
//   try {
//     audioHandler = await AudioService.init(
//       builder: () => AudioPlayerHandler(),
//       config: const AudioServiceConfig(
//         androidNotificationChannelId: 'com.example.noir_player.channel.audio',
//         androidNotificationChannelName: 'Noir Player',
//         androidNotificationOngoing: true,
//       ),
//     );
//     print( 'AudioService initialized successfully.');
//   } catch (e) {
//     print('Error initializing AudioService: $e');
//   }
// }
// // Create a MediaItem to represent the current song.

// class AudioPlayerHandler extends BaseAudioHandler {
//   final _player = AudioPlayer();

//   AudioPlayerHandler() {
//     // Keep media item and playback state updated
//     _player.playerStateStream.listen((state) {
//       playbackState.add(
//         PlaybackState(
//           playing: state.playing,
//           processingState: _mapState(state.processingState),
//         ),
//       );
//     });
//   }

//   Future<void> playSong(String uri) async {
//     try {
//       final item = MediaItem(
//         id: uri,
//         title: uri.split('/').last,
//       );
//       mediaItem.add(item);
//       await _player.setUrl(uri);
//       await _player.play();
//       print('Playing song: $uri');
//       return;

//     } catch (e) {
//       print('Error playing song: $e');
//     }
//   }

//   AudioProcessingState _mapState(ProcessingState state) {
//     switch (state) {
//       case ProcessingState.idle:
//         return AudioProcessingState.idle;
//       case ProcessingState.loading:
//         return AudioProcessingState.loading;
//       case ProcessingState.buffering:
//         return AudioProcessingState.buffering;
//       case ProcessingState.ready:
//         return AudioProcessingState.ready;
//       case ProcessingState.completed:
//         return AudioProcessingState.completed;
//     }
//   }

// }

// import 'package:audio_service/audio_service.dart';
// import 'package:just_audio/just_audio.dart';

// late final AudioHandler audioHandler;
// bool _isInitialized = false;

// Future<void> initAudioService() async {
//   if (_isInitialized) {
//     print('⚠️ AudioService already initialized');
//     return;
//   }

//   try {
//     print('🔄 Initializing AudioService...');
//     audioHandler = await AudioService.init(
//       builder: () => AudioPlayerHandler(),
//       config: const AudioServiceConfig(
//         androidNotificationChannelId: 'com.example.noir_player.channel.audio',
//         androidNotificationChannelName: 'Noir Player',
//         androidNotificationOngoing: true,
//         androidShowNotificationBadge: true,
//       ),
//     );
//     _isInitialized = true;
//     print('✅ AudioService initialized successfully.');
//   } catch (e) {
//     print('❌ Error initializing AudioService: $e');
//     print('Stack: ${StackTrace.current}');
//     rethrow; // Re-throw so we know initialization failed
//   }
// }

// // Helper function to check if initialized
// bool isAudioServiceInitialized() => _isInitialized;

// class AudioPlayerHandler extends BaseAudioHandler {
//   final _player = AudioPlayer();

//   AudioPlayerHandler() {
//     // Keep playback state updated
//     _player.playerStateStream.listen((state) {
//       playbackState.add(
//         PlaybackState(
//           playing: state.playing,
//           processingState: _mapState(state.processingState),
//           controls: [
//             MediaControl.skipToPrevious,
//             if (state.playing) MediaControl.pause else MediaControl.play,
//             MediaControl.skipToNext,
//           ],
//         ),
//       );
//     });
//   }

//   Future<void> playSong(String uri) async {
//     try {
//       print('🎵 Attempting to play: $uri');

//       // ✅ Stop any currently playing song first
//       if (_player.playing) {
//         await _player.stop();
//         print('⏹️ Stopped previous song');
//       }

//       // Extract filename from URI for title
//       final fileName = uri.split('/').last;
//       final title = fileName.replaceAll(RegExp(r'\.[^.]+$'), ''); // Remove extension

//       final item = MediaItem(
//         id: uri,
//         title: title,
//         artist: 'Unknown Artist',
//         album: 'Unknown Album',
//       );

//       mediaItem.add(item);
//       print('📝 MediaItem created: $title');

//       await _player.setFilePath(uri); // ✅ Changed from setUrl to setFilePath for local files
//       print('✅ File path set');

//       await _player.play();
//       print('▶️ Playing song: $title');
//     } catch (e) {
//       print('❌ Error playing song: $e');
//       print('Stack trace: ${StackTrace.current}');
//     }
//   }

//   @override
//   Future<void> play() async {
//     print('▶️ Play called');
//     await _player.play();
//   }

//   @override
//   Future<void> pause() async {
//     print('⏸️ Pause called');
//     await _player.pause();
//   }

//   @override
//   Future<void> stop() async {
//     print('⏹️ Stop called');
//     await _player.stop();
//     await super.stop();
//   }

//   @override
//   Future<void> dispose() async {
//     await _player.dispose();
//   }

//   AudioProcessingState _mapState(ProcessingState state) {
//     switch (state) {
//       case ProcessingState.idle:
//         return AudioProcessingState.idle;
//       case ProcessingState.loading:
//         return AudioProcessingState.loading;
//       case ProcessingState.buffering:
//         return AudioProcessingState.buffering;
//       case ProcessingState.ready:
//         return AudioProcessingState.ready;
//       case ProcessingState.completed:
//         return AudioProcessingState.completed;
//     }
//   }
// }

// import 'package:audio_service/audio_service.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:on_audio_query/on_audio_query.dart';

// late final AudioHandler audioHandler;
// bool _isInitialized = false;

// Future<void> initAudioService() async {
//   if (_isInitialized) {
//     print('⚠️ AudioService already initialized');
//     return;
//   }

//   try {
//     print('🔄 Initializing AudioService...');
//     audioHandler = await AudioService.init(
//       builder: () => AudioPlayerHandler(),
//       config: const AudioServiceConfig(
//         androidNotificationChannelId: 'com.example.noir_player.channel.audio',
//         androidNotificationChannelName: 'Noir Player',
//         androidNotificationOngoing: true,
//         androidShowNotificationBadge: true,
//       ),
//     );
//     _isInitialized = true;
//     print('✅ AudioService initialized successfully.');
//   } catch (e) {
//     print('❌ Error initializing AudioService: $e');
//     print('Stack: ${StackTrace.current}');
//     rethrow;
//   }
// }

// bool isAudioServiceInitialized() => _isInitialized;

// class AudioPlayerHandler extends BaseAudioHandler {
//   final _player = AudioPlayer();
//   final OnAudioQuery _audioQuery = OnAudioQuery();

//   AudioPlayerHandler() {
//     _player.playerStateStream.listen((state) {
//       playbackState.add(
//         PlaybackState(
//           playing: state.playing,
//           processingState: _mapState(state.processingState),
//           controls: [
//             MediaControl.skipToPrevious,
//             if (state.playing) MediaControl.pause else MediaControl.play,
//             MediaControl.skipToNext,
//           ],
//         ),
//       );
//     });
//   }

//   // ✅ Updated to accept SongModel instead of just URI
//   Future<void> playSong(SongModel song) async {
//     try {
//       print('🎵 Attempting to play: ${song.title}');

//       if (_player.playing) {
//         await _player.stop();
//         print('⏹️ Stopped previous song');
//       }

//       // ✅ Note: queryArtwork returns Uint8List (raw bytes), not a file path
//       // MediaItem.artUri expects a URI, but we can't directly use Uint8List
//       // The artwork will be handled separately in the UI using QueryArtworkWidget

//       // ✅ Create MediaItem with actual song metadata
//       final item = MediaItem(
//         id: song.id.toString(),
//         title: song.title,
//         artist: song.artist ?? 'Unknown Artist',
//         album: song.album ?? 'Unknown Album',
//         duration: Duration(milliseconds: song.duration ?? 0),
//         // Note: artUri is null here, we'll use QueryArtworkWidget in PlayerScreen
//       );

//       mediaItem.add(item);
//       print('📝 MediaItem created: ${song.title} by ${song.artist}');

//       await _player.setFilePath(song.data);
//       print('✅ File path set');

//       await _player.play();
//       print('▶️ Playing song: ${song.title}');
//     } catch (e) {
//       print('❌ Error playing song: $e');
//       print('Stack trace: ${StackTrace.current}');
//     }
//   }

//   @override
//   Future<void> play() async {
//     print('▶️ Play called');
//     await _player.play();
//   }

//   @override
//   Future<void> pause() async {
//     print('⏸️ Pause called');
//     await _player.pause();
//   }

//   @override
//   Future<void> stop() async {
//     print('⏹️ Stop called');
//     await _player.stop();
//     await super.stop();
//   }

//   @override
//   Future<void> dispose() async {
//     await _player.dispose();
//   }

//   AudioProcessingState _mapState(ProcessingState state) {
//     switch (state) {
//       case ProcessingState.idle:
//         return AudioProcessingState.idle;
//       case ProcessingState.loading:
//         return AudioProcessingState.loading;
//       case ProcessingState.buffering:
//         return AudioProcessingState.buffering;
//       case ProcessingState.ready:
//         return AudioProcessingState.ready;
//       case ProcessingState.completed:
//         return AudioProcessingState.completed;
//     }
//   }
// }

// import 'package:audio_service/audio_service.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:on_audio_query/on_audio_query.dart';

// late final AudioHandler audioHandler;
// bool _isInitialized = false;

// Future<void> initAudioService() async {
//   if (_isInitialized) {
//     print('⚠️ AudioService already initialized');
//     return;
//   }

//   try {
//     print('🔄 Initializing AudioService...');
//     audioHandler = await AudioService.init(
//       builder: () => AudioPlayerHandler(),
//       config: const AudioServiceConfig(
//         androidNotificationChannelId: 'com.example.noir_player.channel.audio',
//         androidNotificationChannelName: 'Noir Player',
//         androidNotificationOngoing: true,
//         androidShowNotificationBadge: true,
//       ),
//     );
//     _isInitialized = true;
//     print('✅ AudioService initialized successfully.');
//   } catch (e) {
//     print('❌ Error initializing AudioService: $e');
//     print('Stack: ${StackTrace.current}');
//     rethrow;
//   }
// }

// bool isAudioServiceInitialized() => _isInitialized;

// class AudioPlayerHandler extends BaseAudioHandler {
//   final _player = AudioPlayer();
//   final OnAudioQuery _audioQuery = OnAudioQuery();

//   // 🎶 Queue management
//   List<SongModel> _queue = [];
//   int _currentIndex = 0;

//   // 🎵 Expose position stream for progress bar
//   Stream<Duration> get positionStream => _player.positionStream;

//   AudioPlayerHandler() {
//     // 🔁 Update playback state based on player state
//     _player.playerStateStream.listen((state) {
//       // Note: do not pass unsupported named parameters (position/bufferedPosition)
//       playbackState.add(
//         PlaybackState(
//           playing: state.playing,
//           processingState: _mapState(state.processingState),
//           controls: [
//             MediaControl.skipToPrevious,
//             if (state.playing) MediaControl.pause else MediaControl.play,
//             MediaControl.skipToNext,
//           ],
//         ),
//       );
//     });

//     // We do NOT call playbackState.copyWith(position: ...) because
//     // some audio_service versions don't support that named field.
//     // The UI should use positionStream for position updates.
//   }

//   // ✅ Play a specific song
//   Future<void> playSong(SongModel song) async {
//     try {
//       print('🎵 Attempting to play: ${song.title}');

//       if (_player.playing) {
//         await _player.stop();
//         print('⏹️ Stopped previous song');
//       }

//       final item = MediaItem(
//         id: song.id.toString(),
//         title: song.title,
//         artist: song.artist ?? 'Unknown Artist',
//         album: song.album ?? 'Unknown Album',
//         duration: Duration(milliseconds: song.duration ?? 0),
//       );

//       mediaItem.add(item);
//       print('📝 MediaItem created: ${song.title} by ${song.artist}');

//       await _player.setFilePath(song.data);
//       print('✅ File path set');

//       await _player.play();
//       print('▶️ Playing song: ${song.title}');
//     } catch (e) {
//       print('❌ Error playing song: $e');
//       print('Stack trace: ${StackTrace.current}');
//     }
//   }

//   // 🎧 Manage the song queue
//   void setQueue(List<SongModel> songs) {
//     _queue = songs;
//     print('🎶 Queue set with ${songs.length} songs');
//   }

//   Future<void> playSongAt(int index) async {
//     if (_queue.isEmpty || index < 0 || index >= _queue.length) {
//       print('⚠️ Invalid index or empty queue');
//       return;
//     }
//     _currentIndex = index;
//     await playSong(_queue[_currentIndex]);
//   }

//   Future<void> playNext() async {
//     if (_queue.isEmpty) {
//       print('⚠️ Queue is empty, cannot play next.');
//       return;
//     }
//     _currentIndex = (_currentIndex + 1) % _queue.length;
//     print('⏭️ Playing next song (index: $_currentIndex)');
//     await playSongAt(_currentIndex);
//   }

//   Future<void> playPrevious() async {
//     if (_queue.isEmpty) {
//       print('⚠️ Queue is empty, cannot play previous.');
//       return;
//     }
//     _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
//     print('⏮️ Playing previous song (index: $_currentIndex)');
//     await playSongAt(_currentIndex);
//   }

//   @override
//   Future<void> play() async {
//     print('▶️ Play called');
//     await _player.play();
//   }

//   @override
//   Future<void> pause() async {
//     print('⏸️ Pause called');
//     await _player.pause();
//   }

//   @override
//   Future<void> stop() async {
//     print('⏹️ Stop called');
//     await _player.stop();
//     await super.stop();
//   }

//   // 🎯 Seek to a specific position (for slider)
//   @override
//   Future<void> seek(Duration position) async {
//     print('⏩ Seeking to: ${position.inSeconds}s');
//     await _player.seek(position);
//   }

//   @override
//   Future<void> dispose() async {
//     await _player.dispose();
//   }

//   // 🧭 Helper to map JustAudio -> AudioService states
//   AudioProcessingState _mapState(ProcessingState state) {
//     switch (state) {
//       case ProcessingState.idle:
//         return AudioProcessingState.idle;
//       case ProcessingState.loading:
//         return AudioProcessingState.loading;
//       case ProcessingState.buffering:
//         return AudioProcessingState.buffering;
//       case ProcessingState.ready:
//         return AudioProcessingState.ready;
//       case ProcessingState.completed:
//         return AudioProcessingState.completed;
//     }
//   }
// }

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/playlist_model.dart'; // <-- import your PlaylistSong

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

  // 🎶 Queue can be either SongModel or PlaylistSong
  List<dynamic> _queue = [];
  int _currentIndex = 0;

  Stream<Duration> get positionStream => _player.positionStream;

  AudioPlayerHandler() {
    _player.playerStateStream.listen((state) {
      playbackState.add(
        PlaybackState(
          playing: state.playing,
          processingState: _mapState(state.processingState),
          controls: [
            MediaControl.skipToPrevious,
            if (state.playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
        ),
      );
    });
  }

  // ✅ Play a SongModel or PlaylistSong
  Future<void> playSong(dynamic song) async {
    try {
      String path;
      String title;
      String artist;
      String album = '';
      int? durationMs;

      if (song is SongModel) {
        path = song.data;
        title = song.title;
        artist = song.artist ?? 'Unknown Artist';
        album = song.album ?? '';
        durationMs = song.duration;
      } else if (song is PlaylistSong) {
        path = song.data;
        title = song.title;
        artist = song.artist ?? 'Unknown Artist';
        //album = song.album ?? '';
        durationMs = song.duration;
      } else {
        throw Exception('Unsupported song type');
      }

      final item = MediaItem(
        id: song is SongModel
            ? song.id.toString()
            : (song as PlaylistSong).id.toString(),
        title: title,
        artist: artist,
        album: album,
        duration: Duration(milliseconds: durationMs ?? 0),
      );

      mediaItem.add(item);

      await _player.setFilePath(path);
      await _player.play();
    } catch (e) {
      print('❌ Error playing song: $e');
    }
  }

  // 🎧 Manage the queue
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

  @override
  Future<void> play() async => _player.play();

  @override
  Future<void> pause() async => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async => _player.seek(position);

  @override
  Future<void> dispose() async => await _player.dispose();

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
