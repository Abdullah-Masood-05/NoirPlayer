import 'package:flutter/material.dart';

/// The dedicated Material icon for a seek step of [seconds], or null when
/// there is none (only 5, 10 and 30 seconds have one).
IconData? seekIconFor(int seconds, {required bool forward}) {
  switch (seconds) {
    case 5:
      return forward ? Icons.forward_5 : Icons.replay_5;
    case 10:
      return forward ? Icons.forward_10 : Icons.replay_10;
    case 30:
      return forward ? Icons.forward_30 : Icons.replay_30;
    default:
      return null;
  }
}

/// A "back N seconds" / "forward N seconds" button. Uses the matching
/// Material icon when one exists, otherwise a circular arrow with the number
/// drawn inside.
class SeekButton extends StatelessWidget {
  const SeekButton({
    super.key,
    required this.seconds,
    required this.forward,
    required this.onPressed,
    this.iconSize = 30,
  });

  final int seconds;
  final bool forward;
  final VoidCallback onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final unit = seconds == 1 ? 'second' : 'seconds';
    return IconButton(
      iconSize: iconSize,
      tooltip: forward ? 'Forward $seconds $unit' : 'Back $seconds $unit',
      onPressed: onPressed,
      // Builder: read the icon colour IconButton provides to its icon.
      icon: Builder(builder: _icon),
    );
  }

  Widget _icon(BuildContext context) {
    final dedicated = seekIconFor(seconds, forward: forward);
    if (dedicated != null) return Icon(dedicated);

    // Icons.replay is a counter-clockwise arrow; mirrored it points forward.
    final color = IconTheme.of(context).color;
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.flip(
            flipX: forward,
            child: Icon(Icons.replay, size: iconSize),
          ),
          Padding(
            padding: EdgeInsets.only(top: iconSize * 0.12),
            child: SizedBox(
              width: iconSize * 0.42,
              height: iconSize * 0.32,
              child: FittedBox(
                child: Text(
                  '$seconds',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
