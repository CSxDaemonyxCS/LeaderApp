import 'package:flutter/widgets.dart';

/// User-selectable animation intensity. Persisted via SettingsRepository.
///
/// - [full]    : the fully-designed experience — shared-axis transitions,
///               stagger, hero, animated counters, glass BackdropFilter on
///               the bottom navigation.
/// - [reduced] : transitions collapse to instant/fade, stagger disabled,
///               counters set their value directly, hero replaced by a
///               plain push, and the glass nav renders as a solid
///               semi-transparent surface with NO BackdropFilter.
///
/// The single reason this setting exists: the BackdropFilter on the
/// floating bottom nav is the heaviest effect in the app on low-end
/// Android. Everything else scales down to keep the experience
/// consistent when the user opts out of motion.
enum MotionLevel {
  full,
  reduced;

  static MotionLevel fromJson(String s) => switch (s) {
        'reduced' => MotionLevel.reduced,
        _ => MotionLevel.full,
      };

  String toJson() => name;
}

/// Ambient access — every widget that reads motion tokens can look this up
/// through [MotionScope.of]. Bound at the app root by [MotionScope].
class MotionScope extends InheritedWidget {
  const MotionScope({
    super.key,
    required this.level,
    required super.child,
  });

  final MotionLevel level;

  static MotionLevel of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<MotionScope>();
    return s?.level ?? MotionLevel.full;
  }

  @override
  bool updateShouldNotify(MotionScope oldWidget) => level != oldWidget.level;
}
