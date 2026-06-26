import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'
    show AndroidEqualizer, AndroidEqualizerParameters, AndroidEqualizerBand;

import '../../core/services/audio_handler.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/app_theme.dart';

/// Native Android equalizer UI (just_audio's `AndroidEqualizer`).
class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  AndroidEqualizer get _eq => (audioHandler as AudioPlayerHandler).equalizer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Equalizer'),
      ),
      body: Container(
        decoration: AppTheme.topFade(context),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight),
              StreamBuilder<bool>(
                stream: _eq.enabledStream,
                builder: (context, snap) {
                  final enabled = snap.data ?? false;
                  return SwitchListTile(
                    secondary: const Icon(Icons.graphic_eq),
                    title: const Text('Enable equalizer'),
                    value: enabled,
                    onChanged: (v) {
                      _eq.setEnabled(v);
                      SettingsService.instance.setEqualizerEnabled(v);
                    },
                  );
                },
              ),
              const Divider(height: 1),
              Expanded(child: _body(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ThemeData theme) {
    return FutureBuilder<AndroidEqualizerParameters>(
      future: _eq.parameters,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _hint(theme, 'Start playing a track to load the equalizer.');
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _hint(theme, 'The equalizer is not available on this device.');
        }
        final params = snapshot.data!;
        return StreamBuilder<bool>(
          stream: _eq.enabledStream,
          builder: (context, enabledSnap) {
            final enabled = enabledSnap.data ?? false;
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final band in params.bands)
                          Expanded(
                            child: _bandColumn(theme, params, band, enabled),
                          ),
                      ],
                    ),
                  ),
                ),
                _presets(theme, params, enabled),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }

  Widget _bandColumn(
    ThemeData theme,
    AndroidEqualizerParameters params,
    AndroidEqualizerBand band,
    bool enabled,
  ) {
    return StreamBuilder<double>(
      stream: band.gainStream,
      builder: (context, snap) {
        final gain = (snap.data ?? band.gain)
            .clamp(params.minDecibels, params.maxDecibels)
            .toDouble();
        return Column(
          children: [
            Text(
              '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall,
            ),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: Slider(
                  min: params.minDecibels,
                  max: params.maxDecibels,
                  value: gain,
                  onChanged: enabled ? (v) => band.setGain(v) : null,
                  onChangeEnd: enabled ? (_) => _persist(params) : null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(_formatFreq(band.centerFrequency), style: theme.textTheme.bodySmall),
          ],
        );
      },
    );
  }

  Widget _presets(
    ThemeData theme,
    AndroidEqualizerParameters params,
    bool enabled,
  ) {
    const presets = ['Flat', 'Bass', 'Vocal', 'Treble'];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in presets)
          ActionChip(
            label: Text(p),
            onPressed: () => _applyPreset(params, p),
          ),
      ],
    );
  }

  void _applyPreset(AndroidEqualizerParameters params, String preset) {
    final max = params.maxDecibels;
    for (final band in params.bands) {
      final f = band.centerFrequency;
      double g;
      switch (preset) {
        case 'Bass':
          g = f < 250
              ? max * 0.7
              : (f < 900 ? max * 0.25 : 0);
          break;
        case 'Treble':
          g = f > 4000
              ? max * 0.7
              : (f > 1500 ? max * 0.25 : 0);
          break;
        case 'Vocal':
          g = (f >= 500 && f <= 4000)
              ? max * 0.5
              : (f < 250 ? -max * 0.15 : 0);
          break;
        default: // Flat
          g = 0;
      }
      band.setGain(g.clamp(params.minDecibels, params.maxDecibels).toDouble());
    }
    // Applying a preset implies the user wants the EQ active.
    _eq.setEnabled(true);
    SettingsService.instance.setEqualizerEnabled(true);
    _persist(params);
  }

  void _persist(AndroidEqualizerParameters params) {
    SettingsService.instance.setEqualizerBandGains(
      params.bands.map((b) => b.gain).toList(),
    );
  }

  Widget _hint(ThemeData theme, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.graphic_eq,
              size: 56,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  String _formatFreq(double hz) {
    if (hz >= 1000) {
      final k = hz / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k';
    }
    return '${hz.round()}';
  }
}
