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

  /// Show back / forward seek buttons in the media notification and system
  /// media controls.
  bool seekButtonsInNotification = false;

  /// Playback speed multiplier (0.5–2.0).
  double playbackSpeed = 1.0;

  /// Seek back / forward step, in seconds. Used by the player screen buttons,
  /// the notification / lock screen controls and headset seek keys.
  int seekIntervalSeconds = defaultSeekIntervalSeconds;

  /// Seek step limits and the preset choices offered in Settings.
  static const int defaultSeekIntervalSeconds = 10;
  static const int minSeekIntervalSeconds = 1;
  static const int maxSeekIntervalSeconds = 300;
  static const List<int> seekIntervalPresets = [5, 10, 15, 30, 60];

  /// True if [seconds] is an allowed seek step.
  static bool isValidSeekInterval(int? seconds) =>
      seconds != null &&
      seconds >= minSeekIntervalSeconds &&
      seconds <= maxSeekIntervalSeconds;

  /// [seconds] if it is an allowed seek step, otherwise the default.
  static int sanitizeSeekInterval(int? seconds) =>
      isValidSeekInterval(seconds) ? seconds! : defaultSeekIntervalSeconds;

  /// Parses user input for a custom seek step. Returns null unless [text] is
  /// a whole number of seconds within the allowed range.
  static int? parseSeekInterval(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(trimmed)) return null;
    final seconds = int.tryParse(trimmed);
    return isValidSeekInterval(seconds) ? seconds : null;
  }

  /// Settings label for a seek step: "10 seconds" for a preset, otherwise
  /// "Custom (N seconds)".
  static String seekIntervalLabel(int seconds) {
    final unit = seconds == 1 ? 'second' : 'seconds';
    return seekIntervalPresets.contains(seconds)
        ? '$seconds $unit'
        : 'Custom ($seconds $unit)';
  }

  /// Folder the Library's "Music" tab loads from. Null = the device Music
  /// folder (paths containing `/music/`).
  String? musicFolderPath;

  /// Native equalizer state.
  bool equalizerEnabled = false;
  List<double> equalizerBandGains = const [];

  // ── Discover ─────────────────────────────────────────────────────────────
  /// The user's own service keys. A service with a key here is called
  /// directly with it; the others go through Noir Player's server. Empty =
  /// not set.
  String lastFmApiKey = '';
  String youtubeApiKey = '';
  String rapidApiKey = '';

  // ── Keys ─────────────────────────────────────────────────────────────────
  static const _kTheme = 'settings.themeMode';
  static const _kResumeAfterCall = 'settings.resumeAfterCall';
  static const _kResumeLastSong = 'settings.resumeLastSong';
  static const _kStopOnAppSwipe = 'settings.stopOnAppSwipe';
  static const _kSeekButtons = 'settings.seekButtonsInNotification';
  static const _kPlaybackSpeed = 'settings.playbackSpeed';
  static const _kSeekInterval = 'settings.seekIntervalSeconds';
  static const _kMusicFolder = 'settings.musicFolderPath';
  static const _kEqEnabled = 'settings.equalizerEnabled';
  static const _kEqGains = 'settings.equalizerBandGains';
  static const _kLastFmApiKey = 'settings.lastFmApiKey';
  static const _kYoutubeApiKey = 'settings.youtubeApiKey';
  static const _kRapidApiKey = 'settings.rapidApiKey';

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    themeMode = _themeFromName(prefs.getString(_kTheme));
    resumeAfterCall = prefs.getBool(_kResumeAfterCall) ?? true;
    resumeLastSong = prefs.getBool(_kResumeLastSong) ?? true;
    stopOnAppSwipe = prefs.getBool(_kStopOnAppSwipe) ?? false;
    seekButtonsInNotification = prefs.getBool(_kSeekButtons) ?? false;
    playbackSpeed = prefs.getDouble(_kPlaybackSpeed) ?? 1.0;
    seekIntervalSeconds = sanitizeSeekInterval(prefs.getInt(_kSeekInterval));
    musicFolderPath = prefs.getString(_kMusicFolder);
    equalizerEnabled = prefs.getBool(_kEqEnabled) ?? false;
    equalizerBandGains = (prefs.getStringList(_kEqGains) ?? const [])
        .map((g) => double.tryParse(g) ?? 0.0)
        .toList();
    lastFmApiKey = prefs.getString(_kLastFmApiKey) ?? '';
    youtubeApiKey = prefs.getString(_kYoutubeApiKey) ?? '';
    rapidApiKey = prefs.getString(_kRapidApiKey) ?? '';
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

  /// Ignores values outside [minSeekIntervalSeconds]..[maxSeekIntervalSeconds].
  Future<void> setSeekIntervalSeconds(int v) async {
    if (!isValidSeekInterval(v)) return;
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

  Future<void> setEqualizerEnabled(bool v) async {
    equalizerEnabled = v;
    await _prefs?.setBool(_kEqEnabled, v);
    notifyListeners();
  }

  Future<void> setEqualizerBandGains(List<double> gains) async {
    equalizerBandGains = gains;
    await _prefs?.setStringList(
      _kEqGains,
      gains.map((g) => g.toString()).toList(),
    );
    notifyListeners();
  }

  /// Pass an empty string to clear the key.
  Future<void> setLastFmApiKey(String key) async {
    lastFmApiKey = key.trim();
    await _saveKey(_kLastFmApiKey, lastFmApiKey);
    notifyListeners();
  }

  /// Pass an empty string to clear the key.
  Future<void> setYoutubeApiKey(String key) async {
    youtubeApiKey = key.trim();
    await _saveKey(_kYoutubeApiKey, youtubeApiKey);
    notifyListeners();
  }

  /// Pass an empty string to clear the key.
  Future<void> setRapidApiKey(String key) async {
    rapidApiKey = key.trim();
    await _saveKey(_kRapidApiKey, rapidApiKey);
    notifyListeners();
  }

  Future<void> _saveKey(String prefsKey, String value) async {
    if (value.isEmpty) {
      await _prefs?.remove(prefsKey);
    } else {
      await _prefs?.setString(prefsKey, value);
    }
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
