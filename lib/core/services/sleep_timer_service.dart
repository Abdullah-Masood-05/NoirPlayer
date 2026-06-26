import 'dart:async';

import 'package:flutter/foundation.dart';

/// Stops playback after a chosen duration.
///
/// Exposes [remaining] (null when inactive) so the UI can show a live
/// countdown via `ValueListenableBuilder`.
class SleepTimerService {
  SleepTimerService._();
  static final SleepTimerService instance = SleepTimerService._();

  Timer? _ticker;
  DateTime? _endTime;
  VoidCallback? _onComplete;

  /// Time left, or null when no timer is running.
  final ValueNotifier<Duration?> remaining = ValueNotifier<Duration?>(null);

  bool get isActive => _endTime != null;

  /// Start (or restart) the timer. [onComplete] runs when it elapses.
  void start(Duration duration, VoidCallback onComplete) {
    cancel();
    if (duration <= Duration.zero) return;

    _onComplete = onComplete;
    _endTime = DateTime.now().add(duration);
    remaining.value = duration;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final end = _endTime;
      if (end == null) return;
      final left = end.difference(DateTime.now());
      if (left.inMilliseconds <= 0) {
        final callback = _onComplete;
        cancel();
        callback?.call();
      } else {
        remaining.value = left;
      }
    });
  }

  void cancel() {
    _ticker?.cancel();
    _ticker = null;
    _endTime = null;
    _onComplete = null;
    remaining.value = null;
  }
}
