import 'package:flutter/material.dart';

import '../core/services/audio_handler.dart';
import '../core/services/settings_service.dart';
import '../core/services/sleep_timer_service.dart';

String formatTimerDuration(Duration d) {
  if (d.inHours >= 1) {
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatSpeed(double speed) =>
    '${speed.toString().replaceAll(RegExp(r'\.0$'), '')}x';

/// Bottom sheet to start / cancel the sleep timer.
Future<void> showSleepTimerSheet(BuildContext context) {
  const presets = [5, 10, 15, 30, 45, 60];

  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ValueListenableBuilder<Duration?>(
          valueListenable: SleepTimerService.instance.remaining,
          builder: (context, remaining, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Sleep timer',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (remaining != null)
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: Text('Stops in ${formatTimerDuration(remaining)}'),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      onPressed: () {
                        SleepTimerService.instance.cancel();
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final minutes in presets)
                        ActionChip(
                          label: Text('$minutes min'),
                          onPressed: () {
                            SleepTimerService.instance.start(
                              Duration(minutes: minutes),
                              () => audioHandler.pause(),
                            );
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  'Playback will stop in $minutes minutes',
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

/// Bottom sheet to choose playback speed.
Future<void> showPlaybackSpeedSheet(BuildContext context) {
  const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListenableBuilder(
          listenable: SettingsService.instance,
          builder: (context, _) {
            final current = SettingsService.instance.playbackSpeed;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    'Playback speed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RadioGroup<double>(
                  groupValue: current,
                  onChanged: (value) {
                    if (value != null) {
                      (audioHandler as AudioPlayerHandler).setSpeed(value);
                    }
                    Navigator.pop(sheetContext);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final speed in speeds)
                        RadioListTile<double>(
                          title: Text(formatSpeed(speed)),
                          value: speed,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
