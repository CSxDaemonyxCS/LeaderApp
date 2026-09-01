import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The single place where type is defined. No widget should ever set
/// `fontFamily` inline — every text style used in the app must be one of
/// the helpers below (or derived by `.copyWith`).
///
/// Typeface: **IBM Plex Sans Arabic** — a UI-first family, legible at
/// 11–13px, with real Arabic-Indic numeral glyphs (٠١٢٣٤٥٦٧٨٩) so counters
/// and statistics stay in the same font instead of silently falling back.
///
/// Three weights ship: 400 / 500 / 600. Do NOT introduce Light, Thin,
/// or Bold — the design uses 400 and 500 almost exclusively.
class AppTypography {
  // The family name matches the `family:` declaration in pubspec.yaml.
  static const String family = 'IBMPlexSansArabic';

  /// Tabular figures — requested on every animated counter, OTP box,
  /// quantity field, and time stamp.
  ///
  /// NOTE: the bundled IBM Plex Sans Arabic files carry no `tnum`
  /// feature, so this is a no-op for the Arabic-Indic digits the app
  /// renders (their advances range from 263 to 630 units — ٠ is a little
  /// over half the width of ٨). Latin digits in this family are already
  /// monospaced at 600. Anything whose digits change while on screen must
  /// therefore also go through `TabularDigits`, which reserves one
  /// equal-width cell per digit. The feature stays declared so the styles
  /// stay correct if a future font revision ships `tnum`.
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextTheme build(AppColors c) {
    final base = ThemeData(brightness: Brightness.light).textTheme;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: c.ink,
        fontFamily: family,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        fontFamily: family,
        color: c.ink,
        fontSize: 26,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: family,
        color: c.ink,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleLarge: titleLg(c),
      titleMedium: TextStyle(
        fontFamily: family,
        color: c.ink,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontFamily: family,
        color: c.ink2,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: body(c).copyWith(fontSize: 16),
      bodyMedium: body(c),
      bodySmall: TextStyle(
        fontFamily: family,
        color: c.ink3,
        fontSize: 12,
        height: 1.5,
      ),
      labelLarge: buttonLabel(c),
      labelMedium: TextStyle(
        fontFamily: family,
        color: c.ink2,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
    );
  }

  static TextStyle titleLg(AppColors c) => TextStyle(
        fontFamily: family,
        color: c.ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle body(AppColors c) => TextStyle(
        fontFamily: family,
        color: c.ink,
        fontSize: 14,
        height: 1.55,
      );

  static TextStyle sub(AppColors c) => TextStyle(
        fontFamily: family,
        color: c.ink3,
        fontSize: 13,
        height: 1.5,
      );

  static TextStyle chip(AppColors c) => TextStyle(
        fontFamily: family,
        color: c.ink,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  static TextStyle buttonLabel(AppColors c) => TextStyle(
        fontFamily: family,
        color: c.ink,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      );

  /// Numeric style for headline statistics. IBM Plex Sans Arabic carries
  /// real Arabic-Indic digit glyphs, so we never switch families for
  /// numbers.
  static TextStyle number(AppColors c, {double size = 22}) =>
      digits(c.ink, size: size).copyWith(height: 1.1);

  /// Numeric style for inline figures — counters, OTP boxes, quantity
  /// fields, timers, clock ranges. Widgets call this instead of writing
  /// `fontFamily:` inline, so the family is declared in exactly one file.
  ///
  /// [size] may be left null to inherit from the surrounding style.
  static TextStyle digits(
    Color color, {
    double? size,
    FontWeight weight = FontWeight.w600,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: family,
        fontFeatures: tabular,
        color: color,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );

  static TextStyle eyebrow(AppColors c) => TextStyle(
        fontFamily: family,
        color: c.ink3,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
      );
}
