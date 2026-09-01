import 'package:flutter/material.dart';

/// Design tokens — mirror the exact values in `tokens.css` used by the
/// admin dashboards already shipped in this workspace. Do NOT invent new
/// colors here. Any new surface must be derived from these tokens.
enum PaletteId { slate, copper, clay }

class AppColors {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.line2,
    required this.primary,
    required this.primaryInk,
    required this.primaryPressed,
    required this.primaryTint,
    required this.ok,
    required this.okTint,
    required this.warn,
    required this.warnTint,
    required this.crit,
    required this.critTint,
    required this.info,
    required this.infoTint,
    required this.muted,
    required this.mutedTint,
    required this.focus,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color line2;
  final Color primary;
  final Color primaryInk;
  final Color primaryPressed;
  final Color primaryTint;
  final Color ok;
  final Color okTint;
  final Color warn;
  final Color warnTint;
  final Color crit;
  final Color critTint;
  final Color info;
  final Color infoTint;
  final Color muted;
  final Color mutedTint;
  final Color focus;

  // -----------------------------------------------------------
  // Slate — light  (mirrors body[data-palette="slate"][data-mode="light"])
  // -----------------------------------------------------------
  static const AppColors slateLight = AppColors(
    bg: Color(0xFFECEAE4),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF5F3EE),
    surface3: Color(0xFFE4E1D9),
    ink: Color(0xFF1A1F26),
    ink2: Color(0xFF4A5058),
    ink3: Color(0xFF7A8189),
    line: Color(0xFFDAD6CC),
    line2: Color(0xFFC7C2B4),
    primary: Color(0xFFB84A3E),
    primaryInk: Color(0xFFFFFFFF),
    primaryPressed: Color(0xFF9E3B2F),
    primaryTint: Color(0xFFF5E4E0),
    ok: Color(0xFF1F8F5A),
    okTint: Color(0xFFDFF1E7),
    warn: Color(0xFFD48806),
    warnTint: Color(0xFFFBEBCB),
    crit: Color(0xFF7A241B),
    critTint: Color(0xFFF0D8D3),
    info: Color(0xFF1B6C99),
    infoTint: Color(0xFFDCEBF3),
    muted: Color(0xFF7C8B92),
    mutedTint: Color(0xFFE4E7E8),
    focus: Color(0xFFB84A3E),
  );

  static const AppColors slateDark = AppColors(
    bg: Color(0xFF0F1319),
    surface: Color(0xFF171C24),
    surface2: Color(0xFF1E242E),
    surface3: Color(0xFF262D38),
    ink: Color(0xFFEDECE6),
    ink2: Color(0xFFB4B7BD),
    ink3: Color(0xFF7C8189),
    line: Color(0xFF2B323D),
    line2: Color(0xFF3A424F),
    primary: Color(0xFFD26254),
    primaryInk: Color(0xFFFFFFFF),
    primaryPressed: Color(0xFFB84A3E),
    primaryTint: Color(0xFF3A1E1A),
    ok: Color(0xFF3AB878),
    okTint: Color(0xFF143726),
    warn: Color(0xFFE8A63D),
    warnTint: Color(0xFF3A2A0F),
    crit: Color(0xFFE24E3F),
    critTint: Color(0xFF3D1A16),
    info: Color(0xFF4C9BCB),
    infoTint: Color(0xFF13293A),
    muted: Color(0xFF8A939B),
    mutedTint: Color(0xFF2A303A),
    focus: Color(0xFFD26254),
  );

  // -----------------------------------------------------------
  // Copper — light
  // -----------------------------------------------------------
  static const AppColors copperLight = AppColors(
    bg: Color(0xFFEAEBEE),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF2F4F7),
    surface3: Color(0xFFDFE3E9),
    ink: Color(0xFF141B26),
    ink2: Color(0xFF46505E),
    ink3: Color(0xFF78828F),
    line: Color(0xFFD6DBE2),
    line2: Color(0xFFBFC6D0),
    primary: Color(0xFFB45341),
    primaryInk: Color(0xFFFFFFFF),
    primaryPressed: Color(0xFF96412F),
    primaryTint: Color(0xFFF3E1DA),
    ok: Color(0xFF1E8A6E),
    okTint: Color(0xFFDAF0E7),
    warn: Color(0xFFC89424),
    warnTint: Color(0xFFF7EAC9),
    crit: Color(0xFF7B2116),
    critTint: Color(0xFFEDD6D0),
    info: Color(0xFF2E6EA6),
    infoTint: Color(0xFFDCEAF5),
    muted: Color(0xFF7B8894),
    mutedTint: Color(0xFFDFE3E9),
    focus: Color(0xFFB45341),
  );

  static const AppColors copperDark = AppColors(
    bg: Color(0xFF0C121C),
    surface: Color(0xFF141C29),
    surface2: Color(0xFF1B2435),
    surface3: Color(0xFF232E43),
    ink: Color(0xFFE9ECF2),
    ink2: Color(0xFFA9B3C0),
    ink3: Color(0xFF6F7B8B),
    line: Color(0xFF253046),
    line2: Color(0xFF354061),
    primary: Color(0xFFCE6952),
    primaryInk: Color(0xFFFFFFFF),
    primaryPressed: Color(0xFFB45341),
    primaryTint: Color(0xFF3A1E17),
    ok: Color(0xFF35B48D),
    okTint: Color(0xFF12362A),
    warn: Color(0xFFDDA43B),
    warnTint: Color(0xFF38290F),
    crit: Color(0xFFDA4E3F),
    critTint: Color(0xFF3B1A15),
    info: Color(0xFF5B9CD8),
    infoTint: Color(0xFF162A45),
    muted: Color(0xFF8993A2),
    mutedTint: Color(0xFF28324A),
    focus: Color(0xFFCE6952),
  );

  // -----------------------------------------------------------
  // Clay — light
  // -----------------------------------------------------------
  static const AppColors clayLight = AppColors(
    bg: Color(0xFFEDE6D8),
    surface: Color(0xFFFCF9F2),
    surface2: Color(0xFFF3ECDA),
    surface3: Color(0xFFE3D9C1),
    ink: Color(0xFF1F1912),
    ink2: Color(0xFF4E4436),
    ink3: Color(0xFF83795F),
    line: Color(0xFFD6C9AC),
    line2: Color(0xFFBFAE87),
    primary: Color(0xFFA83A2E),
    primaryInk: Color(0xFFFFFFFF),
    primaryPressed: Color(0xFF8B2A21),
    primaryTint: Color(0xFFEFD9D3),
    ok: Color(0xFF4A7A3E),
    okTint: Color(0xFFDFE9D4),
    warn: Color(0xFFB8791A),
    warnTint: Color(0xFFF1E1BE),
    crit: Color(0xFF6B1F17),
    critTint: Color(0xFFE6CDC6),
    info: Color(0xFF2C5F8A),
    infoTint: Color(0xFFDCE5F0),
    muted: Color(0xFF857960),
    mutedTint: Color(0xFFDED4B9),
    focus: Color(0xFFA83A2E),
  );

  static const AppColors clayDark = AppColors(
    bg: Color(0xFF14100A),
    surface: Color(0xFF1E1912),
    surface2: Color(0xFF26201A),
    surface3: Color(0xFF302921),
    ink: Color(0xFFECE4D2),
    ink2: Color(0xFFB0A78F),
    ink3: Color(0xFF7A7057),
    line: Color(0xFF2E2719),
    line2: Color(0xFF40372A),
    primary: Color(0xFFC55643),
    primaryInk: Color(0xFFFFFFFF),
    primaryPressed: Color(0xFFA83A2E),
    primaryTint: Color(0xFF3A1913),
    ok: Color(0xFF6DA55A),
    okTint: Color(0xFF1C2C15),
    warn: Color(0xFFD69A2C),
    warnTint: Color(0xFF382712),
    crit: Color(0xFFC64B3D),
    critTint: Color(0xFF3A1811),
    info: Color(0xFF5989BE),
    infoTint: Color(0xFF182640),
    muted: Color(0xFF9A8E70),
    mutedTint: Color(0xFF2E2716),
    focus: Color(0xFFC55643),
  );

  static AppColors resolve(PaletteId id, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return switch (id) {
      PaletteId.slate => isLight ? slateLight : slateDark,
      PaletteId.copper => isLight ? copperLight : copperDark,
      PaletteId.clay => isLight ? clayLight : clayDark,
    };
  }
}

/// Access colors from context via `Theme.of(context).extension<AppColors>()`.
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  const AppColorsExt(this.c);
  final AppColors c;

  @override
  ThemeExtension<AppColorsExt> copyWith({AppColors? c}) =>
      AppColorsExt(c ?? this.c);

  @override
  ThemeExtension<AppColorsExt> lerp(
    covariant ThemeExtension<AppColorsExt>? other,
    double t,
  ) => this;
}

extension AppColorsX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColorsExt>()!.c;
}
