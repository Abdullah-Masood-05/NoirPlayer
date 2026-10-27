import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's SharedPreferences, loaded once in `main` and provided through an
/// override so every reader gets it synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

/// App-wide user preferences.
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// An immutable snapshot of the user's preferences. Widgets watch only the
/// fields they need with `settingsProvider.select(...)`.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.resumeAfterCall = true,
    this.resumeLastSong = true,
    this.stopOnAppSwipe = false,
    this.seekButtonsInNotification = false,
    this.playbackSpeed = 1.0,
    this.seekIntervalSeconds = defaultSeekIntervalSeconds,
    this.musicFolderPath,
    this.equalizerEnabled = false,
    this.equalizerBandGains = const [],
    this.lastFmApiKey = '',
    this.youtubeApiKey = '',
    this.rapidApiKey = '',
  });

  // ── Appearance ───────────────────────────────────────────────────────────
  final ThemeMode themeMode;

  // ── Playback ─────────────────────────────────────────────────────────────
  /// Resume playback automatically after a phone call / interruption ends.
  final bool resumeAfterCall;

  /// Restore the last played song (paused, at its last position) on launch.
  final bool resumeLastSong;

  /// Stop playback when the app is swiped away from recents.
  final bool stopOnAppSwipe;

  /// Show back / forward seek buttons in the media notification and system
  /// media controls.
  final bool seekButtonsInNotification;

  /// Playback speed multiplier (0.5–2.0).
  final double playbackSpeed;

  /// Seek back / forward step, in seconds. Used by the player screen buttons,
  /// the notification / lock screen controls and headset seek keys.
  final int seekIntervalSeconds;

  /// Folder the Library's "Music" tab loads from. Null = the device Music
  /// folder (paths containing `/music/`).
  final String? musicFolderPath;

  /// Native equalizer state.
  final bool equalizerEnabled;
  final List<double> equalizerBandGains;

  // ── Discover ─────────────────────────────────────────────────────────────
  /// The user's own service keys. A service with a key here is called
  /// directly with it; the others go through Noir Player's server. Empty =
  /// not set.
  final String lastFmApiKey;
  final String youtubeApiKey;
  final String rapidApiKey;

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

  Duration get seekInterval => Duration(seconds: seekIntervalSeconds);

  /// A short display label for the chosen music folder.
  String get musicFolderLabel {
    final path = musicFolderPath;
    if (path == null || path.isEmpty) return 'Music folder (default)';
    final name = path.split('/').where((p) => p.isNotEmpty).lastOrNull;
    return name == null || name.isEmpty ? path : name;
  }

  /// True if [songPath] belongs to the selected music folder.
  bool isInMusicFolder(String songPath) =>
      isInFolder(musicFolderPath, songPath);

  /// True if [songPath] belongs to [folder] (null or empty = the device
  /// Music folder).
  static bool isInFolder(String? folder, String songPath) {
    if (folder == null || folder.isEmpty) {
      return songPath.toLowerCase().contains('/music/');
    }
    return songPath.toLowerCase().startsWith(folder.toLowerCase());
  }

  static const _unset = Object();

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? resumeAfterCall,
    bool? resumeLastSong,
    bool? stopOnAppSwipe,
    bool? seekButtonsInNotification,
    double? playbackSpeed,
    int? seekIntervalSeconds,
    Object? musicFolderPath = _unset,
    bool? equalizerEnabled,
    List<double>? equalizerBandGains,
    String? lastFmApiKey,
    String? youtubeApiKey,
    String? rapidApiKey,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      resumeAfterCall: resumeAfterCall ?? this.resumeAfterCall,
      resumeLastSong: resumeLastSong ?? this.resumeLastSong,
      stopOnAppSwipe: stopOnAppSwipe ?? this.stopOnAppSwipe,
      seekButtonsInNotification:
          seekButtonsInNotification ?? this.seekButtonsInNotification,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      seekIntervalSeconds: seekIntervalSeconds ?? this.seekIntervalSeconds,
      musicFolderPath: identical(musicFolderPath, _unset)
          ? this.musicFolderPath
          : musicFolderPath as String?,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      equalizerBandGains: equalizerBandGains ?? this.equalizerBandGains,
      lastFmApiKey: lastFmApiKey ?? this.lastFmApiKey,
      youtubeApiKey: youtubeApiKey ?? this.youtubeApiKey,
      rapidApiKey: rapidApiKey ?? this.rapidApiKey,
    );
  }
}

