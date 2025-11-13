// import 'package:flutter/material.dart';

// class SettingsScreen extends StatelessWidget {
//   const SettingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text('Settings Screen'),
//     );
//   }
// }

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const SettingsScreen({super.key, required this.themeNotifier});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _isDark = widget.themeNotifier.value == ThemeMode.dark;
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDark = value;
    });
    widget.themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _isDark,
            onChanged: _toggleTheme,
            secondary: const Icon(Icons.brightness_6),
          ),
        ],
      ),
    );
  }
}
