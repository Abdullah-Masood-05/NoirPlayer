import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Small animated equalizer bars used to mark the currently playing track.
class NowPlayingIndicator extends StatefulWidget {
  const NowPlayingIndicator({super.key, required this.color, this.size = 18});

  final Color color;
  final double size;

  @override
  State<NowPlayingIndicator> createState() => _NowPlayingIndicatorState();
}

class _NowPlayingIndicatorState extends State<NowPlayingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
