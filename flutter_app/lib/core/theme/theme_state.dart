import 'package:flutter/material.dart';

import '../brand/brand_logo.dart';
import 'app_palette.dart';

/// The choices that decide how the app looks, as one value.
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
    this.logo = BrandLogo.fallback,
  });

  /// What a device shows before anything has been stored, and the fallback
  /// used while the stored value is still loading.
  ///
  /// The historical MTM default: the clinical palette in light appearance.
  const ThemeState.initial()
      : palette = PaletteId.medical,
        mode = ThemeMode.light,
        eyeProtect = false,
        logo = BrandLogo.fallback;

  final PaletteId palette;
  final ThemeMode mode;

  /// Warm, low-blue wash layered on top of [palette] and [mode]. Independent
  /// of both — a user can run eye-protect over any palette, light or dark.
  final bool eyeProtect;

  /// Which of the three approved Leader marks the app draws on its own
  /// surfaces (Login first of all).
  ///
  /// It rides here rather than in a store of its own for one reason: it is
  /// needed on the very first painted frame, and [ThemeState] is already the
  /// one preference read off the launch path without simulated latency. A
  /// second async source would mean Login drawing the default mark and then
  /// visibly swapping it. It is cosmetic — see [BrandLogo].
  final BrandLogo logo;

  ThemeState copyWith({
    PaletteId? palette,
    ThemeMode? mode,
    bool? eyeProtect,
    BrandLogo? logo,
  }) =>
      ThemeState(
        palette: palette ?? this.palette,
        mode: mode ?? this.mode,
        eyeProtect: eyeProtect ?? this.eyeProtect,
        logo: logo ?? this.logo,
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
        eyeProtect: j['eyeProtect'] is bool ? j['eyeProtect'] as bool : false,
        // Absent for every preference stored before the logo was
        // selectable, and for any value that is not one of the three
        // names — both mean the shipped mark, not a failed read.
        logo: BrandLogo.fromName(j['logo']),
      );

  Map<String, dynamic> toJson() => {
        'palette': palette.name,
        'mode': mode.name,
        'eyeProtect': eyeProtect,
        'logo': logo.name,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          other.palette == palette &&
          other.mode == mode &&
          other.eyeProtect == eyeProtect &&
          other.logo == logo;

  @override
  int get hashCode => Object.hash(palette, mode, eyeProtect, logo);

  @override
  String toString() => 'ThemeState(${palette.name}, ${mode.name}, '
      'eyeProtect: $eyeProtect, logo: ${logo.name})';
}
