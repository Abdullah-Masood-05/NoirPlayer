import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/library.dart';
import '../../core/state/settings.dart';
import '../../core/state/sleep_timer.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/playback_menus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: Container(
        decoration: AppTheme.topFade(context),
        child: Builder(
          builder: (context) {
            return ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + kToolbarHeight,
              ),
              children: [
                _SectionHeader('Appearance'),
                RadioGroup<ThemeMode>(
                  groupValue: settings.themeMode,
                  onChanged: (mode) {
                    if (mode != null) notifier.setThemeMode(mode);
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
                  title: const Text('Music & download folder'),
                  subtitle: Text(
                    '${settings.musicFolderLabel} • new downloads are saved here',
                  ),
                  onTap: () => _pickMusicFolder(context, ref),
                ),
                const Divider(height: 1),

                _SectionHeader('Playback'),
                ListTile(
                  leading: const Icon(Icons.speed),
                  title: const Text('Playback speed'),
                  subtitle: Text(formatSpeed(settings.playbackSpeed)),
                  onTap: () => showPlaybackSpeedSheet(context),
                ),
                ListTile(
                  leading: const Icon(Icons.timelapse),
                  title: const Text('Seek interval'),
                  subtitle: Text(
                    '${AppSettings.seekIntervalLabel(settings.seekIntervalSeconds)}'
                    ' • player buttons, notification / lock screen and '
                    'headset seek',
                  ),
                  onTap: () => _pickSeekInterval(context, settings, notifier),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.call),
                  title: const Text('Resume playback after a call'),
                  subtitle: const Text('Stay paused otherwise'),
                  value: settings.resumeAfterCall,
                  onChanged: notifier.setResumeAfterCall,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.history),
                  title: const Text('Resume last song on startup'),
                  subtitle: const Text('Reopen where you left off'),
                  value: settings.resumeLastSong,
                  onChanged: notifier.setResumeLastSong,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.swipe),
                  title: const Text('Stop on application swipe'),
                  subtitle: const Text(
                    'Stop music when the app is swiped away from recents. '
                    'Off: it keeps playing in the notification',
                  ),
                  value: settings.stopOnAppSwipe,
                  onChanged: notifier.setStopOnAppSwipe,
                ),
                const Divider(height: 1),

                _SectionHeader('Notification'),
                SwitchListTile(
                  secondary: const Icon(Icons.fast_forward),
                  title: const Text('Seek buttons in notification'),
                  subtitle: const Text(
                    'Back / forward buttons in the notification and lock '
                    'screen. Android 13+ shows them only in the expanded media '
                    'player, and some phones hide them. On iPhone they replace '
                    'previous / next.',
                  ),
                  isThreeLine: true,
                  value: settings.seekButtonsInNotification,
                  onChanged: notifier.setSeekButtonsInNotification,
                ),
                const Divider(height: 1),

                _SectionHeader('Timer'),
                Consumer(
                  builder: (context, ref, _) {
                    final remaining = ref.watch(sleepTimerProvider);
                    return ListTile(
                      leading: const Icon(Icons.bedtime_outlined),
                      title: const Text('Sleep timer'),
                      subtitle: Text(
                        remaining != null
                            ? 'Stops in ${formatTimerDuration(remaining)}'
                            : 'Disabled',
                      ),
                      onTap: () => showSleepTimerSheet(context),
                    );
                  },
                ),
                const Divider(height: 1),

                _SectionHeader('Discover'),
                const ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text("Runs through Noir Player's server"),
                  subtitle: Text(
                    'Optionally add your own keys below. A service with a key '
                    'is called directly with it.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: const Text('Last.fm API key'),
                  subtitle: Text(_keyStatus(settings.lastFmApiKey)),
                  onTap: () => _editApiKey(
                    context,
                    title: 'Last.fm API key',
                    current: settings.lastFmApiKey,
                    save: notifier.setLastFmApiKey,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: const Text('YouTube Data API key'),
                  subtitle: Text(_keyStatus(settings.youtubeApiKey)),
                  onTap: () => _editApiKey(
                    context,
                    title: 'YouTube Data API key',
                    current: settings.youtubeApiKey,
                    save: notifier.setYoutubeApiKey,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: const Text('RapidAPI key'),
                  subtitle: Text(_keyStatus(settings.rapidApiKey)),
                  onTap: () => _editApiKey(
                    context,
                    title: 'RapidAPI key',
                    current: settings.rapidApiKey,
                    save: notifier.setRapidApiKey,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickMusicFolder(BuildContext context, WidgetRef ref) async {
    // Folders come from the song list the Library already loaded.
    try {
      await ref.read(librarySongsProvider.future);
    } catch (_) {}
    if (!context.mounted) return;
    final sorted = ref.read(songFoldersProvider);

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
                subtitle: Text(f, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(ctx, f),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await ref
        .read(settingsProvider.notifier)
        .setMusicFolderPath(selected.isEmpty ? null : selected);
  }

  String _keyStatus(String key) => key.isEmpty
      ? "Not set • uses Noir Player's server"
      : 'Your key • called directly';

  Future<void> _editApiKey(
    BuildContext context, {
    required String title,
    required String current,
    required Future<void> Function(String key) save,
  }) async {
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => _ApiKeyDialog(title: title, initialValue: current),
    );
    if (value != null) await save(value);
  }

  Future<void> _pickSeekInterval(
    BuildContext context,
    AppSettings settings,
    SettingsNotifier notifier,
  ) async {
    // Popped by the "Custom…" entry.
    const custom = -1;
    final current = settings.seekIntervalSeconds;
    final isPreset = AppSettings.seekIntervalPresets.contains(current);

    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seek interval'),
        children: [
          RadioGroup<int>(
            groupValue: current,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final seconds in AppSettings.seekIntervalPresets)
                  RadioListTile<int>(
                    title: Text('$seconds seconds'),
                    value: seconds,
                  ),
              ],
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: Icon(isPreset ? Icons.edit_outlined : Icons.check),
            title: const Text('Custom…'),
            subtitle: isPreset
                ? null
                : Text(AppSettings.seekIntervalLabel(current)),
            onTap: () => Navigator.pop(context, custom),
          ),
        ],
      ),
    );
    if (selected == null) return;
    if (selected != custom) {
      await notifier.setSeekIntervalSeconds(selected);
      return;
    }

    if (!context.mounted) return;
    final seconds = await showDialog<int>(
      context: context,
      builder: (context) => _SeekIntervalDialog(initialSeconds: current),
    );
    if (seconds != null) await notifier.setSeekIntervalSeconds(seconds);
  }
}

