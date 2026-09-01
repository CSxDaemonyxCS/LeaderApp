import 'package:flutter/material.dart';

import 'motion_tokens.dart';

/// Staggered entry for the first N children of a list.
/// - Only the first `MotionTokens.staggerMaxItems` items animate.
/// - Total added time stays under 300ms.
class Stagger extends StatelessWidget {
  const Stagger({super.key, required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context) || index >= MotionTokens.staggerMaxItems) {
      return child;
    }
    final delayMs = MotionTokens.staggerStep.inMilliseconds * index;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MotionTokens.staggerItem + Duration(milliseconds: delayMs),
      curve: Interval(
        delayMs / (MotionTokens.staggerItem.inMilliseconds + delayMs),
        1.0,
        curve: MotionTokens.spring,
      ),
      builder: (context, v, c) => Opacity(
        opacity: v.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 10),
          child: c,
        ),
      ),
      child: child,
    );
  }
}
