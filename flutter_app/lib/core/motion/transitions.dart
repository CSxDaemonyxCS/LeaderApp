import 'package:flutter/material.dart';

import 'motion_tokens.dart';

/// Shared-axis (Y) transition — used for every top-level route change.
/// Mirror-safe: the geometry is horizontal only, no directional glyphs.
class SharedAxisPageTransition extends StatelessWidget {
  const SharedAxisPageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;

    final incoming = CurvedAnimation(
      parent: animation,
      curve: MotionTokens.emphasized,
      reverseCurve: MotionTokens.exit,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: MotionTokens.exit,
      reverseCurve: MotionTokens.emphasized,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(incoming),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(outgoing),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(incoming),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.06, 0),
            ).animate(outgoing),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Cross-fade for inner tab switching.
class TabCrossFade extends StatelessWidget {
  const TabCrossFade({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: effectiveDuration(context, MotionTokens.short),
        switchInCurve: MotionTokens.enter,
        switchOutCurve: MotionTokens.exit,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: child,
      );
}
