import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One playback command the audio handler received.
@immutable
class RemoteCommand {
  const RemoteCommand(this.time, this.name, {required this.inBackground});

  final DateTime time;
  final String name;

  /// True if the app was not in the foreground, i.e. the command came from
  /// the notification, the OnePlus media card, a headset or the lock screen.
  final bool inBackground;
}

/// The last commands the audio handler received, newest first. A test aid
/// for the Live build: shows whether taps on the OnePlus media card reach the
/// app at all.
final remoteLogProvider =
    NotifierProvider<RemoteLogNotifier, List<RemoteCommand>>(
      RemoteLogNotifier.new,
    );

class RemoteLogNotifier extends Notifier<List<RemoteCommand>> {
  static const _max = 60;

  @override
  List<RemoteCommand> build() => const [];

  void add(String name) {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    final entry = RemoteCommand(
      DateTime.now(),
      name,
      inBackground: lifecycle != AppLifecycleState.resumed,
    );
    state = [entry, ...state.take(_max - 1)];
  }

  void clear() => state = const [];
}
