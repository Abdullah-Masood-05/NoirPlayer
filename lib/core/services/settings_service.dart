import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user preferences, persisted with SharedPreferences.
///
/// A [ChangeNotifier] singleton: widgets rebuild via `ListenableBuilder` and
/// services (e.g. the audio handler) read the values directly.
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  SharedPreferences? _prefs;

  // ── Appearance ───────────────────────────────────────────────────────────
  ThemeMode themeMode = ThemeMode.system;

  // ── Playback ─────────────────────────────────────────────────────────────
  /// Resume playback automatically after a phone call / interruption ends.
  bool resumeAfterCall = true;

  /// Restore the last played song (paused, at its last position) on launch.
  bool resumeLastSong = true;

  /// Stop playback when the app is swiped away from recents.
  bool stopOnAppSwipe = false;

  /// Show rewind / fast-forward buttons in the media notification.
  bool seekButtonsInNotification = false;

  /// Playback speed multiplier (0.5–2.0).
  double playbackSpeed = 1.0;

  /// Rewind / fast-forward step, in seconds.
  int seekIntervalSeconds = 10;

  /// Folder the Library's "Music" tab loads from. Null = the device Music
  /// folder (paths containing `/music/`).
  String? musicFolderPath;

  // ── Keys ─────────────────────────────────────────────────────────────────
  static const _kTheme = 'settings.themeMode';
  static const _kResumeAfterCall = 'settings.resumeAfterCall';
  static const _kResumeLastSong = 'settings.resumeLastSong';
  static const _kStopOnAppSwipe = 'settings.stopOnAppSwipe';
  static const _kSeekButtons = 'settings.seekButtonsInNotification';
  static const _kPlaybackSpeed = 'settings.playbackSpeed';
  static const _kSeekInterval = 'settings.seekIntervalSeconds';
  static const _kMusicFolder = 'settings.musicFolderPath';

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    themeMode = _themeFromName(prefs.getString(_kTheme));
    resumeAfterCall = prefs.getBool(_kResumeAfterCall) ?? true;
    resumeLastSong = prefs.getBool(_kResumeLastSong) ?? true;
    stopOnAppSwipe = prefs.getBool(_kStopOnAppSwipe) ?? false;
    seekButtonsInNotification = prefs.getBool(_kSeekButtons) ?? false;
    playbackSpeed = prefs.getDouble(_kPlaybackSpeed) ?? 1.0;
    seekIntervalSeconds = prefs.getInt(_kSeekInterval) ?? 10;
    musicFolderPath = prefs.getString(_kMusicFolder);
  }

  /// A short display label for the chosen music folder.
  String get musicFolderLabel {
    final path = musicFolderPath;
    if (path == null || path.isEmpty) return 'Music folder (default)';
    final name = path.split('/').where((p) => p.isNotEmpty).lastOrNull;
    return name == null || name.isEmpty ? path : name;
  }

  /// True if [songPath] belongs to the selected music folder.
  bool isInMusicFolder(String songPath) {
    final path = musicFolderPath;
    if (path == null || path.isEmpty) {
      return songPath.toLowerCase().contains('/music/');
    }
    return songPath.toLowerCase().startsWith(path.toLowerCase());
  }

  Duration get seekInterval => Duration(seconds: seekIntervalSeconds);

  // ── Setters (persist + notify) ────────────────────────────────────────────
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _prefs?.setString(_kTheme, mode.name);
    notifyListeners();
  }

  Future<void> setResumeAfterCall(bool v) async {
    resumeAfterCall = v;
    await _prefs?.setBool(_kResumeAfterCall, v);
    notifyListeners();
  }

  Future<void> setResumeLastSong(bool v) async {
    resumeLastSong = v;
    await _prefs?.setBool(_kResumeLastSong, v);
    notifyListeners();
  }

  Future<void> setStopOnAppSwipe(bool v) async {
    stopOnAppSwipe = v;
    await _prefs?.setBool(_kStopOnAppSwipe, v);
    notifyListeners();
  }

  Future<void> setSeekButtonsInNotification(bool v) async {
    seekButtonsInNotification = v;
    await _prefs?.setBool(_kSeekButtons, v);
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double v) async {
    playbackSpeed = v;
    await _prefs?.setDouble(_kPlaybackSpeed, v);
    notifyListeners();
  }

  Future<void> setSeekIntervalSeconds(int v) async {
    seekIntervalSeconds = v;
    await _prefs?.setInt(_kSeekInterval, v);
    notifyListeners();
  }

  /// Pass null to reset to the default Music folder.
  Future<void> setMusicFolderPath(String? path) async {
    musicFolderPath = path;
    if (path == null) {
      await _prefs?.remove(_kMusicFolder);
    } else {
      await _prefs?.setString(_kMusicFolder, path);
    }
    notifyListeners();
  }

  ThemeMode _themeFromName(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
