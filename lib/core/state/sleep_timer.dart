import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'playback.dart';

/// Time left on the sleep timer, or null when it is off. When it runs out,
/// playback pauses.
final sleepTimerProvider = NotifierProvider<SleepTimerNotifier, Duration?>(
  SleepTimerNotifier.new,
);

class SleepTimerNotifier extends Notifier<Duration?> {
  /// The wall clock; replaced in tests.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  Timer? _ticker;
  DateTime? _endTime;

  @override
  Duration? build() {
    ref.onDispose(() => _ticker?.cancel());
    return null;
  }

  bool get isActive => _endTime != null;

  /// Start (or restart) the timer.
  void start(Duration duration) {
    cancel();
    if (duration <= Duration.zero) return;

    _endTime = now().add(duration);
    state = duration;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final end = _endTime;
    if (end == null) return;
    final left = end.difference(now());
    if (left.inMilliseconds <= 0) {
      cancel();
      ref.read(audioHandlerProvider)?.pause();
    } else {
      state = left;
    }
  }

  void cancel() {
    _ticker?.cancel();
    _ticker = null;
    _endTime = null;
    state = null;
  }
}
