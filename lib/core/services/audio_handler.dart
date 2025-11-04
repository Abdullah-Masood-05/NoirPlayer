

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


import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

late final AudioHandler audioHandler;
bool _isInitialized = false;

Future<void> initAudioService() async {
  if (_isInitialized) {
    print('⚠️ AudioService already initialized');
    return;
  }
  
  try {
    print('🔄 Initializing AudioService...');
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
    print('✅ AudioService initialized successfully.');
  } catch (e) {
    print('❌ Error initializing AudioService: $e');
    print('Stack: ${StackTrace.current}');
    rethrow;
  }
}

bool isAudioServiceInitialized() => _isInitialized;

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

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

  // ✅ Updated to accept SongModel instead of just URI
  Future<void> playSong(SongModel song) async {
    try {
      print('🎵 Attempting to play: ${song.title}');
      
      if (_player.playing) {
        await _player.stop();
        print('⏹️ Stopped previous song');
      }
      
      // ✅ Note: queryArtwork returns Uint8List (raw bytes), not a file path
      // MediaItem.artUri expects a URI, but we can't directly use Uint8List
      // The artwork will be handled separately in the UI using QueryArtworkWidget
      
      // ✅ Create MediaItem with actual song metadata
      final item = MediaItem(
        id: song.id.toString(),
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        album: song.album ?? 'Unknown Album',
        duration: Duration(milliseconds: song.duration ?? 0),
        // Note: artUri is null here, we'll use QueryArtworkWidget in PlayerScreen
      );
      
      mediaItem.add(item);
      print('📝 MediaItem created: ${song.title} by ${song.artist}');
      
      await _player.setFilePath(song.data);
      print('✅ File path set');
      
      await _player.play();
      print('▶️ Playing song: ${song.title}');
    } catch (e) {
      print('❌ Error playing song: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  @override
  Future<void> play() async {
    print('▶️ Play called');
    await _player.play();
  }

  @override
  Future<void> pause() async {
    print('⏸️ Pause called');
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    print('⏹️ Stop called');
    await _player.stop();
    await super.stop();
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