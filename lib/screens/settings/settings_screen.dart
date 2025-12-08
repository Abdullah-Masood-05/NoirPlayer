import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const SettingsScreen({super.key, required this.themeNotifier});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _currentThemeMode;

  @override
  void initState() {
    super.initState();
    _currentThemeMode = widget.themeNotifier.value;
  }

  void _changeThemeMode(ThemeMode? mode) {
    if (mode == null) return;
    setState(() {
      _currentThemeMode = mode;
    });
    widget.themeNotifier.value = mode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Theme',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            subtitle: const Text('Follow system theme setting'),
            value: ThemeMode.system,
            groupValue: _currentThemeMode,
            onChanged: _changeThemeMode,
            secondary: const Icon(Icons.brightness_auto),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light Mode'),
            subtitle: const Text('Always use light theme'),
            value: ThemeMode.light,
            groupValue: _currentThemeMode,
            onChanged: _changeThemeMode,
            secondary: const Icon(Icons.light_mode),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Mode'),
            subtitle: const Text('Always use dark theme'),
            value: ThemeMode.dark,
            groupValue: _currentThemeMode,
            onChanged: _changeThemeMode,
            secondary: const Icon(Icons.dark_mode),
          ),
        ],
      ),
    );
  }
}
