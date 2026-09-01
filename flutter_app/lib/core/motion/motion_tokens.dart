import 'package:flutter/material.dart';

import 'motion_level.dart';

/// Single source of truth for every duration and curve in the app.
/// Widgets must NOT hardcode `Duration(milliseconds: X)` or curves —
/// they call these constants or the context-aware helpers below.
class MotionTokens {
  MotionTokens._();

  // ---------- Durations (the "full" values) ----------
  static const Duration instant = Duration(milliseconds: 80);
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration long = Duration(milliseconds: 420);
  static const Duration xLong = Duration(milliseconds: 600);

  // Stagger — total across first 8 items must stay <300ms.
  static const Duration staggerStep = Duration(milliseconds: 34);
  static const Duration staggerItem = Duration(milliseconds: 240);
  static const int staggerMaxItems = 8;

  // Curves
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
  static const Curve standard = Cubic(0.4, 0, 0.2, 1);
  static const Curve spring = Cubic(0.34, 1.28, 0.64, 1);
  static const Curve exit = Cubic(0.4, 0, 1, 1);
  static const Curve enter = Cubic(0, 0, 0.2, 1);

  // Press feedback
  static const double pressScale = 0.97;

  // Bottom nav pill morph
  static const Duration navPillMorph = medium;

  // Named one-offs. They live here rather than in the widget so the
  // motion-level setting has a single place to reach.
  static const Duration progressFill = Duration(milliseconds: 700);

  // Looping ambience. These drive controllers that are stopped outright
  // under reduced motion (see Skeleton and LockWindow), so they are the
  // one place a raw duration is still the right value to read.
  static const Duration shimmerLoop = Duration(milliseconds: 1200);
  static const Duration haloPulse = Duration(milliseconds: 1600);
}

/// True when the OS asked to disable/reduce animations.
bool osReduceMotion(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;

/// True when we should currently short-circuit animations. This is the
/// SINGLE place that decides — every widget reads through here so the
/// motion-level setting can flip the whole app without scattered `if`s.
///
/// It reads the resolved [MotionLevel] and nothing else. The OS
/// reduce-motion flag is folded in one level up: it seeds the first-launch
/// default in `motionLevelProvider` and the value used while the stored
/// setting is still loading (see `main.dart`). Keeping it out of here is
/// what lets a user who explicitly picks حركة كاملة keep the full
/// experience even on a device that asks for less — the setting has to be
/// an override, not a suggestion.
bool reduceMotion(BuildContext context) =>
    MotionScope.of(context) == MotionLevel.reduced;

/// Pick a duration honoring reduced-motion. Returns [Duration.zero]
/// under reduced motion so `AnimatedContainer`, `AnimatedOpacity`, etc.
/// snap to the target frame.
Duration effectiveDuration(BuildContext context, Duration d) =>
    reduceMotion(context) ? Duration.zero : d;

/// Same idea for curves: a linear curve when reduced (there's no
/// distance to travel anyway, so the curve is a no-op, but returning
/// [Curves.linear] avoids the spring overshoot showing as a jitter
/// when duration is very small).
Curve effectiveCurve(BuildContext context, Curve c) =>
    reduceMotion(context) ? Curves.linear : c;
