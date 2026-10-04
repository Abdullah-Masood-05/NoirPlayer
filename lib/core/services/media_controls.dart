import 'package:audio_service/audio_service.dart';

/// The media controls published with the playback state: the buttons in the
/// notification / lock screen and the actions the system may invoke.
///
/// Kept free of player state so it can be unit tested.
class MediaControlsSpec {
  const MediaControlsSpec({
    required this.controls,
    required this.compactIndices,
    required this.systemActions,
  });

  /// Buttons, in display order.
  final List<MediaControl> controls;

  /// Indices into [controls] shown in the collapsed notification (Android 12
  /// and older; at most three).
  final List<int> compactIndices;

  /// Actions the system UI is allowed to invoke.
  final Set<MediaAction> systemActions;
}

/// Builds the media controls.
///
/// With [showSeek] the controls are prev · back · play/pause · forward ·
/// next, otherwise prev · play/pause · next. The collapsed notification
/// always shows prev / play-pause / next.
///
/// The seek buttons are the standard rewind / fast-forward controls rather
/// than `MediaControl.custom`: on Android 13+ audio_service publishes them as
/// MediaSession custom actions itself (the system media player only shows
/// prev / play-pause / next plus custom actions), and on Android 12 and older
/// only non-custom controls are added to the notification.
///
/// On iOS the rewind / fast-forward actions turn the lock screen's previous /
/// next buttons into skip-back / skip-forward buttons, so they are only
/// enabled with [showSeek].
MediaControlsSpec buildMediaControls({
  required bool playing,
  required bool showSeek,
  required int seekSeconds,
}) {
  final controls = <MediaControl>[
    MediaControl.skipToPrevious,
    if (showSeek)
      MediaControl(
        androidIcon: MediaControl.rewind.androidIcon,
        label: 'Back $seekSeconds seconds',
        action: MediaAction.rewind,
      ),
    if (playing) MediaControl.pause else MediaControl.play,
    if (showSeek)
      MediaControl(
        androidIcon: MediaControl.fastForward.androidIcon,
        label: 'Forward $seekSeconds seconds',
        action: MediaAction.fastForward,
      ),
    MediaControl.skipToNext,
  ];

  return MediaControlsSpec(
    controls: controls,
    compactIndices: showSeek ? const [0, 2, 4] : const [0, 1, 2],
    // Without these the lock-screen and pop-up controls appear but do
    // nothing.
    systemActions: {
      MediaAction.play,
      MediaAction.pause,
      MediaAction.playPause,
      MediaAction.skipToNext,
      MediaAction.skipToPrevious,
      MediaAction.seek,
      MediaAction.seekForward,
      MediaAction.seekBackward,
      if (showSeek) MediaAction.fastForward,
      if (showSeek) MediaAction.rewind,
    },
  );
}