/// Asks for a custom seek interval (whole seconds within the allowed range).
/// Pops with the seconds, or null on cancel.
class _SeekIntervalDialog extends StatefulWidget {
  const _SeekIntervalDialog({required this.initialSeconds});

  final int initialSeconds;

  @override
  State<_SeekIntervalDialog> createState() => _SeekIntervalDialogState();
}

class _SeekIntervalDialogState extends State<_SeekIntervalDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.initialSeconds}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final seconds = AppSettings.parseSeekInterval(_controller.text);
    if (seconds != null) Navigator.pop(context, seconds);
  }

  @override
  Widget build(BuildContext context) {
    const min = AppSettings.minSeekIntervalSeconds;
    const max = AppSettings.maxSeekIntervalSeconds;
    final text = _controller.text;
    final valid = AppSettings.parseSeekInterval(text) != null;

    return AlertDialog(
      title: const Text('Custom seek interval'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: InputDecoration(
          suffixText: 'seconds',
          helperText: '$min–$max seconds',
          errorText: text.isEmpty || valid
              ? null
              : 'Enter a number from $min to $max',
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: valid ? _submit : null,
          child: const Text('OK'),
        ),
      ],
    );
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
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Edits one service key. The key is hidden unless the user chooses to show
/// it. Pops with the entered text, '' to clear, or null on cancel.
class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog({required this.title, required this.initialValue});

  final String title;
  final String initialValue;

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  bool _obscured = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: _obscured,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          hintText: 'Paste your key',
          helperText: "Leave empty to use Noir Player's server",
          helperMaxLines: 2,
          suffixIcon: IconButton(
            tooltip: _obscured ? 'Show key' : 'Hide key',
            icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscured = !_obscured),
          ),
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
