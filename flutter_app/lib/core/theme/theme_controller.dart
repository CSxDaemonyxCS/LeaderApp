import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_providers.dart';
import 'app_palette.dart';
import 'theme_state.dart';

export 'theme_state.dart';

/// The live theme choice, hydrated from [SettingsRepository] on first read
/// and written back on every change.
///
/// An [AsyncNotifier] for the same reason [MotionLevelController] is one: the
/// stored value arrives asynchronously, and the app has to paint something in
/// the meantime. Callers read `valueOrNull ?? const ThemeState.initial()`, so
/// the first frames use the default rather than flashing a theme the user did
/// not pick and then swapping it.
///
/// Every setter updates optimistically and persists in the background — the
/// pill responds on the same frame it is tapped, and a slow or failed write
/// never leaves the UI showing a choice that did not take.
class ThemeController extends AsyncNotifier<ThemeState> {
  @override
  Future<ThemeState> build() async {
    final stored = await ref.read(settingsRepositoryProvider).themePrefs();
    return stored.when(
      success: (data, {stale = false}) => data ?? const ThemeState.initial(),
      failure: (_, __) => const ThemeState.initial(),
      offline: (cached) => cached ?? const ThemeState.initial(),
    );
  }

  ThemeState get _current => state.valueOrNull ?? const ThemeState.initial();

  Future<void> _apply(ThemeState next) async {
    if (next == _current && state.hasValue) return;
    state = AsyncValue.data(next);
    await ref.read(settingsRepositoryProvider).updateThemePrefs(next);
  }

  Future<void> setPalette(PaletteId p) => _apply(_current.copyWith(palette: p));

  Future<void> setMode(ThemeMode m) => _apply(_current.copyWith(mode: m));

  Future<void> toggleMode() => _apply(
        _current.copyWith(
          mode: _current.mode == ThemeMode.dark
              ? ThemeMode.light
              : ThemeMode.dark,
        ),
      );

  Future<void> setEyeProtect(bool on) =>
      _apply(_current.copyWith(eyeProtect: on));
}

final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemeState>(ThemeController.new);

/// The theme to paint right now — the stored choice once it has loaded, the
/// default until then. Widgets that only need to *read* the theme should
/// watch this rather than unwrapping the async value themselves.
final themeStateProvider = Provider<ThemeState>((ref) {
  return ref.watch(themeControllerProvider).valueOrNull ??
      const ThemeState.initial();
});
