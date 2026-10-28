// Unit tests for the seek interval setting, the media controls built from it
// and the seek / version helpers used by the UI.

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noir_player/core/services/media_controls.dart';
import 'package:noir_player/core/state/settings.dart';
import 'package:noir_player/screens/about/about_screen.dart';
import 'package:noir_player/widgets/seek_button.dart';

void main() {
  group('buildMediaControls', () {
    List<MediaAction> actionsOf(MediaControlsSpec spec) =>
        spec.controls.map((c) => c.action).toList();

    test('without seek buttons: prev / play / next', () {
      final spec = buildMediaControls(
        playing: false,
        showSeek: false,
        seekSeconds: 10,
      );
      expect(actionsOf(spec), [
        MediaAction.skipToPrevious,
        MediaAction.play,
        MediaAction.skipToNext,
      ]);
      expect(spec.compactIndices, [0, 1, 2]);
      expect(spec.systemActions, isNot(contains(MediaAction.rewind)));
      expect(spec.systemActions, isNot(contains(MediaAction.fastForward)));
    });

    test('with seek buttons: prev / back / pause / forward / next', () {
      final spec = buildMediaControls(
        playing: true,
        showSeek: true,
        seekSeconds: 15,
      );
      expect(actionsOf(spec), [
        MediaAction.skipToPrevious,
        MediaAction.rewind,
        MediaAction.pause,
        MediaAction.fastForward,
        MediaAction.skipToNext,
      ]);
      expect(spec.compactIndices, [0, 2, 4]);
      expect(spec.controls[1].label, 'Back 15 seconds');
      expect(spec.controls[3].label, 'Forward 15 seconds');
      expect(spec.controls[1].androidIcon, 'drawable/noir_seek_back');
      expect(spec.controls[3].androidIcon, 'drawable/noir_seek_forward');
      // Standard controls: audio_service turns these into session custom
      // actions on Android 13+ and notification actions on older versions.
      expect(spec.controls.every((c) => c.customAction == null), isTrue);
      expect(
        spec.systemActions,
        containsAll([MediaAction.rewind, MediaAction.fastForward]),
      );
    });

    test('compact view always shows prev / play-pause / next', () {
      for (final showSeek in [false, true]) {
        for (final playing in [false, true]) {
          final spec = buildMediaControls(
            playing: playing,
            showSeek: showSeek,
            seekSeconds: 10,
          );
          expect(spec.compactIndices.length, lessThanOrEqualTo(3));
          final compact = [
            for (final i in spec.compactIndices) spec.controls[i].action,
          ];
          expect(compact, [
            MediaAction.skipToPrevious,
            playing ? MediaAction.pause : MediaAction.play,
            MediaAction.skipToNext,
          ]);
        }
      }
    });

    test('system actions always allow play / pause / skip / seek', () {
      for (final showSeek in [false, true]) {
        final spec = buildMediaControls(
          playing: false,
          showSeek: showSeek,
          seekSeconds: 10,
        );
        expect(
          spec.systemActions,
          containsAll([
            MediaAction.play,
            MediaAction.pause,
            MediaAction.playPause,
            MediaAction.skipToNext,
            MediaAction.skipToPrevious,
            MediaAction.seek,
          ]),
        );
      }
    });
  });

  group('seek interval validation', () {
    test('accepts 1 to 300 seconds', () {
      expect(AppSettings.isValidSeekInterval(1), isTrue);
      expect(AppSettings.isValidSeekInterval(15), isTrue);
      expect(AppSettings.isValidSeekInterval(300), isTrue);
      expect(AppSettings.isValidSeekInterval(0), isFalse);
      expect(AppSettings.isValidSeekInterval(-5), isFalse);
      expect(AppSettings.isValidSeekInterval(301), isFalse);
      expect(AppSettings.isValidSeekInterval(null), isFalse);
    });

    test('stored values outside the range fall back to 10', () {
      expect(AppSettings.sanitizeSeekInterval(null), 10);
      expect(AppSettings.sanitizeSeekInterval(0), 10);
      expect(AppSettings.sanitizeSeekInterval(-1), 10);
      expect(AppSettings.sanitizeSeekInterval(1000), 10);
      expect(AppSettings.sanitizeSeekInterval(5), 5);
      expect(AppSettings.sanitizeSeekInterval(45), 45);
    });

    test('parses custom input', () {
      expect(AppSettings.parseSeekInterval('7'), 7);
      expect(AppSettings.parseSeekInterval(' 120 '), 120);
      expect(AppSettings.parseSeekInterval('300'), 300);
      expect(AppSettings.parseSeekInterval(''), isNull);
      expect(AppSettings.parseSeekInterval('0'), isNull);
      expect(AppSettings.parseSeekInterval('301'), isNull);
      expect(AppSettings.parseSeekInterval('-5'), isNull);
      expect(AppSettings.parseSeekInterval('1.5'), isNull);
      expect(AppSettings.parseSeekInterval('abc'), isNull);
    });

    test('labels presets plainly and other values as custom', () {
      expect(AppSettings.seekIntervalLabel(5), '5 seconds');
      expect(AppSettings.seekIntervalLabel(15), '15 seconds');
      expect(AppSettings.seekIntervalLabel(60), '60 seconds');
      expect(AppSettings.seekIntervalLabel(7), 'Custom (7 seconds)');
      expect(AppSettings.seekIntervalLabel(1), 'Custom (1 second)');
    });

    test('presets include 5, 10 and 15 seconds and are all valid', () {
      expect(AppSettings.seekIntervalPresets, containsAll([5, 10, 15]));
      expect(
        AppSettings.seekIntervalPresets.every(AppSettings.isValidSeekInterval),
        isTrue,
      );
    });
  });

  test('seek icons exist for 5, 10 and 30 seconds only', () {
    expect(seekIconFor(5, forward: false), Icons.replay_5);
    expect(seekIconFor(10, forward: false), Icons.replay_10);
    expect(seekIconFor(30, forward: false), Icons.replay_30);
    expect(seekIconFor(5, forward: true), Icons.forward_5);
    expect(seekIconFor(10, forward: true), Icons.forward_10);
    expect(seekIconFor(30, forward: true), Icons.forward_30);
    expect(seekIconFor(15, forward: true), isNull);
    expect(seekIconFor(60, forward: false), isNull);
  });

  test('version label', () {
    expect(formatVersionLabel('1.2.0', '6'), 'Version 1.2.0 (6)');
    expect(formatVersionLabel('1.2.0', ''), 'Version 1.2.0');
    expect(formatVersionLabel('1.2.0', '1.2.0'), 'Version 1.2.0');
    expect(formatVersionLabel('', '6'), 'Build 6');
    expect(formatVersionLabel('', ''), 'Version unknown');
  });

  test('every button uses Noir Player\'s own icons', () {
    for (final playing in [true, false]) {
      final spec = buildMediaControls(
        playing: playing,
        showSeek: true,
        seekSeconds: 10,
      );
      expect(spec.controls.map((c) => c.androidIcon), [
        'drawable/noir_media_previous',
        'drawable/noir_seek_back',
        playing ? 'drawable/noir_media_pause' : 'drawable/noir_media_play',
        'drawable/noir_seek_forward',
        'drawable/noir_media_next',
      ]);
    }
  });
}
