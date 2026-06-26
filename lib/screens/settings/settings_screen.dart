import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../core/services/settings_service.dart';
import '../../core/services/sleep_timer_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/playback_menus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: Container(
        decoration: AppTheme.topFade(context),
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) {
            return ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + kToolbarHeight,
              ),
              children: [
                _SectionHeader('Appearance'),
              RadioGroup<ThemeMode>(
                groupValue: settings.themeMode,
                onChanged: (mode) {
                  if (mode != null) settings.setThemeMode(mode);
                },
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('System default'),
                      subtitle: Text('Follow the system theme'),
                      value: ThemeMode.system,
                      secondary: Icon(Icons.brightness_auto),
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Light'),
                      value: ThemeMode.light,
                      secondary: Icon(Icons.light_mode),
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('Dark'),
                      value: ThemeMode.dark,
                      secondary: Icon(Icons.dark_mode),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              _SectionHeader('Library'),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Music folder'),
                subtitle: Text(settings.musicFolderLabel),
                onTap: () => _pickMusicFolder(context, settings),
              ),
              const Divider(height: 1),

              _SectionHeader('Playback'),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Playback speed'),
                subtitle: Text(formatSpeed(settings.playbackSpeed)),
                onTap: () => showPlaybackSpeedSheet(context),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.call),
                title: const Text('Resume playback after a call'),
                subtitle: const Text('Stay paused otherwise'),
                value: settings.resumeAfterCall,
                onChanged: settings.setResumeAfterCall,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.history),
                title: const Text('Resume last song on startup'),
                subtitle: const Text('Reopen where you left off'),
                value: settings.resumeLastSong,
                onChanged: settings.setResumeLastSong,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.swipe),
                title: const Text('Stop on application swipe'),
                subtitle: const Text('Stop playback when the app is dismissed'),
                value: settings.stopOnAppSwipe,
                onChanged: settings.setStopOnAppSwipe,
              ),
              const Divider(height: 1),

              _SectionHeader('Notification'),
              SwitchListTile(
                secondary: const Icon(Icons.fast_forward),
                title: const Text('Seek buttons in notification'),
                subtitle: const Text(
                  'Show rewind and fast-forward in media controls',
                ),
                value: settings.seekButtonsInNotification,
                onChanged: settings.setSeekButtonsInNotification,
              ),
              ListTile(
                leading: const Icon(Icons.timelapse),
                title: const Text('Seek interval'),
                subtitle: Text('${settings.seekIntervalSeconds} seconds'),
                onTap: () => _pickSeekInterval(context, settings),
              ),
              const Divider(height: 1),

              _SectionHeader('Timer'),
              ValueListenableBuilder<Duration?>(
                valueListenable: SleepTimerService.instance.remaining,
                builder: (context, remaining, _) => ListTile(
                  leading: const Icon(Icons.bedtime_outlined),
                  title: const Text('Sleep timer'),
                  subtitle: Text(
                    remaining != null
                        ? 'Stops in ${formatTimerDuration(remaining)}'
                        : 'Disabled',
                  ),
                  onTap: () => showSleepTimerSheet(context),
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  Future<void> _pickMusicFolder(
    BuildContext context,
    SettingsService settings,
  ) async {
    final audioQuery = OnAudioQuery();
    final songs = await audioQuery.querySongs();
    final folders = <String>{};
    for (final s in songs) {
      final idx = s.data.lastIndexOf('/');
      if (idx > 0) folders.add(s.data.substring(0, idx));
    }
    final sorted = folders.toList()..sort();
    if (!context.mounted) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, controller) => ListView(
          controller: controller,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Music folder',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Default (Music folder)'),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            const Divider(height: 1),
            for (final f in sorted)
              ListTile(
                leading: const Icon(Icons.folder),
                title: Text(
                  f.split('/').lastWhere((p) => p.isNotEmpty, orElse: () => f),
                ),
                subtitle: Text(
                  f,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(ctx, f),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await settings.setMusicFolderPath(selected.isEmpty ? null : selected);
  }

  Future<void> _pickSeekInterval(
    BuildContext context,
    SettingsService settings,
  ) async {
    const options = [5, 10, 15, 30, 60];
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seek interval'),
        children: [
          RadioGroup<int>(
            groupValue: settings.seekIntervalSeconds,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final seconds in options)
                  RadioListTile<int>(
                    title: Text('$seconds seconds'),
                    value: seconds,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) settings.setSeekIntervalSeconds(selected);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
