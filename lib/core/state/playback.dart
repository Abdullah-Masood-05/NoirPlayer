import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;

import '../services/audio_handler.dart';

/// The app's audio handler, or null if the audio service failed to start.
/// Attached in `main` before `runApp`.
final audioHandlerProvider =
    NotifierProvider<AudioHandlerHolder, AudioPlayerHandler?>(
      AudioHandlerHolder.new,
    );

class AudioHandlerHolder extends Notifier<AudioPlayerHandler?> {
  @override
  AudioPlayerHandler? build() => null;

  void attach(AudioPlayerHandler handler) => state = handler;
}

/// The now-playing item (null when nothing is loaded).
final mediaItemProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.mediaItem ?? Stream.value(null);
});

/// The id of the now-playing item. Changes only when the song changes, not
/// when its artwork or duration arrives.
final currentMediaIdProvider = Provider<String?>(
  (ref) => ref.watch(mediaItemProvider.select((item) => item.value?.id)),
);

/// Whether [id] is the now-playing item. List rows watch this, so a song
/// change rebuilds only the two rows involved.
final isCurrentMediaProvider = Provider.family<bool, String>(
  (ref, id) =>
      ref.watch(currentMediaIdProvider.select((current) => current == id)),
);

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.playbackState ?? Stream.value(PlaybackState());
});

/// Playing or paused. Changes far less often than the full playback state,
/// which is re-published on every buffering / position event.
final isPlayingProvider = Provider<bool>(
  (ref) => ref.watch(
    playbackStateProvider.select((state) => state.value?.playing ?? false),
  ),
);

final positionProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.positionStream ?? Stream.value(Duration.zero);
});

final durationProvider = StreamProvider<Duration?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.durationStream ?? Stream.value(null);
});

final loopModeProvider = StreamProvider<LoopMode>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.loopModeStream ?? Stream.value(LoopMode.all);
});

final shuffleEnabledProvider = StreamProvider<bool>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.shuffleModeStream ?? Stream.value(false);
});

/// The queue in play order, for the "Up next" sheet.
final upNextProvider = StreamProvider<UpNext>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler?.upNextStream ?? Stream.value(UpNext.empty);
});
