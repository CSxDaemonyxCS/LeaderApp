import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/motion_level.dart';
import 'settings_providers.dart';

/// User-selectable motion level, persisted via [SettingsRepository].
///
/// On first read the notifier asks the repository for the stored value.
/// If none is stored, it defaults to `reduced` when the OS reports
/// reduce-motion (`MediaQuery.disableAnimations`), otherwise `full`.
///
/// Every setter persists immediately — no restart is needed.
class MotionLevelController extends AsyncNotifier<MotionLevel> {
  @override
  Future<MotionLevel> build() async {
    final r = await ref.read(settingsRepositoryProvider).motionLevel();
    return r.when(
      success: (data, {stale = false}) {
        if (data != null) return data;
        return _osDefault();
      },
      failure: (_, __) => _osDefault(),
      offline: (cached) => cached ?? _osDefault(),
    );
  }

  MotionLevel _osDefault() {
    // WidgetsBinding is safe to touch here — Riverpod's build runs on the
    // Flutter main isolate after binding is up (main.dart calls
    // `WidgetsFlutterBinding.ensureInitialized()`).
    final view = WidgetsBinding.instance.platformDispatcher.views.isEmpty
        ? null
        : WidgetsBinding.instance.platformDispatcher.views.first;
    final osReduced =
        view?.platformDispatcher.accessibilityFeatures.disableAnimations ??
            false;
    return osReduced ? MotionLevel.reduced : MotionLevel.full;
  }

  Future<void> set(MotionLevel level) async {
    // Optimistic update — user feedback is immediate.
    state = AsyncValue.data(level);
    await ref.read(settingsRepositoryProvider).updateMotionLevel(level);
  }
}

final motionLevelProvider =
    AsyncNotifierProvider<MotionLevelController, MotionLevel>(
  MotionLevelController.new,
);
