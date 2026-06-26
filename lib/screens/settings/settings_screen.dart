import 'package:flutter/material.dart';

import '../../core/services/settings_service.dart';
import '../../core/services/sleep_timer_service.dart';
import '../../widgets/playback_menus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ListView(
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
    );
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