/// Loads [AppSettings] from SharedPreferences and persists every change.
class SettingsNotifier extends Notifier<AppSettings> {
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

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      themeMode: _themeFromName(prefs.getString(_kTheme)),
      resumeAfterCall: prefs.getBool(_kResumeAfterCall) ?? true,
      resumeLastSong: prefs.getBool(_kResumeLastSong) ?? true,
      stopOnAppSwipe: prefs.getBool(_kStopOnAppSwipe) ?? false,
      seekButtonsInNotification: prefs.getBool(_kSeekButtons) ?? false,
      playbackSpeed: prefs.getDouble(_kPlaybackSpeed) ?? 1.0,
      seekIntervalSeconds: AppSettings.sanitizeSeekInterval(
        prefs.getInt(_kSeekInterval),
      ),
      musicFolderPath: prefs.getString(_kMusicFolder),
      equalizerEnabled: prefs.getBool(_kEqEnabled) ?? false,
      equalizerBandGains: (prefs.getStringList(_kEqGains) ?? const [])
          .map((g) => double.tryParse(g) ?? 0.0)
          .toList(growable: false),
      lastFmApiKey: prefs.getString(_kLastFmApiKey) ?? '',
      youtubeApiKey: prefs.getString(_kYoutubeApiKey) ?? '',
      rapidApiKey: prefs.getString(_kRapidApiKey) ?? '',
    );
  }

  // ── Setters (update state first so the UI reacts at once, then persist) ──
  Future<void> setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    return _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setResumeAfterCall(bool v) {
    state = state.copyWith(resumeAfterCall: v);
    return _prefs.setBool(_kResumeAfterCall, v);
  }

  Future<void> setResumeLastSong(bool v) {
    state = state.copyWith(resumeLastSong: v);
    return _prefs.setBool(_kResumeLastSong, v);
  }

  Future<void> setStopOnAppSwipe(bool v) {
    state = state.copyWith(stopOnAppSwipe: v);
    return _prefs.setBool(_kStopOnAppSwipe, v);
  }

  Future<void> setSeekButtonsInNotification(bool v) {
    state = state.copyWith(seekButtonsInNotification: v);
    return _prefs.setBool(_kSeekButtons, v);
  }

  Future<void> setPlaybackSpeed(double v) {
    state = state.copyWith(playbackSpeed: v);
    return _prefs.setDouble(_kPlaybackSpeed, v);
  }

  /// Ignores values outside the allowed seek interval range.
  Future<void> setSeekIntervalSeconds(int v) async {
    if (!AppSettings.isValidSeekInterval(v)) return;
    state = state.copyWith(seekIntervalSeconds: v);
    await _prefs.setInt(_kSeekInterval, v);
  }

  /// Pass null to reset to the default Music folder.
  Future<void> setMusicFolderPath(String? path) async {
    state = state.copyWith(musicFolderPath: path);
    if (path == null) {
      await _prefs.remove(_kMusicFolder);
    } else {
      await _prefs.setString(_kMusicFolder, path);
    }
  }

  Future<void> setEqualizerEnabled(bool v) {
    state = state.copyWith(equalizerEnabled: v);
    return _prefs.setBool(_kEqEnabled, v);
  }

  Future<void> setEqualizerBandGains(List<double> gains) {
    state = state.copyWith(equalizerBandGains: List.unmodifiable(gains));
    return _prefs.setStringList(
      _kEqGains,
      gains.map((g) => g.toString()).toList(),
    );
  }

  /// Pass an empty string to clear the key.
  Future<void> setLastFmApiKey(String key) {
    state = state.copyWith(lastFmApiKey: key.trim());
    return _saveKey(_kLastFmApiKey, state.lastFmApiKey);
  }

  /// Pass an empty string to clear the key.
  Future<void> setYoutubeApiKey(String key) {
    state = state.copyWith(youtubeApiKey: key.trim());
    return _saveKey(_kYoutubeApiKey, state.youtubeApiKey);
  }

  /// Pass an empty string to clear the key.
  Future<void> setRapidApiKey(String key) {
    state = state.copyWith(rapidApiKey: key.trim());
    return _saveKey(_kRapidApiKey, state.rapidApiKey);
  }

  Future<void> _saveKey(String prefsKey, String value) async {
    if (value.isEmpty) {
      await _prefs.remove(prefsKey);
    } else {
      await _prefs.setString(prefsKey, value);
    }
  }

  static ThemeMode _themeFromName(String? name) => switch (name) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
