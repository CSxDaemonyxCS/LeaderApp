import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The three choices that decide how the app looks, as one value.
///
/// It lives in its own file rather than beside the controller because it is
/// also the shape `SettingsRepository` persists — a repository importing a
/// Riverpod notifier to name its own payload would have the layering
/// backwards.
@immutable
class ThemeState {
  const ThemeState({
    required this.palette,
    required this.mode,
    this.eyeProtect = false,
  });

  /// What a device shows before anything has been stored, and the fallback
  /// used while the stored value is still loading.
  const ThemeState.initial()
      : palette = PaletteId.medical,
        mode = ThemeMode.light,
        eyeProtect = false;

  final PaletteId palette;
  final ThemeMode mode;

  /// Warm, low-blue wash layered on top of [palette] and [mode]. Independent
  /// of both — a user can run eye-protect over any palette, light or dark.
  final bool eyeProtect;

  ThemeState copyWith({
    PaletteId? palette,
    ThemeMode? mode,
    bool? eyeProtect,
  }) =>
      ThemeState(
        palette: palette ?? this.palette,
        mode: mode ?? this.mode,
        eyeProtect: eyeProtect ?? this.eyeProtect,
      );

  /// Names, not indices: reordering [PaletteId] or [ThemeMode] must not
  /// silently re-point a stored preference at a different theme.
  factory ThemeState.fromJson(Map<String, dynamic> j) => ThemeState(
        palette: PaletteId.values.firstWhere(
          (p) => p.name == j['palette'],
          orElse: () => const ThemeState.initial().palette,
        ),
        mode: ThemeMode.values.firstWhere(
          (m) => m.name == j['mode'],
          orElse: () => const ThemeState.initial().mode,
        ),
        eyeProtect: (j['eyeProtect'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'palette': palette.name,
        'mode': mode.name,
        'eyeProtect': eyeProtect,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          other.palette == palette &&
          other.mode == mode &&
          other.eyeProtect == eyeProtect;

  @override
  int get hashCode => Object.hash(palette, mode, eyeProtect);

  @override
  String toString() =>
      'ThemeState(${palette.name}, ${mode.name}, eyeProtect: $eyeProtect)';
}
