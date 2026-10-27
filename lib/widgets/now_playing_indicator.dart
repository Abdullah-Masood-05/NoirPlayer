import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/state/playback.dart';

/// Small equalizer bars marking the current track. They move only while it
/// is playing and hold still while paused.
class NowPlayingIndicator extends ConsumerStatefulWidget {
  const NowPlayingIndicator({super.key, required this.color, this.size = 18});

  final Color color;
  final double size;

  @override
  ConsumerState<NowPlayingIndicator> createState() =>
      _NowPlayingIndicatorState();
}

class _NowPlayingIndicatorState extends ConsumerState<NowPlayingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  void _follow(bool playing) {
    if (playing) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    _follow(ref.read(isPlayingProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isPlayingProvider, (_, playing) => _follow(playing));
    final barWidth = widget.size * 0.18;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (i) {
              final t = math.sin(_controller.value * 2 * math.pi + i * 1.2);
              final factor = 0.3 + 0.7 * (t * 0.5 + 0.5);
              return Container(
                width: barWidth,
                height: widget.size * factor,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(barWidth),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
