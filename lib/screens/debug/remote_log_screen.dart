import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/remote_log.dart';
import '../../core/theme/app_theme.dart';

/// Live build test aid: lists the playback commands the app received, so we
/// can tell whether the OnePlus media card's buttons reach it.
class RemoteLogScreen extends ConsumerWidget {
  const RemoteLogScreen({super.key});

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final log = ref.watch(remoteLogProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Remote controls log'),
        actions: [
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => ref.read(remoteLogProvider.notifier).clear(),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.topFade(context),
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + kToolbarHeight,
            bottom: 24,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Play a song, pull down the quick settings and tap play, '
                'pause, next and previous on the media card (and in its '
                'expanded Media player). Then come back here.\n\n'
                'Every command the app received is listed, newest first. '
                '"background" means the app was not on screen. If your taps '
                'are missing here, they never reached Noir Player.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Divider(height: 1),
            if (log.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Nothing received yet',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              for (final entry in log)
                ListTile(
                  dense: true,
                  leading: Icon(
                    entry.inBackground
                        ? Icons.notifications_active_outlined
                        : Icons.phone_android,
                    color: entry.inBackground
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color?.withValues(alpha: 0.5),
                  ),
                  title: Text(entry.name),
                  subtitle: Text(
                    '${_time(entry.time)} · '
                    '${entry.inBackground ? 'background' : 'in app'}',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
